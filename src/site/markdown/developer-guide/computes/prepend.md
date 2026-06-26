keywords: computes, prepend
description: Reference for prepend compute operation.

# prepend

## When to Use

Use `prepend` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: prepend
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

- `hardware/DiskPart/DiskPart.yaml`
- `hardware/GenericUPS/GenericUPS.yaml`
