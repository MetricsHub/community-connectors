# DeviceId ($1), TemperatureMax ($6) and Model ($9) of the join
{
	warningThreshold = ""
	alarmThreshold = $6
	model = $9
	if (alarmThreshold == "" || alarmThreshold == 0) {
		if (tolower(model) ~ /ssd|nvm/) {
			warningThreshold = 65
			alarmThreshold = 70
		} else {
			warningThreshold = 41
			alarmThreshold = 50
		}
	}
	print $1, model, warningThreshold, alarmThreshold
}

