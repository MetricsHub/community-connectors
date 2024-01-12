BEGIN {
	FS = "[;]"
}

{
	ID = $5
	gsub(".[^.]*$", "", ID)
	if ($4 == "11") {
		PresenceID[ID] = $5
	}
	if (ID in tags2) {
		if (tags3[ID] < $3) {
			tags3[ID] = ($3)
		}
		if ($3 > 5) {
			if (tags2[ID] == "") {
				tags2[ID] = $2
			} else {
				tags2[ID] = (tags2[ID] " - " $2)
			}
		}
	} else {
		if ($3 > 0) {
			tags3[ID] = ($3)
		}
		if ($3 > 5) {
			tags2[ID] = $2
		}
	}
}

END {
	for (ID in tags3) {
		print ("MSHW;" PresenceID[ID] ";" tags2[ID] ";" tags3[ID] ";")
	}
}

