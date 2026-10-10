BEGIN {
	FS = ": "
	gpuID = ""
	model = ""
	serialNumber = ""
	gpuUuid = ""
	vBios = ""
	driverVersion = ""
	cudaVersion = ""
	firmwareVersion = ""
	transferredBytes = ""
	receivedBytes = ""
	gpuUtilization = ""
	memoryUtilization = ""
	encoderUtilization = ""
	decoderUtilization = ""
	fanSpeed = ""
	voltage = ""
	temperature = ""
	warnTemperature = ""
	critTemperature = ""
	powerConsumption = ""
	minPowerLimit = ""
	maxPowerLimit = ""
	correctable = ""
	uncorrectable = ""
	totalMemory = ""
	usedMemory = ""
}

#Remember the current top-level section of the card, to tell apart the fields that share the same label
#(e.g. "GPU Power Readings" vs. "GPU Memory Power Readings", "FB Memory Usage" vs. "BAR1 Memory Usage").
/^    [^ ]/ {
	section = $0
}

#Discovery related values and informative fields.
/GPU 0/ {
	split($0, outputarray, ":")
	gpuID = outputarray[2]
}

/Product Name/ {
	model = $2
}

/Serial Number/ && /[0-9]/ {
	serialNumber = $2
}

/GPU UUID/ {
	gpuUuid = "GPU UUID: " $2
}

/VBIOS Version/ {
	vBios = " VBIOS Version: " $2
}

#Since v595, "Driver Version" and "CUDA Version" are deprecated (with a "[Deprecated; ...]" suffix that would break our ";" output)
#in favor of "KMD Version" and "CUDA UMD Version". Keep only the version number.
/^(Driver|KMD) Version/ {
	driverVersion = $2
	sub(/ .*/, "", driverVersion)
}

/^CUDA (UMD )?Version/ {
	cudaVersion = $2
	sub(/ .*/, "", cudaVersion)
	cudaVersion = "CUDA Version: " cudaVersion
}

/Firmware Version/ && /[0-9]/ {
	firmwareVersion = $2
}

section ~ /^    FB Memory Usage/ && /^ +Total +:/ {
	totalMemory = $2
	gsub(/ MiB/, "", totalMemory)
}

section ~ /^    FB Memory Usage/ && /^ +Used +:/ {
	usedMemory = $2
	gsub(/ MiB/, "", usedMemory)
}

#Collection related values and removal of units of measurement.
/Tx Throughput/ && /[0-9]/ {
	transferredBytes = $2
	gsub(/ KB\/s/, "", transferredBytes)
}

/Rx Throughput/ && /[0-9]/ {
	receivedBytes = $2
	gsub(/ KB\/s/, "", receivedBytes)
}

#"Gpu" in older versions, "GPU" in newer ones.
/^ *(Gpu|GPU) +:/ && /%/ {
	gpuUtilization = $2
	gsub(/ %/, "", gpuUtilization)
}

/Encoder/ && /%/ {
	encoderUtilization = $2
	gsub(/ %/, "", encoderUtilization)
}

/Decoder/ && /%/ {
	decoderUtilization = $2
	gsub(/ %/, "", decoderUtilization)
}

#We will now extract and do the sum of the ecc errors.
#/Correctable/ && /[0-9]/  { correctable+=$2; }
#/Uncorrectable/ && /[0-9]/  { uncorrectable+=$2; }

#We will now extract the power consumption.
section ~ /^    (GPU )?Power Readings/ && /Power Draw/ && /[0-9]/ {
	powerConsumption = $2
	gsub(/ W/, "", powerConsumption)
}

/Min Power Limit/ && /[0-9]/ {
	minPowerLimit = $2
	gsub(/ W/, "", minPowerLimit)
}

/Max Power Limit/ && /[0-9]/ {
	maxPowerLimit = $2
	gsub(/ W/, "", maxPowerLimit)
}

#TBD IF REQUIRED.
#Parsing through the file to gather the clock speeds. As there are several iterations of these strings, we had to isolate them.

#/^    Clocks$/ { for(i=1; i<=4; i++);
#  IF (/Graphics/) getline; graphicsClock = $2; gsub(/ MHz/,"",graphicsClock);
#  IF (/SM/) getline; smClock = $2; gsub(/ MHz/,"",smClock);
#  IF (/Memory/) getline; memoryClock = $2; gsub(/ MHz/,"",memoryClock);
#  IF (/Video/) getline; videoClock = $2; gsub(/ MHz/,"",videoClock); }

#Collection of fan class values and removal of units of measurement.
/Fan Speed/ && /[0-9]/ {
	fanSpeed = $2
	gsub(/ %/, "", fanSpeed)
}

#Collection of voltage class values and removal of units of measurement.
/Voltage/ {
	getline
	if (/[0-9]/) {
		voltage = $2
	}
	gsub(/ mV/, "", voltage)
}

#We will now extract the temperature along with its thresholds.
/GPU Current Temp/ && /[0-9]/ {
	temperature = $2
	gsub(/ C/, "", temperature)
}

/GPU Target Temperature/ && /[0-9]/ {
	warnTemperature = $2
	gsub(/ C/, "", warnTemperature)
}

/GPU Slowdown Temp/ && /[0-9]/ {
	critTemperature = $2
	gsub(/ C/, "", critTemperature)
}

#We will now print all the relevant information, separated by classes. Processes being the last category, this will allow us to print these at the end of each card.
#We then reset all variables to empty values for the next card, except the driver and CUDA versions which are global to all cards.
/Processes/ {
	#Memory utilization is the fraction of the frame buffer in use (not the "Utilization > Memory" bandwidth activity).
	if (totalMemory > 0 && usedMemory != "") {
		memoryUtilization = usedMemory * 100 / totalMemory
	}
	print "MSHW_GPU;" "GPU" gpuID ";" (transferredBytes * 1024) ";" (receivedBytes * 1024) ";" gpuUtilization ";" memoryUtilization ";" encoderUtilization ";" decoderUtilization ";" powerConsumption ";" minPowerLimit ";" maxPowerLimit ";" correctable ";" uncorrectable ";" model ";" serialNumber ";" gpuUuid vBios ";" driverVersion ";" cudaVersion ";" firmwareVersion ";" totalMemory ";" usedMemory
	print "MSHW_TEMP;" "GPU" gpuID ";" temperature ";" warnTemperature ";" critTemperature
	print "MSHW_VOLTAGE;" "GPU" gpuID ";" voltage
	print "MSHW_FAN;" "GPU" gpuID ";" fanSpeed
	gpuID = ""
	model = ""
	serialNumber = ""
	gpuUuid = ""
	vBios = ""
	firmwareVersion = ""
	transferredBytes = ""
	receivedBytes = ""
	gpuUtilization = ""
	memoryUtilization = ""
	encoderUtilization = ""
	decoderUtilization = ""
	fanSpeed = ""
	voltage = ""
	temperature = ""
	warnTemperature = ""
	critTemperature = ""
	powerConsumption = ""
	minPowerLimit = ""
	maxPowerLimit = ""
	correctable = ""
	uncorrectable = ""
	totalMemory = ""
	usedMemory = ""
}

