BEGIN {
	OFS = ";"
}

/^##SWAPS##$/ { insec = 1; next }
/^##[A-Z_]+##$/ { if (insec) exit; next }

insec && $1 ~ /^\// && $3 ~ /^[0-9]+$/ {
	if ($3 + 0 == 0) {
		next
	}

	# Path;Free;Used;%Free;%Used
	print $1, ($3 - $4) * 1024, $4 * 1024, ($3 - $4) / $3, $4 / $3
}