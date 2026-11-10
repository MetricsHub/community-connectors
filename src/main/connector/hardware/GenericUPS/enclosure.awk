# Loop through each line and sum the values
{
	output += $1
}

# Print the final sum, after MSHW: the constant key that joins this row with the alarm status
END {
	input = output / 0.9
	powerconsumption = input - output
	print "MSHW", powerconsumption
}

