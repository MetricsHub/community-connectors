BEGIN {
    OFS = ";"
    reset_record()
}

function reset_record() {
    current_device = ""
    current_extra = " "
    vendor = ""
    serial = ""
    model = ""
    product = ""
}

function trim(text) {
    sub(/^[ \t]+/, "", text)
    sub(/[ \t]+$/, "", text)
    return text
}

function first_token(text, parts, cleaned) {
    cleaned = trim(text)
    split(cleaned, parts, /[ \t]+/)
    return parts[1]
}

function pick_vendor() {
    # Prefer explicit vendor, then fallback to model/product prefix.
    if (vendor != "") {
        return vendor
    }
    if (model != "") {
        return first_token(model)
    }
    if (product != "") {
        return first_token(product)
    }
    return ""
}

/^###DEVICE;;/ {
    # Reset device-scoped fields for each collected block.
    split($0, header, /;;/)
    current_device = header[2]
    current_extra = (header[3] == "" ? " " : header[3])
    vendor = ""
    serial = ""
    model = ""
    product = ""
    next
}

/^###ENDDEVICE$/ {
    if (current_device != "") {
        # Emit one inventory row per completed device block.
        print "MSHW", current_device, pick_vendor(), serial, current_extra
    }
    reset_record()
    next
}

current_device != "" {
    if ($0 ~ /^[Vv]endor:[ \t]*/) {
        value = $0
        sub(/^[Vv]endor:[ \t]*/, "", value)
        vendor = trim(value)
        next
    }

    if ($0 ~ /^[Pp]roduct:[ \t]*/) {
        value = $0
        sub(/^[Pp]roduct:[ \t]*/, "", value)
        product = trim(value)
        next
    }

    if ($0 ~ /^[Ss]erial [Nn]umber:[ \t]*/) {
        value = $0
        sub(/^[Ss]erial [Nn]umber:[ \t]*/, "", value)
        serial = trim(value)
        next
    }

    if ($0 ~ /^[Dd]evice [Mm]odel:[ \t]*/) {
        value = $0
        sub(/^[Dd]evice [Mm]odel:[ \t]*/, "", value)
        model = trim(value)
        next
    }

    if ($0 ~ /^[Mm]odel [Nn]umber:[ \t]*/) {
        value = $0
        sub(/^[Mm]odel [Nn]umber:[ \t]*/, "", value)
        model = trim(value)
        next
    }
}
