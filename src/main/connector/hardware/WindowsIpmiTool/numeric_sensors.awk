BEGIN {
    FS = OFS = ";"
}

function convertKelvinToCelsius(value) {return value - 273.15}
function convertFahrenheitToCelsius(value) {int(100 * (value - 32) * 5 / 9) / 100}

{
    baseUnit = $1
    currentValue = $2
    descriptionLine = $3
    sensorType = $6
    unitModifier = $7

    if (baseUnit == "") {
        baseUnit = 0
    }

    if (unitModifier == "") {
        unitModifier = 0
    }

    if (sensorType == "") {
        sensorType = 0
    }

    if (currentValue == "") {
        currentValue = 0
    }

    openingParenthesisIndex = index(descriptionLine, "(")
    closingParenthesisIndex = index(descriptionLine, ")")
    twoPointIndex = index(descriptionLine, ":")

    sensorId = substr(descriptionLine, openingParenthesisIndex + 1, closingParenthesisIndex - openingParenthesisIndex - 1)
    sensorName = substr(descriptionLine, 0, openingParenthesisIndex - 1)
    description = substr(descriptionLine, twoPointIndex + 1)

    lookupIndex = index(description, " for ")
    if (lookupIndex != 0) {
        deviceId = substr(description, lookupIndex + 5)

        if (sensorType == "2" && currentValue != 0 && "2 3 4" ~ baseUnit) { # Temperature sensors
            currentValue = currentValue * 10 ^ unitModifier
            threshold1 = $9 == "" ? "" : $9  * 10 ^ unitModifier
            threshold2 = $8 == "" ? "" : $8  * 10 ^ unitModifier

            if (baseUnit == 4) { # Kelvin to Celsius
                currentValue = convertKelvinToCelsius(currentValue)
                if (threshold1 != "") {
                    threshold1 = convertKelvinToCelsius(threshold1)
                }
                if (threshold2 != "") {
                    threshold2 = convertKelvinToCelsius(threshold2)
                }
            } else if (baseUnit == 3) { # Fahrenheit to Celsius
                currentValue = convertFahrenheitToCelsius(currentValue)
                if (threshold1 != "") {
                    threshold1 = convertFahrenheitToCelsius(threshold1)
                }
                if (threshold2 != "") {
                    threshold2 = convertFahrenheitToCelsius(threshold2)
                }
            }
            print "Temperature", sensorId, sensorName, deviceId, currentValue, threshold1, threshold2, ""
        } else if (sensorType == "5" && currentValue != 0 && (baseUnit == 19 || baseUnit == 0)) { # Fans
            currentValue = currentValue * 10 ^ unitModifier
            threshold1 = $5
            threshold2 = $4
            if (threshold1 != "") {
                threshold1 = threshold1 * 10 ^ unitModifier
            }
            if (threshold2 != "") {
                threshold2 = threshold2 * 10 ^ unitModifier
            }
            if (baseUnit == 19) { # currentValue is the fan speed in RPM
                print "Fan", sensorId, sensorName, deviceId, currentValue, threshold1, threshold2, ""
            } else { # currentValue is the fan speed ratio
                print "Fan", sensorId, sensorName, deviceId, "", threshold1, threshold2, currentValue / 100
            }
        } else if (sensorType == "3" && currentValue != 0 && baseUnit == 5) { # Voltage
            currentValue = currentValue * 10 ^ unitModifier

            threshold1 = $5
            if (threshold1 != "") {
                threshold1 = threshold1 * 10 ^ unitModifier
            } else {
                threshold1 = $4
                if (threshold1 != "") {
                    threshold1 = threshold1 * 10 ^ unitModifier
                }
            }
            
            threshold2 = $9
            if (threshold2 != "") {
                threshold2 = threshold2 * 10 ^ unitModifier
            } else {
                threshold2 = $8
                if (threshold2 != "") {
                    threshold2 = threshold2 * 10 ^ unitModifier
                }
            }
            print "Voltage", sensorId, sensorName, deviceId, currentValue, threshold1, threshold2, ""
        } else if (sensorType == "1" && currentValue != 0 && baseUnit == 7) { # Power consumption
            currentValue = currentValue * 10 ^ unitModifier
            threshold1 = $9
            threshold2 = $8
            if (threshold1 != "") {
                threshold1 = threshold1 * 10 ^ unitModifier
            }
            if (threshold2 != "") {
                threshold2 = threshold2 * 10 ^ unitModifier
            }
            print "PowerSupply", sensorId, sensorName, deviceId, currentValue, threshold1, threshold2, ""
        }
    }
}