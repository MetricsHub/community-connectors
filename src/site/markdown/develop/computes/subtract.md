keywords: subtract, compute, subtraction, arithmetic, difference, column math
description: The subtract compute subtracts a number or another column's value from every value of a column.

# subtract (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `subtract` to subtract an operand from every value of one column, row by row. The operand is
either a literal number or, with the `$n` syntax, the value of another column of the same row.
Typical uses are deriving a "used" quantity from a total and a free counter (used = size − free)
or removing an idle component from an aggregate counter. The column values must be numeric.

## Syntax

```yaml
sources:
  fileSystemInformation:
    type: wmi
    namespace: root\CIMv2
    query: SELECT DeviceID,FreeSpace,FreeSpace,Size,Size,VolumeName,FileSystem FROM Win32_LogicalDisk WHERE DriveType = 3
    computes:
    # UsedSpace = Size - FreeSpace
    - type: subtract
      column: 4
      value: $2
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `subtract`. |
| `column` | Yes | None | 1-based index of the column to update. Each value in this column is replaced by `column value - value`. |
| `value` | Yes | None | Operand subtracted from the column value. Either a literal number (e.g. `100`) or a `$n` reference to another column of the same row (e.g. `$2` for the 2nd column). |

## Table Transformation Example

With `column: 4` and `value: $2`, column 4 of each row becomes `column 4 - column 2`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | DeviceID | FreeSpace | FreeSpace | Size | Size | VolumeName | FileSystem |
>   | --- | --- | --- | --- | --- | --- | --- |
>   | C: | 100 | 100 | 500 | 500 | System | NTFS |
>   | D: | 300 | 300 | 400 | 400 | Data | NTFS |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | DeviceID | FreeSpace | FreeSpace | UsedSpace | Size | VolumeName | FileSystem |
>   | --- | --- | --- | --- | --- | --- | --- |
>   | C: | 100 | 100 | 400 | 500 | System | NTFS |
>   | D: | 300 | 300 | 100 | 400 | Data | NTFS |

Note how the source query selects `Size` twice: one copy is turned into the used space while the
original total remains available for the mapping.

## Recommended Pattern

- Select a field twice in the source query (or use `duplicateColumn`) when you need both the raw
  value and the subtracted result downstream.
- Keep the operand column intact and reference it with `value: $n`; `subtract` only modifies
  `column`.
- Comment the resulting column layout above the compute so the mapping indexes stay reviewable.

## Common Mistakes

- Reversing the operands: `subtract` computes `column - value`, never `value - column`. For
  `constant - column`, first `multiply` the column by `-1`, then `add` the constant.
- Pointing `column` or `$n` at indexes that were shifted by an earlier compute such as
  `keepColumns` or `awk`.
- Applying `subtract` to a column that contains non-numeric text such as an empty string or a
  label.

## Community Examples

- [Windows](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Windows/Windows.yaml)
- [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml)

From `Windows.yaml`, deriving used memory from total and free, included directly from the connector source:

<!-- MACRO{snippet|id=subtractUsedMemoryCompute|file=src/main/connector/system/Windows/Windows.yaml} -->
