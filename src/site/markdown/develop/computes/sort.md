keywords: sort, compute, order, numeric, alphabetical, descending, ignoreCase
description: The sort compute sorts the lines of the table on a column, alphabetically or numerically, in ascending or descending order.

# sort (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `sort` to order the lines of a table on one of its columns: the processes by CPU, the files by size, the entries by name. Followed by [`head`](head.html), it keeps the top lines.

## Syntax

```yaml
sources:
  processes:
    type: wmi
    query: SELECT Name, IDProcess, WorkingSetPrivate FROM Win32_PerfFormattedData_PerfProc_Process WHERE Name <> '_Total'
    namespace: root\CIMv2
    computes:
    # The processes that use the most memory first
    - type: sort
      column: 3
      numeric: true
      descending: true
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `sort`. |
| `column` | Yes | None | The **1-based** column to sort on. |
| `numeric` | No | `false` | `true` compares the values as numbers (`9.5` before `10`), `false` alphabetically (`10` before `9.5`). Numbers may be negative, decimal, or written with an exponent (`1.5E3`), but not with a unit or a thousands separator (`12%`, `1,024`). |
| `ignoreCase` | No | `false` | `true` makes the alphabetical comparison ignore the case (`alpha` before `Beta`). By default, the values compare by their characters' code, which puts uppercase letters before lowercase ones (`Beta` before `alpha`). Without effect when `numeric` is `true`. |
| `descending` | No | `false` | `true` sorts from the largest value to the smallest. |

The sort is stable: lines with equal values keep their order. The lines that lack the column, and, in a numeric sort, those whose value is not a number (`n/a`, an empty value, a header), go last, in their original order, in both directions.

## Table Transformation Example

With `column: 3`, `numeric: true` and `descending: true`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | Name | PID | Memory |
>   | --- | --- | --- |
>   | svchost | 880 | 9452 |
>   | sqlservr | 2140 | 812004 |
>   | Idle | 0 | n/a |
>   | w3wp | 5012 | 125340 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Name | PID | Memory |
>   | --- | --- | --- |
>   | sqlservr | 2140 | 812004 |
>   | w3wp | 5012 | 125340 |
>   | svchost | 880 | 9452 |
>   | Idle | 0 | n/a |

## Recommended Pattern

- Sort numbers with `numeric: true`: alphabetically, `10` comes before `9`.
- Follow `sort` with [`head`](head.html) to keep the top lines, or [`tail`](tail.html) to keep the bottom ones.
- Remove units first, with [`replace`](replace.html) or an [`awk`](awk.html) compute, so that the values are numbers.

## Common Mistakes

- Counting columns from 0: `column` is 1-based, and `column: 0` leaves the table unchanged.
- Leaving a header line in the table: a numeric sort moves it last, an alphabetical sort moves it among the data. Remove it with [`excludeMatchingLines`](exclude-matching-lines.html) first.
- Expecting a locale-aware alphabetical order: accented letters come after `z`.
