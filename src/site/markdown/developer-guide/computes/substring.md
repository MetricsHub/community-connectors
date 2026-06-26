keywords: computes, substring
description: Reference for substring compute operation.

# substring

## When to Use

Use `substring` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: substring
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |
| `start` | No | Observed in existing connectors. |
| `length` | No | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `hardware/Director5Linux/Director5Linux.yaml`
- `hardware/IBMAIXDisk/IBMAIXDisk.yaml`
