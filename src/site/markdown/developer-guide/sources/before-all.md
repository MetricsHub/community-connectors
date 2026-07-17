keywords: beforeAll, connector lifecycle, shared sources
description: How to use beforeAll to prepare shared data for monitor mappings.

# beforeAll (Section)

## When To Use

Use `beforeAll` when several monitor sources need the same pre-fetched data.

Typical use cases:

- Login/session bootstrap for HTTP connectors.
- Shared discovery lists reused by multiple monitor tasks.
- Expensive command output collected once per cycle.

`beforeAll` sources still return tables and can be referenced anywhere with `${source::beforeAll.<name>}`.

## Syntax

```yaml
beforeAll:
  session:
    type: http
    method: post
    path: /rest/login-sessions
    body: '{"username":"${username}","password":"${password}"}'
    resultContent: body
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `beforeAll` | Yes | None | Object containing named sources executed before monitor tasks. |
| `<sourceName>` | Yes | None | Standard source definition (`http`, `commandLine`, `snmpTable`, etc.). |

## Recommended Pattern

- Keep `beforeAll` focused on reusable setup/data.
- Use explicit source names (`session`, `inventory`, `deviceList`) rather than `source(1)` for new connectors.
- Feed `executeForEachEntryOf.source` from a `beforeAll` table when fan-out is required.

## Common Mistakes

- Putting monitor-specific business logic in `beforeAll` instead of monitor sources.
- Fetching massive payloads and re-parsing them in every monitor.
- Returning unstable column layouts that break downstream mappings.

## Community Examples

- [Cassandra](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/Cassandra/Cassandra.yaml)
- [LinuxFile](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/LinuxFile/LinuxFile.yaml)
- [WindowsFile](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/WindowsFile/WindowsFile.yaml)
