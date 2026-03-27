#!/bin/sh

# Convert ASCII uppercase letters to lowercase without spawning external tools.
# This is used to normalize labels such as SAT -> sat before building -d options.
lowercase() {
    in=$1
    out=

    while [ -n "$in" ]; do
        c=${in%"${in#?}"}
        in=${in#?}

        case "$c" in
            A) c=a ;;
            B) c=b ;;
            C) c=c ;;
            D) c=d ;;
            E) c=e ;;
            F) c=f ;;
            G) c=g ;;
            H) c=h ;;
            I) c=i ;;
            J) c=j ;;
            K) c=k ;;
            L) c=l ;;
            M) c=m ;;
            N) c=n ;;
            O) c=o ;;
            P) c=p ;;
            Q) c=q ;;
            R) c=r ;;
            S) c=s ;;
            T) c=t ;;
            U) c=u ;;
            V) c=v ;;
            W) c=w ;;
            X) c=x ;;
            Y) c=y ;;
            Z) c=z ;;
        esac

        out=$out$c
    done

    printf '%s\n' "$out"
}

# $1 = path to smartd
# $2 = path to smartctl
SMARTD=$1
SMARTCTL=$2
TMPFILE=/tmp/MS_HW_smartmontoolsHDF_$$

# Build a temporary smartd inventory used to discover SMART-capable disks.
"$SMARTD" -c > "$TMPFILE"
"$SMARTD" -q onecheck >> "$TMPFILE"

while IFS= read -r line; do
    case "$line" in
        "Device: "*' is SMART capable'*)

            # Extract the device path from the second token and strip the trailing comma.
            set -- $line
            DISKID=$2
            DISKID=${DISKID%,}

            DEVTYPE=
            DRIVENUM=
            LABEL=
            # EXTRA is returned so the monitor phase can reuse the same smartctl selector.
            EXTRA=" "

            # Extract the first bracketed label, if present.
            case "$line" in
                *'['*']'*)
                    LABEL=${line#*[}
                    LABEL=${LABEL%%]*}
                    ;;
            esac

            # Ignore bus helper devices that are not real disks.
            case "$DISKID" in
                /dev/bus/*)
                    continue
                    ;;
            esac

            # Build the appropriate smartctl command based on the discovered label.
            if [ -n "$LABEL" ]; then
                LABEL=$(lowercase "$LABEL")

                case "$LABEL" in
                    *_*)
                        # Label format: type_disk_N
                        # Example: sat_disk_2 -> smartctl -d sat,2 -a /dev/sdX
                        DEVTYPE=${LABEL%%_*}
                        DRIVENUM=${LABEL##*_}
                        EXTRA="-d ${DEVTYPE},${DRIVENUM}"
                        OUTPUT=$("$SMARTCTL" -d "${DEVTYPE},${DRIVENUM}" -a "$DISKID" 2>&1)
                        ;;
                    *)
                        # Simple label format: type
                        # Example: sat -> smartctl -d sat -a /dev/sdX
                        DEVTYPE=$LABEL
                        EXTRA="-d ${DEVTYPE}"
                        OUTPUT=$("$SMARTCTL" -d "$DEVTYPE" -a "$DISKID" 2>&1)
                        ;;
                esac
            else
                OUTPUT=$("$SMARTCTL" -a "$DISKID" 2>&1)
            fi

            foundTemperature=0
            warningThreshold=

            # Parse smartctl output to detect whether a temperature reading exists
            # and, when possible, capture the trip/warning threshold.
            while IFS= read -r out_line; do
                case "$out_line" in

                    "Current Drive Temperature:"*)
                        # Example:
                        #   Current Drive Temperature:     31 C
                        # If this line exists with a numeric temperature in Celsius,
                        # then the disk exposes a temperature sensor.
                        set -- $out_line
                        case "$4" in
                            ''|*[!0-9]*)
                                ;;
                            *)
                                [ "$5" = "C" ] && foundTemperature=1
                                ;;
                        esac
                        ;;

                    "Drive Trip Temperature:"*)
                        # Example:
                        #   Drive Trip Temperature:        65 C
                        # Capture the trip threshold when present.
                        set -- $out_line
                        case "$4" in
                            ''|*[!0-9]*)
                                ;;
                            *)
                                warningThreshold=$4
                                ;;
                        esac
                        ;;

                    *)
                        # SMART attributes 190 and 194 are commonly used for temperature.
                        # In the normalized smartctl table, the 10th whitespace-separated
                        # field is the RAW_VALUE column, so we validate that column only.
                        set -- $out_line
                        if [ "$1" = "190" ] || [ "$1" = "194" ]; then
                            i=1
                            for f in "$@"; do
                                if [ "$i" -eq 10 ]; then
                                    case "$f" in
                                        ''|*[!0-9]*)
                                            ;;
                                        *)
                                            foundTemperature=1
                                            # Preserve the historical fallback value
                                            # used when only the SMART attribute exists
                                            # and no explicit trip temperature is printed.
                                            warningThreshold=53
                                            ;;
                                    esac
                                    break
                                fi
                                i=$((i + 1))
                            done
                        fi
                        ;;
                esac
            done <<EOF
$OUTPUT
EOF

            # MetricsHub output format:
            # MSHW;<DeviceID>;<WarningThreshold>;<Extra smartctl args>
            if [ "$foundTemperature" = 1 ]; then
                echo "MSHW;$DISKID;$warningThreshold;$EXTRA"
            fi
            ;;
    esac
done < "$TMPFILE"

rm -f "$TMPFILE"
