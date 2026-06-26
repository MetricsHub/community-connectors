keywords: computes, convert
description: Reference for convert compute operation.

# convert

## When to Use

Use `convert` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: convert
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |
| `conversion` | No | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `hardware/IpmiTool/IpmiTool.yaml`
- `hardware/LinuxIpmiTool/LinuxIpmiTool.yaml`
