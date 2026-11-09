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

# One row, a cell per ";"-separated item (variable count, hence printf); like toTable, drop one trailing empty cell
function printRow(row) {
    sub(/;$/, "", row)
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
    sdr = sdr ";" line
}

END {
    printRow(sdr)
}