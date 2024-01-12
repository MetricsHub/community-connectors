BEGIN {
	FS = ":"
	Manufacturer = ""
	Type = ""
}

{
	if ($1 ~ /Manufacturer/) {
		Manufacturer = $2
	}
	if ($1 ~ /Product Name/) {
		Type = $2
	}
	if ($1 ~ /Serial Number/) {
		SN = $2
		print ("MSHW;" Manufacturer ";" Type ";" SN ";")
	}
}

