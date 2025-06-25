# Input Example: [172.17.0.6, host1, host2];[host3];[host4, host5];[host6];[]
# Columns:
# Column 1: "LiveNodes"
# Column 2: "UnreachableNodes"
# Column 3: "JoiningNodes"
# Column 4: "LeavingNodes"
# Column 5: "MovingNodes"

BEGIN {
    OFS = ";"
    liveNodes = 0
    unreachableNodes = 0
    joiningNodes = 0
    leavingNodes = 0
    movingNodes = 0
}

{
    gsub(/^[ \t]+|[ \t]+$/, "", $0)

    # Remove square brackets
    gsub(/\[|\]/, "", $0)

    split($0, fields, ";")

    liveNodes        += (fields[1] == "" ? 0 : split(fields[1], arr1, ","))
    unreachableNodes += (fields[2] == "" ? 0 : split(fields[2], arr2, ","))
    joiningNodes     += (fields[3] == "" ? 0 : split(fields[3], arr3, ","))
    leavingNodes     += (fields[4] == "" ? 0 : split(fields[4], arr4, ","))
    movingNodes      += (fields[5] == "" ? 0 : split(fields[5], arr5, ","))
}

END {
    print liveNodes, unreachableNodes, joiningNodes, leavingNodes, movingNodes
}
