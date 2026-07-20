keywords: snmpGet source, scalar oid, snmp scalar
description: Reference for snmpGet source used for scalar SNMP values.

# snmpGet (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `snmpGet` for scalar OIDs (single-value fetches), especially for host-level metadata or simple gauges.

If you need many columns from indexed objects, prefer [`snmpTable`](./snmp-table.html).

## Syntax

```yaml
sources:
  upsModel:
    type: snmpGet
    oid: 1.3.6.1.2.1.33.1.1.2.0
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `snmpGet`. |
| `oid` | Yes | None | Scalar OID to query. |
| `executeForEachEntryOf` | No | None | Fan-out execution context. |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

## Recommended Pattern

- Use for true scalar values only.
- Group related scalar fetches logically and map directly.
- Keep OID comments next to source definitions for maintainability.

## Common Mistakes

- Calling many scalar OIDs where one table OID would be cleaner.
- Mixing scalar and indexed semantics in the same mapping logic.
- Skipping translations for enumerated scalar values.

## Community Examples

- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
