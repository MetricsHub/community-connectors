keywords: computes, duplicateColumn
description: Reference for duplicateColumn compute operation.

# duplicateColumn

## When to Use

Use `duplicateColumn` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: duplicateColumn
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `hardware/DiskPart/DiskPart.yaml`
- `hardware/GenBatteryNT/GenBatteryNT.yaml`
