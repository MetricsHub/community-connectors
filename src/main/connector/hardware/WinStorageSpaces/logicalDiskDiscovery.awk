BEGIN {
	alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
}

# Keep only drive type 3 ("Fixed Drive")
$3 == "3" {
	if ($2 > 64 && $2 < 91) {
		deviceId = substr(alphabet, int($2) - 64, 1) ":"
		label = deviceId
	} else {
		deviceId = $1
		label = ""
	}
	if ($5 != "") {
		if (label != "") {
			label = label " "
		}
		label = label $5
	}
	filesystem = $4
	size = $6
	print deviceId, label, "File System: " filesystem, size
}

