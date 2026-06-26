keywords: computes, add
description: Reference for add compute operation.

# add

## When to Use

Use `add` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: add
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

- `hardware/LibreHardwareMonitor/LibreHardwareMonitor.yaml`
- `hardware/MIB2-header/MIB2-header.yaml`
