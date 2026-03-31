{
    # Direct temperature line used by some devices.
    if ($0 ~ /Current Drive Temperature: *[0-9]+ C$/)
    {
        print "MSHW;" $4
        exit;
    }

    # SMART attribute 194 raw value fallback.
    if ($1 == "194" && $10 ~ /[0-9]+/)
    {
      print "MSHW;" $10
      exit;
    }
}
