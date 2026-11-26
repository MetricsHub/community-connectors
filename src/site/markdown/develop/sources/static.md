keywords: static source, constant table, inline rows
description: Reference for static source type used to inject constant or inline tabular values.

# static (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `static` to inject fixed values into a source pipeline.

This is useful for:

- default rows,
- synthetic constants,
- small inline lookup tables.

## Syntax

```yaml
sources:
  fixedState:
    type: static
    value: [ "serviceA", "ok" ]
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `static`. |
| `value` | Yes | None | The table as a YAML list: a list of cells (one row), a list of rows, or an empty list. See [Writing `value`](#writing-value). |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |
| `continueOnFailure` | No | `false` | `true` to go on with the empty result of the source when it fails, instead of stopping the job or the tool (see [continueOnFailure](./index.html#continueonfailure)). |

## Writing `value`

Write `value` as a YAML list. A list of cells is one row holding exactly these cells, `;` included, `[ "", "" ]` being two empty cells:

```yaml
value: [ "DDN", "Data Direct Networks", "Disk Array" ]
```

A list of lists is one row per list:

```yaml
value:
- [ in, ac, AC Input ]
- [ out, ac, AC Output ]
```

- A list holds either cells or rows, not both, and a row has one cell at least. An empty list (`value: []`) is an empty table.
- A cell is a YAML scalar other than null (`~`), and may hold a line break.
- A cell may hold a reference, such as `${attribute::id}`, or `${source::...}` of a source that ends in text: the cell holds that text, line breaks included. A source that ends in a table cannot be referenced in a cell (`TABLE_INTERPOLATED`): read a table with a [copy](./copy.html).
- A string `value` (`value: "a;b"`, or `value: ${source::...}`) does not load: write a list.

## Recommended Pattern

- Keep static payloads tiny and explicit.
- Write one cell per list item; never join cells with `;`.
- Prefer translation tables for large static mappings.

## Common Mistakes

- Encoding large datasets in `static` instead of external files/translations.
- Writing a cell list and a row in the same `value` (`[ a, [ b, c ] ]`): the connector does not load. Write either cells or rows.
- Mixing static defaults with dynamic data without clear join keys.

## Community Examples

- [Cassandra](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/Cassandra/Cassandra.yaml)
