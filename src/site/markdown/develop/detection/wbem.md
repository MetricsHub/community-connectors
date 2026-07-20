keywords: detection, wbem, wql, cim, namespace
description: Reference for WBEM detection criterion, including namespace strategy and table serialization behavior.

# Detection by WBEM

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When to Use

Use `wbem` for any connector that relies on DMTF's WBEM instrumentation standard, i.e. connectors that connect to a CIM server (or sometimes a CIM Agent), typically running on port HTTP 5988/5989.

> [!WARNING]
> Don't confuse `WBEM` with `WMI`, which is Microsoft's implementation of the CIM model in Windows.

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: wbem
      namespace: root/brocade1
      query: SELECT Name FROM Brocade_Switch
      expectedResult: .+
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | - | `wbem`. |
| `query` | Yes | - | WQL query. Must be non-blank. |
| `namespace` | No | `root/cimv2` | WBEM namespace. Can also be `automatic` for namespace discovery. |
| `expectedResult` | No | none | Regex matched against serialized query result. |
| `errorMessage` | No | none | Connector-authored failure context (for logs/reporting). |
| `forceSerialization` | No | `false` | Guarantees operations are performed sequentially against one host. |

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
>   - type: wbem
>     query: SELECT Name, Description FROM CIM_NameSpace
>     expectedResult: ^ibmsd;
>   ```
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Name | Description |
>   | --- | --- |
>   | ibmsd | IBM Director CIMserver |
>   | cimv2 | CIMOMv2 |
>   | default | Default provider |
>
> - <span class="fa-regular fa-file-lines"></span> Result As Text
>
>   ```text
>   ibmsd;IBM Director CIMserver;
>   cimv2;CIMOMv2;
>   default;Default provider;
>   ```
>
>   ✅ The criterion passes because the **first line** of the text result matches `expectedResult: ^ibmsd;`.

## Recommended Pattern

- Prefer explicit namespace when known and stable.
- Use `automatic` namespace only for heterogeneous environments where namespace varies and when the WQL query is specific enough to identify the namespace that hosts the necessary classes for the connector to work.
- Keep detection query minimal and deterministic (single class/property).
- Follow with additional criteria when one class existence is too broad.

## Common Mistakes

- Running deep inventory queries in detection.
- Using broad expected regexes that match unrelated class values.
- Relying on `automatic` when a fixed namespace is already known.

## Example

```yaml
connector:
  detection:
    criteria:
    - type: wbem
      namespace: root/brocade1
      query: SELECT Name FROM Brocade_Switch
```
