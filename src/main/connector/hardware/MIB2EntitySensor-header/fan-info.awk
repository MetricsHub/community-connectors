BEGIN {
    FS = OFS = ";";
}

# Helpers: trim and validity check (treat "N/A" case-insensitively as empty)
function ltrim(s) { sub("^[ \t]+", "", s); return s }
function rtrim(s) { sub(/[ \t]+$/, "", s); return s }
function trim(s)  { s = ltrim(s); s = rtrim(s); return s }
function isInvalid(v) { v = trim(v); return (v == "" || tolower(v) == "n/a") }

# After keepColumns the input columns are (8 columns):
# 1: PhysicalDescription (from left table)
# 2: SerialNumber (primary, original col 7)
# 3: Manufacturer (primary, original col 8)
# 4: Model (primary, original col 9)
# 5: OriginalID (from left table, original col 14)
# 6: SerialNumber (fallback, original col 21)
# 7: Manufacturer (fallback, original col 22)
# 8: Model (fallback, original col 23)
#
# Output (exactly 3 columns):
# 1: id        -> OriginalID (input $5)
# 2: name      -> PhysicalDescription (input $1)
# 3: info      -> formatted string without empty labels
#
# Fallback order: primary (2,3,4) then fallback (6,7,8)
# Primary values equal to "N/A" (any case) are treated as missing.
{
    serial = (isInvalid($2) ? $6 : $2);
    manuf  = (isInvalid($3) ? $7 : $3);
    model  = (isInvalid($4) ? $8 : $4);

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
    print $5, $1, info;
}
