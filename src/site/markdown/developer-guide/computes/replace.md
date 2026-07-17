keywords: replace, compute, substitute, string, cleanup, normalize
description: The replace compute substitutes every occurrence of a string with another value in one column of the table.

# replace (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `replace` to substitute every occurrence of a specific string in a column with another value, on every row of the table. Typical uses are cleanup — stripping quotes from CSV-style output (`existingValue: '"'`, `newValue: ""`), removing spaces, collapsing doubled backslashes in WMI paths — and neutralizing sentinel values (e.g. replacing `4294967295` with `0`, or an invalid reading with an empty string so `mapping` ignores it).

Both `existingValue` and `newValue` accept `$n` column references, which enables conditional-style column fills: replace the whole content of a column (`existingValue: $7`) with the content of another column (`newValue: $19`).

## Syntax

```yaml
sources:
  virtualMachines:
    type: commandLine
    commandLine: powershell -command "Get-VM | ForEach-Object { ... }"
    computes:
      # Remove the double quotes around the VM name
    - type: replace
      column: 1
      existingValue: '"'
      newValue: ""
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `replace`. |
| `column` | Yes | None | **1-based** index of the column to modify. Applied to every row. |
| `existingValue` | Yes | None | Literal string to search for in the column content (not a regular expression). Every occurrence is replaced. Accepts a `$n` reference to match the current content of column *n*. |
| `newValue` | Yes | None | Replacement string. Accepts a literal (including `""` to delete the matched text) or a `$n` reference to another column of the same row. |

## Table Transformation Example

With `column: 1`, `existingValue: '"'`, and `newValue: ""`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | Name | Status |
>   | --- | --- |
>   | "VM-WEB-01" | Operating normally |
>   | "VM-DB-02" | Operating normally |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Name | Status |
>   | --- | --- |
>   | VM-WEB-01 | Operating normally |
>   | VM-DB-02 | Operating normally |

## Recommended Pattern

- Chain several `replace` computes for multi-step cleanup; they run in order, so a first pass can replace a placeholder (`MSHWMSHW` → `$2`) and a second pass can remove what remains (`MSHW` → `""`).
- Use `existingValue: $n` with the same `column: n` to overwrite the entire column with `newValue` — a common way to copy another column (`newValue: $19`) into place.
- Replace sentinel values (`4294967295`, `71582788`) with `0` or `""` before `mapping` interprets them as real measurements.
- Quote YAML-sensitive values: `existingValue: '"'`, `newValue: ""`.

## Common Mistakes

- Expecting regex semantics: `existingValue` is a plain string. Use `awk` or `extract` for pattern-based transformations.
- Forgetting that **all** occurrences in the cell are replaced, not just the first one or exact whole-cell matches.
- Forgetting that `column` is 1-based.
- Writing `newValue: $2` expecting a literal `$2`: `$n` is interpreted as a column reference.

## Community Examples

- [HyperV](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/HyperV/HyperV.yaml)
- [MIB2](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/MIB2/MIB2.yaml)
- [GenBatteryNT](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenBatteryNT/GenBatteryNT.yaml)

From MIB2 (filling a blank placeholder column from another column):

```yaml
    # Replace "MSHWMSHW", i.e. a blank column with the ifTable value.
    # PortID;Description;PortType;MacAddress;AdminStatus;ID;Name;Alias;
  - type: replace
    column: 7
    existingValue: MSHWMSHW
    newValue: $2
```
