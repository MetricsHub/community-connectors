BEGIN { FS=":" }

$1 == "Location" {
    location = substr($0, index($0, ":") + 1)
    gsub(/^[ \t]+|[ \t\r]+$/, "", location)

    # Ne garder que le chemin Redfish
    sub(/^https?:\/\/[^\/]+/, "", location)

    print location
}
