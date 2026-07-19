keywords: json2Csv, compute, json, csv, rest api, entryKey
description: json2Csv flattens a JSON payload into a semicolon-separated table, producing one row per JSON entry plus a leading entry-path column.

# json2Csv (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `json2Csv` to turn a raw JSON payload — typically the `body` of an [`http`](../sources/http.html) source — into the tabular form that mapping and other computes expect. Point `entryKey` at the JSON array (or object) holding the entries, and list in `properties` the values to extract from each entry: the compute emits one row per entry, one column per property.

This is almost always the **first** compute in an HTTP source pipeline: parse the payload into a table immediately, then filter and reshape with regular table computes.

## Syntax

```yaml
sources:
  switches:
    type: http
    method: get
    path: /api/v1/inventory/switches
    resultContent: body
    computes:
    - type: json2Csv
      entryKey: /switches
      properties: /id;/name;/operationalStatus
      separator: ;
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `json2Csv`. |
| `entryKey` | No | None | JSON pointer to the node containing the entries to convert. Point at an array (`/switches`, `/Members`) to get one row per element; use `/` to treat the whole document as a single entry. Always set it explicitly. |
| `properties` | Yes | None | Semicolon-separated list of JSON pointers, each resolved **relative to one entry** (`/id;/name;/operationalStatus`). Nested values use full pointer paths, including array indexes (`/Links/Storage[0]/@odata.id`). The list order defines the column order. |
| `separator` | No | `;` | Column separator of the generated rows. Keep the default `;` so the output matches the engine table serialization. |

> [!IMPORTANT]
> `json2Csv` prepends one extra column identifying the JSON entry each row was built from (its path in the document). Your first property therefore lands in **column 2**: reference it as `$2` in `mapping` and in subsequent computes.

You may encounter two shorthand styles in examples: property pointers written without the leading `/` (`properties: id;name;status`), which resolve against each entry's top level, and array traversal expressed inside the property itself (`properties: Members[*].@odata.id`). Prefer the canonical form used by real connectors: `entryKey` pointing at the array, plus one leading-slash pointer per column (`entryKey: /Members` with `properties: /@odata.id`).

## Table Transformation Example

> [!TABS]
>
> - <span class="fa-solid fa-code"></span> Input (JSON body)
>
>   ```json
>   {
>     "switches": [
>       { "id": "sw-01", "name": "edge-01", "operationalStatus": "ok" },
>       { "id": "sw-02", "name": "core-01", "operationalStatus": "degraded" }
>     ]
>   }
>   ```
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Entry (col 1) | id (col 2) | name (col 3) | operationalStatus (col 4) |
>   | --- | --- | --- | --- |
>   | /switches[0] | sw-01 | edge-01 | ok |
>   | /switches[1] | sw-02 | core-01 | degraded |

Equivalent serialized output:

```text
/switches[0];sw-01;edge-01;ok
/switches[1];sw-02;core-01;degraded
```

## Recommended Pattern

- Set `resultContent: body` on the HTTP source and put `json2Csv` first in its `computes` pipeline.
- Point `entryKey` at the array of records and keep every property pointer relative to a single record.
- Account for the leading entry column: the first property is `$2`, not `$1`.
- Quote the `properties` value when a pointer contains YAML-sensitive characters such as `[0]` (for example `properties: "/@odata.id;/Links/Storage[0]/@odata.id"`).

## Common Mistakes

- Off-by-one column references in `mapping` or later computes because the leading entry column was forgotten.
- Writing property pointers relative to the document root instead of relative to one entry under `entryKey`.
- Separating `properties` with commas: the list is semicolon-separated.
- Leaving `entryKey` pointing at a single object when the payload nests the records one level deeper, which yields a single mostly-empty row instead of one row per record.

## Community Examples

- [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml)

```yaml
          computes:
          - type: json2csv
            entryKey: /Members
            properties: /@odata.id;
            separator: ;
```

> [!NOTE]
> Redfish still uses the legacy lowercase alias `json2csv`. Use the canonical `json2Csv` casing in new connectors (see [Legacy and Compatibility](../legacy-and-compatibility.html)).
