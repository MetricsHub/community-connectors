keywords: tableUnion source, merge tables, table concatenation
description: Reference for tableUnion source used to concatenate multiple source tables.

# tableUnion (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `tableUnion` to append rows from multiple tables into one table.

`tableUnion` does not perform key matching. It is a row concatenation operation.

Its result is the rows of the tables, one after the other. The union holds a copy of the rows: a compute on the union does not change its sources. An `awk` on the union reads its rows structured (`$1..$NF`): write a `toText` before the `awk` to parse them as `;`-separated lines.

Every member must be a table: a source that ends in a table, or a [table literal](#writing-table-literals). To concatenate texts, such as command outputs that one `awk` script parses together, use [textUnion](./text-union.html).

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
| `tables` | Yes | None | Ordered list of the tables to concatenate: source references, or table literals written as lists of rows (see [Writing Table Literals](#writing-table-literals)). |
| `computes` | No | `[]` | Post-union processing pipeline. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

## Writing Table Literals

A member of `tables` can be a table written in the connector, as a YAML list of rows, each row a list of cells. It gives exactly these rows and cells, `;` included (MetricsHub Community 3.9.09 or later):

```yaml
sources:
  powerSupplies:
    type: tableUnion
    tables:
    - [ [ in, ac, AC Input ], [ out, ac, AC Output ] ]
    - ${source::monitors.power.discovery.sources.supplies}
```

- Cells are YAML scalars: quote a number that must keep its text, such as a code or a version. YAML reads `01` as `1` and `1.10` as `1.1`: write `'01'` and `'1.10'`.
- A cell cannot hold a line break. A null cell (`~`), a cell that is a list or a map, an empty row and an empty table are rejected when the connector loads, as is a blank member.
- In a flow list (`[ ... ]`), quote the source references: `{` and `}` are YAML flow indicators, as in `tables: [ [ [ a, b ] ], "${source::supplies}" ]`.

Older connectors write a literal as a string: lines are rows, each split on `;` (`"in;ac;AC Input"`). From MetricsHub Community 3.9.09, this form is rejected when the connector loads (`STRING_LITERAL_ROWS`, see [Strict Content Types](../design-principles.html#strict-content-types)): write a list of rows.

## Texts in a Union

A `tableUnion` is always a table: the rows of its members. A union whose members are not all tables is rejected when the connector loads (see [Strict Content Types](../design-principles.html#strict-content-types)):

- A union whose members are all texts is rejected once (`TABLE_UNION_OF_TEXTS`): replace `type: tableUnion` and `tables` with `type: textUnion` and `texts`.
- A union of texts and tables is rejected once (`MIXED_UNION`), and each text member too (`TEXT_FEEDS_TABLE`). Convert each text member in its own source (`toTable`, `json2Table`, `awk` with `output: table`, ...).

## Recommended Pattern

- Ensure all input tables share compatible column layouts.
- Normalize columns before union (`keepColumns`, `insertColumn`, `replace`).
- Keep ordering explicit in `tables` to ease debugging.

## Common Mistakes

- Unioning incompatible schemas and mapping wrong columns.
- Using union where join semantics are actually required.
- Forgetting to preserve an origin/type column before union.
- Unioning command outputs to parse them with one `awk`: use a [textUnion](./text-union.html).
- Leaving a numeric cell of a table literal unquoted: `01` becomes `1`.

## Community Examples

- [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml)
- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/ipmi/IpmiOverLan/IpmiTool.yaml)
- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
