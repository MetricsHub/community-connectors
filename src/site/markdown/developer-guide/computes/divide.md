keywords: computes, divide
description: Reference for divide compute operation.

# divide

## When to Use

Use `divide` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: divide
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |
| `value` | Yes | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `database/Cassandra/Cassandra.yaml`
- `hardware/AMDRadeon/AMDRadeon.yaml`
