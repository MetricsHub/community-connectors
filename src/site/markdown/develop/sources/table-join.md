keywords: tableJoin source, join tables, joinType, inner join, left join, rightColumns, defaultRightLine, keyType
description: Full reference for the tableJoin source: join types, key matching, the right side of an unmatched row, WBEM keys.

# tableJoin (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `tableJoin` to add to the rows of one table the columns of the matching rows of another table, matched on a key column.

`leftKeyColumn` and `rightKeyColumn` are **1-based column indexes**.

Both inputs must be tables. A text, such as a command output, needs a `toTable` (or an `awk` with `output: table`) in its source before the join: a text input is rejected (`TEXT_FEEDS_TABLE`, see [Strict Content Types](../design-principles.html#strict-content-types)).

## Syntax

```yaml
sources:
  joinedDisks:
    # DiskId;Model;DiskId;Health
    type: tableJoin
    joinType: left
    leftTable: ${source::diskInventory}
    rightTable: ${source::diskHealth}
    leftKeyColumn: 1
    rightKeyColumn: 1
    rightColumns: 2
```

Every disk of the inventory (`DiskId;Model`) keeps its row; a disk without health information (`DiskId;Health`) gets two empty cells instead.

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `tableJoin`. |
| `joinType` | Yes in this library | `inner` | `inner`: keep only the left rows that match a right row. `left`: keep every left row. See [Choosing the Join Type](#choosing-the-join-type). |
| `leftTable` | Yes | None | Left table: a source reference, or a table literal written as a list of rows. See [Writing a Table Literal](#writing-a-table-literal). |
| `rightTable` | Yes | None | Right table: a source reference, or a table literal written as a list of rows. |
| `leftKeyColumn` | Yes | None | Join key column in the left table (1-based). |
| `rightKeyColumn` | Yes | None | Join key column in the right table (1-based). |
| `rightColumns` | No | None | `joinType: left` only. The number of empty cells on the right side of an unmatched left row: the number of columns of the right table. An integer, 1 or more. |
| `defaultRightLine` | No | None | `joinType: left` only. The right side of an unmatched left row when it holds values, such as `[ "", "unknown" ]`: a list of cells. See [Writing `defaultRightLine`](#writing-defaultrightline). |
| `keyType` | No | None | `Wbem` when the keys are WBEM object paths. See [WBEM Keys](#wbem-keys). |
| `computes` | No | `[]` | Post-join compute pipeline. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |
| `continueOnFailure` | No | `false` | `true` to go on with the empty result of the source when it fails, instead of stopping the job or the tool (see [continueOnFailure](./index.html#continueonfailure)). |

The engine joins with `inner` when `joinType` is not written, but every `tableJoin` of this library writes it, `inner` included, so that a reader never has to know the default: the build fails on a `tableJoin` without `joinType` (`ConnectorLibraryIT`).

## How the Join Works

1. The rows of either table whose key cell is missing (a row shorter than the key column) or empty are left out. A left row without key is dropped, whatever the join type.
2. Keys match whatever their case: `Disk0` matches `DISK0`. Nothing else is normalized: spaces, leading zeros and the form of a number count (`7` does not match `07`).
3. When several right rows have the same key, only the **first** one is joined. Several left rows with the same key are all kept, each joined with that same right row.
4. The joined row is the cells of the left row followed by **all** the cells of the right row, key included: joining `A;B` with `A;C` gives `A;B;A;C`. Remove the columns the mapping does not need with [keepColumns](../computes/keep-columns.html).
5. The rows keep the order of the left table.
6. A left row that matches no right row is dropped (`joinType: inner`) or kept with the [right side of an unmatched row](#the-right-side-of-an-unmatched-row) (`joinType: left`).

## Choosing the Join Type

Left table (`DiskId;Model`):

| DiskId | Model |
| --- | --- |
| d1 | NVMe A |
| d2 | NVMe B |

Right table (`DiskId;Health`):

| DiskId | Health |
| --- | --- |
| d1 | ok |
| d3 | failed |

`joinType: inner` keeps the rows found in both tables:

| DiskId | Model | DiskId | Health |
| --- | --- | --- | --- |
| d1 | NVMe A | d1 | ok |

`joinType: left` keeps every left row (here with `rightColumns: 2`):

| DiskId | Model | DiskId | Health |
| --- | --- | --- | --- |
| d1 | NVMe A | d1 | ok |
| d2 | NVMe B |  |  |

`d3`, which is not in the left table, is in neither result: the left table decides which rows exist.

- Use `left` when the left table is the inventory, the rows that create the instances, joined with statistics or optional details. An entity missing from the right table keeps its row, and its instance is not removed (see [Build Instances from an Inventory](../design-principles.html#9-build-instances-from-an-inventory)).
- Use `inner` when the right table is a filter or a mandatory part, and only the rows found in both tables make sense: the disks of a given controller, the processes of a given service.

There is no `right` join and no `full` join: see [Why There Is No `right` or `full` Join](../design-principles.html#why-there-is-no-right-or-full-join).

## The Right Side of an Unmatched Row

With `joinType: left`, a left row without match gets, after its own cells:

| Written | Right side of an unmatched row |
| --- | --- |
| `rightColumns: N` | N empty cells. |
| `defaultRightLine: [ ... ]` | These cells. |
| neither | As many empty cells as the widest row of the right table, and **no cell at all** when the right table is empty. |

Write `rightColumns` (or `defaultRightLine`) on every left join, with the number of columns of the right table: an unmatched row then has the width of a matched row even when the right table is empty, and the columns that follow, read by the mapping or by the computes, stay in place.

- `rightColumns` and `defaultRightLine` are for left joins: on an inner join (`joinType: inner` or no `joinType`), the connector does not load. A connector written before `joinType` existed, where a `defaultRightLine` alone meant a left join, fails to load instead of silently running an inner join: add `joinType: left`.
- Write one of them, not both: the connector does not load.
- `rightColumns` is a number, 1 or more: 0, a negative number, a decimal, a text that is not a number, a list or a map does not load. `rightColumns:` with no value is the same as not writing it.
- A `defaultRightLine` made only of empty cells loads, with a warning in the log that recommends `rightColumns`: `rightColumns: 4` says what `[ "", "", "", "" ]` makes the reader count.

## Writing `defaultRightLine`

Use `defaultRightLine` when a missing right row stands for known values, such as `ok`, `0` or `none` ("absent means none"). Write a YAML list, one item per column of the right table, each item being exactly one cell, `;` included:

| `defaultRightLine` | Cells |
| --- | --- |
| `[ "", "unknown" ]` | 2: empty, `unknown` |
| `[ "a", "b" ]` | 2: `a`, `b` |
| `[ "a;b" ]` | 1: `a;b` |

The list needs one cell at least, and a cell is a scalar other than null (`~`). A string (`defaultRightLine: ";unknown"`) does not load: write a list.

A value of `defaultRightLine` is published for every unmatched row, including every row when the right source failed: read [continueOnFailure](./index.html#continueonfailure) before you set it on the right source.

## WBEM Keys

With `keyType: Wbem`, the keys are WBEM (or WMI) object paths, such as the `Antecedent` and `Dependent` columns of an association class. Two paths match when they have the same class and the same key properties, in any order, and whatever their case:

- `CIM_Disk.CreationClassName="CIM_Disk",DeviceID="0"` matches `cim_disk.DeviceID="0",CreationClassName="CIM_Disk"`;
- a property ends at a comma that follows a double quote: a value is not parsed further;
- a key without `.` after its first character is compared as a plain string.

Without `keyType`, the same two paths do not match. Extract readable properties from a path after the join, with [extractWbemProperty](../computes/extract-wbem-property.html).

## Writing a Table Literal

`leftTable` or `rightTable` can be a table written in the connector, as a YAML list of rows, each row a list of cells. It gives exactly these rows and cells, `;` included:

```yaml
sources:
  tableIds:
    type: tableJoin
    joinType: inner
    leftTable: ${source::tables}
    rightTable: [ [ MSHW_TableID ] ]
    leftKeyColumn: 1
    rightKeyColumn: 1
```

This inner join keeps only the rows of `tables` whose first cell is `MSHW_TableID`.

A list that is not a list of rows is rejected when the connector loads, and so is a string that is not a source reference (`rightTable: MSHW_TableID;`, `STRING_LITERAL_ROWS`). Cells and quoting follow the rules of [Writing Table Literals](./table-union.html#writing-table-literals).

## Recommended Pattern

- Keep the inventory (the rows that create the instances) as the left table, and the statistics or optional details as the right table, with `joinType: left` and `rightColumns`: an entity missing from the right table keeps its row with empty cells.
- Write the columns of the result in a comment above the source (`# DiskId;Model;DiskId;Health`): the column numbers of the mapping and of the computes that follow depend on them.
- Join on stable technical keys, not display labels.
- Normalize the key formats before the join (`replace`, `prepend`, `extract`) when they differ between the tables.
- Use `keyType: Wbem` to join on WBEM/WMI object paths.

## Common Mistakes

- A `tableJoin` without `joinType`: the build of this library fails. Write `joinType: inner` or `joinType: left`.
- A `defaultRightLine` or `rightColumns` without `joinType: left`: the connector does not load.
- An inner join of the inventory with statistics: an entity missing from the right table loses its row. When the join feeds the mapping of a `discovery` or `simple` job, its instance is removed (see [When Instances Are Removed](../monitors-and-jobs.html#when-instances-are-removed)).
- A `rightColumns` other than the number of columns of the right table: an unmatched row does not have the width of a matched one, and the columns after the join are shifted for these rows. Count the columns again when a compute or a query of the right source changes.
- Wrong key column indexes after an upstream compute adds or removes a column.
- Joining on transformed strings that are not unique: only the first right row of each key is joined.
- Chaining joins on a column that an unmatched row leaves empty: a left row with an empty key is dropped by the next join, whatever its join type. Give that cell a value with `defaultRightLine`, such as `[ "", "none" ]`, as `WindowsProcess` does.

## Community Examples

- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
- [WindowsProcess](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/WindowsProcess/WindowsProcess.yaml)
- [WinStorageSpaces](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WinStorageSpaces/WinStorageSpaces.yaml)

> [!NOTE]
> Use `keyType: Wbem`. The engine does not read `isWbemKey: true`, found in older connectors: such a join compares the keys as plain strings.
