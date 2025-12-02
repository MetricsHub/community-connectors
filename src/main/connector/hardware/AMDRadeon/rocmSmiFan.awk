BEGIN {
    FS  = "[ \t]+";
    OFS = ";"
}
$1 ~ /^[0-9]+$/ && $2 ~ /^\[/ {
    id  = $1
    fan = $11 #Fan
    gsub("%", "", fan)
    print id, fan
}
