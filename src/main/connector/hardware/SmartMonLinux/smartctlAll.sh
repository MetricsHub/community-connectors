#!/bin/sh

# Convert ASCII uppercase letters to lowercase without external tools.
# This keeps the script strictly POSIX /bin/sh and avoids using tr/awk.
lowercase() {
    in=$1
    out=

    while [ -n "$in" ]; do
        # Extract the first character.
        c=${in%"${in#?}"}
        # Drop the first character from the remaining input.
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

# Build a temporary smartd inventory:
# - smartd -c dumps the parsed configuration / discovered devices
# - smartd -q onecheck performs one immediate check and prints device lines too
"$SMARTD" -c > "$TMPFILE"
"$SMARTD" -q onecheck >> "$TMPFILE"

# Read smartd output line by line and only keep lines announcing SMART-capable devices.
while IFS= read -r line; do
    case "$line" in
        "Device: "*' is SMART capable'*)
            # Parse the device path from the second whitespace-separated token.
            # Example:
            #   Device: /dev/sdb, is SMART capable. Add to smartd database.
            set -- $line
            DISKID=$2
            # Remove the trailing comma after the device path.
            DISKID=${DISKID%,}

            DEVTYPE=
            DRIVENUM=
            LABEL=
            # EXTRA is echoed as the 5th MetricsHub field so the monitor phase
            # can reuse the exact smartctl device selector.
            EXTRA=" "

            # Extract the first bracketed label, if any.
            # smartd lines may include labels like:
            #   [SAT]
            #   [SAT_disk_12]
            case "$line" in
                *'['*']'*)
                    LABEL=${line#*[}
                    LABEL=${LABEL%%]*}
                    ;;
            esac

            # Ignore USB bus helper devices and similar pseudo-paths.
            case "$DISKID" in
                /dev/bus/*)
                    continue
                    ;;
            esac

            # Decide how smartctl must be called.
            if [ -n "$LABEL" ]; then
                # Normalize the label once so both:
                #   SAT        -> sat
                #   SAT_disk_3 -> sat_disk_3
                # are handled consistently.
                LABEL=$(lowercase "$LABEL")

                case "$LABEL" in
                    *_*)
                        # Label format: type_disk_N
                        # Example:
                        #   sat_disk_3 -> DEVTYPE=sat, DRIVENUM=3
                        DEVTYPE=${LABEL%%_*}
                        DRIVENUM=${LABEL##*_}
                        EXTRA="-d ${DEVTYPE},${DRIVENUM}"
                        OUTPUT=$("$SMARTCTL" -d "${DEVTYPE},${DRIVENUM}" -a "$DISKID" 2>&1)
                        ;;
                    *)
                        # Simple label format: type
                        # Example:
                        #   sat -> -d sat
                        DEVTYPE=$LABEL
                        EXTRA="-d ${DEVTYPE}"
                        OUTPUT=$("$SMARTCTL" -d "$DEVTYPE" -a "$DISKID" 2>&1)
                        ;;
                esac
            else
                # Plain device without special selector.
                OUTPUT=$("$SMARTCTL" -a "$DISKID" 2>&1)
            fi

            # Extract inventory fields from smartctl output.
            vendor=
            serialNumber=
            while IFS= read -r out_line; do
                case "$out_line" in
                    [Vv]endor:*)
                        set -- $out_line
                        vendor=$2
                        ;;
                    [Ss]erial\ [Nn]umber:*)
                        set -- $out_line
                        serialNumber=$3
                        ;;
                    [Dd]evice\ [Mm]odel:*)
                        # Fallback for devices that expose only "Device Model"
                        # and no explicit "Vendor" field.
                        if [ -z "$vendor" ]; then
                            set -- $out_line
                            vendor=$3
                        fi
                        ;;
                esac
            done <<EOF
$OUTPUT
EOF

            # MetricsHub output format:
            # MSHW;<DeviceID>;<Vendor>;<SerialNumber>;<Extra smartctl args>
            echo "MSHW;$DISKID;$vendor;$serialNumber;$EXTRA"
            ;;
    esac
done < "$TMPFILE"

rm -f "$TMPFILE"
