keywords: computes, keepOnlyMatchingLines
description: Reference for keepOnlyMatchingLines compute operation.

# keepOnlyMatchingLines

## When to Use

Use `keepOnlyMatchingLines` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: keepOnlyMatchingLines
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |
| `regExp` | No | Observed in existing connectors. |
| `valueList` | No | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `hardware/IpmiTool/IpmiTool.yaml`
- `hardware/LibreHardwareMonitor/LibreHardwareMonitor.yaml`

> [!NOTE]
> Legacy case/alias variants exist in historical connectors; use canonical naming in new connectors.
