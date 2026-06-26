keywords: detection, snmpGetNext, snmp table probe
description: Reference for the snmpGetNext detection criterion.

# Detection by SNMP GetNext

## When to Use

Use `snmpGetNext` to verify that an SNMP subtree/table exists.
This is the preferred lightweight detection for many SNMP connector families. The SNMP GetNext operation verifies that the proper SNMP sub-agent is responding, and therefore that the expected instrumentation layer is available (typically a vendor agent).

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: snmpGetNext
      oid: 1.3.6.1.2.1.2.2.1
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | - | `snmpGetNext`. |
| `oid` | Yes | - | Base OID subtree expected to return at least one row. |
| `expectedResult` | No | none | Regex matched against extracted value from GETNEXT response. |
| `forceSerialization` | No | `false` | Guarantees operations are performed sequentially against one host. |

## Runtime Behavior

- An SNMP GetNext operation is attempted for the specified SNMP OID.
- Returned OID must stay under requested subtree.
- With no `expectedResult`, response must be non-empty.
- With `expectedResult`, response must match the specified regular expression (case insensitive).

See below example on how the value returned by SNMP GetNext is matched with `expectedResult`:

> [!TABS]
>
> - <span class="fa-regular fa-circle-check"></span> Criterion
>
>   ```yaml
>   - type: snmpGetNext
>     oid: 1.3.6.1.2.1.2.2.1
>     expectedResult: ^eth
>   ```
>
> - <span class="fa-solid fa-sitemap"></span> Result
>
>   ```text
>   eth0
>   ```
>
>   ✅ The criterion passes because the returned OID stays under `1.3.6.1.2.1.2.2.1` **and** the extracted value matches `expectedResult: ^eth`.

## Recommended Pattern

- Use table root OID for quick capability detection.
- Use `expectedResult` only when subtree existence alone is not selective enough.

## Common Mistakes

- Pointing to a too-specific OID that may not exist across firmware variants.

## Examples

In `hardware/MIB2-header/MIB2-header.yaml`:

```yaml
connector:
  detection:
    criteria:
    - type: snmpGetNext
      oid: 1.3.6.1.2.1.2.2.1
```

In `hardware/GenericUPS/GenericUPS.yaml`:

```yaml
connector:
  detection:
    criteria:
    - type: snmpGetNext
      oid: 1.3.6.1.2.1.33
```
