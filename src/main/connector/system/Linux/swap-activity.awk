BEGIN {
	OFS = ";"
	pgfault = 0
	pgmajfault = 0
	pswpin = 0
	pswpout = 0
}
/^##VMSTAT##$/ { insec = 1; next }
/^##[A-Z_]+##$/ { if (insec) exit; next }
insec && /^pgfault / { pgfault = $2 }
insec && /^pgmajfault / { pgmajfault = $2 }
insec && /^pswpin / { pswpin = $2 }
insec && /^pswpout / { pswpout = $2 }
END {
	print pgfault, pgmajfault, pswpin, pswpout
}
