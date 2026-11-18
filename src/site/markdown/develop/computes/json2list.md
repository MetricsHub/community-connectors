keywords: json2List, compute, json, table, key path, flat, token, rest api
description: json2List turns a JSON document into a two-column table, one row per value: its key path and the value, in document order.

# json2List (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `json2List` to pick a few values out of a JSON document, such as an authentication token, an identifier to put in a URL or a header value. Each value in the document gets its own row with two cells: its key path and the value. A following [`awk`](./awk.html) compute can then select the rows it needs.

To get one row per entry of an array, with one column per property, use [json2Table](./json2csv.html) instead.

`json2List` is available from MetricsHub Community 3.9.09.

## Syntax

```yaml
beforeAll:
  login:
    type: http
    method: post
    path: /api/login
    body: '{ "user": "%{esc(json)::USERNAME}", "password": "%{esc(json)::PASSWORD}" }'
    computes:
    # {"data":{"token":"abc123"}} gives abc123
    - type: json2List
    - type: awk
      script: '$1 == "/data/token" { print $2; exit }'
```

The `awk` compute reads the table one row per record: `$1` is the key path and `$2` the value. It prints the token, so `login` is a text, ready for `authenticationToken: ${source::beforeAll.login}` (see [HTTP Authentication Token](../sources/http.html#authentication-token)). The token is the whole first line of that text, without the `;` that the `awk` text output ends it with: a `;` inside the token is kept.

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `json2List` |

## Table Transformation Example

> [!TABS]
>
> - <span class="fa-solid fa-code"></span> Input (JSON body)
>
>   ```json
>   {
>     "data": { "token": "abc123", "expires": 3600 },
>     "items": [
>       { "name": "edge-01", "up": true },
>       { "name": "core-01", "up": false, "note": null }
>     ],
>     "tags": []
>   }
>   ```
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Key path (col 1) | Value (col 2) |
>   | --- | --- |
>   | /data/token | abc123 |
>   | /data/expires | 3600 |
>   | /items[0]/name | edge-01 |
>   | /items[0]/up | TRUE |
>   | /items[1]/name | core-01 |
>   | /items[1]/up | FALSE |
>   | /items[1]/note | NULL |

## Rows

- **One row per value**, in the order of the document. An empty object or array (`"tags": []`) has no row.
- **Key paths** use the JFlat syntax of `json2Table`: `/name` for a member of an object, `[i]` for an element of an array, indexed from 0 (`/items[1]/name`, or `[0]/name` when the document is an array).
- **Values** are kept whole in their cell, even when they hold a line feed or a `;`:
  - a string as it is, without its quotes;
  - a number as JFlat writes it: `42`, `1.50` (the trailing zero stays), `0.0015` for `1.5E-3`, `1E+3` for `1e3`;
  - `TRUE`, `FALSE` and `NULL` for `true`, `false` and `null`.
- **A document that doesn't parse**, or that is not a JSON object or array, gives an empty table and logs a warning. What follows the closing bracket of the document is ignored.

## Recommended Pattern

- Set `resultContent: body` on the HTTP source and put `json2List` first in its `computes`.
- Select the values with an `awk` compute on `$1` (the key path), and print `$2`.
- End with an `awk` that prints a single value when the source must be a text, for example a token or an identifier used in another source's `path`.

## Common Mistakes

- Expecting `/items/0/name`: an array index is written in brackets, `/items[0]/name`.
- Comparing key paths case-insensitively: `/Data/Token` and `/data/token` are different paths, as in the document.
- Placing `json2List` after a compute that already produced a table: there is nothing to parse, and the connector does not load (`TABLE_FEEDS_TEXT`).
- A key that holds a `/` (`"a/b"`) gives the same path as a nested key (`/a/b`): select such values by their position, or with another part of the path.
