BEGIN { FS = ":"; }
$1 ~ /^[Xx]-[Aa][Uu][Tt][Hh]-[Tt][Oo][Kk][Ee][Nn]$/ {
  gsub(/^[ \t]+|[ \t\r]+$/, "", $2)
  print $2
}
