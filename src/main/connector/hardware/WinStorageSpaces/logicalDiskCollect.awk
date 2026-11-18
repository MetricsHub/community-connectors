BEGIN {
	alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
}

{
	if ($2 > 64 && $2 < 91) {
		deviceId = substr(alphabet, int($2) - 64, 1) ":"
	} else {
		deviceId = $1
	}
	print deviceId, $3, $4, $5
}

