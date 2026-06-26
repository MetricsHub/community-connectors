keywords: computes, awk
description: Reference for awk compute operation.

# awk

## When to Use

Use `awk` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: awk
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `script` | No | Observed in existing connectors. |
| `separators` | No | Observed in existing connectors. |
| `keep` | No | Observed in existing connectors. |
| `selectColumns` | No | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `database/Cassandra/Cassandra.yaml`
- `hardware/AMDRadeon/AMDRadeon.yaml`
