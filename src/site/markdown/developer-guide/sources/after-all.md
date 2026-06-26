keywords: afterAll, connector lifecycle, cleanup
description: How to use afterAll to run teardown or cleanup actions after monitor collection.

# afterAll (Section)

## When To Use

Use `afterAll` for teardown work that should run once at the end of the connector cycle.

Typical use cases:

- Session logout.
- Temporary resource cleanup.
- Finalization calls that should not be repeated per monitor.

## Syntax

```yaml
afterAll:
  logout:
    type: http
    method: delete
    path: /rest/login-sessions/current
    resultContent: http_status
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `afterAll` | Yes | None | Object containing named sources executed after monitor tasks. |
| `<sourceName>` | Yes | None | Standard source definition (`http`, `commandLine`, etc.). |

## Recommended Pattern

- Keep actions idempotent so retries are safe.
- Prefer lightweight status checks (`resultContent: http_status`) for cleanup calls.
- Avoid dependencies on monitor output unless strictly needed.

## Common Mistakes

- Running heavy collection logic in `afterAll`.
- Building teardown logic that fails if called twice.
- Assuming `afterAll` output is part of monitor mappings.

## Examples

No current community connector uses `afterAll`.

> [!NOTE]
> `afterAll` is fully supported and useful for modern REST connectors with explicit login/logout flows.
