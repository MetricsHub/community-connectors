keywords: detection, process, local host
description: Reference for the process detection criterion, including locality constraints.

# Detection by Process (Deprecated)

> [!WARNING]
> The `process` detection criterion is deprecated. Use WMI or SSH instead as applicable.

## When to Use

Use `process` only when local process presence is the intended detection signal for detecting a specific instrumentation software (like a vendor-specific server agent) **running on the same system as MetricsHub**. This detection criterion is only supported running Linux, UNIX, or Windows.

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: process
      commandLine: cimserver
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | - | `process`. |
| `commandLine` | Yes | - | Regex for process command line matching. Must be non-blank. |
| `forceSerialization` | No | `false` | Guarantees operations are performed sequentially against one host. |

## Runtime Behavior

- Criterion is effectively local-only.
- If target is not localhost, runtime returns success with "no remote test performed" behavior.
- On localhost, process checks are delegated per local OS implementation.

## Recommended Pattern

This connector is deprecated.

## Common Mistakes

- Assuming `process` validates remote hosts.
- Using process names that match helper commands or wrappers.
- Building critical detection logic around `process` in distributed setups.

## Examples

Enterprise example (`hardware/Director5Linux/Director5Linux.yaml`):

```yaml
connector:
  detection:
    criteria:
    - type: process
      commandLine: cimserver
```

Enterprise example (`hardware/Director52Linux/Director52Linux.yaml`):

```yaml
connector:
  detection:
    criteria:
    - type: process
      commandLine: cimserver
```
