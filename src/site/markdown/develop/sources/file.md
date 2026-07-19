keywords: file source, log files, schema compatibility
description: Reference for the file source definition and compatibility notes.

# file (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `file` to ingest file contents directly when available in your runtime version.

Typical intent:

- Tail-style log ingestion.
- Reading rotating files with wildcard paths.
- Full-file polling for small structured files.

## Syntax

```yaml
sources:
  appLogs:
    type: file
    paths:
    - /var/log/myapp/*.log
    mode: LOG
    maxSizePerPoll: 5MB
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `file`. |
| `paths` | Yes | None | File path patterns to read. |
| `mode` | No | `LOG` | `LOG` (cursor/incremental) or `FLAT` (read full file each cycle). |
| `maxSizePerPoll` | No | `5242880` | Max bytes read per cycle (`-1` for unlimited). |
| `executeForEachEntryOf` | No | None | Fan-out execution context. |
| `computes` | No | `[]` | Post-processing computes. |
| `forceSerialization` | No | `false` | Force raw serialization before next stages. |

## Recommended Pattern

- Prefer `LOG` mode for real log files.
- Keep `maxSizePerPoll` bounded to avoid long polling delays.
- Normalize lines with computes before mapping.

## Common Mistakes

- Using `FLAT` mode on large files.
- Very broad wildcards that match too many files.
- Mapping raw unparsed text without stable separators.

## Examples

No current community connector uses `file`.

> [!CAUTION]
> `file` is present in the official JSON schema, but usage is currently absent in community connectors. Validate behavior against your MetricsHub runtime version before adopting it.
