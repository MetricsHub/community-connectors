keywords: xml2Csv, compute, xml, csv, recordTag
description: xml2Csv flattens an XML payload into a semicolon-separated table, producing one row per record element and one column per selected value.

# xml2Csv (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `xml2Csv` to turn a raw XML payload — typically the `body` of an [`http`](../sources/http.html) source that queries an XML API — into the tabular form that mapping and other computes expect. `recordTag` locates the repeating record elements in the document, and `properties` lists the values (child elements or attributes) to capture from each record: the compute emits one row per record, one column per property.

Like `json2Csv` for JSON payloads, it is almost always the **first** compute in the pipeline: convert to a table immediately, then reshape with regular table computes.

## Syntax

```yaml
sources:
  fanInventory:
    type: http
    method: get
    path: /api/inventory/fans
    resultContent: body
    computes:
    - type: xml2Csv
      recordTag: /inventory/fans
      properties: fan>id;fan>speedRpm;fan>status
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `xml2Csv`. |
| `recordTag` | No | None | Slash-separated absolute path of the element under which the records are read (for example `/inventory/fans`). Use `/` to read records directly under the document root. |
| `properties` | Yes | None | Semicolon-separated list of value selectors, each resolved **relative to `recordTag`**. Use `>` to descend into nested elements (`fan>speedRpm`); a name matches the child element text or the attribute with that name. The list order defines the column order. |

Unlike `json2Csv`, `xml2Csv` does **not** prepend an extra entry column: the first selector in `properties` becomes column 1.

## Table Transformation Example

> [!TABS]
>
> - <span class="fa-solid fa-code"></span> Input (XML body)
>
>   ```xml
>   <inventory>
>     <fans>
>       <fan id="fan-1" speedRpm="4200" status="ok"/>
>       <fan id="fan-2" speedRpm="3900" status="degraded"/>
>     </fans>
>   </inventory>
>   ```
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | id (col 1) | speedRpm (col 2) | status (col 3) |
>   | --- | --- | --- |
>   | fan-1 | 4200 | ok |
>   | fan-2 | 3900 | degraded |

Equivalent serialized output:

```text
fan-1;4200;ok
fan-2;3900;degraded
```

## Recommended Pattern

- Set `resultContent: body` on the HTTP source and put `xml2Csv` first in its `computes` pipeline.
- Point `recordTag` at the deepest element that encloses all records, then keep the selectors short (`record>value` rather than long absolute paths).
- Select a stable identifier (an `id` or DN-style attribute) as the first property so later computes and `mapping` can key on `$1`.
- Follow up with `keepOnlyMatchingLines` or `excludeMatchingLines` when the same container mixes several record types.

## Common Mistakes

- Separating `properties` with commas: the list is semicolon-separated.
- Using `/` inside a property selector: `recordTag` uses `/` for its path, but property selectors descend with `>`.
- Pointing `recordTag` at the record element itself when the selectors already start with that element name (the element would then be looked up one level too deep) — keep `recordTag` on the parent container in that style.
- Expecting a leading entry column as with `json2Csv`: here the first captured property is `$1`.

## Community Examples

> [!NOTE]
> No community connector currently uses `xml2Csv`; the examples above are illustrative.
