keywords: duplicateColumn, compute, copy column, clone, insert column
description: The duplicateColumn compute inserts a copy of a column immediately after the original, shifting subsequent columns to the right.

# duplicateColumn (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `duplicateColumn` when the same raw value must feed two different transformations or two different `mapping` fields. The compute inserts an exact copy of the column **immediately after the original**, so the copy sits at index `column + 1` and every column that was to the right shifts one position right.

The canonical patterns are: duplicate a raw status column so one copy can be run through `translate` while the other is kept as human-readable status information, and duplicate a numeric column so one copy can be turned into a utilization ratio (`divide`, `subtract`) while the other keeps the absolute value.

## Syntax

```yaml
sources:
  batteryStatus:
    type: wmi
    namespace: root\cimv2
    query: SELECT BatteryStatus, DeviceID, EstimatedChargeRemaining, EstimatedRunTime, Status FROM Win32_Battery
    computes:
      # Duplicate Status to translate it
      # BatteryStatus;DeviceID;ChargeRemaining;RunTime;Status;Status;
    - type: duplicateColumn
      column: 5
    - type: translate
      column: 5
      translationTable: ${translation::BatteryStatusTranslationTable}
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `duplicateColumn`. |
| `column` | Yes | None | **1-based** index of the column to duplicate. The copy is inserted right after it (at `column + 1`); subsequent columns shift right by one. |

## Table Transformation Example

With `column: 2`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | PageFileName | AllocatedMB | UsedMB |
>   | --- | --- | --- |
>   | C:\pagefile.sys | 4096 | 512 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | PageFileName | AllocatedMB | AllocatedMB | UsedMB |
>   | --- | --- | --- | --- |
>   | C:\pagefile.sys | 4096 | 4096 | 512 |

`UsedMB`, previously column 3, is now column 4.

## Recommended Pattern

- Duplicate before destructive computes (`translate`, `divide`, `substring`, `extractPropertyFromWbemPath`) so the raw value survives for another `mapping` field.
- Immediately follow the duplication with a `# Column1;Column2;...` comment reflecting the new layout; the shifted indexes are the main source of errors.
- When several copies are needed, apply successive `duplicateColumn` computes and re-check indexes after each one (duplicating column 3 then column 5 in the new layout duplicates two different original columns).

## Common Mistakes

- Continuing to address right-hand columns with their old indexes: everything after `column` shifted one position right.
- Assuming the copy replaces the original or lands at the end of the row: the original stays at `column`, the copy is inserted at `column + 1`.
- Forgetting that `column` is 1-based.

## Community Examples

- [Windows](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Windows/Windows.yaml)
- [GenBatteryNT](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenBatteryNT/GenBatteryNT.yaml)
- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml)

From Windows (duplicating the allocated pagefile size so one copy can be turned into free space), included directly from the connector source:

<!-- MACRO{snippet|id=duplicatePagefileColumnCompute|file=src/main/connector/system/Windows/Windows.yaml} -->
