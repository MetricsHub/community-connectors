keywords: convert, compute, hex2Dec, array2SimpleStatus, worst status
description: Converts a column value from hexadecimal to decimal, or collapses an array of ok/degraded/failed statuses into the single worst status.

# convert (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `convert` for one of two fixed conversions on a column:

- `hex2Dec` turns a hexadecimal string into its decimal value. The engine strips a `0x` prefix, colons, and whitespace before parsing, so `0x1F`, `1f`, and `1A:2B:3C` all convert. Use it before arithmetic computes (`multiply`, `divide`...) or [`perBitTranslation`](translate-per-bit.html), which require decimal input.
- `array2SimpleStatus` collapses a pipe-separated array of statuses (`ok`, `degraded`, `failed`, case-insensitive) into the single **worst** status. It is the standard follow-up to [`arrayTranslate`](array-translate.html) when a device reports several status codes for one component.

## Syntax

```yaml
sources:
  enclosureStatus:
    # Enclosure;Vendor;Model;SerialNumber;Status;StatusInformation;PowerConsumption
    type: ipmi
    computes:
    - type: keepOnlyMatchingLines
      column: 1
      valueList: enclosure
    - type: convert
      column: 5
      conversion: array2SimpleStatus
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `convert`. |
| `column` | Yes | None | **1-based** index of the column to convert in place. |
| `conversion` | Yes | None | `hex2Dec` or `array2SimpleStatus`. |

## Table Transformation Example

With `conversion: array2SimpleStatus` on column 2 (simplified table):

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | DeviceID | StatusArray |
>   | --- | --- |
>   | encl-0 | ok\|degraded\|ok |
>   | encl-1 | ok\|failed |
>   | encl-2 | ok |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | DeviceID | Status |
>   | --- | --- |
>   | encl-0 | degraded |
>   | encl-1 | failed |
>   | encl-2 | ok |

Severity order is `failed` > `degraded` > `ok`; values that are none of the three are ignored, and a cell containing no recognized status becomes `UNKNOWN`.

With `conversion: hex2Dec`, a cell containing `0x1F` becomes `31`, and `1A:2B` becomes `6699`.

## Recommended Pattern

- Chain `arrayTranslate` (codes to `ok`/`degraded`/`failed`) then `convert` with `array2SimpleStatus` to derive one monitorable state from a status array, as WinStorageSpaces does.
- Apply `hex2Dec` immediately after acquisition so every downstream compute and the mapping deal with plain decimal numbers.
- Keep a `duplicateColumn` copy of the raw array if you also want the detail as informational text.

## Common Mistakes

- Feeding `array2SimpleStatus` untranslated numeric codes: only `ok`, `degraded`, and `failed` tokens are recognized, so raw codes yield `UNKNOWN`. Translate first.
- Applying `hex2Dec` to a value that is not valid hexadecimal: the row is left unchanged and a warning is logged, which can go unnoticed.
- Confusing `conversion` values: they are camelCase (`hex2Dec`, `array2SimpleStatus`), not `hex2dec`.
- Counting columns from 0: `column` is 1-based, like everywhere else in connectors.

## Community Examples

- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/IpmiTool/IpmiTool.yaml)
- [LinuxIpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/LinuxIpmiTool/LinuxIpmiTool.yaml)
- [WinStorageSpaces](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WinStorageSpaces/WinStorageSpaces.yaml)

From `WinStorageSpaces`, included directly from the connector source:

<!-- MACRO{snippet|id=convertArray2SimpleStatus|file=src/main/connector/hardware/WinStorageSpaces/WinStorageSpaces.yaml} -->
