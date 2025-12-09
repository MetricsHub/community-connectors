# Transform a single CSV line of ROCm SMI sensor data into three temperature records.
# Input columns: id; val2; val3; val4; val5(edge); val6(junction); val7(memory)
# Output:
#   id;gpu_edge;val5
#   id;gpu_junction;val6
#   id;gpu_memory;val7
BEGIN {
    FS = OFS = ";"
}

NF >= 7 {
    id = $1
    edge = $5
    junction = $6
    memory = $7

    print id, "gpu_edge", edge
    print id, "gpu_junction", junction
    print id, "gpu_memory", memory
}
