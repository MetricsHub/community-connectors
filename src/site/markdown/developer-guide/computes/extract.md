keywords: extract, compute, split column, subSeparators, subColumn, field
description: The extract compute splits one column's value on separator characters and replaces the column with a single extracted sub-part.

# extract (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `extract` when a single column packs several pieces of information into one string — `Model|Size`, `2.5 GHz`, `Name,Instance` — and you only need one of them. The compute splits the column value into sub-columns using the `subSeparators` characters and replaces the column, in place, with the sub-column selected by `subColumn`. All other columns and all rows are untouched.

For extracting a fixed-position slice of a string, see `substring`; for extracting a `key="value"` property from a WBEM object path, see [`extractPropertyFromWbemPath`](extract-wbem-property.html).

## Syntax

```yaml
sources:
  diskInventory:
    type: commandLine
    commandLine: ${file::list-disks.sh}
    computes:
    # Column 5 contains "Model|Size"; keep only "Model"
    - type: extract
      column: 5
      subColumn: 1
      subSeparators: '|'
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `extract`. |
| `column` | Yes | None | **1-based** index of the column to split. The extracted sub-part replaces this column's value in place. |
| `subColumn` | Yes | None | **1-based** index of the sub-part to keep after splitting. If the separator never occurs in the value, the whole value is sub-column 1. |
| `subSeparators` | Yes | None | One or more separator **characters**. Each character in this string is an individual separator (like `awk -F"[...]"`), not a multi-character delimiter. Consecutive separators delimit empty sub-columns, which still count. Quote values that are special in YAML, e.g. `'|'`, `'"'`, `','`. |

If `column` points past the end of a row, or a value in that column is missing, the compute logs a warning and leaves the whole table unchanged.

## Table Transformation Example

With `column: 5`, `subColumn: 1`, `subSeparators: '|'`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | ID | Vendor | Serial | Status | Model &#124; Size |
>   | --- | --- | --- | --- | --- |
>   | disk0 | Seagate | ZC11ABC | ok | ST4000NM&#124;4000 |
>   | disk1 | WDC | WX21DEF | ok | WD40EFRX&#124;4000 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | ID | Vendor | Serial | Status | Model |
>   | --- | --- | --- | --- | --- |
>   | disk0 | Seagate | ZC11ABC | ok | ST4000NM |
>   | disk1 | WDC | WX21DEF | ok | WD40EFRX |

Serialized, `disk0;Seagate;ZC11ABC;ok;ST4000NM|4000` becomes `disk0;Seagate;ZC11ABC;ok;ST4000NM`.

## Recommended Pattern

- Chain two `extract` computes to unpack a two-in-one column: first `duplicateColumn`, then extract sub-column 1 from the original and sub-column 2 from the copy (see `IpmiTool`, which splits `Model|Size` this way).
- Quote `subSeparators` whenever the character is meaningful in YAML (`'|'`, `'"'`, `':'`, `' '`).
- Extract before numeric computes (`multiply`, `divide`): `2.5 GHz` must become `2.5` before you can do arithmetic on it.

## Common Mistakes

- Treating `subSeparators` as one multi-character delimiter: `subSeparators: ', '` splits on comma **and** on space independently.
- Writing the property name as `subSeparator` (singular) — the correct property is `subSeparators` and a misspelled property is rejected by the schema.
- Forgetting that empty sub-parts count: with `subSeparators: ':'`, the value `a::b` has sub-columns `a`, `` (empty) and `b`, so `subColumn: 3` yields `b`.
- Expecting the split parts to be appended as new columns; `extract` replaces the original column with the single selected sub-part.

## Community Examples

- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/IpmiTool/IpmiTool.yaml)
- [Windows](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Windows/Windows.yaml)
- [WBEMGenDiskNT](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WBEMGenDiskNT/WBEMGenDiskNT.yaml)

From `IpmiTool` (column 5 contains `Model|Size`; keep the model, then the size from a duplicated column):

```yaml
          - type: extract
            column: 5
            subColumn: 1
            subSeparators: '|'
```
