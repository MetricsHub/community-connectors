{
    # SCSI/SAS wording.
    if ($0 ~ /^SMART Sense: /)
    {
        print $3
        exit;
    }

    # ATA/NVMe wording.
    if ($0 ~ /^SMART Health Status: /)
    {
        print $4
        exit;
    }

    # Legacy SMART wording.
    if ($0 ~ /^SMART overall-health self-assessment test result: /)
    {
        print $6
        exit;
    }

}
