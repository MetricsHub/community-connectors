keywords: append, compute, concatenate, suffix, add column, string
description: The append compute concatenates a value to the end of every cell in a column, and can materialize new columns when the value contains semicolons.

# append (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `append` to concatenate a value to the **end** of a column's content, on every row of the table. Typical uses are adding a fixed suffix to build an identifier (e.g. appending `_0` to a PnP address so it matches another source), merging two columns by appending `$n` (the content of column *n*) to another column, or adding empty placeholder columns so the table matches the column layout expected by `mapping` or by a `tableJoin`.

Because a table is serialized as semicolon-separated text, appending a value that contains `;` effectively **creates new columns** to the right of the target column — a deliberate and widely used trick in real connectors.

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
| `column` | Yes | None | **1-based** index of the column to modify. Applied to every row. |
| `value` | Yes | None | String appended to the end of the column content. Accepts a literal, a `$n` reference to another column of the same row (e.g. `$5`), or a `${source::...}` reference whose content is appended. A value containing `;` adds new columns (see below). |

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

**Semicolon trick:** since rows serialize as semicolon-separated text, `- type: append` with `column: 2` and `value: ;;` on the row `fan1;OK` produces:

```text
fan1;OK;;
```

which re-parses as 4 columns — two new empty columns now follow column 2. Real connectors use this to insert empty `Status`/`StatusInformation` placeholders (e.g. `value: ;;` in IpmiTool) or a constant extra column (`value: ;joinValue` in SmartMonLinux).

## Recommended Pattern

- Keep a `# Column1;Column2;...` comment before and after each `append` that adds columns, so the evolving table layout stays readable.
- Use `$n` values to merge columns (e.g. append `$5` to column 1 to build a composite identifier).
- Prefer `append` with `;` padding over more complex sources when `mapping` simply needs extra empty columns.
- Quote values that start or end with spaces or contain YAML-significant characters: `value: ' - '`.

## Common Mistakes

- Forgetting that `column` is 1-based: `column: 1` targets the first column.
- Not realizing a `;` in `value` changes the column count — every later compute and the `mapping` section must use the **new** indexes.
- Writing `value: $5` expecting a literal `$5`: `$n` is interpreted as a column reference.
- Leaving an unquoted value that YAML truncates or mangles (a ` #` inside the value starts a comment; leading/trailing spaces are stripped — quote such values: `value: ' - '`).

## Community Examples

- [WBEMGenLUN](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WBEMGenLUN/WBEMGenLUN.yaml)
- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/IpmiTool/IpmiTool.yaml)
- [GenBatteryNT](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenBatteryNT/GenBatteryNT.yaml)

From IpmiTool (adding empty columns with the semicolon trick):

<!-- MACRO{snippet|id=appendEmptyColumnsCompute|file=src/main/connector/hardware/IpmiTool/IpmiTool.yaml} -->
