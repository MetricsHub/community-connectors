keywords: computes, keepColumns
description: Reference for keepColumns compute operation.

# keepColumns

## When to Use

Use `keepColumns` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: keepColumns
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `columnNumbers` | Yes | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `database/Cassandra/Cassandra.yaml`
- `hardware/IpmiTool/IpmiTool.yaml`
