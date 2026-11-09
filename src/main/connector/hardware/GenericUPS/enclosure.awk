# Loop through each line and sum the values
{
	output += $1
}

# Print the final sum
END {
	input = output / 0.9
	powerconsumption = input - output
	print "MSHW", powerconsumption
}

