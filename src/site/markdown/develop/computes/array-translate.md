keywords: arrayTranslate, compute, translation table, array, OperationalStatus
description: Translates each element of an array value stored in a single column using a translation table, then re-joins the translated elements.

# arrayTranslate (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `arrayTranslate` when a single cell contains **several values** packed into one string — typically a WMI/WBEM array property such as `OperationalStatus`, which the engine serializes as `2|11`. Each element is split out, translated individually through the translation table, and the non-empty results are re-joined.

Element matching is case-insensitive, like [`translate`](translate.html). Elements that translate to an empty string are **dropped** from the result; unmatched elements take the table's `default` translation, or are dropped as well if there is no `default` entry.

## Syntax

```yaml
sources:
  physicalDisks:
    # __PATH;DeviceId;OperationalStatus
    type: wmi
    namespace: root\Microsoft\Windows\Storage
    query: SELECT __PATH, DeviceId, OperationalStatus FROM MSFT_PhysicalDisk
    computes:
    - type: arrayTranslate
      column: 3
      translationTable: ${translation::OperationalStatusInformationTranslationTable}
      resultSeparator: ' - '

# Translation tables are declared in the top-level `translations:` section
translations:
  OperationalStatusInformationTranslationTable:
    "2": ""
    "11": In Service
    "13": Lost Communication
    "53272": Device Hardware Error
    default: Unknown
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `arrayTranslate`. |
| `column` | Yes | None | **1-based** index of the column containing the array value. |
| `translationTable` | Yes | None | Reference to a table declared under the top-level `translations:` section, written `${translation::TableName}`. The `default` key is the fallback translation for unmatched elements. |
| `arraySeparator` | No | `\|` | Separator between elements in the input cell. Treated as a regular expression, so escape special characters (e.g. `\.` for a dot). |
| `resultSeparator` | No | `\|` | Plain string inserted between translated elements in the output cell. |

## Table Transformation Example

With the table above, `column: 3` and `resultSeparator: ' - '`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | __PATH | DeviceId | OperationalStatus |
>   | --- | --- | --- |
>   | ...PhysicalDisk.ObjectId="0" | 0 | 2\|11 |
>   | ...PhysicalDisk.ObjectId="1" | 1 | 53272\|13 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | __PATH | DeviceId | StatusInformation |
>   | --- | --- | --- |
>   | ...PhysicalDisk.ObjectId="0" | 0 | In Service |
>   | ...PhysicalDisk.ObjectId="1" | 1 | Device Hardware Error - Lost Communication |

On the first row, `2` translates to an empty string and is silently dropped, leaving only `In Service`.

## Recommended Pattern

- Map "everything is fine" codes to `""` so healthy elements disappear and only anomalies remain in the informational text.
- To turn a status array into a single monitorable state, first `arrayTranslate` the codes into `ok`/`degraded`/`failed`, then apply [`convert`](convert.html) with `array2SimpleStatus` to keep the worst one (see WinStorageSpaces).
- Use `duplicateColumn` upstream when you need both an informational text and a status derived from the same array.

## Common Mistakes

- Forgetting that `arraySeparator` is a regular expression: a separator like `.` or `+` must be escaped (`\.`, `\+`).
- Expecting unmatched elements to pass through unchanged: without a `default` entry they are removed entirely, which can produce empty cells.
- Using `arrayTranslate` on a plain single-value column — [`translate`](translate.html) is the right compute there.
- Miscounting the column index: WMI sources prepend requested properties in query order, and `__PATH` counts as a column.

## Community Examples

- [WinStorageSpaces](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WinStorageSpaces/WinStorageSpaces.yaml)

From `WinStorageSpaces`, included directly from the connector source:

<!-- MACRO{snippet|id=arrayTranslateStatusInfo|file=src/main/connector/hardware/WinStorageSpaces/WinStorageSpaces.yaml} -->
