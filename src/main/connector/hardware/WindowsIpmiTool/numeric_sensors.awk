###############################################################################
# numeric_sensors.awk
#
# Purpose:
#   Parse numeric sensor rows (typically from WMI NumericSensor / IPMI numeric
#   equivalents) and normalize them into the simplified format expected by
#   enclosure.awk.
#
# Input format (9 fields, ';' separated):
#   BaseUnits;CurrentReading;Description;LowerThresholdCritical;
#   LowerThresholdNonCritical;SensorType;UnitModifier;
#   UpperThresholdCritical;UpperThresholdNonCritical
#
# Description parsing:
#   "<SensorName>(<SensorID>): <something> for <DeviceType> <DeviceID>"
#   - Extracts SensorName, SensorID
#   - Extracts DeviceID as everything after " for " (kept as-is)
#
# Output format:
#   Temperature;SensorID;SensorName;DeviceID;Value;UpperNonCritical;UpperCritical
#   Fan;SensorID;SensorName;DeviceID;Value;LowerNonCritical;LowerCritical
#   Voltage;SensorID;SensorName;DeviceID;Value(mV);LowerThreshold;UpperThreshold
#   Current;SensorID;SensorName;DeviceID;Value
#   PowerConsumption;SensorID;SensorName;DeviceID;Value;UpperNonCritical;UpperCritical
#   EnergyUsage;SensorID;SensorName;DeviceID;Value(Wh)
#
# Notes:
#   - UnitModifier is applied as 10^UnitModifier
#   - Temperature is normalized to Celsius (C/F/K handled)
#   - Voltage is converted to milliVolts (mV)
#   - EnergyUsage converts Joules to Wh by dividing by 3,600,000
#   - CurrentReading == 0 is treated as invalid and skipped
#
###############################################################################

BEGIN { FS=";"; OFS=";" }

function isNumeric(value) { return (value ~ /^-?[0-9]+(\.[0-9]+)?$/) }

function powerOfTen(exponent,   result, i) {
  result = 1
  if (exponent > 0) for (i=0; i<exponent; i++) result *= 10
  else if (exponent < 0) for (i=0; i<(-exponent); i++) result /= 10
  return result
}

# Parse Description like: "<SensorName>(<SensorID>): <something> for <DeviceType> <DeviceID>"
function parse_description(description,   openParenPos, afterParen, closeParenPos, forPos) {
  sensorName = ""; sensorID = ""; deviceID = ""

  # sensorName and sensorID from "Name(ID)"
  openParenPos = index(description, "(")
  if (openParenPos > 0) {
    sensorName = substr(description, 1, openParenPos-1)
    afterParen = substr(description, openParenPos+1)
    closeParenPos = index(afterParen, ")")
    if (closeParenPos > 0) sensorID = substr(afterParen, 1, closeParenPos-1)
  } else {
    sensorName = description
    sensorID = ""
  }

  # deviceID after " for "
  forPos = index(description, " for ")
  if (forPos > 0) {
    deviceID = substr(description, forPos+5)
  } else {
    deviceID = ""
  }

  gsub(/[ \t]+$/, "", sensorName)
  gsub(/^[ \t]+/, "", sensorName)
}

