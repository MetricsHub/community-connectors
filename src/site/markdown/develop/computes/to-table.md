keywords: toTable, compute, text to table, split, separator, lines, content type
description: The toTable compute turns a text result into a table, one row per line, split on a separator, with optional line filtering and column selection.

# toTable (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

A source result is either **text** (lines, as produced by `http`, `file`, `ipmiRaw`, `commandLine` and the `awk` source or compute) or a **table** (rows of cells, as produced by every other source and by every other compute). Use `toTable` to turn a text result into a table before a table compute (`keepColumns`, `translate`, `append`, ...) or before `mapping`.

Each line of the text becomes a row and is split on `separator`. Lines can be filtered with `keep` and `exclude`, and the columns selected with `selectColumns`, with the same semantics as the equivalent properties of the [`commandLine` source](../sources/command-line.html) and the [`awk` compute](./awk.html).

MetricsHub inserts this conversion itself in existing connectors (a table compute after `commandLine` or after an `awk` compute), so a connector written before the conversion existed keeps working unchanged. Write it explicitly in new connectors: the chain then says what it does.

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
| `separator` | No | `;` | The character(s) separating the cells of a line. A trailing separator does not add an empty cell; a separator between two consecutive separators does. |
| `keep` | No | None | Regular expression; only the lines that match become rows. |
| `exclude` | No | None | Regular expression; the lines that match are dropped. |
| `selectColumns` | No | None | Comma-separated **1-based** column numbers or ranges to keep after the split, e.g. `"2,4-6"`. |

Blank lines never become rows.

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

- Applying a table compute to a text result without `toTable`: the table is empty, so the compute has nothing to work on.
- Choosing a separator that also appears inside cells: the cell is split. Use the `awk` compute to build the rows when the text has no safe separator.
- Expecting `selectColumns` to work without a split: the columns are the cells produced by `separator`.
