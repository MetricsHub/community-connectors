keywords: computes, xml2Csv
description: Reference for xml2Csv compute operation.

# xml2Csv

## When to Use

Use `xml2Csv` to normalize source output before mapping.

## Syntax

```yaml
computes:
- type: xml2Csv
```

## Properties

| Property | Required | Description |
| --- | --- | --- |
| `recordTag` | Yes | Observed in existing connectors. |
| `properties` | Yes | Observed in existing connectors. |

## Recommended Pattern

- Apply filtering and projection computes early.
- Use translation tables for status normalization when possible.

## Common Mistakes

- Chaining transforms that could be simplified.
- Applying arithmetic transforms to non-numeric columns.

## Examples

- `hardware/HPPrinter/HPPrinter.yaml`
- `hardware/CiscoUCSRest/CiscoUCSRest.yaml`

> [!NOTE]
> Legacy case/alias variants exist in historical connectors; use canonical naming in new connectors.