# BaseUnits;CurrentReading;Description;LowerCrit;LowerNonCrit;SensorType;UnitModifier;UpperCrit;UpperNonCrit
NF >= 9 {
  baseUnitCode             = $1
  currentReadingRaw        = $2
  description              = $3
  lowerCriticalThreshold   = $4
  lowerNonCriticalThreshold= $5
  sensorTypeCode           = $6
  unitModifierRaw          = $7
  upperCriticalThreshold   = $8
  upperNonCriticalThreshold= $9

  if (!isNumeric(unitModifierRaw)) unitModifierRaw = 0
  if (!isNumeric(currentReadingRaw) || currentReadingRaw == 0) next

  parse_description(description)
  unitScale = powerOfTen(unitModifierRaw)

  # Temperatures (SensorType=2, BaseUnits=2(C),3(F),4(K))
  if (sensorTypeCode == 2) {
    if (!(baseUnitCode == 2 || baseUnitCode == 3 || baseUnitCode == 4)) next

    value = currentReadingRaw * unitScale
    upperNonCritical = upperNonCriticalThreshold
    upperCritical    = upperCriticalThreshold

    if (isNumeric(upperNonCritical)) upperNonCritical = upperNonCritical * unitScale; else upperNonCritical = ""
    if (isNumeric(upperCritical))    upperCritical    = upperCritical    * unitScale; else upperCritical    = ""

    # Kelvin -> Celsius
    if (baseUnitCode == 4) {
      value -= 273.15
      if (upperNonCritical != "") upperNonCritical -= 273.15
      if (upperCritical    != "") upperCritical    -= 273.15
    }
    # Fahrenheit -> Celsius
    else if (baseUnitCode == 3) {
      value = (value - 32) / 1.8
      if (upperNonCritical != "") upperNonCritical = (upperNonCritical - 32) / 1.8
      if (upperCritical    != "") upperCritical    = (upperCritical    - 32) / 1.8
    }

    print "Temperature", sensorID, sensorName, deviceID, value, upperNonCritical, upperCritical
    next
  }

  # Fans (SensorType=5, BaseUnits=19 RPM)
  if (sensorTypeCode == 5) {
    if (baseUnitCode != 19) next

    value = currentReadingRaw * unitScale
    lowerNonCritical = lowerNonCriticalThreshold
    lowerCritical    = lowerCriticalThreshold

    if (isNumeric(lowerNonCritical)) lowerNonCritical = lowerNonCritical * unitScale; else lowerNonCritical = ""
    if (isNumeric(lowerCritical))    lowerCritical    = lowerCritical    * unitScale; else lowerCritical    = ""

    print "Fan", sensorID, sensorName, deviceID, value, lowerNonCritical, lowerCritical
    next
  }

  # Voltage (SensorType=3, BaseUnits=5 Volts) -> milliVolts
  if (sensorTypeCode == 3) {
    if (baseUnitCode != 5) next

    value = currentReadingRaw * unitScale * 1000

    lowerThreshold = lowerNonCriticalThreshold
    if (!isNumeric(lowerThreshold)) lowerThreshold = lowerCriticalThreshold

    upperThreshold = upperNonCriticalThreshold
    if (!isNumeric(upperThreshold)) upperThreshold = upperCriticalThreshold

    if (isNumeric(lowerThreshold)) lowerThreshold = lowerThreshold * unitScale * 1000; else lowerThreshold = ""
    if (isNumeric(upperThreshold)) upperThreshold = upperThreshold * unitScale * 1000; else upperThreshold = ""

    print "Voltage", sensorID, sensorName, deviceID, value, lowerThreshold, upperThreshold
    next
  }

  # Current (SensorType=4, BaseUnits=6 Amps)
  if (sensorTypeCode == 4) {
    if (baseUnitCode != 6) next
    value = currentReadingRaw * unitScale
    print "Current", sensorID, sensorName, deviceID, value
    next
  }

  # PowerConsumption / EnergyUsage (SensorType=1)
  if (sensorTypeCode == 1 && (baseUnitCode == 7 || baseUnitCode == 8)) {
    value = currentReadingRaw * unitScale
    upperNonCritical = upperNonCriticalThreshold
    upperCritical    = upperCriticalThreshold

    if (isNumeric(upperNonCritical)) upperNonCritical = upperNonCritical * unitScale; else upperNonCritical = ""
    if (isNumeric(upperCritical))    upperCritical    = upperCritical    * unitScale; else upperCritical    = ""

    # 7 = Watts
    if (baseUnitCode == 7) {
      print "PowerConsumption", sensorID, sensorName, deviceID, value, upperNonCritical, upperCritical
    }
    # 8 = Joules -> Wh  ( divide by 3600000)
    else if (baseUnitCode == 8) {
      value = value / 3600000
      print "EnergyUsage", sensorID, sensorName, deviceID, value
    }
    next
  }
}