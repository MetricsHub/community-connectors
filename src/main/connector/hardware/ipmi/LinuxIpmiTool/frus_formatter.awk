BEGIN {
    fru = "FRU"
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

# One row, a cell per ";"-separated item (variable count, hence printf)
function printRow(row) {
    printf "%s\n", row
}

/FRU Device Description/ {
    if (fru != "FRU") {
        printRow(fru)
        fru = "FRU"
    }
}

{
    line = trim($0)
    fru = fru ";" line
}

END {
    printRow(fru)
}