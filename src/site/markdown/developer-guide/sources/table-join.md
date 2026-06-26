keywords: tableJoin source, join tables, defaultRightLine, keyType
description: Full reference for tableJoin source with key columns, WBEM key handling, and fallback rows.

# tableJoin (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `tableJoin` to enrich one source table with columns from another using key columns.

`leftKeyColumn` and `rightKeyColumn` are **1-based column indexes**.

## Syntax

```yaml
sources:
  joinedDisks:
    type: tableJoin
    leftTable: ${source::monitors.disk.discovery.sources.diskInventory}
    rightTable: ${source::monitors.disk.collect.sources.diskHealth}
    leftKeyColumn: 1
    rightKeyColumn: 1
    defaultRightLine: ;unknown;
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `tableJoin`. |
| `leftTable` | Yes | None | Left source table reference. |
| `rightTable` | Yes | None | Right source table reference. |
| `leftKeyColumn` | Yes | None | Join key column in left table (1-based). |
| `rightKeyColumn` | Yes | None | Join key column in right table (1-based). |
| `defaultRightLine` | No | None | Fallback right-side row when no match is found. |
| `keyType` | No | None | Key comparison mode. Use `Wbem` for WBEM/WMI path keys. |
| `isWbemKey` | No | None | Legacy compatibility flag in older connectors. Prefer `keyType: Wbem`. |
| `computes` | No | `[]` | Post-join compute pipeline. |
| `forceSerialization` | No | `false` | Force raw serialization before next stages. |

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

Joined result with `defaultRightLine: ;unknown`:

| id | model | id | health |
| --- | --- | --- | --- |
| d1 | NVMe A | d1 | ok |
| d2 | NVMe B |  | unknown |

Equivalent serialized output:

```text
d1;NVMe A;d1;ok
d2;NVMe B;;unknown
```

## Recommended Pattern

- Join on stable technical keys, not display labels.
- Add `defaultRightLine` whenever missing right rows are acceptable.
- Normalize key formats before join (`replace`, `prepend`, `extract`) when needed.
- Use `keyType: Wbem` for WBEM/WMI `__PATH`-style joins.

## Common Mistakes

- Using wrong key column indexes after upstream compute changes.
- Omitting `defaultRightLine` and silently losing unmatched rows.
- Joining on transformed strings that are not unique.

## Community Examples

- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
- [WindowsProcess](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/WindowsProcess/WindowsProcess.yaml)
- [WinStorageSpaces](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WinStorageSpaces/WinStorageSpaces.yaml)

> [!NOTE]
> Prefer `keyType: Wbem`. Legacy connectors may still show `isWbemKey`, which should be considered compatibility syntax and avoided in new connectors.
