keywords: awk source, jawk, scripting source, variables, arrays
description: Reference for the awk source type (JAWK), scalar and source-table variables, and when to prefer compute-level AWK.

# awk (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use source-level `awk` when your source itself is a script computation, consuming an explicit `input` string or source reference, or reading source tables through `variables`.

For most connectors, it is cleaner to:

1. collect with `commandLine`, `http`, `wmi`, or `snmp*`,
2. then transform with compute-level `awk`.

## Syntax

```yaml
sources:
  normalizeInventory:
    type: awk
    input: ${source::beforeAll.inventoryRaw}
    script: |
      BEGIN { FS=";"; OFS=";" }
      NF >= 3 { print $1, $2, tolower($3) }
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `awk`. |
| `script` | Yes | None | Inline AWK script or `${file::...}` reference. |
| `input` | No | Empty | Input text or source reference consumed by the script. |
| `variables` | No | `{}` | Map of AWK variable names to values. Source references become arrays of rows; other values become scalars. See [Variables](#variables). |
| `separators` | No | None | Compatibility property; usually unnecessary for source-level AWK. |
| `keep` | No | None | Schema-compatibility filter property; prefer compute-level filtering. |
| `exclude` | No | None | Schema-compatibility filter property; prefer compute-level filtering. |
| `selectColumns` | No | None | Schema-compatibility selection property; prefer compute-level selection. |
| `executeForEachEntryOf` | No | None | Run once per row from another source table. |
| `computes` | No | `[]` | Optional post-processing computes. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

> [!TIP]
> If you need `keep`, `exclude`, `separators`, or `selectColumns` behavior, prefer compute-level `awk` in the source `computes` pipeline.

## Variables

Both AWK sources and [AWK computes](../computes/awk.html#variables) accept a `variables` map. Variables are available by name in the script, including in `BEGIN` blocks, for inline scripts and embedded `.awk` files alike.

| Value | Available in AWK as |
| --- | --- |
| Literal text or a quoted number, such as `"365.25"` | A scalar, usable in string expressions or arithmetic. |
| A resource attribute, monitor attribute, or protocol property reference | A scalar resolved immediately before execution, e.g. `${resource.attribute::host.name}`, `${attribute::id}`, or `${protocol::http.port}`. |
| A source reference, such as `${source::monitors.disk.discovery.sources.raw}` | An array of rows: `aTable[row][column]`, with **zero-based** row and column indexes. `length(aTable)` returns the row count. |

### Read A Source Table

Assuming `monitors.disk.discovery.sources.raw` has already run and contains at least three columns:

```yaml
sources:
  merged:
    type: awk
    variables:
      hostname: ${resource.attribute::host.name}
      someConstant: "365.25"
      aTable: ${source::monitors.disk.discovery.sources.raw}
    script: |
      BEGIN {
        for (row = 0; row < length(aTable); row++) {
          print aTable[row][0] ";" aTable[row][2] ";" hostname ";" (someConstant * 2)
        }
      }
```

For a row `disk0;SSD;100` and hostname `server01`, the output is `disk0;100;server01;730.5`. No `input` is needed here: the `BEGIN` block reads the table variable directly. By contrast, `input: ${source::...}` supplies serialized text to the script's normal record processing.

If a referenced source has no table but has raw data, MetricsHub parses that data as semicolon-separated rows. An empty or unavailable source becomes an empty array (`length(aTable) == 0`); an unavailable source also logs an error. A variable declared without a value is exposed as an empty scalar.

## Recommended Pattern

- Emit semicolon-separated rows from the script.
- Keep source-level AWK focused on one transformation concern.
- Move complex business logic to dedicated `.awk` files with `${file::...}`.

## Common Mistakes

- Mixing source acquisition and heavy parsing into one unreadable AWK script.
- Returning irregular row widths that break mapping.
- Using source-level `awk` where a simple `commandLine` + compute `awk` would be clearer.
- Treating a source-table variable as CSV text or using one-based indexes: the first cell is `aTable[0][0]`, unlike AWK record fields `$1`, `$2`, etc.

## Community Examples

No current community connector uses source-level `awk` directly.

Relevant AWK-heavy connectors (compute-level AWK patterns):

- [Linux](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Linux/Linux.yaml)
- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml)
- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
