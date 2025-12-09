BEGIN {
    FS = ",";
    OFS = ";"
}
# Skip headers and global system line
$1 == "device" { next }
$1 == "system" { next }
$1 ~ /^$/ { next }
# Per-card lines: card0, card1,
$1 ~ /^card[0-9]+$/ {
  id           = $1  # Device card0, card1,
  edgeTemp     = $6  # Temperature (Sensor edge) (C)
  junctionTemp = $7  # Temperature (Sensor junction) (C)
  memTemp      = $8  # Temperature (Sensor memory) (C)
  maxPower     = $19 # Max Graphics Package Power (W)
  avgPower     = $20 # Average Graphics Package Power (W)
  gpuUse       = $21 # GPU use (%)
  gpuMemUse    = $22 # GPU memory use (%)
  memBw        = $24 # Avg. Memory Bandwidth
  memVendor    = $25 # GPU memory vendor
  serialNumber = $27 # Serial Number
  voltage_mV   = $28 # Voltage (mV)
  cardModel    = $42 # Card model
  cardVendor   = $43 # Card vendor
  energyCnt    = $45 # Energy counter
  performanceLevel = $18 #performanceLevel
  sclkClockSpeed = $9
  gsub(/[() ]|M[hH][zZ]/, "", sclkClockSpeed)
  # Output:
  print id, cardModel, cardVendor, serialNumber, edgeTemp, junctionTemp, memTemp, gpuUse, gpuMemUse, avgPower, maxPower, voltage_mV, energyCnt, memBw, performanceLevel, sclkClockSpeed
}
