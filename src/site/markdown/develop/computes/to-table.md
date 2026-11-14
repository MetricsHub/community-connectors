keywords: toTable, compute, text to table, split, separator, lines, content type
description: The toTable compute turns a text result into a table, one row per line, split on a separator, with optional line filtering and column selection.

# toTable (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

A source result is either **text** (lines, as produced by `http`, `file`, `ipmi`, `commandLine` and the `awk` source or compute with the default `output: text`) or a **table** (rows of cells, as produced by every other source and by every other compute). Use `toTable` to turn a text result into a table before a table compute (`keepColumns`, `translate`, `append`, ...) or before `mapping`.

Each line of the text becomes a row and is split on `separator`, taken literally (a multi-character separator is one separator). Lines can be filtered with `keep` and `exclude` as on the [`commandLine` source](../sources/command-line.html), and the columns selected with `selectColumns`.

MetricsHub inserts no conversion (see the [content types](./index.html#content-types)): write `toTable` wherever a text is read as a table. A text read as a table without a conversion is rejected when the connector loads (`TEXT_FEEDS_TABLE`, see [Strict Content Types](../design-principles.html#strict-content-types)).

On a table, `toTable` without properties leaves the table unchanged. With `keep`, `exclude`, `selectColumns` or a `separator` other than `;`, it applies them to the table written as [toText](./to-text.html) writes it. A `toTable` on a table is rejected (`TABLE_FEEDS_TEXT`, whose hint reads "write a toText"): remove it, or, when its properties are meant to apply to the serialized table, write a `toText` before it.

## Syntax

```yaml
sources:
  disks:
    type: commandLine
    commandLine: /usr/bin/lsblk -r -o NAME,SIZE,TYPE
    computes:
      # NAME;SIZE;TYPE
    - type: toTable
      separator: " "
      keep: disk$
    - type: keepColumns
      columnNumbers: "1,2"
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `toTable`. |
| `separator` | No | `;` | The text separating the cells of a line, taken literally. A trailing separator does not add an empty cell; two consecutive separators do. A blank separator (a space, a tab) splits on runs of it and keeps no empty cell, as the `commandLine` source does. |
| `keep` | No | None | Regular expression; only the lines that match become rows. |
| `exclude` | No | None | Regular expression; the lines that match are dropped. |
| `selectColumns` | No | None | Comma-separated **1-based** column numbers or ranges to keep after the split, in that order, e.g. `"2,4-6,8-"` (`8-` means from column 8 to the last one). A selected column absent from a row gives an empty cell, so the row is kept. `0` selects nothing. |

Blank lines never become rows, and CRLF line endings are read as LF.

## Table Transformation Example

With `separator: " "` and `keep: disk$` on the text:

```text
NAME SIZE TYPE
sda 931.5G disk
sda1 512M part
sdb 1.8T disk
```

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | NAME | SIZE | TYPE |
>   | --- | --- | --- |
>   | sda | 931.5G | disk |
>   | sdb | 1.8T | disk |

## Recommended Pattern

- Put `toTable` right after the text producer, then refine with the table computes.
- Keep the `# Column1;Column2;...` comment after it, as after any compute that changes the column layout.
- Filter the lines here (`keep`, `exclude`) rather than in a later `keepOnlyMatchingLines` when the filter applies to the whole line.

## Common Mistakes

- Applying a table compute, or the `mapping`, to a text without a conversion: the connector does not load (`TEXT_FEEDS_TABLE`).
- Choosing a separator that also appears inside cells: the cell is split. Use the `awk` compute to build the rows when the text has no safe separator.
- Expecting `selectColumns` to work without a split: the columns are the cells produced by `separator`.
