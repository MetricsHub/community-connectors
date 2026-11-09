$1 ~ /.Device.MPIO/ {
	print $1, toupper($2)
}

