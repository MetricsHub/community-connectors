keywords: computes, extract
description: Reference for extract compute operation.

# extract

## When to Use

Use `extract` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: extract
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |
| `subColumn` | No | Observed in existing connectors. |
| `subSeparators` | No | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `hardware/IpmiTool/IpmiTool.yaml`
- `hardware/LibreHardwareMonitor/LibreHardwareMonitor.yaml`
