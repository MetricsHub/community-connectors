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
    - type: json2Csv
      properties: Members[*].@odata.id
      separator: ;
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
| `authenticationToken` | No | None | Token value/expression used by HTTP extension. |
| `resultContent` | No | `body` | Response part: `body`, `header`, `all`, `http_status`. |
| `executeForEachEntryOf` | No | None | Execute request once per input row (`$1`, `$2`, ... placeholders). |
| `computes` | No | `[]` | Post-processing pipeline (often `json2Csv`/`xml2Csv`). |
| `forceSerialization` | No | `false` | Force raw serialization before next stages. |

> [!IMPORTANT]
> Define at least one of `path` or `url`. New connectors should generally prefer `path` with protocol configuration.

## Recommended Pattern

- Use `beforeAll` for login/session bootstrap, then reuse tokens/headers.
- Parse JSON/XML immediately after retrieval.
- Use `executeForEachEntryOf` for endpoint fan-out (`/Systems/$1`, `/Drives/$1`, ...).
- Keep response scope narrow (`?$select=...` when API supports it).

## Common Mistakes

- Pulling huge payloads and filtering later.
- Mixing relative `path` and absolute `url` inconsistently in one connector.
- Forgetting `resultContent` and trying to parse headers as body.
- Using body parsing for simple health checks.

## Community Examples

- [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml)
- [HPPrinter](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/HPPrinter/HPPrinter.yaml)

> [!NOTE]
> `resultContent: http_status` is the preferred pattern for cheap status-only calls. Keep `resultContent: body` for payload extraction.
