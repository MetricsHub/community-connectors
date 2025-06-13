#!/usr/bin/awk -f

{
    # Remove leading and trailing whitespace, store each row
    gsub(/^[ \t]+|[ \t]+$/, "", $0)
    data[NR] = $0
}

END {
    # Print all stored values as a single row, tab-separated
    for (i = 1; i <= NR; i++) {
        printf "%s", data[i]
    }
    printf "\n"
}