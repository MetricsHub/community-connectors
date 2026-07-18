keywords: keepColumns, compute, column projection, columnNumbers, reduce table
description: The keepColumns compute keeps only the listed columns of the table, discarding all others.

# keepColumns (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `keepColumns` to project a wide source table down to just the columns your mapping (or the next compute) needs. It is typically applied after a query or command that returns more fields than necessary, or after computes such as `duplicateColumn` and `tableJoin` have widened the table. Every column not listed in `columnNumbers` is discarded; rows are never removed.

`keepColumns` filters columns; to filter rows, use [`keepOnlyMatchingLines`](keep-only-matching-lines.html) or [`excludeMatchingLines`](exclude-matching-lines.html).

## Syntax

```yaml
sources:
  fanSensors:
    type: commandLine
    commandLine: ${file::ipmi-fru.sh}
    computes:
    - type: keepColumns
      columnNumbers: 1,2,3,7,8,9
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `keepColumns`. |
| `columnNumbers` | Yes | None | Comma-separated list of **1-based** column indexes to keep, e.g. `1,2,4,6,8`. The kept columns always appear in ascending index order, regardless of the order in which they are listed. If any listed index does not exist in a row, the table is left unchanged. |

## Table Transformation Example

With `columnNumbers: 1,3,5`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | ID | Location | Model | Firmware | Status |
>   | --- | --- | --- | --- | --- |
>   | fan1 | front | Delta F1 | 1.02 | ok |
>   | fan2 | rear | Delta F1 | 1.02 | failed |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | ID | Model | Status |
>   | --- | --- | --- |
>   | fan1 | Delta F1 | ok |
>   | fan2 | Delta F1 | failed |

Serialized, `fan1;front;Delta F1;1.02;ok` becomes `fan1;Delta F1;ok`.

## Recommended Pattern

- Apply `keepColumns` as the **last** compute of the pipeline whenever possible: earlier computes reference columns by index, and dropping columns mid-pipeline renumbers everything after it.
- Add a comment listing the kept column names right next to the compute (as `IpmiTool` and `WindowsIpmiTool` do), so the mapping's `$1`, `$2`, ... references stay understandable.
- Trim `tableJoin` results with `keepColumns` to remove the duplicated key columns before mapping.

## Common Mistakes

- Expecting `keepColumns` to reorder columns: `columnNumbers: 3,1` yields columns 1 then 3, not 3 then 1. Use `duplicateColumn` or an `awk` compute when you really need reordering.
- Forgetting that every subsequent compute and the mapping must use the **new** column numbering, not the original one.
- Listing an index larger than the row width: the compute logs a warning and leaves the table unchanged, which can silently break the mapping.
- Counting columns from 0: `columnNumbers` is 1-based.

## Community Examples

- [Cassandra](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/Cassandra/Cassandra.yaml)
- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/IpmiTool/IpmiTool.yaml)
- [WinStorageSpaces](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WinStorageSpaces/WinStorageSpaces.yaml)

From `Cassandra`:

```yaml
          - type: keepColumns
            columnNumbers: 1,2,4,6,8
```
