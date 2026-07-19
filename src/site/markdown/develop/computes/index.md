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
> Because serialization uses semicolons as column separators, some transforms that append semicolon-delimited content may increase the number of materialized columns after reparsing.

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
| [append](./append.html) | Concatenate a value to the end of a column (can materialize new columns with `;`). |
| [prepend](./prepend.html) | Concatenate a value to the start of a column (can materialize new columns with `;`). |
| [replace](./replace.html) | Replace a literal value in a column. |
| [substring](./substring.html) | Keep a portion of a column's value (1-based start, length). |
| [duplicateColumn](./duplicate-column.html) | Insert a copy of a column immediately after the original. |

### Row Filtering and Column Projection

| Compute | Purpose |
| --- | --- |
| [keepOnlyMatchingLines](./keep-only-matching-lines.html) | Keep rows whose column matches a regex or value list. |
| [excludeMatchingLines](./exclude-matching-lines.html) | Remove rows whose column matches a regex or value list. |
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
| [json2Csv](./json2csv.html) | Flatten a JSON payload into table rows (prepends an entry column). |
| [xml2Csv](./xml2csv.html) | Flatten an XML payload into table rows. |
| [encode](./encode.html) | Encode a column as `base64` or `url`. |
| [decode](./decode.html) | Decode a `base64` or `url` column. |

### Scripted Transformation

| Compute | Purpose |
| --- | --- |
| [awk](./awk.html) | Run an AWK script over the source result for arbitrary reshaping. |
