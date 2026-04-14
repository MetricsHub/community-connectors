#!/bin/sh

# Collector only: discover SMART-capable devices, run smartctl -a,
# and emit a deterministic record stream for MetricsHub/Jawk.
# Output contract:
#   ###DEVICE;;<device>;;<smartctl_extra>
#   <verbatim smartctl -a output>
#   ###ENDDEVICE

SMARTD=$1
SMARTCTL=$2
SEEN=

normalize_type() {
    case "$1" in
        SAT|sat)
            printf '%s' 'sat'
            ;;
        NVME|nvme)
            printf '%s' 'nvme'
            ;;
        SCSI|scsi)
            printf '%s' 'scsi'
            ;;
        ATA|ata)
            printf '%s' 'ata'
            ;;
        megaraid|MEGARAID)
            printf '%s' 'megaraid'
            ;;
        *)
            printf '%s' "$1"
            ;;
    esac
}

set -- $SMARTD
"$@" -q onecheck 2>&1 |
while IFS= read -r line; do
    case "$line" in
        "Device: "*' is SMART capable'*)
            set -- $line
            DISKID=$2
            DISKID=${DISKID%,}

            LABEL=
            EXTRA=
            KEY=

            case "$line" in
                *'['*']'*)
                    LABEL=${line#*[}
                    LABEL=${LABEL%%]*}
                    ;;
            esac

            case "$DISKID" in
                /dev/bus/*)
                    continue
                    ;;
            esac

            if [ -n "$LABEL" ]; then
                # smartctl label encodes transport and optional slot/index.
                case "$LABEL" in
                    *_*)
                        DEVTYPE=${LABEL%%_*}
                        DRIVENUM=${LABEL##*_}
                        DEVTYPE=$(normalize_type "$DEVTYPE")
                        EXTRA="-d ${DEVTYPE},${DRIVENUM}"
                        KEY="$DISKID|$EXTRA"
                        ;;
                    *)
                        DEVTYPE=$(normalize_type "$LABEL")
                        EXTRA="-d ${DEVTYPE}"
                        KEY="$DISKID|$EXTRA"
                        ;;
                esac
            else
                KEY="$DISKID|plain"
            fi

            case "|$SEEN|" in
                *"|$KEY|"*)
                    # Skip duplicate device/type combinations.
                    continue
                    ;;
            esac
            SEEN="$SEEN|$KEY"

            set -- $SMARTCTL
            if [ -n "$EXTRA" ]; then
                set -- "$@" $EXTRA
            fi

            printf '###DEVICE;;%s;;%s\n' "$DISKID" "$EXTRA"
            "$@" -a "$DISKID" 2>&1
            printf '%s\n' '###ENDDEVICE'
            ;;
    esac
done
