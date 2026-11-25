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
| `output` | No | `text` | What the source produces: `text` (the value) or `table` (one row of one cell holding the value). See [Result](#result). |
| `executeForEachEntryOf` | No | None | Fan-out execution context. |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |
| `continueOnFailure` | No | `false` | `true` to go on with the empty result of the source when it fails, instead of stopping the job or the tool (see [continueOnFailure](./index.html#continueonfailure)). |

## Result

By default, `snmpGet` returns the value of the OID as a **text**, its line breaks as LF, which a `${source::...}` reference (in a mapping value, the `value` of a compute, a `static` cell) and an `awk` read (see [Serialization Details](./index.html#serialization-details-you-must-know)). When the request fails (no answer, an error, no SNMP configuration for the host), the text is empty.

With `output: table`, it returns a **table** of one row and one cell that holds the value whole: a `;` or a line break in the value stays in the cell, and an empty value gives one row with an empty cell. When the request fails, the table has no row, so a mapping that reads it creates no instance and collects nothing.

Declare `output: table` when the result is read as a table: by the `mapping` source, a `tableJoin`, a `tableUnion` or a table compute (`translate`, `insertColumn`, `multiply`, ...). A text there is rejected when the connector loads (`TEXT_FEEDS_TABLE`, see [Strict Content Types](../design-principles.html#strict-content-types)). Unlike a [toTable](../computes/to-table.html), `output: table` never splits the value.

```yaml
sources:
  batteryStatus:
    type: snmpGet
    oid: 1.3.6.1.2.1.33.1.2.1.0
    output: table
    computes:
    - type: translate
      column: 1
      translationTable: ${translation::BatteryStatusTranslationTable}
```

## Recommended Pattern

- Use for true scalar values only.
- Group related scalar fetches logically and map directly.
- Keep OID comments next to source definitions for maintainability.
- Keep the default text for a value that is only interpolated (`${source::upsModel}` in a mapping value or in the `value` of an `append`) or computed by an `awk`.

## Common Mistakes

- Calling many scalar OIDs where one table OID would be cleaner.
- Mixing scalar and indexed semantics in the same mapping logic.
- Skipping translations for enumerated scalar values.
- Reading the default text as a table (the `mapping` source, a join, a union, a table compute): the connector does not load (`TEXT_FEEDS_TABLE`). Declare `output: table`.

## Community Examples

- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
