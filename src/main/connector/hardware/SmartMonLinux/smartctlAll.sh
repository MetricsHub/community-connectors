SMARTD=$1
SMARTCTL=$2
TMPFILE=/tmp/MS_HW_smartmontoolsHDF_$$

# Generate smartd output and save it to a temporary file.
$SMARTD -c > $TMPFILE
$SMARTD -q onecheck >> $TMPFILE

# Extract each device along with its label (if available) from smartd’s output.
# The label (if any) is captured from the first pair of square brackets.
DEVICE_LABEL_LIST=$(awk '/^Device: .* is SMART capable/ {
    deviceID = $2;
    if (substr(deviceID, length(deviceID), 1) == ",")
        deviceID = substr(deviceID, 1, length(deviceID)-1);
    label = "";
    if (match($0, /\[[^]]+\]/)) {
        label = substr($0, RSTART+1, RLENGTH-2);
    }
    print deviceID "|" label;
}' $TMPFILE)


rm -f $TMPFILE

# Loop over each device-label pair.
echo "$DEVICE_LABEL_LIST" | while IFS='|' read DISKID LABEL; do
    DEVTYPE=""
    DRIVENUM=""
    EXTRA=" "
    CMD=""

    # Skip bus devices; if the device path starts with /dev/bus/ then ignore it.
    if echo "$DISKID" | grep -q "^/dev/bus/"; then
        continue
    fi

    if [ -n "$LABEL" ]; then
        # If the label contains an underscore, assume it's of the form "type_disk_N".
        if echo "$LABEL" | grep -q '_'; then
            DEVTYPE=$(echo "$LABEL" | cut -d'_' -f1)
            DRIVENUM=$(echo "$LABEL" | awk -F'_' '{print $NF}')
            EXTRA="-d ${DEVTYPE},${DRIVENUM}"
            CMD="$SMARTCTL -d ${DEVTYPE},${DRIVENUM} -a $DISKID"
        else
            DEVTYPE=$(echo "$LABEL" | tr '[:upper:]' '[:lower:]')
            EXTRA="-d ${DEVTYPE}"
            CMD="$SMARTCTL -a $DISKID"
        fi
    else
        CMD="$SMARTCTL -a $DISKID"
    fi

    # Run smartctl with the determined command.
    OUTPUT=$($CMD 2>&1)

    # Parse the output: extract the vendor from the "Vendor:" line and the serial number.
    echo "$OUTPUT" | awk -v deviceID="$DISKID" -v extra="$EXTRA" '
    BEGIN { vendor=""; serialNumber=""; }
    {
        if (tolower($1)=="vendor:") { vendor = $2; }
        if (tolower($1)=="serial" && tolower($2)=="number:") { serialNumber = $3; }
        if (vendor == "" && tolower($1)=="device" && tolower($2)=="model:") { vendor = $3; }
    }
    END {
        print "MSHW;" deviceID ";" vendor ";" serialNumber ";" extra
    }'
done