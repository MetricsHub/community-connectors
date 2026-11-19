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

## Result

`snmpGet` returns the value of the OID as a **text**, whole: a `;` or a line break in the value stays in it. When the request fails (no answer, an error, no SNMP configuration for the host), the result is an empty text. An OID that answers an empty string gives the same empty text, so it counts as no answer.

A text is read as it is by a `${source::...}` reference (in a mapping value, a compute value, a static cell) and by an `awk`. The `mapping` source, a `tableJoin`, a `tableUnion` and the table computes (`translate`, `insertColumn`, `multiply`, ...) read a table: a text there is rejected when the connector loads (`TEXT_FEEDS_TABLE`, see [Strict Content Types](../design-principles.html#strict-content-types)).

## Read the Value as a Table

When the value is a code or a number (a status, a temperature, a counter), write [toTable](../computes/to-table.html) as the first compute: the value becomes one row of one cell, and an empty text gives no row, so a mapping that reads it creates no instance and collects nothing when the OID does not answer.

```yaml
sources:
  batteryStatus:
    type: snmpGet
    oid: 1.3.6.1.2.1.33.1.2.1.0
    computes:
    - type: toTable
    - type: duplicateColumn
      column: 1
    - type: translate
      column: 1
      translationTable: ${translation::BatteryStatusTranslationTable}
```

`toTable` splits a line on `;` and makes a row of each line. When the value is a free text that may hold a `;` or a line break (a model, a serial number, a description), keep it in one cell instead: a [static](./static.html) source whose cell references the text, followed by an [excludeMatchingLines](../computes/exclude-matching-lines.html) on `^$` so that no answer gives no row.

```yaml
sources:
  upsModelValue:
    type: snmpGet
    oid: 1.3.6.1.2.1.33.1.1.2.0
  upsModel:
    type: static
    value: [ "${source::upsModelValue}" ]
    computes:
    - type: excludeMatchingLines # no answer, no row
      column: 1
      regExp: ^$
```

## Recommended Pattern

- Use for true scalar values only.
- Group related scalar fetches logically and map directly.
- Keep OID comments next to source definitions for maintainability.
- Read a value that the mapping only shows (a model, a firmware version) as a text, `${source::upsModel}` in a mapping value, when the mapping has a source of its own.

## Common Mistakes

- Calling many scalar OIDs where one table OID would be cleaner.
- Mixing scalar and indexed semantics in the same mapping logic.
- Skipping translations for enumerated scalar values.
- Using the `snmpGet` as the `mapping` source, or as the input of a join, a union or a table compute, without `toTable`: the connector does not load (`TEXT_FEEDS_TABLE`).
- Writing `toTable` on a free text: a `;` in the value splits it into several cells, and a line break into several rows.

## Community Examples

- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
