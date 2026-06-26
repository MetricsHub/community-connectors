keywords: computes, perBitTranslation
description: Reference for perBitTranslation compute operation.

# perBitTranslation

## When to Use

Use `perBitTranslation` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: perBitTranslation
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |
| `bitList` | No | Observed in existing connectors. |
| `translationTable` | Yes | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `hardware/DellOpenManage/DellOpenManage.yaml`
- `hardware/Director52Linux/Director52Linux.yaml`
