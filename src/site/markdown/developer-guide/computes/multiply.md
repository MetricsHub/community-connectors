keywords: computes, multiply
description: Reference for multiply compute operation.

# multiply

## When to Use

Use `multiply` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: multiply
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

- `hardware/GenericUPS/GenericUPS.yaml`
- `hardware/LibreHardwareMonitor/LibreHardwareMonitor.yaml`
