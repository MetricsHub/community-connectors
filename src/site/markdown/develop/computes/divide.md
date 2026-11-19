keywords: divide, compute, division, arithmetic, ratio, unit conversion
description: The divide compute divides every value of a column by a number or by another column's value.

# divide (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `divide` to divide every value of one column by an operand, row by row. The operand is either
a literal number or, with the `$n` syntax, the value of another column of the same row. Literal
divisors handle unit conversion (100-nanosecond intervals to seconds with `value: 10000000`,
milliseconds to seconds with `value: 1000`); `$n` divisors compute ratios such as
usage / capacity for a utilization metric. The column values must be numeric, and the divisor
must not be `0`.

## Syntax

```yaml
sources:
  processInformation:
    type: wmi
    namespace: root\CIMv2
    query: SELECT Name,ProcessId,KernelModeTime,UserModeTime FROM Win32_Process
    computes:
    # Convert 100-nanosecond intervals to seconds
    - type: divide
      column: 3
      value: 10000000
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `divide`. |
| `column` | Yes | None | 1-based index of the column to update. Each value in this column is replaced by `column value / value`. |
| `value` | Yes | None | Divisor. Either a literal number other than `0` (e.g. `1000`) or a `$n` reference to another column of the same row (e.g. `$7` for the 7th column). |

## Table Transformation Example

With `column: 3` and `value: 10000000`, column 3 of each row is divided by 10,000,000:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | Name | ProcessId | KernelModeTime (100 ns) | UserModeTime (100 ns) |
>   | --- | --- | --- | --- |
>   | services.exe | 704 | 156250000 | 93750000 |
>   | explorer.exe | 4212 | 31250000 | 625000000 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Name | ProcessId | KernelModeTime (s) | UserModeTime (100 ns) |
>   | --- | --- | --- | --- |
>   | services.exe | 704 | 15.625 | 93750000 |
>   | explorer.exe | 4212 | 3.125 | 625000000 |

## Recommended Pattern

- Comment both the source unit and the target unit next to the compute
  (`# unit = 100-nanosecond intervals`, `# divide by 10000000 to get seconds`).
- For a utilization metric that also needs the raw usage, select the usage twice in the source query
  and `divide` one copy by the capacity column with `value: $n`. When the source needs more than
  that (a `duplicateColumn` first, or several columns divided by the same capacity), write one
  [awk](./awk.html) compute that does it all (see [Awk Or Computes](./index.html#awk-or-computes)).

## Common Mistakes

- Dividing by `0`, either literally or through a `$n` reference to a column that can hold `0` or
  an empty value.
- Reversing the operands: `divide` computes `column / value`, never `value / column`.
- Converting units twice: check whether the mapping already applies a conversion function before
  also dividing in the compute pipeline.
- Pointing `column` or `$n` at indexes that were shifted by an earlier compute such as
  `keepColumns` or `awk`.

## Community Examples

- [Cassandra](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/Cassandra/Cassandra.yaml)
- [Windows](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Windows/Windows.yaml)

From `Cassandra.yaml`, converting the uptime of the instance from milliseconds into seconds, included directly from the connector source:

<!-- MACRO{snippet|id=divideUptimeCompute|file=src/main/connector/database/Cassandra/Cassandra.yaml} -->
