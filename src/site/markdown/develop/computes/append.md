keywords: append, compute, concatenate, suffix, add column, string
description: The append compute concatenates a value to the end of every cell in a column.

# append (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `append` to concatenate a value to the **end** of a column's content, on every row of the table. Typical uses are adding a fixed suffix to build an identifier (e.g. appending `_0` to a PnP address so it matches another source), or merging two columns by appending `$n` (the content of column *n*) to another column.

The value is added to the cell as it is: a `;` or a line feed in it is an ordinary character of the cell, and adds no column and no row. To add a column (an empty placeholder, a constant), use [insertColumn](./insert-column.html).

## Syntax

```yaml
sources:
  diskDrives:
    type: wmi
    namespace: root\CIMv2
    query: SELECT Name, PNPDeviceID FROM Win32_DiskDrive
    computes:
      # Add a _0 suffix to the PnP address so that it matches the MPIO ID
      # PhysicalDiskName;PnPAddress_0;
    - type: append
      column: 2
      value: _0
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `append`. |
| `column` | On a table | None | **1-based** index of the column to modify. Applied to every row. Omit it to append to a text, see [On A Text](#on-a-text). |
| `value` | Yes | None | String appended to the end of the column content. Accepts a literal, a `$n` reference to another column of the same row (e.g. `$5`), or a `${source::...}` reference to a text, whose content is appended (a table there is reported, `TABLE_INTERPOLATED`, see [Strict Content Types](../design-principles.html#strict-content-types)). A `;` or a line feed in the value stays in the cell. |

## Table Transformation Example

With `column: 2` and `value: _0`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | PhysicalDiskName | PnPAddress |
>   | --- | --- |
>   | Disk0 | SCSI\DISK&VEN_MSFT&PROD_VIRTUAL_DISK\1&2AFD7D61&3&000001 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | PhysicalDiskName | PnPAddress |
>   | --- | --- |
>   | Disk0 | SCSI\DISK&VEN_MSFT&PROD_VIRTUAL_DISK\1&2AFD7D61&3&000001_0 |

## On A Text

Without `column`, `append` works on a **text** (the result of an `http`, a `commandLine`, an `awk` without `output: table`, ...): the value is added once, at the end of the whole text, and the result is still a text.

```yaml
sources:
  firmwareLabel:
    # The body is the bare version: 2.4.1
    type: http
    method: get
    path: /api/version
    computes:
    # 2.4.1 -> 2.4.1 (REST)
    - type: append
      value: " (REST)"
```

- The value goes after the last character of the text, whatever it is: after the final line feed of a command output, and after the `;` that an `awk` compute writes at the end of each line of its text. To add a value at the end of each line, use an `awk`.
- `$n` is not a column reference here: a text has no column.
- `column` and the content must agree: an `append` without `column` after a table, or with `column` after a text, is reported when the connector loads (see [Strict Content Types](../design-principles.html#strict-content-types)).

## Recommended Pattern

- Keep a `# Column1;Column2;...` comment before the `append`, so the table layout stays readable.
- Use `$n` values to merge columns (e.g. append `$5` to column 1 to build a composite identifier).
- Use [insertColumn](./insert-column.html) to add a column (an empty placeholder, a constant).
- Quote values that start or end with spaces or contain YAML-significant characters: `value: ' - '`.

## Common Mistakes

- Forgetting that `column` is 1-based: `column: 1` targets the first column.
- Expecting a `;` in `value` to add columns: `value: ;;` on the cell `OK` gives the single cell `OK;;`. Use [insertColumn](./insert-column.html).
- Appending a `${source::...}` reference to a table of several cells to bring its columns in: the cell receives the serialized row (`OK` becomes `OKa;b;`), and the reference is reported (`TABLE_INTERPOLATED`). Combine sources with a [tableJoin](../sources/table-join.html).
- Writing `value: $5` expecting a literal `$5`: `$n` is interpreted as a column reference.
- Leaving an unquoted value that YAML truncates or mangles (a ` #` inside the value starts a comment; leading/trailing spaces are stripped — quote such values: `value: ' - '`).

## Community Examples

- [WBEMGenLUN](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WBEMGenLUN/WBEMGenLUN.yaml)
- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
- [GenBatteryNT](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenBatteryNT/GenBatteryNT.yaml)
