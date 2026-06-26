keywords: detection, ipmi, out-of-band
description: Reference for the IPMI detection criterion.

# Detection of IPMI

## When to Use

Use `ipmi` to verify the responsiveness of the IPMI-over-LAN protocol for the targeted host, in connectors that rely on the IPMI protocol and data source.

Connectors that rely on IPMI will solely address management cards and BMC (Baseboard Management Cards) connected to the network.

> [!WARNING]
> The "IPMI" protocol, detection criterion, and data source supports IPMI-over-LAN only. It doesn't cover connection to the BMC through an OS-specific driver (through `ipmitool` or WMI on Windows).

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: ipmi
      forceSerialization: true
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | - | `ipmi`. |
| `forceSerialization` | No | `false` | Guarantees operations are performed sequentially against one host. **Strongly recommended for IPMI** |

## Runtime Behavior

- Performs "get chassis status" query through IPMI-over-LAN
- For hosts that properly respond to IPMI-over-LAN, we get this result: `System power state is up` and the detection criterion succeeds.
- Otherwise, the detection criterion fails.

## Recommended Pattern

- Use `ipmi` as a protocol capability gate, then do model/vendor discrimination in monitor data paths.
- Keep additional detection criteria lightweight (`deviceType`, optional vendor check).
- Prefer a non-IPMI criterion when you need strict product identification before collection.

## Common Mistakes

- Using `ipmi` alone for vendor-specific connectors where false positives are possible.
- Assuming all OS/device categories can execute IPMI detection.
- Mixing in expensive criteria before confirming IPMI availability.

## Examples

Community example (`hardware/IpmiTool/IpmiTool.yaml`):

```yaml
connector:
  detection:
    criteria:
    - type: ipmi
      forceSerialization: true
```
