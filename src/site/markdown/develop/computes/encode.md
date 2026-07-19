keywords: encode, compute, base64, url, authorization header
description: encode applies Base64 or URL encoding to the value of one column in every row of the table.

# encode (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `encode` to apply `base64` or `url` encoding to a single column, row by row, leaving the other columns untouched. Typical uses: building the Base64 credential of an HTTP `Authorization: Basic` header from a `user:password` string, or URL-encoding an identifier that will be injected into a request `path` (for example through `executeForEachEntryOf` and a `$1` placeholder).

## Syntax

```yaml
sources:
  basicAuth:
    type: static
    value: "%{USERNAME}:%{PASSWORD}"
    computes:
    - type: encode
      column: 1
      encoding: base64
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `encode`. |
| `column` | Yes | None | 1-based index of the column to encode. Every row is processed; other columns are left unchanged. |
| `encoding` | No | None | Encoding to apply: `base64` or `url`. Set it explicitly. |

## Table Transformation Example

With `column: 1` and `encoding: base64`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | Column 1 |
>   | --- |
>   | admin:S3cr3t! |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Column 1 |
>   | --- |
>   | YWRtaW46UzNjcjN0IQ== |

With `encoding: url`, a value such as `sensor bay 1` becomes `sensor%20bay%201`, safe to substitute into a request path or query string.

## Recommended Pattern

- Build credential strings in a `beforeAll` source (for example a `static` source combining `%{USERNAME}` and `%{PASSWORD}`), encode them once, and reference the result wherever the header is needed.
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
