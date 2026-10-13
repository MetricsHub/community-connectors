BEGIN {
	FS = ": "
	vmName = ""
	uuid = ""
	powerState = ""
	powerShare = ""
}

# One row per domain of virsh list, even when its virsh dominfo failed (no state, no CPU count):
# a missing row would remove the vm monitor
function printDomain() {
	if (vmName != "") {
		print vmName ";" powerState ";" powerShare ";" (uuid == "" ? "" : "UUID: " uuid)
	}
	vmName = ""
	uuid = ""
	powerState = ""
	powerShare = ""
}

/^Domain / {
	printDomain()
	vmName = substr($0, 8)
	gsub(/ /, "", vmName)
	next
}

/UUID/ {
	uuid = $2
	gsub(/ /, "", uuid)
}

/State/ {
	powerState = $2
	gsub(/ /, "", powerState)
}

/CPU\(s\)/ {
	powerShare = $2
	gsub(/ /, "", powerShare)
}

END {
	printDomain()
}

