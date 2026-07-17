keywords: excludeMatchingLines, compute, filter rows, regex, valueList, grep -v
description: The excludeMatchingLines compute removes the table rows whose selected column matches a regular expression or an exact-value list.

# excludeMatchingLines (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `excludeMatchingLines` to drop unwanted rows from a source table: aggregate rows such as `_Total` in Windows performance counters, removable media in a disk listing, sensors reporting `N/A`, or devices with a size of `0`. It is the table equivalent of `grep -v`: rows that match are discarded, all other rows pass through unchanged.

To do the opposite (keep only matching rows), use [`keepOnlyMatchingLines`](keep-only-matching-lines.md).

## Syntax

```yaml
sources:
  physicalDisks:
    type: commandLine
    commandLine: ${file::diskpart-list.bat}
    computes:
    - type: excludeMatchingLines
      column: 4
      valueList: CD-ROM,DVD-ROM,Removable
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `excludeMatchingLines`. |
| `column` | Yes | None | **1-based** index of the column tested on each row. |
| `regExp` | No | None | Case-insensitive regular expression. A row is removed when the regex is found anywhere in the column value (unanchored, like `grep`); use `^` and `$` to force a full match. Follows PSL regex conventions: alternation is a backslash-escaped pipe, as in `keepOnlyMatchingLines`. Can be set from a connector variable, e.g. `${var::excludedDevices}`. |
| `valueList` | No | None | Comma-separated list of exact values, e.g. `CD-ROM,DVD-ROM,Removable`. A row is removed when the column value equals one of the listed values (case-insensitive, whole-value comparison). |

Provide `regExp`, `valueList`, or both. When both are specified, both filters are applied one after the other: a row is removed if it matches the `regExp` **or** its value is in the `valueList` (only rows that pass both filters survive).

## Table Transformation Example

With `column: 4` and `valueList: CD-ROM,DVD-ROM,Removable`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | ID | Model | Size | Type |
>   | --- | --- | --- | --- |
>   | 0 | Samsung SSD 990 | 1000 GB | Fixed |
>   | 1 | Kingston DT USB | 64 GB | Removable |
>   | 2 | Virtual DVD | 0 GB | DVD-ROM |
>   | 3 | WDC WD40EFRX | 4000 GB | Fixed |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | ID | Model | Size | Type |
>   | --- | --- | --- | --- |
>   | 0 | Samsung SSD 990 | 1000 GB | Fixed |
>   | 3 | WDC WD40EFRX | 4000 GB | Fixed |

## Recommended Pattern

- Exclude noise early in the `computes` pipeline (aggregate rows, `N/A` readings, zero-sized devices) so later computes and the mapping only see real hardware.
- Prefer `valueList` when the unwanted values are a fixed set of literals; use `regExp` for actual patterns, e.g. `regExp: ^[0.]+$` in `LibreHardwareMonitor` to drop all-zero readings.
- Chain one `excludeMatchingLines` per column when you need to filter on several columns.

## Common Mistakes

- Forgetting that `regExp` is unanchored: `regExp: 5` removes every row whose column merely *contains* `5` — use `valueList: 5` or `regExp: ^5$` to remove exact values only.
- Expecting `valueList` entries to support wildcards; they are literal values only (the comparison is case-insensitive, though).
- Using `excludeMatchingLines` with a long value list when an anchored `keepOnlyMatchingLines` on the wanted values would be shorter and safer.
- Counting columns from 0: `column` is 1-based.

## Community Examples

- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml)
- [LibreHardwareMonitor](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/LibreHardwareMonitor/LibreHardwareMonitor.yaml)
- [Windows](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Windows/Windows.yaml)

From `Windows` (drops the `_Total` aggregate row of a performance counter table):

```yaml
          - type: excludeMatchingLines
            column: 1
            regExp: _Total
```
