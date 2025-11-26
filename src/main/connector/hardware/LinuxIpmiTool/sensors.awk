function checkSubStrAndReturnDelimitedString(str, subStr) {
    pos = index(str, subStr)
    if (pos != 0) {
        rest = substr(str, pos + length(subStr))
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

/Sensor ID/ {
    sensorIdLine = $0
    indexTwoPoint = index(sensorIdLine, ":")
    indexOpeningParenthesis = index(sensorIdLine, "(")
    indexClosingParenthesis = index(sensorIdLine, ")")
    sensorName = trim(substr($0, indexTwoPoint + 1, indexOpeningParenthesis - indexTwoPoint - 1))

    sensorId = trim(substr($0, indexOpeningParenthesis + 1, indexClosingParenthesis - indexOpeningParenthesis - 1))
}

/Device ID/ {
    trueDeviceId = trim(substr($0, indexTwoPoint + 1))
}

/Entity ID/ {
    entityId = trim($4)

    indexPoint = index(entityId, ".")
    if (indexPoint != 0) {
        deviceId = trim(substr(entityId, 0, indexPoint - 1))
    }

    entityIdLine = $0
    openingParenthesisIndex = index(entityIdLine, "(")
    closingParenthesisIndex = index(entityIdLine, ")")
    if (openingParenthesisIndex > 0 && closingParenthesisIndex > openingParenthesisIndex) {
        deviceType = trim(substr(entityIdLine, openingParenthesisIndex + 1, closingParenthesisIndex - openingParenthesisIndex - 1))
    }
}

/OEM Specific/ {
    sdrEntry = $0
    zeroXIndex = index(sdrEntry, "0x")

    if (statesAsserted == 1 && zeroXIndex != 0) {
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
}

/States Asserted/ {
    statesAsserted = 1
}

/Assertions Enabled/ {
    # sometimes there is nothing after "Assertions Enabled    :"
    sdrEntry = $0
    assertionsEnabledLine = trim(substr(sdrEntry, index(sdrEntry, ":") + 1))
    if (assertionsEnabledLine != "") {
        assertionsEnabled = 1
    }
}

/Deassertions Enabled/ {
    assertionsEnabled = 0
}

/\[*\]/ {
    if (assertionsEnabled == 1) {
        assertion = $0
        gsub("\\[", "", assertion)
        gsub("\\]", "", assertion)
        statusGroup = statusGroup separator sensorName "=" trim(assertion)
        separator = "|"
    }
}

/Status/ {
    if (statusGroup == "") {
        sdrEntry = $0
        status = trim(substr(sdrEntry, index(sdrEntry, ":") + 1))
        statusGroup = sensorName "=" status
    }
}

/Logical FRU Device/ {
    fruDevice = $5
    gsub("h", "", fruDevice)
    sensorFruId = hex_to_dec(fruDevice)
}

/Sensor Reading/ {
    sdrEntry = $0
    sensorReading = trim(substr(sdrEntry, index(sdrEntry, ":") + 1))
}

/Upper non-critical/ {
    thresholdUpperNonCritical = $4
}

/Upper critical/ {
    thresholdUpperCritical = $4
}

/Lower non-critical/ {
    thresholdLowerNonCritical = $4
}

/Lower critical/ {
    thresholdLowerCritical = $4
}

/Upper non-recoverable/ {
    thresholdUpperNonRecoverable = $4
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