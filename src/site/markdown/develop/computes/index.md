keywords: computes, transformations
description: Compute pipeline reference for MetricsHub connectors.

# Computes

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## Compute Pipeline Model

Computes run in order and transform source tables before mapping.

Most compute operations are column-oriented because they operate on table rows:

```yaml
computes:
- type: replace
  column: 3
  existingValue: 1
  newValue: ok
```

Table example:

| id | display_name | status_code |
| --- | --- | --- |
| fan01 | Fan A | 1 |
| fan02 | Fan B | 3 |

Serialized:

```text
fan01;Fan A;1
fan02;Fan B;3
```

After translation/replace, mapping consumes the transformed table.

> [!NOTE]
> A compute changes the cells of the table, never its text: a `;` or a line feed that `append`, `prepend`, `replace` or `translate` writes into a cell stays in that cell, and adds no column and no row. This holds for a `${source::...}` reference in the value as well: a table of several cells is written into the cell as its serialized text (`a;b;c;`), and the reference is reported (`TABLE_INTERPOLATED`, a value must reference a text). Use [insertColumn](./insert-column.html) to add a column, and a [tableJoin](../sources/table-join.html) to combine the columns of two sources.

## Content Types

A source result, and the result of each compute, is either **text** (lines) or a **table** (rows of cells), never both:

- `commandLine`, `http`, `file`, `ipmi` and the `awk` source with the default `output: text` produce text (`commandLine` after its own `keep`, `exclude`, `separators` and `selectColumns`), and so does a source with `executeForEachEntryOf` and a `json_array`, `json_array_extended` or custom `concatMethod`; every other source produces a table (`sql`, `wmi`, `snmpTable`, `static`, the `awk` source with `output: table`, ...); a `copy` produces what it copies, a [textUnion](../sources/text-union.html) is a text, and so is a `tableUnion` of texts (see [tableUnion](../sources/table-union.html#texts-in-a-union));
- `awk` reads its input as it is (a text the traditional way, a table structured, see [awk](./awk.html#table-input-and-output)) and writes text unless it declares `output: table`; `json2Table`, `json2List`, `xml2Csv` and `toTable` read text and write a table; `toText` reads a table and writes text; every other compute reads and writes a table.

Convert with [toTable](./to-table.html) and [toText](./to-text.html) when a compute does not read what the previous step produced. MetricsHub checks every chain when it loads a connector and reports a step that reads the wrong type (see [Strict Content Types](../design-principles.html#strict-content-types)). In this release, it still inserts these conversions itself, and they behave exactly like written ones; a later release rejects the connector instead, so write them:

- a `toTable` with its default properties (one row per line, cells split on `;`) after the text of a `commandLine` source, an `awk` source or an `awk` compute: before the next table compute, and at the end of the source, so that the `mapping`, a `tableJoin` or a variable reads a table. A source that only `copy` sources and text unions read, or that a tool without columns returns, keeps its text at the end: the copies and unions convert it where they need a table, and the tool returns the text;
- a `toTable` with its default properties before a table compute that follows an explicit `toText`.

Nothing is inserted before an `awk` compute: it reads the text or the table it receives. Write a `toText` before an `awk` whose script parses a table as `;`-separated lines.

Nothing is inserted between a table compute or the `mapping` and the text of `http`, `file` or `ipmi`, of a source with `executeForEachEntryOf` and a `json_array`, `json_array_extended` or custom `concatMethod`, or of a text union with such a source among its members: convert it with `json2Table`, `json2List`, `xml2Csv`, `toTable` or `awk` (with `output: table`). A step that reads the wrong type sees nothing: a table compute (or the `mapping`) on text reads no rows and produces an empty table, and `json2Table`, `json2List` or `xml2Csv` on a table leaves the table unchanged.

A source that returns nothing, or fails, gives an empty result of its own type: after a failed `commandLine`, an `awk` compute still runs its `BEGIN` and `END` blocks.

## Compute Pages

### Arithmetic and Bitwise

| Compute | Purpose |
| --- | --- |
| [add](./add.html) | Add a value (literal or `$n`) to a numeric column. |
| [subtract](./subtract.html) | Subtract a value from a numeric column. |
| [multiply](./multiply.html) | Multiply a numeric column (unit conversions, sign flips). |
| [divide](./divide.html) | Divide a numeric column (unit conversions, ratios). |
| [and](./and.html) | Bitwise AND a column with a bitmask. |

### String Manipulation

| Compute | Purpose |
| --- | --- |
| [append](./append.html) | Concatenate a value to the end of a column. |
| [prepend](./prepend.html) | Concatenate a value to the start of a column. |
| [replace](./replace.html) | Replace a literal value in a column. |
| [substring](./substring.html) | Keep a portion of a column's value (1-based start, length). |
| [duplicateColumn](./duplicate-column.html) | Insert a copy of a column immediately after the original. |
| [insertColumn](./insert-column.html) | Insert a new column at a position, holding a literal or `$n` value. |

### Row Filtering, Sorting and Column Projection

| Compute | Purpose |
| --- | --- |
| [keepOnlyMatchingLines](./keep-only-matching-lines.html) | Keep rows whose column matches a regex or value list. |
| [excludeMatchingLines](./exclude-matching-lines.html) | Remove rows whose column matches a regex or value list. |
| [sort](./sort.html) | Sort the rows on a column, alphabetically or numerically, ascending or descending. |
| [head](./head.html) | Keep the first rows. |
| [tail](./tail.html) | Keep the last rows. |
| [keepColumns](./keep-columns.html) | Keep only the listed columns. |
| [extract](./extract.html) | Split a column on separators and keep one sub-part. |
| [extractPropertyFromWbemPath](./extract-wbem-property.html) | Pull one property value out of a WBEM object path. |

### Translation and Normalization

| Compute | Purpose |
| --- | --- |
| [translate](./translate.html) | Map raw values to normalized values through a translation table. |
| [arrayTranslate](./array-translate.html) | Translate each element of a multi-value cell. |
| [perBitTranslation](./translate-per-bit.html) | Decode a bitmask status word bit by bit through a translation table. |
| [convert](./convert.html) | Built-in conversions: `hex2Dec`, `array2SimpleStatus`. |

### Format Conversion and Encoding

| Compute | Purpose |
| --- | --- |
| [json2Table](./json2csv.html) | Flatten a JSON payload into table rows (prepends an entry column). Formerly `json2Csv`, still accepted as a deprecated alias. |
| [json2List](./json2list.html) | List every value of a JSON document as a row: its key path and the value. |
| [xml2Csv](./xml2csv.html) | Flatten an XML payload into table rows. |
| [toTable](./to-table.html) | Turn a text result into a table (one row per line, split on a separator). |
| [toText](./to-text.html) | Turn a table into semicolon-separated text for an `awk` compute. |
| [encode](./encode.html) | Encode a column as `base64` or `url`. |
| [decode](./decode.html) | Decode a `base64` or `url` column. |

### Scripted Transformation

| Compute | Purpose |
| --- | --- |
| [awk](./awk.html) | Run an AWK script over the source result for arbitrary reshaping. |
