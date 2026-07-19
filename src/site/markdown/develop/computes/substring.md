keywords: substring, compute, extract, truncate, string, characters
description: The substring compute keeps only a portion of a column's content, defined by a starting character position and a length.

# substring (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `substring` to keep only part of a column's content, defined by a **1-based** starting character position and a number of characters. It replaces the column content in place, on every row. Reach for it when a fixed-width fragment of a value is meaningful on its own — for example, keeping the first 5 characters of an AIX disk device path to obtain the parent controller identifier.

For separator-based splitting (take field *n* of a `|`-delimited value), use the `extract` compute instead; for pattern-based extraction, use `awk`.

## Syntax

```yaml
sources:
  diskControllers:
    type: commandLine
    commandLine: /usr/sbin/lsdev -c disk -F 'name physloc'
    computes:
      # Keep only the first 5 chars of the disk path to obtain the controller ID
      # DeviceID;controllerID;
    - type: substring
      column: 2
      start: 1
      length: 5
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `substring`. |
| `column` | Yes | None | **1-based** index of the column to modify. Applied to every row. |
| `start` | Yes | None | **1-based** position of the first character to keep (`start: 1` starts at the beginning of the value). |
| `length` | Yes | None | Number of characters to keep from `start`. |

## Table Transformation Example

With `column: 2`, `start: 1`, and `length: 5`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | DeviceID | DevicePath |
>   | --- | --- |
>   | hdisk0 | scsi0/00-08-00-3,0 |
>   | hdisk1 | scsi1/00-08-01-4,0 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | DeviceID | ControllerID |
>   | --- | --- |
>   | hdisk0 | scsi0 |
>   | hdisk1 | scsi1 |

## Recommended Pattern

- Use `duplicateColumn` first when you need both the full value and its fragment (duplicate, then `substring` one of the copies).
- Comment the resulting column layout (`# DeviceID;controllerID;`) so the intent of the truncation stays visible.
- Prefer `extract` over `substring` when the interesting part is delimited by a separator rather than located at a fixed position.

## Common Mistakes

- Using 0-based indexes: both `column` and `start` are 1-based; `start: 0` does not mean "beginning of the string".
- Confusing `length` with an end position: `length` is the number of characters kept, not the index of the last character.
- Applying `substring` to variable-format values where the fragment is not at a fixed position — use `extract` or `awk` instead.

## Community Examples

> [!NOTE]
> No community connector currently uses `substring`; the examples above are illustrative (adapted from an enterprise connector that shortens AIX disk device paths into controller identifiers).
