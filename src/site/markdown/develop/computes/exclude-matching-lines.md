keywords: excludeMatchingLines, compute, filter rows, regex, valueList, grep -v
description: The excludeMatchingLines compute removes the table rows whose selected column matches a regular expression or an exact-value list.

# excludeMatchingLines (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `excludeMatchingLines` to drop unwanted rows from a source table: aggregate rows such as `_Total` in Windows performance counters, removable media in a disk listing, or, in a `collect` job, `N/A` readings on rows that carry nothing else. It is the table equivalent of `grep -v`: rows that match are discarded, all other rows pass through unchanged.

To do the opposite (keep only matching rows), use [`keepOnlyMatchingLines`](keep-only-matching-lines.html).

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

- Exclude noise early in the `computes` pipeline (aggregate rows, removable media, rows of another class) so later computes and the mapping only see real hardware.
- In a `discovery` or `simple` job, whose rows create the instances, exclude on a type or a class only. A value or a state that can change (`N/A` or all-zero readings, a size of `0`, `Disabled`) removes the instance as soon as it matches (MetricsHub Community 3.9.08 or later, see [When Instances Are Removed](../monitors-and-jobs.html#when-instances-are-removed)). Blank such a value instead of dropping the row, or set [`removalDelay`](../monitors-and-jobs.html#removaldelay) on the monitor.
- In a `collect` job, dropping a row also drops the status and the other metrics it carries. When the row holds more than the unwanted value, blank the value instead: an [`awk`](awk.html) compute that empties the reading column, or a [`replace`](replace.html) compute when the exact value is known. Exclude the row only when it carries nothing but that value.
- Prefer `valueList` when the unwanted values are a fixed set of literals; use `regExp` for actual patterns, e.g. `regExp: ^[0.]+$` to drop all-zero readings from rows that carry nothing else.
- Chain one `excludeMatchingLines` per column when you need to filter on several columns.

## Common Mistakes

- Excluding a value or a state (`N/A`, `0`, `Disabled`) in a `discovery` or `simple` job: the instance is removed when the value matches, and comes back with fresh counters when it no longer does.
- Forgetting that `regExp` is unanchored: `regExp: 5` removes every row whose column merely *contains* `5` — use `valueList: 5` or `regExp: ^5$` to remove exact values only.
- Expecting `valueList` entries to support wildcards; they are literal values only (the comparison is case-insensitive, though).
- Using `excludeMatchingLines` with a long value list when an anchored `keepOnlyMatchingLines` on the wanted values would be shorter and safer.
- Counting columns from 0: `column` is 1-based.

## Community Examples

- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml)
- [LibreHardwareMonitor](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/LibreHardwareMonitor/LibreHardwareMonitor.yaml)
- [Windows](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Windows/Windows.yaml)

From `Windows` (drops the `_Total` aggregate row of a performance counter table), included directly from the connector source:

<!-- MACRO{snippet|id=excludeTotalLineCompute|file=src/main/connector/system/Windows/Windows.yaml} -->
