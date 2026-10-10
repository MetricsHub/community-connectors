BEGIN {
	FS = "[;]"
	Column = 6
}

{
	n = split($Column, PortWWN, "|")
	printf "MSHW;"
	for (i = 1; i <= NF - 1; i++) {
		if (i == Column) {
			# Skip empty elements: older WMI clients add a trailing "|" to arrays
			for (j = 1; j <= n; j++) {
				if (PortWWN[j] != "") {
					printf "%02X", PortWWN[j]
				}
			}
			printf ";"
		} else {
			printf $i
			printf ";"
		}
	}
	print ""
}

