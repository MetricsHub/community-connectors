# Normalize and merge IPMI FRU and SDR records into a stable, semicolon-separated
# format for downstream hardware monitoring.
#
# - Correlates SDR sensors with FRU inventory data
# - Normalizes heterogeneous IPMI outputs into fixed column layouts
# - Ensures Chassis FRU is emitted first (required by enclosure.awk)
# - Emits numeric sensors immediately; buffers discrete sensors until FRU mapping
#
# Notes:
# - Fan thresholds are often not numerically readable via IPMI; empty threshold
#   columns are expected on some platforms.
# - Several helper functions intentionally set global variables (AWK style).
#
# Sensor types:
# - Threshold sensors (Temperature, Fan, Voltage, etc.) expose numeric readings
#   and optional warning/critical limits; they are emitted immediately.
# - Discrete sensors expose state changes only (no numeric value); states are
#   normalized (asserted/deasserted) and emitted once FRU mapping is available.

BEGIN {
  FS=";"; OFS=";"
  chassis_fru_id = -1
  fru_count = 0
  fru_flushed = 0
}

# --- basics ---
function trim(text){
  sub(/^[ \t\r\n]+/,"",text)
  sub(/[ \t\r\n]+$/,"",text)
  return text
}
function is_number(text){
  return (text ~ /^[-+]?[0-9]+(\.[0-9]+)?$/)
}

# --- hex helpers ---
function normalize_hex(text){
  text=trim(text)
  sub(/^0x/,"",text)
  gsub(/[^0-9a-fA-F]/,"",text)
  return tolower(text)
}

function hex_to_decimal(hex_text,    clean_hex,position,char,digit,decimal_value){
  clean_hex=normalize_hex(hex_text)
  decimal_value=0
  for(position=1; position<=length(clean_hex); position++){
    char=substr(clean_hex,position,1)
    if(char>="0" && char<="9") digit=char+0
    else digit=index("abcdef",tolower(char))
    decimal_value = decimal_value*16 + digit
  }
  return decimal_value
}

# --- filtering (discrete devices) ---
function is_kept_discrete_type(entity_type){
  return (entity_type=="External Environment" || \
          entity_type=="Processor" || \
          entity_type=="Power Unit" || \
          entity_type=="System Management Software" || \
          entity_type=="Power Supply" || \
          entity_type=="Disk Drive Bay" || \
          entity_type=="Add-in Card")
}

# Extract value after "Label : " until next ';' (no split/capture groups)
# Extract value for an exact label (matches start of a logical line: beginning or after ';')
# Example match: ";Board Mfg   : FUJITSU;" but NOT ";Board Mfg Date : Mon May ...;"
function get_field_value(record_text, label_text,    re, segment){
  re = "(^|;)[ \t]*" label_text "[ \t]*:[ \t]*"
  if (!match(record_text, re)) return ""
  segment = substr(record_text, RSTART + RLENGTH)
  sub(/;.*$/, "", segment)
  return trim(segment)
}

function strip_record_prefix(line){ sub(/^[A-Z]+;/,"",line); return line }

function extract_fru_id(record_text,    description_text,id_token){
  description_text=get_field_value(record_text,"FRU Device Description")
  if(description_text=="" || !match(description_text,/\(ID[ \t]*[0-9]+\)/)) return -1
  id_token=substr(description_text,RSTART,RLENGTH)
  gsub(/[^0-9]/,"",id_token)
  return id_token+0
}

# Return FRU "name" from "FRU Device Description", without "(ID n)"
# e.g. "Chassis (ID 2)" -> "Chassis"
function extract_fru_desc_name(record_text,    desc){
  desc = get_field_value(record_text, "FRU Device Description")
  if (desc == "") return ""
  sub(/[ \t]*\([ \t]*ID[ \t]*[0-9]+[ \t]*\)[ \t]*$/, "", desc)
  return trim(desc)
}

function extract_sensor_hex_id(record_text,    sensor_id_text,open_paren,hex_part){
  sensor_id_text=get_field_value(record_text,"Sensor ID")
  if(sensor_id_text=="") return ""
  open_paren=index(sensor_id_text,"(")
  if(!open_paren) return ""
  hex_part=substr(sensor_id_text,open_paren+1)
  sub(/\).*/,"",hex_part)
  return normalize_hex(hex_part)
}

