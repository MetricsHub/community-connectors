keywords: computes, encode
description: Reference for encode compute operation.

# encode

## When to Use

Use `encode` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: encode
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| _none_ |  |  |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- No usage found in current community/enterprise connector sets.

> [!NOTE]
> Documented for compatibility completeness; no usage found in current connector sets.
