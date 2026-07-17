keywords: extractPropertyFromWbemPath, compute, WBEM, WMI, object path, CIM reference
description: The extractPropertyFromWbemPath compute replaces a column containing a WBEM object path with the value of one key property of that path.

# extractPropertyFromWbemPath (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `extractPropertyFromWbemPath` when a WBEM or WMI query returns a **reference** column — an object path such as `\\HOST\root\cimv2:Win32_Account.Domain="CONTOSO",Name="jsmith"` — and you need one of its key properties as a plain value. The compute parses the path's `key="value"` pairs in the selected column and replaces the whole path, in place, with the value of the requested `property` (quotes removed).

This is typical after querying WMI association classes (`Win32_LoggedOnUser`, `Win32_SessionProcess`, ...) whose `Antecedent`/`Dependent` columns are object paths, often right after a `tableJoin` with `keyType: Wbem`.

## Syntax

```yaml
sources:
  loggedOnUsers:
    type: wmi
    namespace: root\cimv2
    query: SELECT Antecedent, Dependent FROM Win32_LoggedOnUser
    computes:
    # Antecedent (column 1) is \\HOST\root\cimv2:Win32_Account.Domain="...",Name="..."
    - type: duplicateColumn
      column: 1
    - type: extractPropertyFromWbemPath
      column: 1
      property: Domain
    - type: extractPropertyFromWbemPath
      column: 2
      property: Name
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `extractPropertyFromWbemPath`. |
| `column` | Yes | None | **1-based** index of the column containing the WBEM object path. The extracted value replaces the path in place. |
| `property` | Yes | None | Name of the key property to extract, e.g. `Name` or `Domain`. Matching is case-insensitive and also matches qualified keys such as `Win32_Account.Domain`. Surrounding double quotes are stripped and the value is trimmed. |

If the property is not found in the path, the column value is left as is.

## Table Transformation Example

With `column: 2` and `property: Name`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | PID | User Reference |
>   | --- | --- |
>   | 4212 | \\\\SRV01\root\cimv2:Win32_Account.Domain="CONTOSO",Name="jsmith" |
>   | 5120 | \\\\SRV01\root\cimv2:Win32_Account.Domain="NT AUTHORITY",Name="SYSTEM" |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | PID | User |
>   | --- | --- |
>   | 4212 | jsmith |
>   | 5120 | SYSTEM |

## Recommended Pattern

- To extract **two** properties from the same path (e.g. `Domain` and `Name`), `duplicateColumn` first, then run one `extractPropertyFromWbemPath` per copy, as `WindowsProcess` does.
- Combine with `tableJoin` and `keyType: Wbem` when joining association-class results on object-path keys, and extract the human-readable properties only after the join.
- Follow up with `keepOnlyMatchingLines` or `keepColumns` once the plain values are available.

## Common Mistakes

- Running the compute twice on the same column expecting to get two properties; each run replaces the path with a single value — duplicate the column first.
- Using it on a column that holds a plain value rather than a `key="value"` object path; without a matching `property=` pair, the value is left unchanged.
- Counting columns from 0: `column` is 1-based.
- Property values that themselves contain commas are not supported: the path is split on commas before the `key="value"` pairs are parsed.

## Community Examples

- [WindowsProcess](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/WindowsProcess/WindowsProcess.yaml)

From `WindowsProcess` (the only community connector using this compute):

```yaml
          - type: duplicateColumn
            column: 21
          - type: extractPropertyFromWbemPath
            column: 21
            property: Domain
          - type: extractPropertyFromWbemPath
            column: 22
            property: Name
```