function extract_sensor_name(record_text,    sensor_id_text,open_paren){
  sensor_id_text=get_field_value(record_text,"Sensor ID")
  if(sensor_id_text=="") return ""
  open_paren=index(sensor_id_text,"(")
  if(open_paren) sensor_id_text=substr(sensor_id_text,1,open_paren-1)
  return trim(sensor_id_text)
}

# Parse Entity ID into globals:
# entity_address "X.Y", entity_instance "Y", entity_type_name "Type" (supports nested "(0xE0)")
function parse_entity_info(record_text,    entity_text,address_only,open_paren,close_paren,scan_pos){
  entity_address=""; entity_instance=""; entity_type_name=""
  entity_text=get_field_value(record_text,"Entity ID")
  if(entity_text=="") return

  address_only=entity_text
  sub(/[ \t].*$/,"",address_only)
  entity_address=trim(address_only)

  entity_type_name=""
  open_paren=index(entity_text,"(")
  close_paren=0
  for(scan_pos=length(entity_text); scan_pos>=1; scan_pos--){
    if(substr(entity_text,scan_pos,1)==")"){ close_paren=scan_pos; break }
  }
  if(open_paren && close_paren && close_paren>open_paren){
    entity_type_name=trim(substr(entity_text,open_paren+1,close_paren-open_paren-1))
  }

  entity_instance=entity_address
  sub(/^[^.]*\./,"",entity_instance)
  if(entity_instance==entity_address) entity_instance="0"
}

# Extract [STATE] blocks before "Assertions Enabled", dedupe per call using stamp
function collect_states_before_assertions(record_text,    cutoff_pos,left_text,open_pos,close_pos,state_text,states_out){
  cutoff_pos=index(record_text,"Assertions Enabled")
  left_text = (cutoff_pos ? substr(record_text,1,cutoff_pos-1) : record_text)

  states_out=""
  dedupe_stamp++
  while(1){
    open_pos=index(left_text,"["); if(!open_pos) break
    left_text=substr(left_text,open_pos+1)
    close_pos=index(left_text,"]"); if(!close_pos) break

    state_text=trim(substr(left_text,1,close_pos-1))
    if(state_text!="" && seen_state_stamp[state_text]!=dedupe_stamp){
      seen_state_stamp[state_text]=dedupe_stamp
      states_out = states_out (states_out=="" ? "" : "\n") state_text
    }
    left_text=substr(left_text,close_pos+1)
  }
  return states_out
}

function build_oem_specific_status(record_text, sensor_name,    asserted_text,hex_text,value){
  asserted_text=get_field_value(record_text,"States Asserted")
  if(asserted_text ~ /^0x[0-9A-Fa-f]+[ \t]+OEM Specific/){
    hex_text=asserted_text
    sub(/[ \t]+OEM Specific.*$/,"",hex_text)
    value=hex_to_decimal(hex_text)
    if(value < 32768) value += 32768
    return sensor_name "=0x" sprintf("%04x",value)
  }
  return ""
}

# Print and cleanup a discrete device once FRU mapping is known
function emit_device_for_entity(entity_key,    device_key,fru_id,vendor,model,serial,device_line){
  device_key = device_type_by_entity[entity_key] SUBSEP device_instance_by_entity[entity_key]
  if(!(device_key in device_status_by_key)) return

  if(device_status_by_key[device_key] ~ /=Device Absent/){
    delete device_status_by_key[device_key]
    delete device_type_by_entity[entity_key]
    delete device_instance_by_entity[entity_key]
    delete device_key_by_entity[entity_key]
    return
  }

  fru_id = entity_to_logical_fru_id[entity_key] + 0
  vendor=model=serial=""
  if(fru_id!=0){
    vendor=fru_vendor_by_id[fru_id]
    model =fru_model_by_id[fru_id]
    serial=fru_serial_by_id[fru_id]
  }

  device_line = device_type_by_entity[entity_key] OFS device_instance_by_entity[entity_key] \
                OFS device_type_by_entity[entity_key] " " device_instance_by_entity[entity_key] \
                OFS vendor OFS model OFS serial OFS device_status_by_key[device_key]

  gsub(/=State Asserted/,"=1",device_line)
  gsub(/=State Deasserted/,"=0",device_line)
  gsub(/=Asserted/,"=1",device_line)
  gsub(/=Deasserted/,"=0",device_line)

  print device_line

  delete device_status_by_key[device_key]
  delete device_type_by_entity[entity_key]
  delete device_instance_by_entity[entity_key]
  delete device_key_by_entity[entity_key]
}

