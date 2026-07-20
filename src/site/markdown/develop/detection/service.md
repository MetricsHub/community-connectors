keywords: detection, service, windows service
description: Reference for the Windows service detection criterion.

# Detection by Windows Service (Deprecated)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

> [!WARNING]
> The `service` detection criterion is deprecated. Use WMI or SSH instead as applicable.

## When to Use

Use `service` only when local service presence is the intended detection signal for detecting a specific instrumentation software (like a vendor-specific server agent) **running on the same system as MetricsHub**. This detection criterion is only supported when MetricsHub is running on Windows.

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: service
      name: WINMGMT
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | - | `service`. |
| `name` | Yes | - | Windows service name (not display name). Must be non-blank. |
| `forceSerialization` | No | `false` | Guarantees operations are performed sequentially against one host. |

## Runtime Behavior

- Service detection is implemented through a generated WMI query on `Win32_Service`.
- Criterion succeeds only if service state contains `running`.
- Requires Windows host type for this check path.

## Common Mistakes

- Using display names instead of service names.
- Relying on service detection where local runtime cannot execute Windows service checks.
- Expecting `service` to replace deeper product checks.

## Examples

Community example — the `service` criterion of `hardware/GenBatteryNT/GenBatteryNT.yaml`, included directly from the connector source:

<!-- MACRO{snippet|id=serviceCriterion|file=src/main/connector/hardware/GenBatteryNT/GenBatteryNT.yaml} -->
