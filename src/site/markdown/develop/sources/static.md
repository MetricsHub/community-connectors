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
| `value` | Yes | None | The row of the table as a list of cells (recommended), or a string: a source reference, or legacy `;` CSV text. See [Writing `value`](#writing-value). |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

## Writing `value`

Write `value` as a YAML list: the source produces one row holding exactly these cells, `;` included, `[ "", "" ]` being two empty cells:

```yaml
value: [ "DDN", "Data Direct Networks", "Disk Array" ]
```

A string `value` holding a source reference (`${source::...}`) copies that source's table.

### Legacy string form

Older connectors write the table as a string: lines are rows, each line is split on `;`, and a trailing `;` may be left out only when the last cell is not empty (`a;;` is 2 cells, `;;;` is 3 empty cells). A cell cannot hold a `;` in this form, and the multi-line string is the only way to produce several rows. Prefer the list form in new connectors.

## Recommended Pattern

- Keep static payloads tiny and explicit.
- Write one cell per list item; never join cells with `;`.
- Prefer translation tables for large static mappings.

## Common Mistakes

- Encoding large datasets in `static` instead of external files/translations.
- Writing a string `value` holding `;` and expecting one cell: the string form is parsed as table text.
- Mixing static defaults with dynamic data without clear join keys.

## Community Examples

- [Cassandra](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/Cassandra/Cassandra.yaml)
