keywords: prepend, compute, concatenate, prefix, insert column, string
description: The prepend compute concatenates a value at the beginning of every cell in a column.

# prepend (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `prepend` to concatenate a value at the **beginning** of a column's content, on every row of the table. Typical uses are labeling a raw value for display (`value: "SerialNumber: "` before the serial number column), prepending `$n` (the content of column *n*) to build composite values, or prepending the content of another source with `${source::...}`.

The value is added to the cell as it is: a `;` or a line feed in it is an ordinary character of the cell, and adds no column and no row. To add a column, such as a constant `MSHW` key in front of single-value SNMP results, use [insertColumn](./insert-column.html).

## Syntax

```yaml
sources:
  upsInputVoltage:
    type: snmpTable
    oid: 1.3.6.1.2.1.33.1.3.3.1
    selectColumns: ID
    computes:
      # Add an "Input " label prefix
      # Input <lineID>;
    - type: prepend
      column: 1
      value: 'Input '
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `prepend`. |
| `column` | Yes | None | **1-based** index of the column to modify. Applied to every row. |
| `value` | Yes | None | String inserted at the beginning of the column content. Accepts a literal, a `$n` reference to another column of the same row, or a `${source::...}` reference whose content is prepended. A `;` or a line feed in the value stays in the cell. |

## Table Transformation Example

With `column: 1` and `value: 'Input '`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | ID |
>   | --- |
>   | 1 |
>   | 2 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Name |
>   | --- |
>   | Input 1 |
>   | Input 2 |

## Recommended Pattern

- Quote values that end with a space, so YAML preserves them verbatim: `value: 'Input '`.
- Use [insertColumn](./insert-column.html) with `column: 1` (`value: MSHW`) to add a constant leading key column to keyless single-value sources before a `tableJoin` or `mapping`.
- Label human-readable fields (`"Model: "`, `"SerialNumber: "`) with `prepend` right before `mapping` rather than in AWK scripts — it keeps the pipeline declarative.

## Common Mistakes

- Expecting a `;` in `value` to insert columns: `value: MSHW;` on the cell `1` gives the single cell `MSHW;1`. Use [insertColumn](./insert-column.html).
- Prepending a `${source::...}` reference to a table of several cells to bring its columns in: the cell receives the serialized row (`1` becomes `a;b;1`). Combine sources with a [tableJoin](../sources/table-join.html).
- Forgetting that `column` is 1-based.
- Writing `value: $2` expecting a literal `$2`: `$n` is interpreted as a column reference.
- Losing a trailing space by leaving the value unquoted: write `value: "Model: "`, not `value: Model: `.

## Community Examples

- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/ipmi/IpmiOverLan/IpmiTool.yaml) (`"Model: "` and `"SerialNumber: "` labels)
