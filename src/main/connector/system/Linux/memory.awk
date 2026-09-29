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

/^##MEM##$/ { insec = 1; next }
/^##[A-Z_]+##$/ { if (insec) exit; next }

insec && /^Total online memory:/ {
    memTotal = $NF
}

insec && /^MemTotal:/ && memTotal == 0 {
    memTotal = $2 * 1024
}

insec && /^MemFree:/ {
    memFree = $2 * 1024
}

insec && /^Buffers:/ {
    memBuffers = $2 * 1024
}

insec && /^Cached:/ {
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
