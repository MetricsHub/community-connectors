keywords: detection, snmpGet, snmp scalar
description: Reference for the snmpGet detection criterion.

# Detection by SNMP Get

## When to Use

Use `snmpGet` if the monitored target responds in SNMP to the specified precise OID, typically an OID in a private MIB (`1.3.6.1.4.*`).

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: snmpGet
      oid: 1.3.6.1.4.1.318.1.1.1.1.1.1.0
      expectedResult: UPS
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | - | `snmpGet`. |
| `oid` | Yes | - | Scalar OID to read. Must be non-blank. |
| `expectedResult` | No | none | Regex matched against returned value. |
| `forceSerialization` | No | `false` | Guarantees operations are performed sequentially against one host. |

## Runtime Behavior

- Performs an SNMP Get on the specified OID.
- No `expectedResult`: success when SNMP value is non-null and non-blank.
- With `expectedResult`: case-insensitive, regex match.
- Returned value is treated as plain text for matching.

See below example on how the returned SNMP value is matched with `expectedResult`:

> [!TABS]
>
> - <span class="fa-regular fa-circle-check"></span> Criterion
>
>   ```yaml
>   - type: snmpGet
>     oid: 1.3.6.1.2.1.1.1.0
>     expectedResult: Linux
>   ```
>
> - <span class="fa-solid fa-sitemap"></span> Result
>
>   ```text
>   Linux my-server 6.8.0-52-generic #53-Ubuntu SMP
>   ```
>
>   ✅ The criterion passes because the returned value matches `expectedResult: Linux`.

## Recommended Pattern

- Pick a stable vendor/product OID with low latency.
- Use `snmpGetNext` for table-existence probing, `snmpGet` for scalar identity.
- Keep this criterion early in SNMP connector detection.

## Common Mistakes

- Querying table OIDs with `snmpGet`.
- Matching volatile values (uptime, counters) for product identity.
- Using weak regex such as `.` for strict product filtering.
