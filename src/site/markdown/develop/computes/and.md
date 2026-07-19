keywords: and, compute, bitwise, bitmask, binary, status word
description: The and compute applies a bitwise AND between every value of a column and a bitmask.

# and (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `and` to apply a bitwise AND between every value of one column and a bitmask, row by row.
This isolates the bits you care about in a packed status word — for example keeping only the
low-order bits of a raw hardware register, or testing a single flag bit before translating it to
a status. The mask is either a literal number or, with the `$n` syntax, the value of another
column of the same row. When each bit of the word maps to its own status message, prefer
`perBitTranslation`, which decodes all bits in one pass.

## Syntax

```yaml
sources:
  sensorStatus:
    type: snmpTable
    oid: 1.3.6.1.4.1.9999.1.2.1
    selectColumns: "ID,2"
    computes:
    # Keep only the 10 low-order bits of the raw status word
    - type: and
      column: 2
      value: 1023
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `and`. |
| `column` | Yes | None | 1-based index of the column to update. Each value in this column is replaced by `column value AND value` (bitwise). |
| `value` | Yes | None | Bitmask combined with the column value. Either a literal number (e.g. `1023` to keep the 10 low-order bits, `8` to test bit 3) or a `$n` reference to another column of the same row. |

## Table Transformation Example

With `column: 2` and `value: 1023` (binary `1111111111`), any bits above bit 9 are cleared:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | ID | RawStatus |
>   | --- | --- |
>   | 1 | 5123 |
>   | 2 | 18 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | ID | RawStatus |
>   | --- | --- |
>   | 1 | 3 |
>   | 2 | 18 |

`5123` is binary `1010000000011`; masking with `1023` keeps only the 10 low-order bits, leaving
`3`. `18` fits entirely within the mask and is unchanged.

## Recommended Pattern

- Document the mask in binary in a comment (`# 1023 = 1111111111, keep bits 0-9`) so reviewers do
  not have to convert it mentally.
- Follow `and` with a `translate` compute to turn the isolated bit value into a readable status.
- To test one flag, mask with the bit's value (`1`, `2`, `4`, `8`, ...): the result is non-zero
  when the flag is set.
- Reach for `perBitTranslation` instead when several independent bits each carry their own
  meaning.

## Common Mistakes

- Writing the mask in binary or hexadecimal notation while a plain decimal number is expected
  (`1023`, not `0b1111111111`).
- Masking a column that is not an integer status word (decimal or textual values).
- Confusing `and` with a logical filter: it transforms values in place and never removes rows —
  use `keepOnlyMatchingLines` or `excludeMatchingLines` to filter.

## Community Examples

> [!NOTE]
> No community connector currently uses `and`; the examples above are illustrative.