# Flush buffered FRUs, ensuring Chassis is first (so enclosure.awk picks the right one)
function flush_fru_lines(    i,id){
  if (fru_flushed) return
  fru_flushed = 1

  if (chassis_fru_id in fru_line_by_id) {
    print fru_line_by_id[chassis_fru_id]
  }

  for (i = 1; i <= fru_count; i++) {
    id = fru_ids[i]
    if (id == chassis_fru_id) continue
    if (id in fru_line_by_id) print fru_line_by_id[id]
  }
}

# --- main ---
{
  record_type=$1
  record_text=strip_record_prefix($0)

  # ---- FRU ----
  if(record_type=="FRU"){
    if(record_text ~ /^Unknown FRU header version/) next

    fru_id=extract_fru_id(record_text)
    if(fru_id<0) next

    product_mfg   = get_field_value(record_text,"Product Manufacturer")
    product_name  = get_field_value(record_text,"Product Name")
    product_serial= get_field_value(record_text,"Product Serial")

    board_mfg     = get_field_value(record_text,"Board Mfg")
    board_product = get_field_value(record_text,"Board Product")
    board_serial  = get_field_value(record_text,"Board Serial")

    vendor=trim(product_mfg); model=trim(product_name); serial=trim(product_serial)
    if(vendor=="" && model=="" && serial==""){
      vendor=trim(board_mfg); model=trim(board_product); serial=trim(board_serial)
    }

    fru_vendor_by_id[fru_id]=vendor
    fru_model_by_id[fru_id]=model
    fru_serial_by_id[fru_id]=serial

    # Buffer FRU output so we can print Chassis first
    if (vendor != "") {
      fru_line_by_id[fru_id] = "FRU" OFS vendor OFS model OFS serial
      fru_ids[++fru_count] = fru_id
    }

    desc_name = extract_fru_desc_name(record_text)
    if (tolower(desc_name) == "chassis") {
      chassis_fru_id = fru_id
    }

    next
  }

  # As soon as we leave FRU section, flush FRUs before any other output
  if (!fru_flushed) flush_fru_lines()

  if(record_type!="SDR") next

  # ---- Mapping (Device ID -> Logical FRU) ----
  if(get_field_value(record_text,"Device ID")!=""){
    parse_entity_info(record_text)

    logical_fru_text=get_field_value(record_text,"Logical FRU Device")
    gsub(/[ \t]/,"",logical_fru_text)
    sub(/h$/,"",logical_fru_text)
    logical_fru_text=normalize_hex(logical_fru_text)

    if(entity_address!="" && logical_fru_text!=""){
      entity_to_logical_fru_id[entity_address]=hex_to_decimal(logical_fru_text)
    }

    if(entity_address in device_key_by_entity) emit_device_for_entity(entity_address)
    next
  }

  # Must have Sensor ID + Entity ID
  if(get_field_value(record_text,"Sensor ID")=="" || get_field_value(record_text,"Entity ID")=="") next

  reading_text=get_field_value(record_text,"Sensor Reading")
  if(reading_text=="" || reading_text ~ /^Not Reading/ || record_text ~ /Sensor Reading[ \t]*:[ \t]*Not Reading/) next

  # ---- Discrete device list ----
  if(index(record_text,"States Asserted")){
    # PSL behavior: ignore discrete sensors that don't include "Assertions Enabled"
    if (index(record_text, "Assertions Enabled") == 0) next

    parse_entity_info(record_text)
    if(is_kept_discrete_type(entity_type_name)){
      sensor_name=extract_sensor_name(record_text)

      status_text=build_oem_specific_status(record_text,sensor_name)
      if(status_text==""){
        raw_states=collect_states_before_assertions(record_text)  # now safe: Assertions Enabled exists
        status_text=""
        if(raw_states!=""){
          state_count=split(raw_states,state_lines,"\n")
          for(state_index=1; state_index<=state_count; state_index++){
            if(state_lines[state_index]!=""){
              status_text = status_text (status_text=="" ? "" : "|") sensor_name "=" state_lines[state_index]
            }
          }
        }
      }

      if(status_text!=""){
        entity_key=entity_address
        device_key=entity_type_name SUBSEP entity_instance

        device_key_by_entity[entity_key]=device_key
        device_type_by_entity[entity_key]=entity_type_name
        device_instance_by_entity[entity_key]=entity_instance

        if(!(device_key in device_status_by_key)) device_status_by_key[device_key]=status_text
        else device_status_by_key[device_key]=device_status_by_key[device_key] "|" status_text
      }
    }
  }


  # ---- Numeric sensors (emit now) ----
  sensor_hex_id=extract_sensor_hex_id(record_text)
  if(sensor_hex_id=="") next

  sensor_name=extract_sensor_name(record_text)
  parse_entity_info(record_text)
  device_location=entity_type_name " " entity_instance

  numeric_value=reading_text
  sub(/[ \t].*$/,"",numeric_value)
  if(!is_number(numeric_value)) next

  unit_text=reading_text
  if(match(unit_text,/\)[ \t]*/)) unit_text=substr(unit_text,RSTART+RLENGTH)
  else sub(/^[^ \t]+[ \t]*/,"",unit_text)
  unit_text=trim(unit_text)

  if(unit_text=="degrees C"){
    threshold_low = get_field_value(record_text,"Upper non-critical")
    threshold_high= get_field_value(record_text,"Upper critical")
    if(!is_number(threshold_high)) threshold_high=get_field_value(record_text,"Upper non-recoverable")
    if(!is_number(threshold_low)) threshold_low=""
    if(!is_number(threshold_high)) threshold_high=""
    print "Temperature" OFS sensor_hex_id OFS sensor_name OFS device_location OFS numeric_value OFS threshold_low OFS threshold_high
  }
  else if(unit_text=="RPM"){
    threshold_low = get_field_value(record_text,"Lower non-critical")
    threshold_high= get_field_value(record_text,"Lower critical")
    if(!is_number(threshold_high)) threshold_high=get_field_value(record_text,"Lower non-recoverable")
    if(!is_number(threshold_low)) threshold_low=""
    if(!is_number(threshold_high)) threshold_high=""
    print "Fan" OFS sensor_hex_id OFS sensor_name OFS device_location OFS numeric_value OFS threshold_low OFS threshold_high
  }
  else if(unit_text=="Volts"){
    threshold_low=get_field_value(record_text,"Lower non-critical")
    if(!is_number(threshold_low) || threshold_low==0) threshold_low=get_field_value(record_text,"Lower critical")
    if(!is_number(threshold_low) || threshold_low==0) threshold_low=get_field_value(record_text,"Lower non-recoverable")

    threshold_high=get_field_value(record_text,"Upper non-critical")
    if(!is_number(threshold_high) || threshold_high==0) threshold_high=get_field_value(record_text,"Upper critical")
    if(!is_number(threshold_high) || threshold_high==0) threshold_high=get_field_value(record_text,"Upper non-recoverable")

    if(!is_number(threshold_low) || threshold_low==0) threshold_low=""; else threshold_low=threshold_low*1000
    if(!is_number(threshold_high) || threshold_high==0) threshold_high=""; else threshold_high=threshold_high*1000
    numeric_value=numeric_value*1000

    print "Voltage" OFS sensor_hex_id OFS sensor_name OFS device_location OFS numeric_value OFS threshold_low OFS threshold_high
  }
  else if(unit_text=="Amps"){
    print "Current" OFS sensor_hex_id OFS sensor_name OFS device_location OFS numeric_value
  }
  else if(unit_text=="Watts"){
    print "PowerConsumption" OFS sensor_hex_id OFS sensor_name OFS device_location OFS numeric_value
  }
}

END{
  # If input had only FRU records, still flush them
  if (!fru_flushed) flush_fru_lines()

  # Fallback: entities that never got a Device ID mapping
  for(entity_key in device_key_by_entity){
    emit_device_for_entity(entity_key)
  }
}
