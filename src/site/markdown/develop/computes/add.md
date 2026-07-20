keywords: add, compute, addition, arithmetic, sum, column math
description: The add compute adds a number or another column's value to every value of a column.

# add (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `add` to perform an addition on every value of one column, row by row. The operand is either a
literal number or, with the `$n` syntax, the value of another column of the same row, which makes
`add` the standard way to sum two counters into one (e.g. read errors + write errors = total
errors, inbound + outbound traffic = total traffic). The column values must be numeric.

## Syntax

```yaml
sources:
  diskErrors:
    type: wmi
    namespace: root\Microsoft\Windows\Storage
    query: SELECT DeviceId,ReadErrorsTotal,Wear,WriteErrorsTotal FROM MSFT_StorageReliabilityCounter
    computes:
    # TotalErrors = ReadErrors + WriteErrors
    - type: add
      column: 2
      value: $4
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `add`. |
| `column` | Yes | None | 1-based index of the column to update. Each value in this column is replaced by the result of the addition. |
| `value` | Yes | None | Operand added to the column value. Either a literal number (e.g. `100`) or a `$n` reference to another column of the same row (e.g. `$4` for the 4th column). |

## Table Transformation Example

With `column: 2` and `value: $4`, column 2 of each row becomes `column 2 + column 4`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | DeviceId | ReadErrors | Wear | WriteErrors |
>   | --- | --- | --- | --- |
>   | disk0 | 12 | 3 | 5 |
>   | disk1 | 0 | 1 | 0 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | DeviceId | TotalErrors | Wear | WriteErrors |
>   | --- | --- | --- | --- |
>   | disk0 | 17 | 3 | 5 |
>   | disk1 | 0 | 1 | 0 |

The operand column (here column 4) is left untouched; drop it later with `keepColumns` if it is no
longer needed.

## Recommended Pattern

- Use `value: $n` to sum two counter columns of the same row into a single metric column.
- Comment the expected column layout above the compute (`# DeviceId;TotalErrors;Wear;WriteErrors`)
  so later index changes are easy to review.
- Combine with `multiply` `value: -1` when you need `constant - column` (negate, then `add` the
  constant), as no reversed-operand subtract exists.
- Add derived columns via the source query (select a field twice) rather than overwriting a value
  you still need downstream.

## Common Mistakes

- Confusing `column` (the 1-based index that is overwritten) with `value: $n` (the operand that is
  only read).
- Forgetting that upstream computes (`keepColumns`, `awk`, `json2Csv`) may have renumbered the
  columns, so `column` and `$n` point to the wrong data.
- Applying `add` to a column that contains non-numeric text such as an empty string or a label.

## Community Examples

- [WinStorageSpaces](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WinStorageSpaces/WinStorageSpaces.yaml)
- [WindowsProcess](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/WindowsProcess/WindowsProcess.yaml)
- [MIB2-header](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/MIB2-header/MIB2-header.yaml)

From `MIB2-header.yaml`, accumulating the multicast and broadcast packet counters into the unicast packets column, included directly from the connector source:

<!-- MACRO{snippet|id=addPacketCountersCompute|file=src/main/connector/hardware/MIB2-header/MIB2-header.yaml} -->
