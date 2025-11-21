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
function ltrim(ltrimString) { sub(/^[ \t\r\n]+/, "", ltrimString); return ltrimString }
function rtrim(rtrimString) { sub(/[ \t\r\n]+$/, "", rtrimString); return rtrimString }
function trim(trimString) { return rtrim(ltrim(trimString)); }

BEGIN {
    OFS = ";"
    fruId = ""
    fruVendor = ""
    fruModel = ""
    fruSN = ""
    boardVendor = ""
    boardModel = ""
    boardSN = ""
}

/Product Manufacturer/ {
    fruEntry = $0
    fruVendor = trim(substr(fruEntry, index(fruEntry, ":") + 1))
}

/Product Name/ {
    fruEntry = $0
    fruModel = trim(substr(fruEntry, index(fruEntry, ":") + 1))
}

/Product Serial/ {
    fruSN = $4
}

/Board Mfg  / {
    fruEntry = $0
    boardVendor = trim(substr(fruEntry, index(fruEntry, ":") + 1))
}

/Board Product/ {
    fruEntry = $0
    boardModel = trim(substr(fruEntry, index(fruEntry, ":") + 1))
}

/Board Serial/ {
    boardSN = $4
}

/FRU Device Description/ {
    fruEntry = $0
    id = trim(substr(fruEntry, index(fruEntry, ":") + 1))
    if (fruId != "") {

        fruEntryResult = "FRU;" fruId ";" fruVendor ";" fruModel ";" fruSN

        if (boardVendor == "" && boardModel == "" && boardSN == "") {
            if (fruModel != "" && fruSN != "") {
                print fruEntryResult ";goodFru"
            } else if (fruVendor != "") {
                print fruEntryResult ";poorFru"
            }
        } else if (boardVendor != "") {
            print "FRU;" fruId ";" boardVendor ";" boardModel ";" boardSN ";poorFru"
        } else {
            print fruEntryResult
        }
        fruVendor = ""
        fruModel = ""
        fruSN = ""
        boardVendor = ""
        boardModel = ""
        boardSN = ""
    }

    openingParenthesisIndex = index(id, "(")
    closingParenthesisIndex = index(id, ")")
    if (openingParenthesisIndex != 0 && closingParenthesisIndex != 0 && openingParenthesisIndex < closingParenthesisIndex) {
        fruId = trim(substr(id, openingParenthesisIndex + 1, closingParenthesisIndex - openingParenthesisIndex - 1))
        gsub("ID ", "", fruId)
    }
}