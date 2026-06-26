keywords: detection, deviceType, host kind
description: Reference for the deviceType detection criterion in MetricsHub connectors.

# Detection by Host Type

## When to Use

For each host to monitor with MetricsHub, the user will provide 2 critical attributes:

* `host.name`: the host name of the system to monitor
* `host.type`: the type of host (`Windows`, `Linux`, `AIX`, `HPUX`, `Solaris`, `Network`, `Storage`, `Management`, etc.)

Use `deviceType` as an early guardrail to avoid expensive protocol tests on incompatible hosts, where `host.type` is clearly not a possible target of this connector. This is usually the first criterion in a detection block.

For example, it is inept to try using Windows-specific connectors on non-Windows systems, so you specify `Windows` for the `deviceType` property of the connector, as in the below example.

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: deviceType
      keep:
      - Windows
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | - | `deviceType` |
| `keep` | No | empty | Allowed host kinds. If host kind is in this list, criterion succeeds. |
| `exclude` | No | empty | Denied host kinds. If host kind is here and not in `keep`, criterion fails. |

## Runtime Behavior

Evaluation rule is:

1. Consider the `host.type` attribute of the host configured by the user in the MetricsHub configuration.
2. If host kind matches `keep`: success.
3. Else if host kind matches `exclude`: failure.
4. Else success only when `keep` is empty.

> [!IMPORTANT]
> The `keep` property has priority over `exclude`.

## Recommended Pattern

- Put `deviceType` first in criteria lists.
- Use `keep` for strict targeting (`Windows`, `Linux`, `Storage`, `Network`, `OOB`).
- Use `exclude` only when you intentionally keep a broad target then filter out exceptions.

## Common Mistakes

- Using `exclude` without `keep` and expecting strict allow-list behavior.
- Adding both `keep` and `exclude` for the same kind without realizing `keep` wins.
- Skipping `deviceType` and letting costly protocol criteria run first.

## Examples

Community example (`hardware/WinStorageSpaces/WinStorageSpaces.yaml`):

```yaml
connector:
  detection:
    criteria:
    - type: deviceType
      keep:
      - Windows
```
