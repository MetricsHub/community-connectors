# With the variable type (10 for the fans), only the sensors of that type
type == "" || $12 "" == type {
	print $1 - 11, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $1
}

