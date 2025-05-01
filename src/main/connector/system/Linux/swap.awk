BEGIN {
	OFS = ";"
}
$1 ~ "^/" {
	# Path;Free;Used;%Free;%Used
	print $1, ($3 - $4) * 1024, $4 * 1024, ($3 - $4) / $3, $4 / $3
}