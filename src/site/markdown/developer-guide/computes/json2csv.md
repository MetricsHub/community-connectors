keywords: computes, json2Csv
description: Reference for json2Csv compute operation.

# json2Csv

## When to Use

Use `json2Csv` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: json2Csv
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `properties` | Yes | Observed in existing connectors. |
| `entryKey` | Yes | Observed in existing connectors. |
| `separator` | No | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `hardware/Redfish/Redfish.yaml`
- `hardware/BrocadeSANnavREST/BrocadeSANnavREST.yaml`

> [!NOTE]
> Legacy case/alias variants exist in historical connectors; use canonical naming in new connectors.
