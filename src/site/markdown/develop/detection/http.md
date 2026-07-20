keywords: detection, http, rest, resultContent
description: Reference for the HTTP detection criterion, including status/body matching patterns.

# Detection by HTTP

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When to Use

Use `http` when connector eligibility can be validated through a REST or web endpoint.
Typical checks: product signature in body, auth header behavior, or explicit HTTP status validation.

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: http
      method: GET
      path: /redfish/v1/Systems
      header: "Authorization: Basic %{BASIC_AUTH_BASE64}"
      resultContent: body
      expectedResult: redfish
      errorMessage: Invalid credentials / not a redfish system
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | - | `http`. |
| `method` | No | `GET` | HTTP method (`GET`, `POST`, `PUT`, `DELETE`). |
| `path` | Cond. | none | Path (related to specified protocol/host/port from HTTP config in MetricsHub). |
| `url` | Cond. | none | Absolute/base URL override. |
| `header` | No | none | Request headers string or embedded-file reference. |
| `body` | No | none | Request body string or embedded-file reference. |
| `resultContent` | No | `body` | Which response part to match: `body`, `header`, `all`, `http_status`. |
| `authenticationToken` | No | none | Optional token injected in request content. |
| `expectedResult` | No | none | Regex matched against selected `resultContent`. |
| `errorMessage` | No | none | Connector-authored failure context (for logs/reporting). |
| `forceSerialization` | No | `false` | Guarantees operations are performed sequentially against one host. |

At least one of `path` or `url` must be provided.

## Runtime Behavior

- The specified HTTP request is performed against the targeted host.
- For HTTP status `>= 400`, request processing returns an empty result string.
- If `expectedResult` is absent: criterion succeeds only if selected result is non-empty.
- If `expectedResult` is present: case-insensitive regex match on selected result.

See below example on how the selected HTTP response content is matched with `expectedResult`:

> [!TABS]
>
> - <span class="fa-regular fa-circle-check"></span> Criterion
>
>   ```yaml
>   - type: http
>     method: GET
>     path: /redfish/v1
>     resultContent: body
>     expectedResult: RedfishVersion
>   ```
>
> - <span class="fa-solid fa-globe"></span> Result
>
>   Selected result (`resultContent: body`):
>
>   ```json
>   {
>     "@odata.type": "#ServiceRoot.v1_15_0.ServiceRoot",
>     "RedfishVersion": "1.17.0"
>   }
>   ```
>
>   ✅ The criterion passes because the selected response content matches `expectedResult: RedfishVersion`.

> [!WARNING] Warning
> `expectedResult` only needs to match one line of the selected result content. In HTTP responses, line breaks in JSON, HTML, or similar text are often incidental and may change over time. Avoid regular expressions that rely on exact line boundaries or formatting unless that structure is known to be stable.

## Recommended Pattern

- Prefer two-stage detection for authenticated APIs:
    1. endpoint availability check (`http_status` = `200` or expected redirect/auth code)
    2. authenticated functional check
- For robust product checks, validate status and body separately.
- Keep detection payloads minimal.

## Common Mistakes

- Matching body while endpoint actually returns relevant signal in headers or status.
- Using wide body regexes that accidentally match generic HTML or proxy responses.
- Performing large JSON requests in detection when a tiny health endpoint exists.

## Examples

Community example — the `http` criterion of [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml), included directly from the connector source (`resultContent` is not set, so it defaults to `body`):

<!-- MACRO{snippet|id=httpCriterion|file=src/main/connector/hardware/Redfish/Redfish.yaml} -->
