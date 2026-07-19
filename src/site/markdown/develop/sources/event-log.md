keywords: eventLog source, windows events, log monitoring
description: Reference for the eventLog source type used to query Windows Event Logs.

# eventLog (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `eventLog` to collect Windows Event Log entries directly (system/application/security-style logs).

This source is useful for event-driven monitors and error counters when WMI/Perf counters are not enough.

## Syntax

```yaml
sources:
  windowsErrors:
    type: eventLog
    logName: System
    levels:
    - error
    - warning
    eventIds:
    - "41"
    - "6008"
    maxEventsPerPoll: 50
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `eventLog`. |
| `logName` | No | Provider/runtime default | Event log channel name (for example `System`, `Application`). |
| `eventIds` | No | `[]` | Event IDs to include. |
| `sources` | No | `[]` | Event providers/sources to include. |
| `levels` | No | `[]` | Level filters: names (`error`, `warn`, `info`, `success`, `failure`) or numeric `1..5`. |
| `maxEventsPerPoll` | No | `50` | Maximum events per cycle. Use `-1` for unlimited. |
| `executeForEachEntryOf` | No | None | Execute with fan-out context from another source. |
| `computes` | No | `[]` | Post-processing computes. |
| `forceSerialization` | No | `false` | Force raw serialization before next stages. |

## Recommended Pattern

- Set `logName` explicitly.
- Filter early with `levels`, `eventIds`, and `sources`.
- Keep `maxEventsPerPoll` bounded for predictable polling time.

## Common Mistakes

- Using unlimited events on noisy logs.
- Filtering only in computes after pulling huge event sets.
- Mixing numeric and textual levels inconsistently across connectors.

## Examples

No current community connector uses `eventLog`.

> [!NOTE]
> `eventLog` is supported by the runtime but currently low-usage in community connectors.
