{
    # SCSI/SAS wording.
    if ($0 ~ /^SMART Sense: /)
    {
        print "MSHW;" $3
        exit;
    }

    # ATA/NVMe wording.
    if ($0 ~ /^SMART Health Status: /)
    {
        print "MSHW;" $4
        exit;
    }

    # Legacy SMART wording.
    if ($0 ~ /^SMART overall-health self-assessment test result: /)
    {
        print "MSHW;" $6
        exit;
    }

}
