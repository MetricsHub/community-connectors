keywords: computes, replace
description: Reference for replace compute operation.

# replace

## When to Use

Use `replace` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: replace
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |
| `existingValue` | No | Observed in existing connectors. |
| `newValue` | No | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `hardware/GenBatteryNT/GenBatteryNT.yaml`
- `hardware/HyperV/HyperV.yaml`
