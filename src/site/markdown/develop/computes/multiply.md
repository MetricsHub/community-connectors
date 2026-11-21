keywords: multiply, compute, multiplication, arithmetic, unit conversion, scaling
description: The multiply compute multiplies every value of a column by a number or by another column's value.

# multiply (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `multiply` to multiply every value of one column by an operand, row by row. The operand is
either a literal number or, with the `$n` syntax, the value of another column of the same row.
It is the workhorse of unit conversion — kilobytes to bytes (`value: 1024`), megabytes to bytes
(`value: 1048576`), ratios to percentages (`value: 100`) — and `value: -1` negates a column. The
column values must be numeric.

## Syntax

```yaml
sources:
  memoryUsage:
    type: wmi
    namespace: root\CIMv2
    query: SELECT Caption,TotalVisibleMemorySize FROM Win32_OperatingSystem
    computes:
    # Convert kilobytes to bytes
    - type: multiply
      column: 2
      value: 1024
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `multiply`. |
| `column` | Yes | None | 1-based index of the column to update. Each value in this column is replaced by the result of the multiplication. |
| `value` | Yes | None | Multiplier. Either a literal number (e.g. `1024`, `100`, `-1`) or a `$n` reference to another column of the same row (e.g. `$3` for the 3rd column). |

## Table Transformation Example

With `column: 2` and `value: 1024`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | Caption | TotalVisibleMemorySize (kB) |
>   | --- | --- |
>   | Microsoft Windows Server 2022 | 16777216 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Caption | TotalVisibleMemorySize (B) |
>   | --- | --- |
>   | Microsoft Windows Server 2022 | 17179869184 |

## Recommended Pattern

- Convert source units to the units expected by the metric right after collection, and record the
  conversion in a comment (`# Convert kilobytes to bytes`).
- For `constant - column` (e.g. endurance remaining = 100 - wear), write one [awk](./awk.html)
  compute (`$3 = 100 - $3`): `subtract` only computes `column - value`, and a `multiply` by `-1`
  followed by an `add` is a run of two computes (see [Awk Or Computes](./index.html#awk-or-computes)).
- When the same conversion applies to several columns, convert them all in one `awk` compute rather
  than with one `multiply` per column.

## Common Mistakes

- Converting units twice: check whether the mapping already applies a conversion function (e.g.
  `megaHertz2Hertz`, `percent2Ratio`) before also multiplying in the compute pipeline.
- Using the wrong factor for byte conversions (`1024` for kB, `1048576` for MB — not `1000`).
- Applying `multiply` to a column that contains non-numeric text such as an empty string or a
  label.

## Community Examples

- [LibreHardwareMonitor](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/LibreHardwareMonitor/LibreHardwareMonitor.yaml)
- [MIB2EntitySensor-header](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/MIB2EntitySensor-header/MIB2EntitySensor-header.yaml)

From `LibreHardwareMonitor.yaml`, converting volts into millivolts, included directly from the connector source:

<!-- MACRO{snippet|id=multiplyVoltsCompute|file=src/main/connector/hardware/LibreHardwareMonitor/LibreHardwareMonitor.yaml} -->
