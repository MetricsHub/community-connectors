keywords: computes, translate
description: Reference for translate compute operation.

# translate

## When to Use

Use `translate` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: translate
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `column` | Yes | Observed in existing connectors. |
| `translationTable` | Yes | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `database/MariaDB/MariaDB.yaml`
- `hardware/DiskPart/DiskPart.yaml`
