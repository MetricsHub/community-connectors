keywords: encode, compute, base64, url, authorization header
description: encode applies Base64 or URL encoding to the value of one column in every row of the table.

# encode (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `encode` to apply `base64` or `url` encoding to a single column, row by row, leaving the other columns untouched. The typical use is URL-encoding a device-provided identifier before injecting it into a request `path` (for example through `executeForEachEntryOf` and a `$1` placeholder), or Base64-encoding a value the target API expects in encoded form.

> [!IMPORTANT]
> For HTTP Basic authentication, do **not** build the credential with `encode`: use the [`%{BASIC_AUTH_BASE64}` runtime macro](../references-and-expressions.html) directly in the `Authorization` header. Credential macros (`%{USERNAME}`, `%{PASSWORD}`, ...) are resolved only in protocol fields (HTTP `url`/`path`/`header`/`body`, command lines) — a `static` source does **not** expand them, so encoding one would Base64 the literal macro text.

## Syntax

```yaml
sources:
  volumes:
    # One row per volume: <entry>;<name> — names may contain spaces or slashes
    type: http
    path: /api/volumes
    computes:
    - type: json2Csv
      entryKey: /volumes
      properties: /name
    - type: encode
      column: 2
      encoding: url
  volumeDetails:
    type: http
    path: /api/volumes/$2      # safe: the name is URL-encoded
    executeForEachEntryOf:
      source: ${source::volumes}
      concatMethod: json_array
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `encode`. |
| `column` | Yes | None | 1-based index of the column to encode. Every row is processed; other columns are left unchanged. |
| `encoding` | No | None | Encoding to apply: `base64` or `url`. Set it explicitly. |

## Table Transformation Example

With `column: 2` and `encoding: url`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | Entry | Name |
>   | --- | --- |
>   | /volumes[0] | Data/Archive 2024 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Entry | Name |
>   | --- | --- |
>   | /volumes[0] | Data%2FArchive%202024 |

With `encoding: base64`, a value such as `admin:S3cr3t!` becomes `YWRtaW46UzNjcjN0IQ==`.

## Recommended Pattern

- Apply `encode` as late as possible, after all human-readable filtering and matching computes: encoded values are opaque to `keepOnlyMatchingLines`, `replace`, and friends.
- Use `encoding: url` only on the individual value being substituted into a URL, not on a whole path.

## Common Mistakes

- Encoding the wrong column after an upstream compute added or removed columns (indexes are 1-based and shift with the table shape).
- URL-encoding a complete URL or path: `/` and `?` get escaped and the request breaks. Encode only the parameter value.
- Running comparisons or translations on a column that was already Base64-encoded; filter first, encode last.
- Confusing direction: `encode` produces the encoded form; use [`decode`](./decode.html) to recover the original text.

## Community Examples

> [!NOTE]
> No community connector currently uses `encode`; the examples above are illustrative.
