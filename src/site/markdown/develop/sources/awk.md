keywords: awk source, jawk, scripting source
description: Reference for the awk source type (JAWK) and when to prefer compute-level AWK.

# awk (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use source-level `awk` when your source itself is a script computation, usually consuming an explicit `input` string or source reference.

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
| `separators` | No | None | Compatibility property; usually unnecessary for source-level AWK. |
| `keep` | No | None | Schema-compatibility filter property; prefer compute-level filtering. |
| `exclude` | No | None | Schema-compatibility filter property; prefer compute-level filtering. |
| `selectColumns` | No | None | Schema-compatibility selection property; prefer compute-level selection. |
| `executeForEachEntryOf` | No | None | Run once per row from another source table. |
| `computes` | No | `[]` | Optional post-processing computes. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

> [!TIP]
> If you need `keep`, `exclude`, `separators`, or `selectColumns` behavior, prefer compute-level `awk` in the source `computes` pipeline.

## Recommended Pattern

- Emit semicolon-separated rows from the script.
- Keep source-level AWK focused on one transformation concern.
- Move complex business logic to dedicated `.awk` files with `${file::...}`.

## Common Mistakes

- Mixing source acquisition and heavy parsing into one unreadable AWK script.
- Returning irregular row widths that break mapping.
- Using source-level `awk` where a simple `commandLine` + compute `awk` would be clearer.

## Community Examples

No current community connector uses source-level `awk` directly.

Relevant AWK-heavy connectors (compute-level AWK patterns):

- [Linux](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Linux/Linux.yaml)
- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml)
- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
