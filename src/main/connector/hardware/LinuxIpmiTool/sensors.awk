function checkSubStrAndReturnDelimitedString(str, subStr) {
    pos = index(str, subStr)
    if (pos != 0) {
        rest = substr(str, pos + length("subStr"))
        colonIndex = index(rest, ":")

        if (colonIndex > 0) {
            result = substr(rest, colonIndex + 1)
            gsub("/^[ \t]+|[ \t]+$/", "", result)

            return result
        }
    }
    return ""
}

function hex_to_dec(hex, i, c, val, digit) {
    val = 0
    for (i = 1; i <= length(hex); i++) {
        c = substr(hex, i, 1)
        if (c >= "0" && c <= "9") digit = c - "0"
        else if (c >= "A" && c <= "F") digit = 10 + index("ABCDEF", c) - 1
        else if (c >= "a" && c <= "f") digit = 10 + index("abcdef", c) - 1
        else digit = 0
        val = val * 16 + digit
    }
    return val
}

function isANumber(value) {
    return value ~ /^[+-]?[0-9]+([.][0-9]+)?$/
}

function formatResult(sensorString) {
    if (index(sensorString, "=Device Absent") == 0) {
        gsub("=State Asserted", "=1", sensorString)
        gsub("=State Deasserted", "=0", sensorString)
        gsub("=Asserted", "=1", sensorString)
        gsub("=Deasserted", "=0", sensorString)
        location = deviceType " " deviceId

        if (sensorReading == "") {
            if (statusGroup == "" && sensorFruId == "") {
                return ""
            } else {
                return sensorString
            }
        }
        indexSensorOpenParenthesis = index(sensorReading, "(")
        indexSensorTwoPoints = index(sensorReading, ":")

        if (indexSensorOpenParenthesis != 0) {
            valueReading = substr(sensorReading, indexSensorTwoPoints + 1, indexSensorOpenParenthesis - indexSensorTwoPoints - 1)
            gsub(" ", "", valueReading)

            unit = substr(sensorReading, index(sensorReading, ")") + 1)
            gsub(" ", "", unit)

            if (unit == "degreesC") {
                threshold1 = thresholdUpperNonCritical
                if (!isANumber(threshold1)) {
                    threshold1 = ""
                }

                threshold2 = thresholdUpperCritical
                if (!isANumber(threshold2)) {
                    threshold2 = thresholdUpperNonRecoverable
                    if (!isANumber(threshold2)) {
                        threshold2 = ""
                    }
                }
                return "Temperature;" sensorId ";" sensorName ";" status ";" statusGroup ";" sensorFruId ";" location ";" valueReading ";" threshold1 ";" threshold2
            } else if (unit == "RPM") {
                threshold1 = thresholdLowerNonCritical

                if (!isANumber(threshold1)) {
                    threshold1 = ""
                }

                threshold2 = thresholdLowerCritical
                if (!isANumber(threshold2)) {
                    threshold2 = thresholdLowerNonRecoverable
                    if (!isANumber(threshold2)) {
                        threshold2 = ""
                    }
                }

                return "Fan;" sensorId ";" sensorName ";" status ";" statusGroup ";" sensorFruId ";" location ";" valueReading ";" threshold1 ";" threshold2
            } else if (unit == "Volts") {
                threshold1 = thresholdLowerNonCritical
                if (threshold1 == "" || !isANumber(threshold1) || threshold1 == "0") {
                    threshold1 = thresholdLowerCritical
                    if (threshold1 == "" || !isANumber(threshold1) || threshold1 == "0") {
                        threshold1 = thresholdLowerNonRecoverable
                        if (!isANumber(threshold1) || threshold1 == "0") {
                            threshold1 == ""
                        }
                    }
                }
                threshold2 = thresholdUpperNonCritical
                if (threshold2 == "" || !isANumber(threshold2) || threshold2 == "0") {
                    threshold2 = thresholdUpperCritical
                    if (threshold2 == "" || !isANumber(threshold2) || threshold2 == "0") {
                        threshold2 = thresholdUpperNonRecoverable
                        if (!isANumber(threshold2) || threshold2 == "0") {
                            threshold2 == ""
                        }
                    }
                }
                if (isANumber(threshold1)) {
                    threshold1 = threshold1 * 1000
                }
                if (isANumber(threshold2)) {
                    threshold2 = threshold2 * 1000
                }
                if (isANumber(valueReading)) {
                    valueReading = valueReading * 1000
                }
                return "Voltage;" sensorId ";" sensorName ";" status ";" statusGroup ";" sensorFruId ";" location ";" valueReading ";" threshold1 ";" threshold2
            } else if (unit == "Amps") {
                return "Current;" sensorId ";" sensorName ";" status ";" statusGroup ";" sensorFruId ";" location ";" valueReading ";" statusGroup
            } else if (unit == "Watts") {
                return "PowerConsumption;" sensorId ";" sensorName ";" status ";" statusGroup ";" sensorFruId ";" location ";" valueReading
            } else if (unit == "percent") {
                return sensorName ";" sensorId ";" sensorName ";" status ";" statusGroup ";" sensorFruId ";" location ";" valueReading / 100
            }
        }
        if (statusGroup == "" && sensorFruId == "") {
            return ""
        } else {
            return sensorString
        }
    }
}

