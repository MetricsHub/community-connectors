BEGIN {
    FS = OFS = ";"
}

function ltrim(ltrimString) { sub(/^[ \t\r\n]+/, "", ltrimString); return ltrimString }
function rtrim(rtrimString) { sub(/[ \t\r\n]+$/, "", rtrimString); return rtrimString }
function trim(trimString) { return rtrim(ltrim(trimString)); }

{
    state = $1
    descriptionLine = $2

    if (descriptionLine != "" && state != "" && state != "N/A") {
        openingParenthesisIndex = index(descriptionLine, "(")
        closingParenthesisIndex = index(descriptionLine, ")")

        sensorId = substr(descriptionLine, openingParenthesisIndex + 1, closingParenthesisIndex - openingParenthesisIndex - 1)
        description = substr(descriptionLine, index(descriptionLine, ":") + 1)
        sensorName = substr(descriptionLine, 0, openingParenthesisIndex - 1)
        
        lookupIndex = index(description, " for ")
        if (lookupIndex != 0) {
            entityId = substr(description, lookupIndex + 5)
            n = split(entityId, entityArray, " ")

            if (n > 1) {
                deviceType = ""
                separator = ""
                for (i = 1; i < n; i++) {
                    deviceType = deviceType separator entityArray[i]
                    separator = " "
                }

                if (state ~ "OEM State,Value=") {
                    state = "0x" substr(state, 19, 2) substr(state, 17, 2)
                }
                gsub(".,", "|" sensorName "=", state)

                currentDevice = devicesMap[entityId]
                if (currentDevice == "") {
                    currentDevice = deviceType ";" sensorId ";" entityId ";" sensorName "=" state
                } else {
                    currentDevice = currentDevice "|" sensorName "=" state
                }
                devicesMap[entityId] = currentDevice
            }
        }
    }
}

END {
    for (entityId in devicesMap) {
        device = devicesMap[entityId]
        split(device, deviceArray, ";")
        deviceState = deviceArray[4]
        if (index(deviceState, "=Device Removed/Device Absent") == 0) {
            gsub("=State Asserted", "=1", deviceState)
            gsub("=State Deasserted", "=0", deviceState)
            gsub("=Deasserted", "=0", deviceState)
            print deviceArray[1], deviceArray[2], deviceArray[3], deviceState
        }
    }
}