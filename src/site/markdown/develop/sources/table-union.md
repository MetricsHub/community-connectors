keywords: tableUnion source, merge tables, table concatenation
description: Reference for tableUnion source used to concatenate multiple source tables.

# tableUnion (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `tableUnion` to append rows from multiple tables into one table.

`tableUnion` does not perform key matching. It is a row concatenation operation.

When every source in `tables` ends in text, the empty ones aside (a text source without computes: `commandLine`, `http`, `file`, `ipmi`, or `awk` with the default `output: text`; a source whose last compute produces text; a `copy` of one of these; or another such union), the union is a **text union**: its result is the texts of the sources joined with a line feed. A `commandLine` or `awk` source that something else reads as a table (a `mapping`, a `tableJoin`, ...) ends in a table, since MetricsHub then appends a `toTable` to it. An `awk` compute on the union, or on a `copy` of it, reads that text as is, so a script can parse the outputs of several commands in one pass. Do not add `toTable` to the sources of a text union: it would rewrite each line with a trailing `;` before the script sees it.

```yaml
sources:
  version:
    type: commandLine
    commandLine: show version
  environment:
    type: commandLine
    commandLine: show environment
  outputs:
    type: tableUnion
    tables:
    - ${source::version}
    - ${source::environment}
    computes:
    - type: awk
      script: ${file::parse-show.awk}
    - type: toTable
```

Each pair of consecutive line feeds in the joined text becomes a single line feed, so most blank lines disappear: do not rely on blank lines to separate the outputs, match a line of each output instead.

Otherwise the union is a table union: the rows of the tables, one after the other. The text of an `http`, `file` or `ipmi` source contributes no rows, so convert it in that source first (`toTable`, `json2Csv`, ...). A `commandLine` or `awk` source gets a `toTable` from MetricsHub only when something reads it as a table: in a union of such sources where only some are also read as a table elsewhere, the others stay texts and contribute no rows. End each of them with an explicit `toTable` in that case. An `awk` on a table union reads it through `toText`: write it explicitly before the `awk`. The union holds a copy of the rows: a compute on the union does not change its sources.

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
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

## Recommended Pattern

- Ensure all input tables share compatible column layouts.
- Normalize columns before union (`keepColumns`, `insertColumn`, `replace`).
- Keep ordering explicit in `tables` to ease debugging.

## Common Mistakes

- Unioning incompatible schemas and mapping wrong columns.
- Using union where join semantics are actually required.
- Forgetting to preserve an origin/type column before union.

## Community Examples

- [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml)
- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/ipmi/IpmiOverLan/IpmiTool.yaml)
- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
