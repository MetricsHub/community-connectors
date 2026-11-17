keywords: tableJoin source, join tables, defaultRightLine, keyType
description: Full reference for tableJoin source with key columns, WBEM key handling, and fallback rows.

# tableJoin (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `tableJoin` to enrich one source table with columns from another using key columns.

`leftKeyColumn` and `rightKeyColumn` are **1-based column indexes**.

Both inputs must be tables. A text, such as a command output, needs a `toTable` (or an `awk` with `output: table`) in its source before the join: a text input is rejected (`TEXT_FEEDS_TABLE`, see [Strict Content Types](../design-principles.html#strict-content-types)).

## Syntax

```yaml
sources:
  joinedDisks:
    type: tableJoin
    leftTable: ${source::monitors.disk.discovery.sources.diskInventory}
    rightTable: ${source::monitors.disk.collect.sources.diskHealth}
    leftKeyColumn: 1
    rightKeyColumn: 1
    defaultRightLine: [ "", "unknown" ]
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `tableJoin`. |
| `leftTable` | Yes | None | Left table: a source reference, or a table literal written as a list of rows. See [Writing a Table Literal](#writing-a-table-literal). |
| `rightTable` | Yes | None | Right table: a source reference, or a table literal written as a list of rows. |
| `leftKeyColumn` | Yes | None | Join key column in left table (1-based). |
| `rightKeyColumn` | Yes | None | Join key column in right table (1-based). |
| `defaultRightLine` | No | None | Fallback right-side row when no match is found: a list of cells (recommended), or a legacy string split on `;`. Without it, unmatched left rows are dropped (inner join). See [Writing `defaultRightLine`](#writing-defaultrightline). |
| `keyType` | No | None | Key comparison mode. Use `Wbem` for WBEM/WMI path keys. |
| `isWbemKey` | No | None | Legacy compatibility flag in older connectors. Prefer `keyType: Wbem`. |
| `computes` | No | `[]` | Post-join compute pipeline. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

## Table Shape Example

Left table:

| id | model |
| --- | --- |
| d1 | NVMe A |
| d2 | NVMe B |

Right table:

| id | health |
| --- | --- |
| d1 | ok |

Joined result with `defaultRightLine: [ "", "unknown" ]`:

| id | model | id | health |
| --- | --- | --- | --- |
| d1 | NVMe A | d1 | ok |
| d2 | NVMe B |  | unknown |

Equivalent serialized output:

```text
d1;NVMe A;d1;ok
d2;NVMe B;;unknown
```

## Writing `defaultRightLine`

Write `defaultRightLine` as a YAML list: one item per column of the right table, each item being exactly one cell, `;` included. An all-empty line for a 4-column right table is four empty cells:

```yaml
defaultRightLine: [ "", "", "", "" ]
```

| `defaultRightLine` | Cells |
| --- | --- |
| `[ "", "unknown" ]` | 2: empty, `unknown` |
| `[ "a", "b" ]` | 2: `a`, `b` |
| `[ "a", "" ]` | 2: `a`, empty |
| `[ "a;b" ]` | 1: `a;b` |

### Legacy string form

Older connectors write `defaultRightLine` as a string. It is split on `;`, and each field ends with a `;`. The final `;` may be left out only when the last field is not empty:

| `defaultRightLine` | Fields |
| --- | --- |
| `;unknown` or `;unknown;` | 2: empty, `unknown` |
| `a;b` | 2: `a`, `b` |
| `a;;` | 2: `a`, empty |
| `;;;;` | 4 empty fields |
| `;;;` | 3 empty fields |

An all-empty line therefore needs **one semicolon per column** of the right table: `;;;;` for a 4-column right table. With one semicolon less, the unmatched rows are one column short of the matched ones. A cell cannot hold a `;` in this form. Prefer the list form in new connectors.

## Writing a Table Literal

`leftTable` or `rightTable` can be a table written in the connector, as a YAML list of rows, each row a list of cells. It gives exactly these rows and cells, `;` included (MetricsHub Community 3.9.09 or later):

```yaml
sources:
  tableIds:
    type: tableJoin
    leftTable: ${source::monitors.enclosure.discovery.sources.tables}
    rightTable: [ [ MSHW_TableID ] ]
    leftKeyColumn: 1
    rightKeyColumn: 1
```

A list that is not a list of rows is rejected when the connector loads, and so is the older `;` string form (`rightTable: MSHW_TableID;`, `STRING_LITERAL_ROWS`). Cells and quoting follow the rules of [Writing Table Literals](./table-union.html#writing-table-literals).

## Recommended Pattern

- Join on stable technical keys, not display labels.
- Keep the inventory (the rows that create the instances) as the left table, and the statistics or optional details as the right table, with a `defaultRightLine`: an entity missing from the right table keeps its row with empty cells.
- Normalize key formats before join (`replace`, `prepend`, `extract`) when needed.
- Use `keyType: Wbem` for WBEM/WMI `__PATH`-style joins.

## Common Mistakes

- Using wrong key column indexes after upstream compute changes.
- Omitting `defaultRightLine` and silently losing unmatched rows. When the join feeds the mapping of a `discovery` or `simple` job, the instances of these rows are removed (MetricsHub Community 3.9.08 or later, see [When Instances Are Removed](../monitors-and-jobs.html#when-instances-are-removed)).
- Writing one semicolon per column minus one for an all-empty `defaultRightLine` in the legacy string form (`;;;` for a 4-column right table). The list form has no such trap: `[ "", "", "", "" ]`.
- Joining on transformed strings that are not unique.

## Community Examples

- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
- [WindowsProcess](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/WindowsProcess/WindowsProcess.yaml)
- [WinStorageSpaces](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WinStorageSpaces/WinStorageSpaces.yaml)

> [!NOTE]
> Prefer `keyType: Wbem`. Legacy connectors may still show `isWbemKey`, which should be considered compatibility syntax and avoided in new connectors.
