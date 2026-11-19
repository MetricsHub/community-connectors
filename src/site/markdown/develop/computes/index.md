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

After translation/replace, mapping consumes the transformed table.

> [!NOTE]
> A compute changes the cells of the table, never its text: a `;` or a line feed that `append`, `prepend`, `replace` or `translate` writes into a cell stays in that cell, and adds no column and no row. This holds for a `${source::...}` reference in the value as well. A value must reference a text: a table there is rejected when the connector loads (`TABLE_INTERPOLATED`). Use [insertColumn](./insert-column.html) to add a column, and a [tableJoin](../sources/table-join.html) to combine the columns of two sources.

## Content Types

A source result, and the result of each compute, is either **text** (lines) or a **table** (rows of cells), never both:

- `commandLine`, `http`, `file`, `ipmi` and the `awk` source with the default `output: text` produce text (`commandLine` after its own `keep`, `exclude`, `separators` and `selectColumns`), and so does a source with `executeForEachEntryOf` and a `json_array`, `json_array_extended` or custom `concatMethod`; every other source produces a table (`sql`, `wmi`, `snmpTable`, `static`, the `awk` source with `output: table`, ...); a `copy` produces what the chain of the source it copies ends in, a [textUnion](../sources/text-union.html) is a text, and a [tableUnion](../sources/table-union.html) is always a table;
- `awk` reads its input as it is (a text the traditional way, a table structured, see [awk](./awk.html#table-input-and-output)) and writes text unless it declares `output: table`; `json2Table`, `json2List`, `xml2Csv` and `toTable` read text and write a table; `toText` reads a table and writes text; `append`, `prepend`, `replace` and `substring` keep the type they are fed, a text or a table (see [append](./append.html#on-a-text)); every other compute reads and writes a table.

Convert with [toTable](./to-table.html) and [toText](./to-text.html) when a compute does not read what the previous step produced. MetricsHub inserts no conversion: it checks every chain when it loads a connector, and a connector with a step that reads the wrong type does not load (see [Strict Content Types](../design-principles.html#strict-content-types)). Write:

- a `toTable` (one row per line, cells split on `;` by default) after the text of a `commandLine` source, an `awk` source or an `awk` compute, or declare `output: table` on the `awk`: before the next table compute, and at the end of the source when the `mapping`, a `tableJoin`, a `tableUnion`, a tool with `columns`, an `awk` variable, `executeForEachEntryOf` or an `internalDbQuery` reads it as a table. A source that only `copy` sources and text unions read, or that a tool without columns returns, keeps its text at the end: a copy that needs a table writes its own `toTable`, and the tool returns the text;
- a `toTable` before a table compute that follows a `toText`.

An `awk` compute reads the text or the table it receives. Write a `toText` before an `awk` whose script parses a table as `;`-separated lines.

Convert the text of `http`, `file` or `ipmi`, of a source with `executeForEachEntryOf` and a `json_array`, `json_array_extended` or custom `concatMethod`, or of a text union, with `json2Table`, `json2List`, `xml2Csv`, `toTable` or `awk` (with `output: table`) before a table compute or the `mapping` reads it.

A source that returns nothing, or fails, gives an empty result of its own type: after a failed `commandLine`, an `awk` compute still runs its `BEGIN` and `END` blocks.

## Awk Or Computes

One compute that does what the source needs stays a compute. When a source needs two or more consecutive computes that AWK expresses directly (`add`, `subtract`, `multiply`, `divide`, `duplicateColumn`, `insertColumn`, `keepColumns`, `append`, `prepend`, `replace`, `substring`, `keepOnlyMatchingLines`, `excludeMatchingLines`, `head`, or an `awk` next to them), write one [awk](./awk.html) compute with `output: table` instead: the whole transformation reads in one place.

These stay computes, and end the run: the computes before them and after them are written as separate scripts.

- `translate`, `arrayTranslate` and `perBitTranslation`, with their translation tables;
- the conversions (`convert`, `extract`, `extractPropertyFromWbemPath`, `json2Table`, `json2List`, `xml2Csv`, `toTable`, `toText`, `encode`, `decode`), `and` (AWK has no bitwise AND), `sort` and `tail`;
- a compute whose value is a `${source::...}` reference;
- a `keepOnlyMatchingLines` or `excludeMatchingLines` whose `regExp` comes from a variable (`${var::...}`, `${param::...}`): the user writes it for the compute.

Instead of:

```yaml
- type: subtract
  column: 8
  value: $7
- type: divide
  column: 6
  value: $8
- type: multiply
  column: 6
  value: 100
```

Write:

```yaml
- type: awk
  output: table
  script: |
    BEGIN { OFMT = "%.15g" }
    function isNumber(x) { return x ~ /^[ \t]*[-+]?([0-9]+[.]?[0-9]*|[.][0-9]+)([eE][-+]?[0-9]+)?[ \t]*$/ }
    {
      if (isNumber($8) && isNumber($7)) $8 = $8 - $7
      if (isNumber($6) && isNumber($8) && $8 + 0 != 0) $6 = $6 / $8
      if (isNumber($6)) $6 = $6 * 100
      print
    }
```

The script takes care of what the computes do on their own:

- An arithmetic compute leaves a cell as it is when an operand is empty or not a number, or when it would divide by 0. AWK computes with such an operand anyway (as 0, or as the number it starts with), and a division by 0 gives `inf`: test the operands before computing, as `isNumber` does above.
- `print` writes a computed number that is not a whole number (an argument, or a field the script assigned) with `OFMT`, 6 significant digits by default. Set `OFMT = "%.15g"`: 15 digits keep the value, and a computed 0.3 prints `0.3` (17 digits would print `0.29999999999999999`). A whole number prints without decimals (`8000`, where `multiply` writes `8000.0`), and a number concatenated into a text uses `CONVFMT` (`%.6g`): format it with `sprintf` there.
- `keepOnlyMatchingLines` and `excludeMatchingLines` ignore case: `regExp` matches anywhere in the cell (`tolower($2) ~ /gpu/`), a `valueList` compares whole cells (`tolower($1) == "fan"`).
- `replace` replaces every occurrence of a literal text, and `gsub` takes a regular expression: escape its special characters (`gsub(/[|]/, ".", $5)`).
- `print $1, $2, $3` writes three cells, empty ones for a shorter row, and `print` without argument writes the row as it is.

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
| [json2Table](./json2table.html) | Flatten a JSON payload into table rows (prepends an entry column). |
| [json2List](./json2list.html) | List every value of a JSON document as a row: its key path and the value. |
| [xml2Csv](./xml2csv.html) | Flatten an XML payload into table rows. |
| [toTable](./to-table.html) | Turn a text result into a table (one row per line, split on a separator). |
| [toText](./to-text.html) | Turn a table into text, one line per row, for an `awk` script that parses lines. |
| [encode](./encode.html) | Encode a column as `base64` or `url`. |
| [decode](./decode.html) | Decode a `base64` or `url` column. |

### Scripted Transformation

| Compute | Purpose |
| --- | --- |
| [awk](./awk.html) | Run an AWK script over the source result for arbitrary reshaping. |
