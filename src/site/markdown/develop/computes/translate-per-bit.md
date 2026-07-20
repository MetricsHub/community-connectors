keywords: perBitTranslation, compute, bitmask, translation table, status bits
description: Decodes a numeric bitmask column by translating each significant bit into text through a translation table.

# perBitTranslation (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `perBitTranslation` when a column contains a numeric **status word** in which each bit carries its own meaning (common in IPMI, Dell OpenManage, and other hardware instrumentation). The compute reads the value as an integer, tests every bit listed in `bitList`, looks up the key `<bit>,1` when the bit is set (or `<bit>,0` when it is clear) in the translation table, and replaces the cell with the non-empty matches joined by `" - "`.

Bits whose key is absent from the table, or translates to an empty string, contribute nothing; a value with no meaningful bits set becomes an empty cell.

## Syntax

```yaml
sources:
  powerSupplies:
    # DeviceID;StatusInformation
    type: wmi
    namespace: root\cimv2\dell
    query: SELECT DeviceID, Status FROM CIM_PowerSupply
    computes:
    - type: perBitTranslation
      column: 2
      bitList: "0,2,3,6,7,8,9,10,11,12,13,14"
      translationTable: ${translation::PowerSupplyStatusInformationTranslationTable}

# Translation tables are declared in the top-level `translations:` section
translations:
  PowerSupplyStatusInformationTranslationTable:
    "0,1": ""
    "2,1": Not Ready
    "3,1": Fan Failure
    "6,1": AC Switch On
    "7,1": AC Power On
    "9,1": Failed
    "10,1": Predicted Failure
    "11,1": AC Lost
    "12,1": AC Lost or Out-of-range
    "13,1": AC Out-of-range
    "14,1": Configuration Error
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `perBitTranslation`. |
| `column` | Yes | None | **1-based** index of the column holding the numeric value to decode. The value must parse as a number (a decimal form such as `520.0` left by an earlier arithmetic compute is accepted). |
| `bitList` | Yes | None | Comma-separated list of bit positions to test, e.g. `"0,2,3,6"`. Bit `0` is the least-significant bit. Bits are evaluated in `bitList` order. |
| `translationTable` | Yes | None | Reference to a table declared under the top-level `translations:` section, written `${translation::TableName}`. Keys have the form `"<bit>,1"` (bit set) or `"<bit>,0"` (bit clear). Unlike `translate` and `arrayTranslate`, the `default` key is **not** used by this compute. |

## Table Transformation Example

With the table above, `520` = bits 3 and 9 set, and `192` = bits 6 and 7 set:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | DeviceID | Status |
>   | --- | --- |
>   | PS1 | 520 |
>   | PS2 | 192 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | DeviceID | StatusInformation |
>   | --- | --- |
>   | PS1 | Fan Failure - Failed |
>   | PS2 | AC Switch On - AC Power On |

## Recommended Pattern

- List in `bitList` only the bits that carry meaning for the monitor; unlisted bits are ignored.
- Use `"<bit>,0"` entries when the *absence* of a bit is the noteworthy condition (e.g. `"7,0": AC Power Off`).
- If the device reports the status word in hexadecimal, insert a [`convert`](convert.html) compute with `conversion: hex2Dec` first.
- Duplicate the column upstream (`duplicateColumn`) when you also need the raw value or a separate `translate` of the same word.

## Common Mistakes

- Treating the cell as a binary string: the engine parses it as an integer and tests powers of two, so `"101"` means one-hundred-one, not bits 0 and 2.
- A non-numeric value in the column aborts the compute for the whole table, leaving every row untranslated.
- Forgetting to quote the table keys: `"13,1": AC Out-of-range` must be a quoted string key.
- Expecting a `default` fallback — this compute ignores the `default` entry; unmatched bits are simply skipped.

## Community Examples

> [!NOTE]
> No community connector currently uses `perBitTranslation`; the examples above are illustrative, adapted from enterprise-grade connectors such as Dell OpenManage.
