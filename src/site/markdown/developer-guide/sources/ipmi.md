keywords: ipmi source, sensors, hardware monitoring
description: Reference for IPMI source usage and normalization patterns.

# ipmi (Source)

## When To Use

Use `ipmi` when metrics are exposed through IPMI sensor outputs and your target platform supports IPMI collection.

This source usually feeds AWK/compute normalization steps before mapping.

## Syntax

```yaml
sources:
  sensorDump:
    type: ipmi
    forceSerialization: true
    computes:
    - type: awk
      script: ${file::sdr_formatter.awk}
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `ipmi`. |
| `computes` | No | `[]` | Post-processing pipeline, typically required for shaping. |
| `forceSerialization` | No | `false` | Force raw serialization before next stages. |
| `executeForEachEntryOf` | No | None | Fan-out context when needed. |

## Recommended Pattern

- Parse IPMI command output into semicolon-delimited tables quickly.
- Branch with `copy` for multiple monitor views (status, thresholds, counters).
- Keep translation logic in reusable translation tables.

## Common Mistakes

- Mapping raw IPMI output without normalization.
- Mixing discrete and numeric sensors in one unstable table shape.
- Running redundant IPMI calls instead of reusing one source table.

## Community Examples

- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/IpmiTool/IpmiTool.yaml)
- [LinuxIpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/LinuxIpmiTool/LinuxIpmiTool.yaml)
- [WindowsIpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WindowsIpmiTool/WindowsIpmiTool.yaml)
