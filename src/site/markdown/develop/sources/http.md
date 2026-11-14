keywords: http source, rest api, redfish
description: Full reference for HTTP source including auth/session and resultContent strategy.

# http (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `http` when the target exposes REST/HTTP endpoints (for example Redfish or appliance APIs).

HTTP sources usually return raw payload text first, then computes convert payloads into tabular data for mapping.

## Syntax

```yaml
sources:
  systems:
    type: http
    method: get
    path: /redfish/v1/Systems
    resultContent: body
    computes:
    - type: json2Table
      entryKey: /Members
      properties: /@odata.id
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `http`. |
| `method` | No | `get` | HTTP method (`get`, `post`, `put`, `delete`). |
| `path` | Conditionally | None | Relative path on target endpoint. |
| `url` | Conditionally | None | Absolute URL. |
| `header` | No | None | Request headers (inline or `${file::...}`). |
| `body` | No | None | Request payload. |
| `authenticationToken` | No | None | Token value/expression used by HTTP extension, usually a reference to the source that extracts it. See [Authentication Token](#authentication-token). |
| `resultContent` | No | `body` | Response part: `body`, `header`, `all`, `http_status`. |
| `executeForEachEntryOf` | No | None | Execute request once per input row (`$1`, `$2`, ... placeholders). |
| `computes` | No | `[]` | Post-processing pipeline (often `json2Table`/`xml2Csv`). |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

> [!IMPORTANT]
> Define at least one of `path` or `url`. New connectors should generally prefer `path` with protocol configuration.

The fields `url`, `path`, `header`, `body` and `authenticationToken` interpolate their `${source::...}` references: each one must reference a text (see [Strict Content Types](../design-principles.html#strict-content-types)).

## Authentication Token

`authenticationToken` usually references the source that extracts the token from a login response. That source must end in text: the token is its whole first line, without its LF or CR LF ending (a lone CR does not end the line), and without the trailing `;` that an `awk` text output ends a line of one value with. The line loses its `;` only when that `;` is its last and only one, the same rule as for a reference in a `header` or a `path`; a `;` elsewhere in the line is part of the token. This holds from MetricsHub Community 3.9.09; earlier versions took the text up to its first `;`. A table there is rejected (`TABLE_INTERPOLATED`).

Extract the token as a text, for example with a [json2List](../computes/json2list.html) and an `awk` that prints only the token:

```yaml
beforeAll:
  login:
    type: http
    method: post
    path: /api/login
    body: '{ "user": "%{esc(json)::USERNAME}", "password": "%{esc(json)::PASSWORD}" }'
    computes:
    # {"token":"abc123"} gives abc123
    - type: json2List
    - type: awk
      script: '$1 == "/token" { print $2; exit }'
monitors:
  enclosure:
    simple:
      sources:
        inventory:
          type: http
          path: /api/enclosure
          authenticationToken: ${source::beforeAll.login}
```

## Recommended Pattern

- Use `beforeAll` for login/session bootstrap, then reuse tokens/headers.
- Parse JSON/XML immediately after retrieval.
- Use `executeForEachEntryOf` for endpoint fan-out (`/Systems/$1`, `/Drives/$1`, ...).
- Keep response scope narrow (`?$select=...` when API supports it).

## Common Mistakes

- Pulling huge payloads and filtering later.
- Mixing relative `path` and absolute `url` inconsistently in one connector.
- Forgetting `resultContent` and trying to parse headers as body.
- Applying a table compute, or the `mapping`, to the HTTP result directly: it is text, and the connector does not load (`TEXT_FEEDS_TABLE`). Convert it first with `json2Table`, `xml2Csv`, `toTable` or `awk` (with `output: table`).
- Referencing a table in `url`, `path`, `header`, `body` or `authenticationToken`: the connector does not load (`TABLE_INTERPOLATED`). Reference a source that ends in text, such as an `awk` that prints the value.
- Using body parsing for simple health checks.

## Community Examples

- [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml)

> [!NOTE]
> `resultContent: http_status` is the preferred pattern for cheap status-only calls. Keep `resultContent: body` for payload extraction.
