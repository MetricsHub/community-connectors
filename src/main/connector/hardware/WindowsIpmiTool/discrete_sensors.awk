###############################################################################
# discrete_sensors.awk
#
# Purpose:
#   Parse discrete sensor data (WMI / IPMI) and aggregate sensor states
#   by hardware entity (device) for further processing by enclosure.awk.
#
# Input format:
#   CurrentState;Description
#
#   - CurrentState may contain:
#       * Standard textual states
#       * "OEM State,Value=XXXX" (vendor-specific)
#   - Description is expected to contain:
#       "<Sensor Name>(<Sensor ID>): ... for <Device Type> <Device ID>"
#
# Output format (7 fields, expected by enclosure.awk):
#   deviceType;deviceID;entityID;vendor;model;serial;sensorList
#
# Notes:
#   - OEM state values are byte-swapped and converted to hexadecimal
#     (XXXX -> 0xYYXX).
#   - No normalization of sensor states (OK/FAILED/DEGRADED) is done here;
#     interpretation is delegated to enclosure.awk.
#   - This script is intentionally generic and vendor-agnostic.
#
###############################################################################

BEGIN { FS=";"; OFS=";" }

function parse_desc(description,
                    openParenPos,
                    fullDescription,
                    afterParen,
                    unused,
                    unused2,
                    lastSpacePos) {

  sensorName=""; sensorID=""; entityID=""; deviceType=""; deviceID=""

  # sensorName and sensorID from "Name(ID)"
  fullDescription = description
  openParenPos = index(fullDescription, "(")
  if (openParenPos > 0) {
    sensorName = substr(fullDescription, 1, openParenPos-1)
    afterParen = substr(fullDescription, openParenPos+1)
    openParenPos = index(afterParen, ")")
    if (openParenPos > 0)
      sensorID = substr(afterParen, 1, openParenPos-1)
  } else {
    sensorName = description
    sensorID = ""
  }

  gsub(/[ \t]+$/, "", sensorName)
  gsub(/^[ \t]+/, "", sensorName)

  # entityID after " for "
  openParenPos = index(description, " for ")
  if (openParenPos <= 0) return 0
  entityID = substr(description, openParenPos+5)

  # deviceType + deviceID split on last space in entityID
  lastSpacePos = 0
  for (i=1; i<=length(entityID); i++)
    if (substr(entityID,i,1)==" ") lastSpacePos=i

  if (lastSpacePos <= 0) return 0

  deviceType = substr(entityID, 1, lastSpacePos-1)
  deviceID   = substr(entityID, lastSpacePos+1)

  return 1
}

# CurrentState;Description
NF >= 2 {
  currentState = $1
  description  = $2

  if (currentState == "" || currentState == "N/A") next
  if (!parse_desc(description)) next

  # OEM State,Value=XXXX -> reverse bytes -> 0xYYXX
  if (substr(currentState, 1, 16) == "OEM State,Value=") {
    rawHex = substr(currentState, 17, 4)
    currentState = "0x" substr(rawHex,3,2) substr(rawHex,1,2)
  }

  # Expand ".,"
  gsub(/\.\,/, "|" sensorName "=", currentState)

  deviceKey = entityID

  if (deviceSensor[deviceKey] == "")
    deviceSensor[deviceKey] = sensorName "=" currentState
  else
    deviceSensor[deviceKey] = deviceSensor[deviceKey] "|" sensorName "=" currentState

  deviceTypeByKey[deviceKey] = deviceType
  deviceIdByKey[deviceKey]   = deviceID
  entityIdByKey[deviceKey]   = entityID
}

END {
  for (deviceKey in deviceSensor) {
    # Output 7 fields expected by enclosure.awk:
    # deviceType;deviceID;entityID;vendor;model;serial;sensorList
    print deviceTypeByKey[deviceKey], \
          deviceIdByKey[deviceKey], \
          entityIdByKey[deviceKey], \
          "", "", "", \
          deviceSensor[deviceKey]
  }
}
