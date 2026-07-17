keywords: decode, compute, base64, url, decoding
description: decode reverses Base64 or URL encoding on the value of one column in every row of the table.

# decode (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `decode` to reverse `base64` or `url` encoding on a single column, row by row, leaving the other columns untouched. Reach for it when an API or command returns encoded values — a Base64-encoded name, description, or token payload, or percent-encoded identifiers extracted from URLs — and you need the original text for matching, translation tables, or display attributes in `mapping`.

## Syntax

```yaml
sources:
  sensors:
    type: http
    method: get
    path: /api/v1/sensors
    resultContent: body
    computes:
    - type: json2Csv
      entryKey: /sensors
      properties: /id;/encodedName;/status
    # Column 3 (/encodedName) holds a Base64-encoded display name
    - type: decode
      column: 3
      encoding: base64
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `decode`. |
| `column` | Yes | None | 1-based index of the column to decode. Every row is processed; other columns are left unchanged. |
| `encoding` | No | None | Encoding to reverse: `base64` or `url`. Set it explicitly and match the encoding actually applied to the data. |

## Table Transformation Example

With `column: 3` and `encoding: base64` (columns shown after `json2Csv`, whose leading entry column is column 1):

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | Entry | id | encodedName | status |
>   | --- | --- | --- | --- |
>   | /sensors[0] | s1 | U2Vuc29yIEJheSAx | ok |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Entry | id | encodedName | status |
>   | --- | --- | --- | --- |
>   | /sensors[0] | s1 | Sensor Bay 1 | ok |

With `encoding: url`, a value such as `sensor%20bay%201` becomes `sensor bay 1`.

## Recommended Pattern

- Decode as early as possible, right after the payload-to-table compute, so every later compute (`keepOnlyMatchingLines`, `translate`, `replace`) and `mapping` works on readable text.
- Pick the `encoding` from the API documentation or an observed sample; a wrong choice yields garbage, not an error you can grep for.
- Combine with `extract` or `substring` when only part of a column is encoded: isolate the encoded fragment in its own column first, then decode it.

## Common Mistakes

- Decoding the wrong column after an upstream compute changed the table shape (indexes are 1-based and shift when columns are added or removed).
- Forgetting the leading entry column produced by `json2Csv`: the first JSON property sits in column 2, so the decoded field is one column further right than expected.
- Applying `base64` decoding to plain text: the result is binary garbage that silently corrupts the row.
- Confusing direction: `decode` recovers original text; use [`encode`](./encode.html) to produce Base64/URL-encoded values.

## Community Examples

> [!NOTE]
> No community connector currently uses `decode`; the examples above are illustrative.
