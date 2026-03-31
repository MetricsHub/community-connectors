BEGIN {
    OFS = ";"
    reset_record()
}

function reset_record() {
    current_device = ""
    in_smart_table = 0
}

function normalize_attribute_name(name) {
    gsub(/[_-]+/, " ", name)
    return name
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
        if (parts[i] ~ /^-?[0-9]+$/) {
            return parts[i]
        }
    }
    return ""
}

function first_two_tokens(text, tokens, cleaned) {
    cleaned = trim(text)
    return split(cleaned, tokens, /[ \t]+/)
}

/^###DEVICE;;/ {
    # Start a new device section from collector markers.
    split($0, header, /;;/)
    current_device = header[2]
    in_smart_table = 0
    next
}

/^###ENDDEVICE$/ {
    reset_record()
    next
}

current_device != "" {
    # SMART attributes table starts after this header row.
    if ($0 ~ /ID#[ \t]+ATTRIBUTE_NAME/) {
        in_smart_table = 1
        next
    }

    if (!in_smart_table) {
        next
    }

    if ($0 == "" || $0 ~ /^SMART / || $0 ~ /^General SMART Values:/ || $0 ~ /^SMART Error Log Version:/ || $0 ~ /^ATA Error Count:/ || $0 ~ /^Error counter log:/ || $0 ~ /^SMART Self-test log/ || $0 ~ /^SCT /) {
        # Stop when leaving the attributes table.
        in_smart_table = 0
        next
    }

    count = first_two_tokens($0, parts)
    if (parts[1] !~ /^[0-9]+$/) {
        next
    }

    attribute_name = parts[2]
    raw_value = extract_last_integer($0)
    if (raw_value == "") {
        next
    }

    lower_name = tolower(attribute_name)
    # Emit only risk-oriented attributes.
    if (attribute_name == "Current_Pending_Sector" || attribute_name == "Reallocated_Sector_Ct" || lower_name ~ /(error|fail|bad|timeout)/) {
        print "MSHW", current_device, normalize_attribute_name(attribute_name), raw_value
    }
}
