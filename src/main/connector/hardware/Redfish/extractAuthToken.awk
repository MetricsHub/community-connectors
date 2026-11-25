BEGIN { FS = ":"; }
$1 ~ /^[Xx]-[Aa][Uu][Tt][Hh]-[Tt][Oo][Kk][Ee][Nn]$/ {
  token = substr($0, index($0, ":") + 1)
  gsub(/^[ \t]+|[ \t\r]+$/, "", token)
  print token
}
