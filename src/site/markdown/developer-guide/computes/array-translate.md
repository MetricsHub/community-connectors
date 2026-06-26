keywords: computes, arrayTranslate
description: Reference for arrayTranslate compute operation.

# arrayTranslate

## When to Use

Use `arrayTranslate` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: arrayTranslate
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |
| `translationTable` | Yes | Observed in existing connectors. |
| `resultSeparator` | No | Observed in existing connectors. |
| `arraySeparator` | No | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `hardware/WinStorageSpaces/WinStorageSpaces.yaml`
- `hardware/BrocadeSwitchWBEM/BrocadeSwitchWBEM.yaml`
