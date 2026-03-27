# Extract disk error counters from smartctl output.
BEGIN {
    OFS = ";"
    in_error_log = 0

    # Read-side counters.
    ecc_fast_read = ""
    ecc_delayed_read = ""
    rereads_rewrites_read = ""
    corrected_read = ""
    invocations_read = ""
    uncorrected_read = ""

    # Write-side counters.
    ecc_fast_write = ""
    ecc_delayed_write = ""
    rereads_rewrites_write = ""
    corrected_write = ""
    invocations_write = ""
    uncorrected_write = ""

    non_medium = ""
}

# Start parsing once the error counter section appears.
/^Error counter log:/ {
    in_error_log = 1
    next
}

# Capture the read counters row.
in_error_log && /^read:/ {
    ecc_fast_read         = $2
    ecc_delayed_read      = $3
    rereads_rewrites_read = $4
    corrected_read        = $5
    invocations_read      = $6
    uncorrected_read      = $NF
    next
}

# Capture the write counters row.
in_error_log && /^write:/ {
    ecc_fast_write         = $2
    ecc_delayed_write      = $3
    rereads_rewrites_write = $4
    corrected_write        = $5
    invocations_write      = $6
    uncorrected_write      = $NF
    next
}

# Keep the final non-medium error count.
/^Non-medium error count:/ {
    non_medium = $NF
    next
}

# Emit one joined record for the caller.
END {
    print ecc_fast_read, ecc_delayed_read, rereads_rewrites_read, corrected_read, invocations_read, uncorrected_read, ecc_fast_write, ecc_delayed_write, rereads_rewrites_write, corrected_write, invocations_write, uncorrected_write, non_medium, "joinValue;"
}
