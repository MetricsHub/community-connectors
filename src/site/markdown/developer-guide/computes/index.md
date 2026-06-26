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

- [add](./add.html)
- [and](./and.html)
- [append](./append.html)
- [arrayTranslate](./array-translate.html)
- [awk](./awk.html)
- [convert](./convert.html)
- [decode](./decode.html)
- [divide](./divide.html)
- [duplicateColumn](./duplicate-column.html)
- [encode](./encode.html)
- [excludeMatchingLines](./exclude-matching-lines.html)
- [extract](./extract.html)
- [extractPropertyFromWbemPath](./extract-wbem-property.html)
- [json2Csv](./json2csv.html)
- [keepColumns](./keep-columns.html)
- [keepOnlyMatchingLines](./keep-only-matching-lines.html)
- [multiply](./multiply.html)
- [perBitTranslation](./translate-per-bit.html)
- [prepend](./prepend.html)
- [replace](./replace.html)
- [substring](./substring.html)
- [subtract](./subtract.html)
- [translate](./translate.html)
- [xml2Csv](./xml2csv.html)
