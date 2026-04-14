#!/bin/sh

# Read a few blocks from the target device/file to validate accessibility.
# The %{SUDO:/bin/dd} macro lets MetricsHub prepend sudo when configured.
# We discard the data itself and keep only stderr/stdout for status analysis.
ERRORMESSAGE=`%{SUDO:/bin/dd}/bin/dd if=$1 of=/dev/null count=20 2>&1`

# dd exited successfully: report a healthy status.
if [ "$?" = "0" ]; then
  printf '%s\n' "MSHW;1;OK;Working"
else
    # Keep only the part after the last colon to remove the noisy dd prefix.
    # Example:
    #   dd: failed to open '/dev/sdb': Permission denied
    # becomes:
    #   Permission denied
    ERRORMESSAGE=${ERRORMESSAGE##*:}
    ERRORMESSAGE=${ERRORMESSAGE# }

    case "$ERRORMESSAGE" in
        # Permission / missing-device cases are treated as UNKNOWN rather than ALARM.
        *denied*|*[Nn]o\ such\ file*|'')
            printf '%s\n' "MSHW;1;UNKNOWN;Unknown Status"
            ;;
        # Any other explicit dd error is reported as ALARM with the extracted message.
        *)
            printf '%s\n' "MSHW;1;ALARM;$ERRORMESSAGE"
            ;;
    esac
fi
