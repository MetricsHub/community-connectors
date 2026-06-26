keywords: computes, append
description: Reference for append compute operation.

# append

## When to Use

Use `append` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: append
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

- `hardware/GenBatteryNT/GenBatteryNT.yaml`
- `hardware/GenericUPS/GenericUPS.yaml`
