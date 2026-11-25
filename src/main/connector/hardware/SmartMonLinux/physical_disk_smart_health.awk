# The SMART status twice: the first copy becomes the join key, the second the PredictedFailure value
{
    # SCSI/SAS wording.
    if ($0 ~ /^SMART Sense: /)
    {
        print $3, $3
        exit;
    }

    # ATA/NVMe wording.
    if ($0 ~ /^SMART Health Status: /)
    {
        print $4, $4
        exit;
    }

    # Legacy SMART wording.
    if ($0 ~ /^SMART overall-health self-assessment test result: /)
    {
        print $6, $6
        exit;
    }

}
