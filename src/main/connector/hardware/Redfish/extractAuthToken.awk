BEGIN { FS = ":"; }
$1 == "X-Auth-Token" {
  gsub(/^[ \t]+|[ \t\r]+$/, "", $2)
  print $2
}