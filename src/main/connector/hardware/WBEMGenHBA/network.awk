BEGIN {
	Column = 6
}

{
	# Convert Speed from Gbps to Mbps (unchanged when blank or not a number)
	if ($4 + 0 == $4) $4 = $4 * 1000
	# Remove the array pipes from the port WWN
	gsub(/[|]/, ".", $5)
	n = split($Column, PortWWN, "|")
	hex = ""
	# Skip empty elements: older WMI clients add a trailing "|" to arrays
	for (j = 1; j <= n; j++) {
		if (PortWWN[j] != "") {
			hex = hex sprintf("%02X", PortWWN[j])
		}
	}
	$Column = hex
	print $1, $2, $3, $4, $5, $6, $7
}

