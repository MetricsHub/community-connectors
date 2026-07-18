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
    value: serviceA;ok
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `static`. |
| `value` | Yes | None | Inline serialized table content or reference. |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Force raw serialization before next stages. |

## Recommended Pattern

- Keep static payloads tiny and explicit.
- Use semicolon-separated rows when emitting multi-column values.
- Prefer translation tables for large static mappings.

## Common Mistakes

- Encoding large datasets in `static` instead of external files/translations.
- Forgetting that `value` is parsed as table text (semicolon/newline semantics apply).
- Mixing static defaults with dynamic data without clear join keys.

## Community Examples

- [Cassandra](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/Cassandra/Cassandra.yaml)
