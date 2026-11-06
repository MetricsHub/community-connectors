keywords: insertColumn, compute, add column, new column, placeholder, constant, join key
description: The insertColumn compute inserts a new column at a 1-based position in every row, holding a literal value or the content of another column.

# insertColumn (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `insertColumn` to add a column to every row of a table: a constant (a device type, a `MSHW` marker, a join key such as `joinValue`), an empty placeholder that `mapping` or a `tableJoin` expects, or a copy of another column (`$n`). The columns at and after the position shift one position right.

This replaces the historical trick of an `append` or `prepend` whose value contains `;` (for instance `value: ;joinValue` or `value: MSHW;`), which relied on the table being re-parsed from its semicolon-separated text. `insertColumn` adds exactly one cell, whatever the value holds.

## Syntax

```yaml
sources:
  enclosures:
    type: wmi
    namespace: root\cimv2
    query: SELECT Name, IdentifyingNumber FROM Win32_ComputerSystemProduct
    computes:
      # Name;IdentifyingNumber;
    - type: insertColumn
      column: 1
      value: Computer
      # DeviceType;Name;IdentifyingNumber;
    - type: insertColumn
      column: 4
      value: $2-$3
      # DeviceType;Name;IdentifyingNumber;ID;
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `insertColumn`. |
| `column` | Yes | None | **1-based** position of the new column: `1` inserts before the first column, *number of columns + 1* appends after the last one. A row shorter than `column - 1` cells is padded with empty cells first, so the new cell always lands at `column`. At most 1000; a larger position leaves the table unchanged. |
| `value` | Yes | None | The value of the new cell. `$n` is replaced by the content of column *n* of the same row (an empty string when the row has no such column); several references and literal text can be combined, e.g. `$2-$3`. |

## Table Transformation Example

With `column: 2` and `value: ok`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | ID | Name |
>   | --- | --- |
>   | fan1 | Fan 1 |
>   | fan2 | Fan 2 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | ID | Status | Name |
>   | --- | --- | --- |
>   | fan1 | ok | Fan 1 |
>   | fan2 | ok | Fan 2 |

## Recommended Pattern

- Use `insertColumn` rather than `append`/`prepend` with a `;` in the value: the intent is explicit and a value containing `;` stays one cell.
- Keep a `# Column1;Column2;...` comment after each insertion, since every later index shifts.
- To copy a column next to itself, [`duplicateColumn`](./duplicate-column.html) is shorter; `insertColumn` with `$n` places the copy anywhere and can combine columns.

## Common Mistakes

- Forgetting that the columns from `column` onwards shift right: update the indexes of the following computes and of the `mapping` section.
- Writing `value: $5` expecting a literal `$5`: `$n` is a column reference. Use `$$5` for a literal.
- Using a position greater than *number of columns + 1* by mistake: the rows are padded with empty cells up to the new column, so check the position against the `# column` comment above the compute.
