#!/bin/sh
SMARTD=$1
SMARTCTL=$2
TMPFILE=/tmp/MS_HW_smartmontoolsHDF_$$

# Generate smartd output and save it to a temporary file.
$SMARTD -c > "$TMPFILE"
$SMARTD -q onecheck >> "$TMPFILE"

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
    # Skip bus devices; if the device path starts with /dev/bus/ then ignore it.
    if echo "$DISKID" | grep -q "^/dev/bus/"; then
        continue
    fi
    # Decide the proper smartctl command based on whether a label was detected.
    if [ -n "$LABEL" ]; then
        # If the label contains an underscore, assume it's of the form "type_disk_N".
        if echo "$LABEL" | grep -q '_'; then
            DEVTYPE=$(echo "$LABEL" | cut -d'_' -f1)
            DRIVENUM=$(echo "$LABEL" | awk -F'_' '{print $NF}')
            CMD="$SMARTCTL -d ${DEVTYPE},${DRIVENUM} -a $DISKID"
        else
            CMD="$SMARTCTL -a $DISKID"
        fi
    else
        CMD="$SMARTCTL -a $DISKID"
    fi
    OUTPUT=$($CMD 2>&1)

    # Parse the output: extract temperature info.
    echo "$OUTPUT" | awk -v deviceID="$DISKID" -v deviceType="$DEVTYPE" -v driveNum="$DRIVENUM" '
    BEGIN {
        foundTemperature = 0;
        warningThreshold = "";
    }
    {
        # Check for a "Current Drive Temperature:" line.
        if ($0 ~ /^Current Drive Temperature: *[0-9]+ C$/) {
            foundTemperature = 1;
        }
        # Check for the SMART attribute 194 line (commonly used for temperature).
        if ($1 == "194" && $10 ~ /^[0-9]+$/) {
            foundTemperature = 1;
            # Using a fixed value (53) as in the original script.
            warningThreshold = 53;
        }
        # Check for a "Drive Trip Temperature:" line.
        if ($0 ~ /^Drive Trip Temperature: /) {
            warningThreshold = $4;
        }
    }
    END {
        if (foundTemperature == 1)
            result = "MSHW;" deviceID ";" warningThreshold;
            if (deviceType != "")
                result = result ";" "-d " deviceType "," driveNum;
            print result;
    }'
done