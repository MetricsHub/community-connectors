{
	if (length($2) > 0) {
		upper = $2 / 100 * 110
		lower = $2 / 100 * 90
	} else{
		upper = ""
		lower = ""
	}

	print $1, $2, upper, lower
}

