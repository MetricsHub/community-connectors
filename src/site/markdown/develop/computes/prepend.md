keywords: prepend, compute, concatenate, prefix, insert column, string
description: The prepend compute concatenates a value at the beginning of every cell in a column, and can materialize new columns when the value contains semicolons.

# prepend (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `prepend` to concatenate a value at the **beginning** of a column's content, on every row of the table. Typical uses are labeling a raw value for display (`value: "SerialNumber: "` before the serial number column), prepending `$n` (the content of column *n*) to build composite values, or prepending the content of another source with `${source::...}`.

Because a table is serialized as semicolon-separated text, prepending a value that contains `;` effectively **inserts new columns** to the left of the target column — a deliberate and widely used trick, especially to add a constant marker column (`value: MSHW;`) in front of single-value SNMP results.

## Syntax

```yaml
sources:
  upsInputVoltage:
    type: snmpTable
    oid: 1.3.6.1.2.1.33.1.3.3.1
    selectColumns: ID
    computes:
      # Add a constant "MSHW" ID column and an "Input " label prefix
      # MSHW;Input <lineID>;
    - type: prepend
      column: 1
      value: 'MSHW;Input '
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `prepend`. |
| `column` | Yes | None | **1-based** index of the column to modify. Applied to every row. |
| `value` | Yes | None | String inserted at the beginning of the column content. Accepts a literal, a `$n` reference to another column of the same row, or a `${source::...}` reference whose content is prepended. A value containing `;` inserts new columns (see below). |

## Table Transformation Example

With `column: 1` and `value: 'MSHW;Input '`:

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
>   | Constant | Name |
>   | --- | --- |
>   | MSHW | Input 1 |
>   | MSHW | Input 2 |

**Semicolon trick:** the first row serializes as `1`; prepending `MSHW;Input ` to column 1 yields:

```text
MSHW;Input 1
```

which re-parses as **2 columns**: the `;` inside the value split the old column 1 into a new constant column plus the prefixed original. GenericUPS uses exactly this (`value: MSHW;`) to give single-value `snmpGet` results a stable ID column.

## Recommended Pattern

- Quote values that end with a space or contain `;` followed by text, so YAML preserves them verbatim: `value: 'MSHW;Input '`.
- Use `prepend` with a trailing `;` (`value: MSHW;`) to add a constant leading key column to keyless single-value sources before a `tableJoin` or `mapping`.
- Label human-readable fields (`"Model: "`, `"SerialNumber: "`) with `prepend` right before `mapping` rather than in AWK scripts — it keeps the pipeline declarative.
- Keep a `# Column1;Column2;...` comment after any `prepend` that inserts columns, so later computes are written against the new layout.

## Common Mistakes

- Forgetting that a `;` in `value` shifts **all** column indexes right — every subsequent compute and the `mapping` section must use the new indexes.
- Forgetting that `column` is 1-based.
- Writing `value: $2` expecting a literal `$2`: `$n` is interpreted as a column reference.
- Losing a trailing space by leaving the value unquoted: write `value: "Model: "`, not `value: Model: `.

## Community Examples

- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/IpmiTool/IpmiTool.yaml)
- [Windows](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Windows/Windows.yaml)

From Windows (prepending the content of another source to combine both tables for calculations):

```yaml
    computes:
    # Combining both sources for calculations
    - type: prepend
      column: 1
      value: ${source::memoryInformation}
```
