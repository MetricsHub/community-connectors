# cpuinfo_to_freq.awk
/^processor/ {
    # If we’ve already captured a processor entry, emit its data first
    if (cpu != "") {
        print cpu ";" freq_hz
    }

    # Start a new record
    split($0, a, ": ")
    cpu     = a[2]               # logical processor number
    freq_hz = "N/A"              # default until we see “cpu MHz”
}

/^cpu MHz/ {
    split($0, a, ": ")
    freq_hz = int(a[2] * 1000000 + 0.5)   # MHz → Hz, rounded
}

END {
    # Emit the last record (if any)
    if (cpu != "") {
        print cpu ";" freq_hz
    }
}