function ltrim(ltrimString) { sub(/^[ \t\r\n]+/, "", ltrimString); return ltrimString }
function rtrim(rtrimString) { sub(/[ \t\r\n]+$/, "", rtrimString); return rtrimString }
function trim(trimString) { return rtrim(ltrim(trimString)); }

BEGIN {
    FS = "\n"
    OFS = ";"
    sensorId = ""
    sensorName = ""
    entityId = ""
    deviceType = ""
    deviceId = ""
    trueDeviceId = ""
    statesAsserted = 0
    statusGroup = ""
    status = ""
    assertionsEnabled = 0
    separator = ""
    sensorReading = ""
    sensorFruId = ""
    thresholdUpperNonCritical = ""
    thresholdUpperCritical = ""
    thresholdLowerNonCritical = ""
    thresholdLowerCritical = ""
    thresholdUpperNonRecoverable = ""
}

{
    sdrEntry = $0

    if (trim(sdrEntry) == "") {
        # enf of sensor, so we print it if there is actually one

        if (sensorId != "" || trueDeviceId == "System Board") {
            result = formatResult(deviceType ";" deviceId ";" deviceType " " deviceId ";" status ";" statusGroup ";" sensorFruId)
            if (result != "") {
                print result
            }
        }

        # prepare next sensor
        sensorId = ""
        sensorName = ""
        entityId = ""
        deviceType = ""
        deviceId = ""
        trueDeviceId = ""
        statesAsserted = 0
        statusGroup = ""
        status = ""
        assertionsEnabled = 0
        separator = ""
        sensorReading = ""
        sensorFruId = ""
        thresholdUpperNonCritical = ""
        thresholdUpperCritical = ""
        thresholdLowerNonCritical = ""
        thresholdLowerCritical = ""
        thresholdUpperNonRecoverable = ""
    } else {
        sensorIdLine = checkSubStrAndReturnDelimitedString(sdrEntry, "Sensor ID")
        openingParenthesisIndex = index(sensorIdLine, "(")
        closingParenthesisIndex = index(sensorIdLine, ")")
        if (openingParenthesisIndex != 0) {
            sensorName = trim(substr(sensorIdLine, 0, openingParenthesisIndex - 2))
            if (closingParenthesisIndex != 0 && closingParenthesisIndex > openingParenthesisIndex) {
                sensorId = trim(substr(sensorIdLine, openingParenthesisIndex + 1, closingParenthesisIndex - openingParenthesisIndex - 1))
            }
        }

        trueDeviceIdIndex = index(sdrEntry, "Device ID")

        if (trueDeviceIdIndex != 0) {
            trueDeviceId = trim(checkSubStrAndReturnDelimitedString(sdrEntry, "Device ID"))
        }

        entityIdLine = checkSubStrAndReturnDelimitedString(sdrEntry, "Entity ID")
        if (entityIdLine != "") {
            openingParenthesisIndex = index(entityIdLine, "(")
            if (openingParenthesisIndex != 0) {
                entityId = trim(substr(entityIdLine, 0, openingParenthesisIndex- 1))
            }

            indexPoint = index(entityIdLine, ".")
            if (indexPoint != 0) {
                deviceId = trim(substr(entityIdLine, 1, indexPoint - 1))
            }

            openingParenthesisIndex = index(entityIdLine, "(")
            closingParenthesisIndex = index(entityIdLine, ")")
            if (openingParenthesisIndex > 0 && closingParenthesisIndex > openingParenthesisIndex) {
                deviceType = substr(entityIdLine, openingParenthesisIndex + 1, closingParenthesisIndex - openingParenthesisIndex - 1)
                deviceType = trim(substr(entityIdLine, openingParenthesisIndex + 1, closingParenthesisIndex - openingParenthesisIndex - 1))
            }
        }

        oemSpecificIndex = index(sdrEntry, "OEM Specific")
        zeroXIndex = index(sdrEntry, "0x")

        if (index(sdrEntry, "States Asserted") != 0) {
            statesAsserted = 1
        }

        if (statesAsserted == 1 && oemSpecificIndex != 0 && zeroXIndex != 0) {
            oemSpecific = substr(sdrEntry, zeroXIndex + 2)
            
            # Convert from hex string to decimal
            decVal = hex_to_dec(oemSpecific)

            # Bitwise OR with 32768 (0x8000)
            decVal = decVal + 32768

            # Convert back to hex (lowercase)
            hexVal = tolower(sprintf("%x", decVal))

            # Pad to 4 characters with leading zeros
            oemSpecific = sprintf("%04s", hexVal)

            statusGroup = trim(sensorName "=0x" oemSpecific)
        }
        
        assertionsEnabledIndex = index(sdrEntry, "Assertions Enabled ")
        if (assertionsEnabledIndex != 0) {
            assertionsEnabledLine = trim(checkSubStrAndReturnDelimitedString(sdrEntry, "Assertions Enabled"))
            if (assertionsEnabledLine != "") {
                assertionsEnabled = 1
            }
        } else {
            openingBracketIndex = index(sdrEntry, "[")
            closingBracketIndex = index(sdrEntry, "]")
            if (openingBracketIndex != 0 && closingBracketIndex != 0) {
                if (assertionsEnabled == 1) {
                    statusGroup = statusGroup separator sensorName "=" trim(substr(sdrEntry, openingBracketIndex + 1, closingBracketIndex - openingBracketIndex - 1))
                    separator = "|"
                }
            } else {
                assertionsEnabled = 0
            }
        }

        statusLine = checkSubStrAndReturnDelimitedString(sdrEntry, "Status")

        if (statusLine != "" && statusGroup == "") {
            status = trim(statusLine)
            statusGroup = sensorName "=" status
        }

        logicalFRUDeviceIndex = index(sdrEntry, "Logical FRU Device")

        if (logicalFRUDeviceIndex != 0) {
            fruDevice = checkSubStrAndReturnDelimitedString(sdrEntry, "Logical FRU Device")
            gsub(" ", "", fruDevice)
            gsub("h", "", fruDevice)
            sensorFruId = hex_to_dec(fruDevice)
        }

        sensorReadingLine = checkSubStrAndReturnDelimitedString(sdrEntry, "Sensor Reading")
        if (sensorReadingLine != "") {
            sensorReading = sensorReadingLine
        }

        thresholdUpperNonCriticalLine = checkSubStrAndReturnDelimitedString(sdrEntry, "Upper non-critical")
        if (thresholdUpperNonCriticalLine != "") {
            thresholdUpperNonCritical = thresholdUpperNonCriticalLine
            gsub(" ", "", thresholdUpperNonCritical)
            gsub(":", "", thresholdUpperNonCritical)
        }

        thresholdUpperCriticalLine = checkSubStrAndReturnDelimitedString(sdrEntry, "Upper critical")
        if (thresholdUpperCriticalLine != "") {
            thresholdUpperCritical = thresholdUpperCriticalLine
            gsub(" ", "", thresholdUpperCritical)
            gsub(":", "", thresholdUpperCritical)
        }

        thresholdLowerNonCriticalLine = checkSubStrAndReturnDelimitedString(sdrEntry, "Lower non-critical")
        if (thresholdLowerNonCriticalLine != "") {
            thresholdLowerNonCritical = thresholdLowerNonCriticalLine
            gsub(" ", "", thresholdLowerNonCritical)
            gsub(":", "", thresholdLowerNonCritical)
        }

        thresholdLowerCriticalLine = checkSubStrAndReturnDelimitedString(sdrEntry, "Lower critical")
        if (thresholdLowerCriticalLine != "") {
            thresholdLowerCritical = thresholdLowerCriticalLine
            gsub(" ", "", thresholdLowerCritical)
            gsub(":", "", thresholdLowerCritical)
        }

        thresholdUpperNonRecoverableLine = checkSubStrAndReturnDelimitedString(sdrEntry, "Upper non-recoverable")
        if (thresholdUpperNonRecoverableLine != "") {
            thresholdUpperNonRecoverable = thresholdUpperNonRecoverableLine
            gsub(" ", "", thresholdUpperNonRecoverable)
            gsub(":", "", thresholdUpperNonRecoverable)
        }
    }
}

END {
    if (sensorId != "" || trueDeviceId == "System Board") {
        result = formatResult(deviceType ";" deviceId ";" deviceType " " deviceId ";" status ";" statusGroup ";" sensorFruId)
        if (result != "") {
            print result
        }
    }
}