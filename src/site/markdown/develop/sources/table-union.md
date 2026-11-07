keywords: tableUnion source, merge tables, table concatenation
description: Reference for tableUnion source used to concatenate multiple source tables.

# tableUnion (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `tableUnion` to append rows from multiple tables into one table.

`tableUnion` does not perform key matching. It is a row concatenation operation.

When every source in `tables` ends in text (a `commandLine` or `awk` source without computes, a source whose last compute produces text, a `copy` of one of these, or another such union), the union is a **text union**: its result is the texts of the sources joined with a line feed. An `awk` compute on the union, or on a `copy` of it, reads that text as is, so a script can parse the outputs of several commands in one pass. Do not add `toTable` to the sources of a text union: it would rewrite each line with a trailing `;` before the script sees it.

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

When the sources mix text and tables, the union is a table union: give the text sources an explicit `toTable`, and an `awk` on the union an explicit `toText` before it.

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
- Normalize columns before union (`keepColumns`, `append`, `prepend`, `replace`).
- Keep ordering explicit in `tables` to ease debugging.

## Common Mistakes

- Unioning incompatible schemas and mapping wrong columns.
- Using union where join semantics are actually required.
- Forgetting to preserve an origin/type column before union.

## Community Examples

- [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml)
- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/ipmi/IpmiOverLan/IpmiTool.yaml)
- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
