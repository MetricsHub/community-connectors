# PartitionLetter ($2), PartitionName ($3) and LunId(WithDevice) ($11) of the join
$11 ~ /.Device.MPIO/ {
	DriveLetter = $2
	DriveName = $3
	MPIOID = $11
	gsub(".*MPIO", "MPIO ", MPIOID)
	MPIOInfo[MPIOID] = MPIOInfo[MPIOID] DriveLetter " (" DriveName ") "
}

END {
	for (MPIOID in MPIOInfo) {
		if (MPIOInfo[MPIOID] != "") {
			print MPIOID, MPIOInfo[MPIOID]
		}
	}
}

