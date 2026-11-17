BEGIN {
	deviceID = ""
}

$1 ~/^[0-9]+:/ && $2 ~ /^.*:/ {
	deviceID = $2
	gsub(":", "", deviceID)
	ports[deviceID] = deviceID
	if ($2 ~ /UP/ || $3 ~ /UP/) {
		portActive[deviceID] = 1
	}
}

$1 ~ /link.ether/ {
	macAddress[deviceID] = $2
}

/ +inet [0-9]+/ {
	ipAddress[deviceID] = $2
	gsub("/.*", "", ipAddress[deviceID])
}

(/ UP /) {
	portActive[deviceID] = 1
}

END {
	for (deviceID in ports) {
		if (ports[deviceID] != "" && portActive[deviceID] == 1) {
			print deviceID, macAddress[deviceID], ipAddress[deviceID]
		}
	}
}