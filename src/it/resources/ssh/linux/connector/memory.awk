BEGIN {
	# Initialization of variables
	memTotal = 0
	memFree = 0
	memUsed = 0
	memBuffers = 0
	memCached = 0
	memFreeUtilization = 0
	memUsedUtilization = 0
	memBuffersUtilization = 0
	memCachedUtilization = 0
	OFS = ";"
}

# From lsmem -b
/^Total online memory:/ {
	memTotal = $4
}

# From /proc/meminfo
/^MemTotal:/ && memTotal == 0 {
	memTotal = $2 * 1024
}

/^MemFree:/ {
	memFree = $2 * 1024
	memFreeUtilization = memFree / memTotal
}

/^Buffers:/ {
	memBuffers = $2 * 1024
	memBuffersUtilization = memBuffers / memTotal
}

/^Cached:/ {
	memCached = $2 * 1024
	memCachedUtilization = memCached / memTotal
}

END {
	# Calculate used memory and its utilization
	memUsed = memTotal - memFree - memBuffers - memCached
	memUsedUtilization = memUsed / memTotal

	# Print the results in the required format
	print(memTotal, memFree, memUsed, memBuffers, memCached, memFreeUtilization, memUsedUtilization, memBuffersUtilization, memCachedUtilization)
}