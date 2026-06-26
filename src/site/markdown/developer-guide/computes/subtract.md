keywords: computes, subtract
description: Reference for subtract compute operation.

# subtract

## When to Use

Use `subtract` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: subtract
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

- `hardware/Redfish/Redfish.yaml`
- `system/Windows/Windows.yaml`
