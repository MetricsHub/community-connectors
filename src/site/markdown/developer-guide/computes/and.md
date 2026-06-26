keywords: computes, and
description: Reference for and compute operation.

# and

## When to Use

Use `and` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: and
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

- `hardware/MIB2NT/MIB2NT.yaml`
