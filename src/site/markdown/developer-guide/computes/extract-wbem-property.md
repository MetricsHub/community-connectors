keywords: computes, extractPropertyFromWbemPath
description: Reference for extractPropertyFromWbemPath compute operation.

# extractPropertyFromWbemPath

## When to Use

Use `extractPropertyFromWbemPath` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: extractPropertyFromWbemPath
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |
| `property` | No | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `system/WindowsProcess/WindowsProcess.yaml`
