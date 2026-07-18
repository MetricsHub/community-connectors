keywords: internalDbQuery source, in-memory sql, dedup, aggregation
description: Reference for internalDbQuery source used for SQL-like joins and aggregations over source tables.

# internalDbQuery (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `internalDbQuery` when table pipelines become too complex for plain compute chains.

Best use cases:

- Deduping rows.
- Grouping/aggregation across multiple source tables.
- SQL joins on pre-collected source datasets.

## Syntax

```yaml
sources:
  mergedInventory:
    type: internalDbQuery
    tables:
    - source: ${source::monitors.disk.discovery.sources.diskRaw}
      alias: D
      columns:
      - name: id
        number: 1
        type: VARCHAR(128)
      - name: size_bytes
        number: 4
        type: BIGINT
    - source: ${source::monitors.disk.collect.sources.healthRaw}
      alias: H
      columns:
      - name: id
        number: 1
        type: VARCHAR(128)
      - name: status
        number: 2
        type: VARCHAR(32)
    query: SELECT D.id, D.size_bytes, H.status FROM D LEFT JOIN H ON D.id = H.id
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `internalDbQuery`. |
| `tables` | Yes | None | SQL table definitions backed by source tables. |
| `query` | Yes | None | SQL query executed on internal in-memory tables. |
| `parameters` | No | `[]` | Optional query parameters (schema-level support). |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Force raw serialization before next stages. |

## Recommended Pattern

- Keep `tables` schemas explicit and typed.
- Do SQL-heavy shaping once, then map directly.
- Name table aliases clearly (`Inventory`, `Metrics`, `Status`) instead of opaque letters when queries get long.

## Common Mistakes

- Treating this as a replacement for simple computes.
- Defining ambiguous column names across tables.
- Building huge intermediate tables when a pre-filter can reduce size first.

## Examples

No current community connector uses `internalDbQuery`.

> [!NOTE]
> Use this source when connector logic truly needs SQL semantics. For simple merges, `tableJoin` and `tableUnion` are easier to read and maintain.
