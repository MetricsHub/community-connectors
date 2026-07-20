keywords: keepOnlyMatchingLines, compute, filter rows, regex, valueList, grep
description: The keepOnlyMatchingLines compute keeps only the table rows whose selected column matches a regular expression or an exact-value list.

# keepOnlyMatchingLines (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `keepOnlyMatchingLines` to filter a source table down to the rows you actually want to monitor: keep only the sensors of a given type, only the services whose name matches a connector variable, only the rows with a valid status. It is the table equivalent of `grep`: rows that do not match are discarded, rows that match pass through unchanged.

To do the opposite (discard matching rows), use [`excludeMatchingLines`](exclude-matching-lines.html). To drop columns instead of rows, use [`keepColumns`](keep-columns.html).

## Syntax

```yaml
sources:
  temperatureSensors:
    type: commandLine
    commandLine: ${file::ipmi-sensors.sh}
    computes:
    - type: keepOnlyMatchingLines
      column: 1
      valueList: temperature
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `keepOnlyMatchingLines`. |
| `column` | Yes | None | **1-based** index of the column tested on each row. Rows shorter than this index are discarded. |
| `regExp` | No | None | Case-insensitive regular expression. A row is kept when the regex is found anywhere in the column value (unanchored, like `grep`); use `^` and `$` to force a full match. Follows PSL regex conventions: alternation is a backslash-escaped pipe (see Common Mistakes). Often set from a connector variable, e.g. `${var::matchName}`. |
| `valueList` | No | None | Comma-separated list of exact values, e.g. `temperature,fan`. A row is kept when the column value equals one of the listed values (case-insensitive, whole-value comparison). |

Provide `regExp`, `valueList`, or both. When both are specified, both are applied one after the other: a row is kept only if it matches the `regExp` **and** its value is in the `valueList`.

## Table Transformation Example

With `column: 1` and `valueList: temperature`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | Type | ID | Reading |
>   | --- | --- | --- |
>   | temperature | CPU1 Temp | 42 |
>   | fan | Fan1A | 4800 |
>   | Temperature | Ambient | 24 |
>   | voltage | 12V Rail | 12.1 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Type | ID | Reading |
>   | --- | --- | --- |
>   | temperature | CPU1 Temp | 42 |
>   | Temperature | Ambient | 24 |

Note that `Temperature` is kept: `valueList` comparison is case-insensitive.

## Recommended Pattern

- Prefer `valueList` for exact category values (`temperature`, `fan`, `enclosure`); reserve `regExp` for real patterns.
- Filter as early as possible in the `computes` pipeline so subsequent computes process fewer rows.
- Drive `regExp` from a connector variable (`regExp: ${var::serviceNames}`) when the user should choose what to monitor, as done in `LinuxService` and `WindowsProcess`.
- Anchor the regex (`^value$`) when you need an exact match with regex features; otherwise `abc` also keeps `xabcy`.

## Common Mistakes

- Forgetting that `regExp` is unanchored: `regExp: 5` keeps every row whose column merely *contains* `5` — use `valueList: 5` or `regExp: ^5$` for an exact match.
- Expecting `valueList` to support patterns; it is a list of literal values only.
- Combining `regExp` and `valueList` and expecting an OR: the two criteria are ANDed.
- Counting columns from 0: `column` is 1-based.
- Writing Java-style alternation `a|b` where PSL-style `a\|b` is expected.

## Community Examples

- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/IpmiTool/IpmiTool.yaml)
- [WindowsProcess](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/WindowsProcess/WindowsProcess.yaml)
- [LinuxService](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/LinuxService/LinuxService.yaml)

From `IpmiTool`:

<!-- MACRO{snippet|id=keepOnlyMatchingLinesCompute|file=src/main/connector/hardware/IpmiTool/IpmiTool.yaml} -->
