BEGIN {
    sdr = "SDR"
    # Table output splits printf text on OFS: SUBSEP, which no cell contains, keeps a ";" in its cell
    OFS = SUBSEP
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

# One row, a cell per OFS-separated item (variable count, hence printf)
function printRow(row) {
    printf "%s\n", row
}

/Sensor ID/ {
    if(sdr != "SDR") {
        printRow(sdr)
        sdr = "SDR"
    }
}

/Device ID/ {
    if(sdr != "SDR") {
        printRow(sdr)
        sdr = "SDR"
    }
}

{
    line = trim($0)
    sdr = sdr OFS line
}

END {
    printRow(sdr)
}