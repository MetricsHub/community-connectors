keywords: snmpTable source, snmp index table, selectColumns
description: Reference for snmpTable source and table-first design patterns.

# snmpTable (Source)

## When To Use

Use `snmpTable` for indexed SNMP data. It is usually more efficient than issuing many `snmpGet` calls.

## Syntax

```yaml
sources:
  batteryInfo:
    type: snmpTable
    oid: 1.3.6.1.2.1.33.1.2.3
    selectColumns: ID,1,2,3,4
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `snmpTable`. |
| `oid` | Yes | None | Base table OID to walk. |
| `selectColumns` | Yes | None | Columns/indexes to keep (`ID` commonly preserves table index). |
| `executeForEachEntryOf` | No | None | Fan-out execution context. |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Force raw serialization before next stages. |

## Recommended Pattern

- Start with one `snmpTable` and shape downstream with computes.
- Preserve stable join keys (`ID` or explicit index columns).
- Use `tableJoin` to enrich with complementary tables.

## Common Mistakes

- Dropping index columns too early.
- Joining on translated labels instead of stable IDs.
- Overusing scalar `snmpGet` where one table walk is enough.

## Community Examples

- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
- [GenericSwitchEnclosure](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericSwitchEnclosure/GenericSwitchEnclosure.yaml)
- [MIB2-header](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/MIB2-header/MIB2-header.yaml)
