keywords: computes, excludeMatchingLines
description: Reference for excludeMatchingLines compute operation.

# excludeMatchingLines

## When to Use

Use `excludeMatchingLines` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: excludeMatchingLines
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |
| `valueList` | No | Observed in existing connectors. |
| `regExp` | No | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `hardware/DiskPart/DiskPart.yaml`
- `hardware/GenericSwitchEnclosure/GenericSwitchEnclosure.yaml`
