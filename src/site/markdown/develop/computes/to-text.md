keywords: toText, compute, table to text, serialize, awk, content type
description: The toText compute turns a table into text, one semicolon-separated line per row, so that a text compute such as awk can read it.

# toText (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

A source result is either **text** (lines) or a **table** (rows of cells). Use `toText` to turn a table into text before a compute that reads text, in practice before an [`awk` compute](./awk.html) whose script parses the rows of a table produced by `snmpTable`, `wmi`, `wbem`, `sql`, `json2Table`, ... as `;`-separated lines. Write it also at the end of a table source that a [textUnion](../sources/text-union.html) reads.

Each row becomes a line, the cells are joined with `;` and the line ends with a `;`. A `;` inside a cell is replaced by `,` so that the number of columns does not change. The result is text only: the table is gone until a `toTable` rebuilds one. An `awk` compute writes text as well, so when its output is meant as a table, follow it with an explicit `toTable` (MetricsHub inserts one where the text is read as a table, and reports it, see the [content types](./index.html#content-types)), or declare `output: table` on the `awk`. On a text, `toText` changes nothing, and it is reported (`TEXT_FEEDS_TABLE`).

MetricsHub inserts nothing before an `awk` compute: without `toText`, an `awk` that follows a table reads it structured, one record per row and one field per cell (`$1..$NF`). Write `toText` only for a script that parses the `;`-separated lines.

## Syntax

```yaml
sources:
  fans:
    type: snmpTable
    oid: 1.3.6.1.4.1.674.10892.5.4.700.12.1
    selectColumns: "ID,2,5,6"
    computes:
    - type: toText
    - type: awk
      script: |
        BEGIN { FS = ";" }
        { print $1 ";" $2 ";" ($3 / 60) ";" }
    - type: toTable
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `toText`. |

## Table Transformation Example

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | ID | Name | Speed |
>   | --- | --- | --- |
>   | 1 | Fan 1 | 3000 |
>   | 2 | Fan 2; rear | 2700 |
>
> - <span class="fa-solid fa-file-lines"></span> Result (text)
>
>   ```text
>   1;Fan 1;3000;
>   2;Fan 2, rear;2700;
>   ```

## Recommended Pattern

- Set `FS = ";"` in the AWK script that follows, and print `;`-separated lines with a trailing `;` so that the `awk` compute rebuilds the same column layout.
- Prefer the table computes (`translate`, `multiply`, `keepOnlyMatchingLines`, ...) when they can express the transformation: they keep the table typed and need no conversion.

## Common Mistakes

- Reading the cells with the default AWK field separator (whitespace): set `FS = ";"`.
- Expecting a `;` inside a cell to survive: it becomes `,`.
- Following `toText` with a table compute: MetricsHub converts the text back with a `toTable`: the round trip changes nothing, except that a `;` inside a cell comes back as a `,` and a line feed inside a cell splits its row. Ending the chain with `toText`: the `mapping` reads no rows.
