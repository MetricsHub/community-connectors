# Helpers: trim and validity check (treat "N/A" case-insensitively as empty)
function ltrim(s) { sub("^[ \t]+", "", s); return s }
function rtrim(s) { sub(/[ \t]+$/, "", s); return s }
function trim(s)  { s = ltrim(s); s = rtrim(s); return s }
function isInvalid(v) { v = trim(v); return (v == "" || tolower(v) == "n/a") }

# The input columns used (the join of the fan sensors with the entities):
# 2: PhysicalDescription (from left table)
# 7: SerialNumber (primary)
# 8: Manufacturer (primary)
# 9: Model (primary)
# 14: OriginalID (from left table)
# 21: SerialNumber (fallback)
# 22: Manufacturer (fallback)
# 23: Model (fallback)
#
# Output (exactly 3 columns):
# 1: id        -> OriginalID (input $14)
# 2: name      -> PhysicalDescription (input $2)
# 3: info      -> formatted string without empty labels
#
# Fallback order: primary (7,8,9) then fallback (21,22,23)
# Primary values equal to "N/A" (any case) are treated as missing.
{
    serial = (isInvalid($7) ? $21 : $7);
    manuf  = (isInvalid($8) ? $22 : $8);
    model  = (isInvalid($9) ? $23 : $9);

    info = "";
    if (!isInvalid(model)) {
        info = (info=="" ? "" : info " ") "Model: " model;
    }
    if (!isInvalid(manuf)) {
        info = (info=="" ? "" : info " ") "Manufacturer: " manuf;
    }
    if (!isInvalid(serial)) {
        info = (info=="" ? "" : info " ") "Serial Number: " serial;
    }

    # Emit only: id;name;info
    print $14, $2, info;
}
