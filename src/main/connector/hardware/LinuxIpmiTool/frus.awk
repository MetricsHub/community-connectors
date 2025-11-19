function checkSubStrAndReturnDelimitedString(str, subStr) {
    pos = index(str, subStr)
    if (pos != 0) {
        rest = substr(str, pos + length("subStr"))
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
    FS = "\n"
    OFS = ";"
    fruId = ""
    fruVendor = ""
    fruModel = ""
    fruSN = ""
    boardVendor = ""
    boardModel = ""
    boardSN = ""
}

{
    fruEntry = $0

    id = checkSubStrAndReturnDelimitedString(fruEntry, "FRU Device Description")

    if (id != "") {
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

    productManufacturer = checkSubStrAndReturnDelimitedString(fruEntry, "Product Manufacturer")
    if (productManufacturer != "") {
        fruVendor = trim(productManufacturer)
    }

    productName = checkSubStrAndReturnDelimitedString(fruEntry, "Product Name")
    if (productName != "") {
        fruModel = trim(productName)
    }

    productSN = checkSubStrAndReturnDelimitedString(fruEntry, "Product Serial")
    if (productSN != "") {
        fruSN = trim(productSN)
    }

    fruEntryNoSpace = fruEntry
    gsub(" ", "", fruEntryNoSpace)
    if (checkSubStrAndReturnDelimitedString(fruEntryNoSpace, "BoardMfg:") != "") {
        boardVendor = trim(checkSubStrAndReturnDelimitedString(fruEntry, "Board Mfg"))
    }

    boardProduct = checkSubStrAndReturnDelimitedString(fruEntry, "Board Product")
    if (boardProduct != "") {
        boardModel = trim(boardProduct)
    }

    boardSerial = checkSubStrAndReturnDelimitedString(fruEntry, "Board Serial")
    if (boardSerial != "") {
        boardSN = trim(boardSerial)
    }
}