BEGIN {
    sdr = "SDR"
    OFS = ";"
}

function ltrim(ltrimString) {
    sub(/^[ \t\r\n]+/, "", ltrimString);
    return ltrimString
}

function rtrim(rtrimString) {
    sub(/[ \t\r\n]+$/, "", rtrimString);
    return rtrimString
}

function trim(trimString) {
    return rtrim(ltrim(trimString));
}

/Sensor ID/ {
    if(sdr != "SDR") {
        print sdr
        sdr = "SDR"
    }
}

/Device ID/ {
    if(sdr != "SDR") {
        print sdr
        sdr = "SDR"
    }
}

{
    line = trim($0)
    sdr = sdr ";" line
}

END {
    print sdr
}