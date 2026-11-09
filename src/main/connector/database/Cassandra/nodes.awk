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

# Number of nodes in a list cell such as [host1, host2]
function count(list,   arr) {
    # Remove surrounding blanks and square brackets
    gsub(/^[ \t]+|[ \t]+$|\[|\]/, "", list)
    return list == "" ? 0 : split(list, arr, ",")
}

{
    liveNodes        += count($1)
    unreachableNodes += count($2)
    joiningNodes     += count($3)
    leavingNodes     += count($4)
    movingNodes      += count($5)
}

END {
    print liveNodes, unreachableNodes, joiningNodes, leavingNodes, movingNodes
}
