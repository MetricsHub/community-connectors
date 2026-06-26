keywords: detection, wmi, wql, windows, namespace
description: Reference for WMI detection criterion, including namespace handling and serialized-table matching.

# Detection by WMI

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When to Use

Use `wmi` for any connector that relies on WMI (Windows Management Instrumentation) or WINMGMT for retrieve Windows-specific information.

The `wmi` detection criteria will work when the `wmi` or the `winrm` protocols are configured by the user for a given resource.

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: wmi
      namespace: root/cimv2
      query: SELECT Name FROM Win32_LogicalDisk
      expectedResult: .+
```

## Properties

| Property             | Required | Default      | Description                                                        |
| -------------------- | -------- | ------------ | ------------------------------------------------------------------ |
| `type`               | Yes      | -            | `wmi`.                                                            |
| `query`              | Yes      | -            | WQL query. Must be non-blank.                                      |
| `namespace`          | No       | `root/cimv2` | CIM namespace. Can also be `automatic` for namespace discovery.   |
| `expectedResult`     | No       | none         | Regex matched against serialized query result.                     |
| `errorMessage`       | No       | none         | Connector-authored failure context (for logs/reporting).           |
| `forceSerialization` | No       | `false`      | Guarantees operations are performed sequentially against one host. |

## Runtime Behavior

- With `namespace: automatic`, runtime probes candidate namespaces, selects one matching the criterion, then caches it per connector/host.
- Result tables are serialized with semicolons/newlines before regex matching.
- No `expectedResult`: success if serialized result is non-empty.
- With `expectedResult`: case-insensitive, multiline regex.

See below example on how a result table of a WBEM query is converted to text before matching with `expectedResult`:

> [!TABS]
>
> - <span class="fa-regular fa-circle-check"></span> Criterion
>
>   ```yaml
>   - type: wmi
>     query: SELECT Name, DriveType, FreeSpace FROM Win32_LogicalDisk
>     expectedResult: ^[C-Z]:;3;[1-9]
>   ```
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Name | DriveType | FreeSpace |
>   | --- | --- | --- |
>   | C: | 3 | 1406479736832 |
>   | D: | 3 | 703239868416 |
>
> - <span class="fa-regular fa-file-lines"></span> Result As Text
>
>   ```text
>   C:;3;1406479736832;
>   D:;3;703239868416;
>   ```
>
>   ✅ The criterion passes because the both lines of the text result matches with `expectedResult: ^[C-Z]:;3;[1-9]`. **One single matching line is enough for the criterion to pass.**

## Recommended Pattern

- Prefer explicit namespace when known and stable.
- Use `automatic` namespace only for heterogeneous environments where namespace varies and when the WQL query is specific enough to identify the namespace that hosts the necessary classes for the connector to work.
- Keep detection query minimal and deterministic (single class/property).
- Follow with additional criteria when one class existence is too broad.

## Common Mistakes

- Running deep inventory queries in detection.
- Using broad expected regexes that match unrelated class values.
- Relying on `automatic` when a fixed namespace is already known.

## Examples

Community example (`system/WindowsService/WindowsService.yaml`):

```yaml
connector:
  detection:
    criteria:
    - type: wmi
      namespace: root\\CIMv2
      query: SELECT * FROM Win32_OperatingSystem
```
