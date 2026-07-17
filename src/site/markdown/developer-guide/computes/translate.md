keywords: translate, compute, translation table, status mapping, normalization
description: Replaces each value in a column with its translation from a translation table, typically to normalize vendor status codes into ok/degraded/failed.

# translate (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `translate` to map raw values in one column to normalized values through a lookup table. The typical case is converting vendor-specific status codes (SNMP enumerations, WMI integers, CLI keywords) into the state names your monitor's metrics expect, such as `ok`, `degraded`, and `failed`.

Matching is **case-insensitive**: translation table keys are lower-cased when the connector is loaded, and the cell value is lower-cased before lookup. If a value is not found, the special `default` entry is used; if there is no `default` entry either, the cell is left unchanged (with a warning in the logs).

## Syntax

```yaml
sources:
  diskStatus:
    # DeviceID;Model;StatusCode
    type: snmpTable
    oid: 1.3.6.1.4.1.4413.1.5.2.1
    selectColumns: ID,2,5
    computes:
    - type: translate
      column: 3
      translationTable: ${translation::physicalDiskStatuses}

# Translation tables are declared in the top-level `translations:` section
translations:
  physicalDiskStatuses:
    "3": ok
    "4": degraded
    "5": failed
    "6": failed
    "7": ok
    default: UNKNOWN
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `translate`. |
| `column` | Yes | None | **1-based** index of the column whose values are translated in place. |
| `translationTable` | Yes | None | Reference to a table declared under the top-level `translations:` section, written `${translation::TableName}`. A bare table name is legacy syntax. The table's `default` key (case-insensitive, `Default` also works) is the fallback for unmatched values. |

## Table Transformation Example

With the `physicalDiskStatuses` table above applied to column 3:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | DeviceID | Model | StatusCode |
>   | --- | --- | --- |
>   | disk-0 | ST4000NM | 3 |
>   | disk-1 | ST4000NM | 5 |
>   | disk-2 | ST4000NM | 99 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | DeviceID | Model | Status |
>   | --- | --- | --- |
>   | disk-0 | ST4000NM | ok |
>   | disk-1 | ST4000NM | failed |
>   | disk-2 | ST4000NM | UNKNOWN |

`99` is not a key of the table, so it falls back to the `default` translation (`UNKNOWN`).

## Recommended Pattern

- Translate status codes into exactly the state names declared in your metric's `stateSet` (e.g. `ok`, `degraded`, `failed`), so the mapping section can use the column directly.
- Always provide a `default` entry: devices routinely report codes that were not in the vendor documentation.
- Quote numeric keys (`"3": ok`) so YAML treats them as strings consistently.
- Declare the table once under `translations:` and reference it from every source that needs it.

## Common Mistakes

- Using a column index that no longer matches the table layout after an upstream `keepColumns`, `awk`, or `extract` compute.
- Referencing the table by bare name instead of `${translation::TableName}`.
- Omitting `default`, which lets untranslated raw codes flow into mapping and break `stateSet` metrics.
- Translating a whole-cell array value: for cells that contain several values (e.g. `2|11`), use [`arrayTranslate`](array-translate.html) instead.

## Community Examples

- [LinuxService](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/LinuxService/LinuxService.yaml)
- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
- [MariaDB](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/MariaDB/MariaDB.yaml)

From `LinuxService`:

```yaml
          - type: translate
            column: 2
            translationTable: ${translation::serviceLoadedTranslationTable}
```
