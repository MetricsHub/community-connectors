BEGIN {
	OFS = ";"
	pgfault = 0
	pgmajfault = 0
	pswpin = 0
	pswpout = 0
}
/^pgfault / { pgfault = $2 }
/^pgmajfault / { pgmajfault = $2 }
/^pswpin / { pswpin = $2 }
/^pswpout / { pswpout = $2 }
END {
	print pgfault, pgmajfault, pswpin, pswpout
}