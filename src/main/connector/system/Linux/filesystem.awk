/^##DF##$/ { insec = 1; next }
/^##[A-Z_]+##$/ { if (insec) exit; next }

# LC_ALL=C in the snapshot makes the df header independent of the host locale.
# Modern: Filesystem Mounted on Type Used Avail 1B-blocks
# Legacy: Filesystem Type 1024-blocks Used Available Capacity Mounted on
insec && /^Filesystem[ \t]/ { legacy = ($2 == "Type"); next }

insec && $1 ~ /^\/dev/ {
	if (!legacy) {
		# Modern: df -B1 --output=source,target,fstype,used,avail,size
		size = $6
		used = $4
		free = $5
		mountpoint = $2
		fstype = $3
	} else {
		# Legacy: df -k -P -T
		size = $3 * 1024
		used = $4 * 1024
		free = $5 * 1024
		mountpoint = $7
		fstype = $2
	}

	if (size <= 0) next

	reserved = size - (used + free)
	if (reserved < 0) reserved = 0

	print $1 "(" mountpoint ")" ";" mountpoint ";" fstype ";" used ";" free ";" used / size ";" free / size ";" reserved ";" reserved / size
}
