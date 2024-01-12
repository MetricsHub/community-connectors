BEGIN {
	FS = ";"
}

{
	warningThreshold = ""
	alarmThreshold = $2
	model = $3
	if (alarmThreshold == "" || alarmThreshold == 0) {
		if (tolower(model) ~ /ssd|nvm/) {
			warningThreshold = 65
			alarmThreshold = 70
		} else {
			warningThreshold = 41
			alarmThreshold = 50
		}
	}
	print "MSHW;" $1 ";" model ";" warningThreshold ";" alarmThreshold
}

