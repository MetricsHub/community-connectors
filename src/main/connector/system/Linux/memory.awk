BEGIN {
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

/^Total online memory:/ {
    memTotal = $NF
}

/^MemTotal:/ && memTotal == 0 {
    memTotal = $2 * 1024
}

/^MemFree:/ {
    memFree = $2 * 1024
}

/^Buffers:/ {
    memBuffers = $2 * 1024
}

/^Cached:/ {
    memCached = $2 * 1024
}

END {
    if (memTotal > 0) {
        memUsed = memTotal - memFree - memBuffers - memCached
        memFreeUtilization = memFree / memTotal
        memUsedUtilization = memUsed / memTotal
        memBuffersUtilization = memBuffers / memTotal
        memCachedUtilization = memCached / memTotal
    } else {
        memUsed = 0
        memFreeUtilization = 0
        memUsedUtilization = 0
        memBuffersUtilization = 0
        memCachedUtilization = 0
    }

    print memTotal, memFree, memUsed, memBuffers, memCached, memFreeUtilization, memUsedUtilization, memBuffersUtilization, memCachedUtilization
}
