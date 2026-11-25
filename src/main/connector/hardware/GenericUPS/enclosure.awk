# Loop through each line and sum the values
{
	output += $1
}

# Print the final sum, after MSHW: the constant key that joins this row with the alarm status.
# No row on an empty input (failed or empty output table): the power stays unset instead of 0
END {
	if (NR == 0) {
		exit
	}
	input = output / 0.9
	powerconsumption = input - output
	print "MSHW", powerconsumption
}

