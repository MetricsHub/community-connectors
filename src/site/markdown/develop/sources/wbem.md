keywords: wbem source, cim query, namespace
description: Reference for WBEM source with query and namespace guidance.

# wbem (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `wbem` when the target exposes CIM/WBEM endpoints and you need structured CIM query results.

For Windows-native environments, `wmi` is usually the first choice.

## Syntax

```yaml
sources:
  diskInventory:
    type: wbem
    namespace: root/cimv2
    query: SELECT DeviceID, Model, Size FROM CIM_DiskDrive
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `wbem`. |
| `query` | Yes | None | WBEM/CIM query. |
| `namespace` | No | Provider default | WBEM namespace. |
| `executeForEachEntryOf` | No | None | Fan-out execution context. |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

## Recommended Pattern

- Select only required columns.
- Always set `namespace` explicitly for clarity.
- Keep key fields (`__PATH`, IDs) until join operations are complete.

## Common Mistakes

- Using broad `SELECT *` queries.
- Dropping path/identity columns before joins.
- Mixing WBEM and WMI key formats without explicit normalization.

## Examples

No current community connector uses source type `wbem`.

> [!NOTE]
> `wbem` remains part of the official source model and is useful for non-Windows CIM providers.
