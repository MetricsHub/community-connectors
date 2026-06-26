keywords: wmi source, windows management instrumentation, namespace
description: Full reference for WMI source with query design and join-ready table patterns.

# wmi (Source)

## When To Use

Use `wmi` for Windows system/hardware/application monitoring via WMI classes.

This is one of the highest-usage source types in community connectors.

## Syntax

```yaml
sources:
  logicalDisks:
    type: wmi
    namespace: root\\CIMV2
    query: SELECT DeviceID,FreeSpace,Size FROM Win32_LogicalDisk WHERE DriveType = 3
    computes:
    - type: duplicateColumn
      column: 3
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `wmi`. |
| `query` | Yes | None | WMI query string. |
| `namespace` | No | Provider default | WMI namespace (`root\\CIMV2`, `root\\Microsoft\\Windows\\Storage`, ...). |
| `executeForEachEntryOf` | No | None | Fan-out query execution context. |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Force raw serialization before next stages. |

## Recommended Pattern

- Keep namespaces explicit for readability and compatibility.
- Select stable key columns (`__PATH`, IDs) when later joins are required.
- Filter and normalize early with computes before mapping.
- Use `tableJoin` with `keyType: Wbem` when joining path-like keys.

## Common Mistakes

- Overusing `SELECT *`.
- Joining on display names instead of technical identifiers.
- Dropping identity columns too early in the pipeline.

## Community Examples

- [Windows](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Windows/Windows.yaml)
- [WinStorageSpaces](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WinStorageSpaces/WinStorageSpaces.yaml)
- [LibreHardwareMonitor](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/LibreHardwareMonitor/LibreHardwareMonitor.yaml)
- [WindowsProcess](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/WindowsProcess/WindowsProcess.yaml)
