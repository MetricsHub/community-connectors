BEGIN {
	OFS = ";"
}

/^##NET##$/ { insec = 1; next }
/^##[A-Z_]+##$/ { if (insec) exit; next }
!insec { next }

# Legacy /proc/net/dev counters use the same output columns as ip -s link.
/^Inter-\|/ { legacy = 1; next }
legacy {
	if ($0 !~ /:/) next
	line = $0
	sub(/:/, " ", line)
	split(line, f, " ")
	if (f[1] != "lo") {
		print f[1], "", "", f[2], f[3], f[4], f[5], "", f[9], f[10], f[11], f[12], f[13], f[16], f[15]
	}
	next
}

/RX:/ {
	getline
	rx_bytes = $1
	rx_packets = $2
	rx_errors = $3
	rx_dropped = $4
	rx_missed = $5
	rx_mcast = $6
}

/TX:/ {
	getline
	tx_bytes = $1
	tx_packets = $2
	tx_errors = $3
	tx_dropped = $4
	tx_carrier = $5
	tx_collsns = $6
}

/^[0-9]+:/ {
	if (iface != "") {
		print iface, mtu, state, rx_bytes, rx_packets, rx_errors, rx_dropped, rx_missed, rx_mcast, tx_bytes, tx_packets, tx_errors, tx_dropped, tx_carrier, tx_collsns
	}
	split($2, a, ":")
	iface = a[1]
	mtu = state = rx_bytes = rx_packets = rx_errors = rx_dropped = rx_missed = rx_mcast = tx_bytes = tx_packets = tx_errors = tx_dropped = tx_carrier = tx_collsns = ""
}

# Read header attributes after flushing/resetting the previous interface.
/mtu/ {
	mtu = $5
}

/state/ {
	state = $9
}

END {
	if (iface != "") {
		print iface, mtu, state, rx_bytes, rx_packets, rx_errors, rx_dropped, rx_missed, rx_mcast, tx_bytes, tx_packets, tx_errors, tx_dropped, tx_carrier, tx_collsns
	}
}

