BEGIN {
	deviceID = ""
}

#ifconfig
($2 ~ /flags/ || $2 ~ /Link/ && $3 ~ /encap/) {
	deviceID = $1
	gsub(":", "", deviceID)
	ports[deviceID] = deviceID
	if ($(NF - 1) == "HWaddr") {
		macAddress[deviceID] = $NF
	}
	if ($2 ~ /UP/ || $3 ~ /UP/) {
		portActive[deviceID] = 1
	}
}

/ +inet (addr:)?/ {
    ipAddress[deviceID] = $2
    gsub("addr:", "", ipAddress[deviceID])
}

(/ UP /) {
	portActive[deviceID] = 1
}

$1 ~ /^ether$/ && $2 ~ /[0-9A-Fa-f][0-9A-Fa-f]:[0-9A-Fa-f][0-9A-Fa-f]:/ {
	macAddress[deviceID] = $2
}

END {
	for (deviceID in ports) {
		if (ports[deviceID] != "" && portActive[deviceID] == 1) {
			print deviceID, macAddress[deviceID], ipAddress[deviceID]
		}
	}
}