BEGIN {
	transmitPackets = ""
	transmitErrors = ""
	receivePackets = ""
	receiveErrors = ""
	transmitBytes = ""
	receiveBytes = ""
	ipState = ""
}

$1 ~/^[0-9]+:/ && $2 ~ /^.*:/ {
	deviceID = $2
	gsub(":", "", deviceID)

	ipState = ""
	if (match($0, / state [A-Z_]+ /)) {
		ipState = substr($0, RSTART + 7, RLENGTH - 8)
	}
}

$1 ~ /RX:/ && $2 ~ /bytes/ && $3 ~ /packets/ {
	getline
	receiveBytes = $1
	receivePackets = $2
	receiveErrors = $3
}

$1 ~ /TX:/ && $2 ~ /bytes/ && $3 ~ /packets/ {
	getline
	transmitBytes = $1
	transmitPackets = $2
	transmitErrors = $3
}

END {
	print "MSHW;" deviceID ";" receivePackets ";" transmitPackets ";" (receiveErrors + transmitErrors) ";" receiveBytes ";" transmitBytes ";" ipState
}