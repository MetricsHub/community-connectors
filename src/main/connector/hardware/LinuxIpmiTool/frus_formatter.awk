function ltrim(ltrimString) { sub(/^[ \t\r\n]+/, "", ltrimString); return ltrimString }
function rtrim(rtrimString) { sub(/[ \t\r\n]+$/, "", rtrimString); return rtrimString }
function trim(trimString) { return rtrim(ltrim(trimString)); }

BEGIN {
    fru = "FRU"
}

/FRU Device Description/ {
    if (fru != "FRU") {
        print fru
        fru = "FRU"
    }
}

{
    line = trim($0)
    fru = fru ";" line
}

END {
    print fru
}