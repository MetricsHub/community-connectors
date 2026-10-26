# Turns the output of "ipmitool chassis status" into the Chassis line read by interpret_sensors.awk:
# Chassis;powerOn;powerFault;powerOverload;interlock;powerControlFault;coolingFault;driveFault;intrusion;frontPanelLockout;powerRestorePolicy;identifyState;lastPowerEvents
# Flags are 1/0. identifyState stays empty: ipmitool does not report it.
# Nothing is printed when the output has no "System Power" line (empty output, command refused by the BMC).
BEGIN {
	FS = ":"
}

function flag(value) {
	value = tolower(value)
	return (value == "on" || value == "true" || value == "active") ? 1 : 0
}

{
	sub(/\r$/, "")
	key = $1
	sub(/[ \t]+$/, "", key)
	value = substr($0, index($0, ":") + 1)
	gsub(/^[ \t]+|[ \t]+$/, "", value)
	status[key] = value
}

END {
	if ("System Power" in status) {
		policy = status["Power Restore Policy"]
		if (policy == "previous") {
			policy = "PowerRestored"
		} else if (policy == "always-off") {
			policy = "PoweredOff"
		} else if (policy == "always-on") {
			policy = "PoweredUp"
		} else {
			policy = "Unknown"
		}
		events = ""
		eventCount = split(status["Last Power Event"], eventTokens, " ")
		for (i = 1; i <= eventCount; i++) {
			event = eventTokens[i]
			if (event == "ac-failed") {
				event = "AC_FAILED"
			} else if (event == "overload") {
				event = "POWER_OVERLOAD"
			} else if (event == "interlock") {
				event = "INTERLOCK"
			} else if (event == "fault") {
				event = "POWER_FAULT"
			} else if (event == "command") {
				event = "IPMI_COMMAND"
			} else {
				continue
			}
			events = events (events == "" ? "" : "|") event
		}
		print "Chassis;" flag(status["System Power"]) ";" flag(status["Main Power Fault"]) ";" flag(status["Power Overload"]) ";" flag(status["Power Interlock"]) ";" flag(status["Power Control Fault"]) ";" flag(status["Cooling/Fan Fault"]) ";" flag(status["Drive Fault"]) ";" flag(status["Chassis Intrusion"]) ";" flag(status["Front-Panel Lockout"]) ";" policy ";;" events
	}
}
