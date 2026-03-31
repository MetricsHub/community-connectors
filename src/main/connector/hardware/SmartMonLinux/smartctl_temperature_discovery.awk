BEGIN {
    OFS = ";"
    reset_record()
}

function reset_record() {
    current_device = ""
    current_extra = " "
    in_smart_table = 0
    found_temperature = 0
    warning_threshold = ""
}

function start_record(device, extra) {
    reset_record()
    current_device = device
    current_extra = (extra == "" ? " " : extra)
}

function emit_record() {
    if (current_device != "" && found_temperature) {
        if (warning_threshold == "") {
            warning_threshold = 53
        }
        print "MSHW", current_device, warning_threshold, current_extra
    }
}

function trim(text) {
    sub(/^[ \t]+/, "", text)
    sub(/[ \t]+$/, "", text)
    return text
}

function extract_last_integer(text, parts, n, i, cleaned) {
    cleaned = trim(text)
    n = split(cleaned, parts, /[ \t]+/)
    for (i = n; i >= 1; i--) {
        if (parts[i] ~ /^[0-9]+$/) {
            return parts[i]
        }
    }
    return ""
}

function first_token(text, parts, cleaned) {
    cleaned = trim(text)
    split(cleaned, parts, /[ \t]+/)
    return parts[1]
}

/^###DEVICE;;/ {
    # Flush previous device before starting the next one.
    emit_record()
    split($0, header, /;;/)
    start_record(header[2], header[3])
    next
}

/^###ENDDEVICE$/ {
    emit_record()
    reset_record()
    next
}

current_device == "" {
    next
}

$0 ~ /^Current Drive Temperature:[ \t]*[0-9]+[ \t]+C$/ {
    # Device reports a direct current temperature line.
    found_temperature = 1
    next
}

$0 ~ /^Drive Trip Temperature:/ {
    # Prefer vendor-provided trip temperature when available.
    value = extract_last_integer($0)
    if (value != "") {
        warning_threshold = value
    }
    next
}

$0 ~ /ID#[ \t]+ATTRIBUTE_NAME/ {
    # Start scanning SMART attributes as a fallback signal.
    in_smart_table = 1
    next
}

in_smart_table {
    if ($0 == "" ||
        $0 ~ /^SMART / ||
        $0 ~ /^General SMART Values:/ ||
        $0 ~ /^SMART Error Log Version:/ ||
        $0 ~ /^ATA Error Count:/ ||
        $0 ~ /^Error counter log:/ ||
        $0 ~ /^SMART Self-test log/ ||
        $0 ~ /^SCT /) {
        in_smart_table = 0
        next
    }

    token = first_token($0)
    if (token == "190" || token == "194") {
        # Attributes 190/194 indicate temperature support.
        found_temperature = 1
        if (warning_threshold == "") {
            warning_threshold = 53
        }
        next
    }
}

END {
    emit_record()
}
