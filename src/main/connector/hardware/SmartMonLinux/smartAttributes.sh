#!/bin/sh

# smartAttributes.sh
#
# Discover SMART-capable disks and extract selected SMART attributes.
# Output:
#   MSHW;<DiskId>;<AttributeName>;<RawValue>

# Lowercase labels without relying on external tools.
lowercase() {
    in=$1
    out=

    while [ -n "$in" ]; do
        c=${in%"${in#?}"}
        in=${in#?}

        case "$c" in
            A) c=a ;; B) c=b ;; C) c=c ;; D) c=d ;; E) c=e ;;
            F) c=f ;; G) c=g ;; H) c=h ;; I) c=i ;; J) c=j ;;
            K) c=k ;; L) c=l ;; M) c=m ;; N) c=n ;; O) c=o ;;
            P) c=p ;; Q) c=q ;; R) c=r ;; S) c=s ;; T) c=t ;;
            U) c=u ;; V) c=v ;; W) c=w ;; X) c=x ;; Y) c=y ;;
            Z) c=z ;;
        esac

        out=$out$c
    done

    printf '%s\n' "$out"
}

SMARTD=$1
SMARTCTL=$2
TMPFILE=/tmp/MS_HW_smartAttributes_$$
SEEN=

# Collect smartd discovery output in one temp file.
"$SMARTD" -c > "$TMPFILE"
"$SMARTD" -q onecheck >> "$TMPFILE"

while IFS= read -r line; do
    case "$line" in
        Device:\ *SMART\ capable*)
            set -- $line
            DISKID=$2
            DISKID=${DISKID%,}

            DEVTYPE=
            DRIVENUM=
            LABEL=
            EXTRA=

            # Extract the bracketed transport hint when present.
            case "$line" in
                *\[*\]*)
                    LABEL=${line#*[}
                    LABEL=${LABEL%%]*}
                    ;;
            esac

            # Skip usb bus entries, smartctl handles the real device.
            case "$DISKID" in
                /dev/bus/*)
                    continue
                    ;;
            esac

            if [ -n "$LABEL" ]; then
                LABEL=$(lowercase "$LABEL")
                case "$LABEL" in
                    *_*)
                        DEVTYPE=${LABEL%%_*}
                        DRIVENUM=${LABEL##*_}
                        EXTRA="-d ${DEVTYPE},${DRIVENUM}"
                        KEY="$DISKID|$EXTRA"
                        ;;
                    *)
                        DEVTYPE=$LABEL
                        EXTRA="-d ${DEVTYPE}"
                        KEY="$DISKID|$EXTRA"
                        ;;
                esac
            else
                KEY="$DISKID|plain"
            fi

            # Avoid probing the same device/type combo twice.
            case "|$SEEN|" in
                *"|$KEY|"*)
                    continue
                    ;;
            esac
            SEEN="$SEEN|$KEY"

            # Run smartctl with extra device hints when needed.
            if [ -n "$EXTRA" ]; then
                OUTPUT=$($SMARTCTL $EXTRA -a "$DISKID" 2>&1)
            else
                OUTPUT=$($SMARTCTL -a "$DISKID" 2>&1)
            fi

            in_smart_table=0

            while IFS= read -r smart_line; do

                # Start reading rows after the SMART attribute header.
                case "$smart_line" in
                    *ID#*ATTRIBUTE_NAME*)
                        in_smart_table=1
                        continue
                        ;;
                esac

                if [ "$in_smart_table" -eq 1 ]; then

                    # Stop once we leave the attribute table.
                    case "$smart_line" in
                        SMART\ *|General\ SMART\ Values:*|SMART\ Error\ Log\ Version:*|ATA\ Error\ Count:*|Error\ counter\ log:*|SMART\ Self-test\ log*|SCT\ *|'')
                            in_smart_table=0
                            continue
                            ;;
                    esac

                    set -- $smart_line

                    # Ignore malformed or non-attribute rows.
                    case "$1" in
                        ''|*[!0-9]*)
                            continue
                            ;;
                    esac

                    attr=$2
                    raw=

                    # Keep the last numeric field as RAW_VALUE.
                    for field in "$@"; do
                        case "$field" in
                            ''|*[!0-9]*)
                                ;;
                            *)
                                raw=$field
                                ;;
                        esac
                    done

                    [ -n "$raw" ] || continue

                    lower_attr=$(lowercase "$attr")

                    match_attr=0
                    case "$attr" in
                        Current_Pending_Sector|Reallocated_Sector_Ct)
                            match_attr=1
                            ;;
                        *)
                            case "$lower_attr" in
                                *error*|*fail*|*bad*|*timeout*)
                                    match_attr=1
                                    ;;
                            esac
                            ;;
                    esac

                    if [ "$match_attr" -eq 1 ]; then
                        display=
                        tmp=$attr

                        # Make attribute names easier to read.
                        while [ -n "$tmp" ]; do
                            c=${tmp%"${tmp#?}"}
                            tmp=${tmp#?}

                            case "$c" in
                                "_"|"-") c=" " ;;
                            esac

                            display=$display$c
                        done

                        printf 'MSHW;%s;%s;%s\n' "$DISKID" "$display" "$raw"
                    fi
                fi

            done <<EOF
$OUTPUT
EOF
            ;;
    esac
done < "$TMPFILE"

rm -f "$TMPFILE"
