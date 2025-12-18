function ltrim(ltrimString) { sub(/^[ \t\r\n]+/, "", ltrimString); return ltrimString }
function rtrim(rtrimString) { sub(/[ \t\r\n]+$/, "", rtrimString); return rtrimString }
function trim(trimString) { return rtrim(ltrim(trimString)); }

function isANumber(value) {
    return value ~ /^[+-]?[0-9]+([.][0-9]+)?$/
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

BEGIN {
    FS = OFS = ";"
    devicesArray[1] = ""
}

{
    line = $0

    if ($1 == "SDR" && (index($2, "BMC req") != 0 || index($2, "--") != 0)) {
        next
    }

    if ($1 == "FRU") {
        fruIdBlock = $2
        openingParenthesisIndex = index(fruIdBlock, "(")
        closingParenthesisIndex = index(fruIdBlock, ")")

        if (openingParenthesisIndex != 0 && closingParenthesisIndex != 0 && openingParenthesisIndex < closingParenthesisIndex) {
            fruId = trim(substr(fruIdBlock, openingParenthesisIndex + 1, closingParenthesisIndex - openingParenthesisIndex - 1))
            gsub("ID ", "", fruId)
        }

        for (i = 2; i <= NF; i++) {
            entry = trim($i)

            if (entry != "") {
                endOfEntry = trim(substr(entry, index(entry, ":") + 1))

                if (index(entry, "Product Manufacturer") != 0) {
                    fruVendor = endOfEntry
                }
                if (index(entry, "Product Name") != 0) {
                    fruModel = endOfEntry
                }
                if (index(entry, "Product Serial") != 0) {
                    fruSN = endOfEntry
                }
                if (index(entry, "Board Mfg") != 0) {
                    boardVendor = endOfEntry
                }
                if (index(entry, "Board Product") != 0) {
                    boardModel = endOfEntry
                }
                if (index(entry, "Board Serial") != 0) {
                    boardSN = endOfEntry
                }
            }
        }

        fruEntryResult = fruVendor ";"  fruModel ";" fruSN
        if (index(line, "Board") == 0) {
            if (fruModel != "" && fruSN != "") {
                print "FRU", fruVendor, fruModel, fruSN
            } else if (fruVendor != "") {
                print "FRU", fruVendor, fruModel, fruSN
            }
        } else if (boardVendor != "") {
            fruEntryResult = boardVendor ";" boardModel ";" boardS
            print "FRU", boardVendor, boardModel, boardSN
        }
        frusArray[fruId] = fruEntryResult
    }

    if ($1 == "SDR") {
        if (index($2, "Sensor ID ") != 0 && ((index(line, "States Asserted") != 0 && index(line, "Not Reading") != 0) || index(line, "Sensor Reading") != 0)) {
            separator = ""
            sensorName = ""
            sensorId = ""
            deviceType = ""
            deviceId = ""
            model = ""
            vendor = ""
            serialNumber = ""
            valueReading = ""
            unit = ""
            statusArray = ""
            oemSpecificActive = 0
            assertionEnabled = 0
            thresholdUpperNonCritical = ""
            thresholdUpperCritical = ""
            thresholdLowerNonCritical = ""
            thresholdLowerCritical = ""
            thresholdUpperNonRecoverable = ""

            for (i = 2; i <= NF; i++) {
                entry = $i

                twoPointIndex = index(entry, ":")
                openingParenthesisIndex = index(entry, "(")
                closingParenthesisIndex = index(entry, ")")
                openingBracketIndex = index(entry, "[")
                closingBracketIndex = index(entry, "]")
                endOfEntry = trim(substr(entry, index(entry, ":") + 1))
                oemSpecificIndex = index(entry, "OEM Specific")
                zeroXIndex = index(entry, "0x")
                assertionEnabledIndex = index(entry, "Assertions Enabled")
                deassertionEnabledIndex = index(entry, "Deassertions Enabled")

                # Sensor ID              : Ambient (0x38)
                if (index(entry, "Sensor ID") != 0) {
                    sensorName = trim(substr(entry, twoPointIndex + 1, openingParenthesisIndex - twoPointIndex - 1))
                    sensorId = trim(substr(entry, zeroXIndex + 2, closingParenthesisIndex - zeroXIndex - 2))
                }

                # Entity ID             : 39.0 (External Environment)
                if (index(entry, "Entity ID") != 0) {
                    entityId = trim(substr(entry, twoPointIndex + 1, openingParenthesisIndex - twoPointIndex - 1))
                    if (openingParenthesisIndex > 0 && closingParenthesisIndex > openingParenthesisIndex) {
                        deviceType = trim(substr(entry, openingParenthesisIndex + 1, closingParenthesisIndex - openingParenthesisIndex - 1))
                        # There can be Entity ID line like "Entity ID             : 224.1 (Unknown (0xE0))".
                        # Then we need to add a closing parenthesis at the end to obtain "Unknown (0xE0)" as the deviceType
                        n = split(entry, tmp, ")")
                        if (n > 2) {
                            deviceType = deviceType ")"
                        }
                    }

                    entityIdPointIndex = index(entityId, ".")
                    if (entityIdPointIndex != 0) {
                        deviceId = trim(substr(entityId, 0, entityIdPointIndex - 1))
                    }
                }

                # States Asserted       : Temperature
                #                         [Device Present]
                if (index(entry, "States Asserted") != 0 && oemSpecificIndex != 0 ) { # States Asserted : 0x181 OEM Specific
                    assertionEnabled = 0
                    oemSpecificActive = 1
                    oemSpecific = trim(substr(entry, zeroXIndex + 2, oemSpecificIndex - zeroXIndex - 2))
                    # Add zeroes to have an hexadecimal number on 4 digits
                    for (j = length(oemSpecific); j < 4; j++) {
                        oemSpecific = "0" oemSpecific
                    }
                    statusArray = sensorName "=0x" oemSpecific
                    separator = "|"
                }

                if (assertionEnabledIndex != 0) {
                    assertionEnabled = 1
                }

                if (deassertionEnabledIndex != 0) {
                    assertionEnabled = 0
                }

                # Assertions Enabled    : Temperature
                #                         [Device Absent]
                #                         [Device Present]
                if (assertionEnabled == 1 && oemSpecificActive == 0 && openingBracketIndex != 0 && closingBracketIndex != 0 && closingBracketIndex > openingBracketIndex) {
                    statusArray = statusArray separator sensorName "=" substr(entry, openingBracketIndex + 1, closingBracketIndex - openingBracketIndex - 1)
                    separator = "|"
                }

                # Logical FRU Device: 05h
                if (index(entry, "Logical FRU Device") != 0) {
                    # convert ID to hexadecimal
                    fruDeviceId = trim(substr(entry, twoPointIndex + 1))
                    gsub("h", "", fruDeviceId)
                    fruDeviceId = sprintf("%X", fruDeviceId)

                    fru = frusArray[fruDeviceId]
                    split(fru, fruArray, ";")
                    model = fruArray[1]
                    vendor = fruArray[2]
                    serialNumber = fruArray[3]
                }

                # SensorReading
                if (index(entry, "Sensor Reading") != 0 && openingParenthesisIndex != 0 && closingParenthesisIndex != 0 && closingParenthesisIndex > openingParenthesisIndex) {
                    valueReading = trim(substr(entry, twoPointIndex + 1, openingParenthesisIndex - twoPointIndex - 1))

                    if (!isANumber(valueReading)) {
                        valueReading = ""
                    }
                    unit = trim(substr(entry, closingParenthesisIndex + 1))
                }

                if (index(entry, "Upper non-critical") != 0) {
                    thresholdUpperNonCritical = trim(substr(entry, twoPointIndex + 1))
                }

                if (index(entry, "Upper critical") != 0) {
                    thresholdUpperCritical = trim(substr(entry, twoPointIndex + 1))
                }

                if (index(entry, "Lower non-critical") != 0) {
                    thresholdLowerNonCritical = trim(substr(entry, twoPointIndex + 1))
                }

                if (index(entry, "Lower critical") != 0) {
                    thresholdLowerCritical = trim(substr(entry, twoPointIndex + 1))
                }

                if (index(entry, "Upper non-recoverable") != 0) {
                    thresholdUpperNonRecoverable = trim(substr(entry, twoPointIndex + 1))
                }
            }

            if (sensorId != "") {
                deviceElement = deviceId " " deviceType
                existingDevice = devicesArray[deviceElement]
                # If the deviceId was already there, we just had its status array
                if (existingDevice == "" && statusArray != "") {
                    deviceEntryResult = deviceId ";" deviceType ";" model ";" vendor ";" serialNumber ";" statusArray
                    devicesArray[deviceElement] = deviceEntryResult
                } else if (statusArray != "") {
                    devicesArray[deviceElement] = existingDevice "|" statusArray
                }

                # Sensor reading formatting
                if (unit == "degrees C") {
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
                    print "Temperature", sensorId, sensorName, deviceType " " deviceId, valueReading, threshold1, threshold2
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

                    print "Fan", sensorId, sensorName, deviceType " " deviceId, valueReading, threshold1, threshold2
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
                    print "Voltage", sensorId, sensorName, deviceType " " deviceId, valueReading, threshold1, threshold2
                } else if (unit == "Amps") {
                    print "Current", sensorId, sensorName, deviceType " " deviceId, valueReading
                } else if (unit == "Watts") {
                    print "PowerConsumption", sensorId, sensorName, deviceType " " deviceId, valueReading
                } else if (unit == "percent") {
                    print sensorName, sensorId, sensorName, deviceType " " deviceId, valueReading / 100
                }
            }
        }
    }
}

END {
    for (deviceId in devicesArray) {
        device = devicesArray[deviceId]
        # no empty device and no absent device
        if (device != "") {
            print device
        }
    }
}