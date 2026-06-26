keywords: tableUnion source, merge tables, table concatenation
description: Reference for tableUnion source used to concatenate multiple source tables.

# tableUnion (Source)

## When To Use

Use `tableUnion` to append rows from multiple tables into one table.

`tableUnion` does not perform key matching. It is a row concatenation operation.

## Syntax

```yaml
sources:
  allSensors:
    type: tableUnion
    tables:
    - ${source::monitors.hw.collect.sources.fanSensors}
    - ${source::monitors.hw.collect.sources.psuSensors}
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `tableUnion`. |
| `tables` | Yes | None | Ordered list of source tables to concatenate. |
| `computes` | No | `[]` | Post-union processing pipeline. |
| `forceSerialization` | No | `false` | Force raw serialization before next stages. |

## Recommended Pattern

- Ensure all input tables share compatible column layouts.
- Normalize columns before union (`keepColumns`, `append`, `prepend`, `replace`).
- Keep ordering explicit in `tables` to ease debugging.

## Common Mistakes

- Unioning incompatible schemas and mapping wrong columns.
- Using union where join semantics are actually required.
- Forgetting to preserve an origin/type column before union.

## Community Examples

- [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml)
- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/IpmiTool/IpmiTool.yaml)
- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
