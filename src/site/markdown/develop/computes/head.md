keywords: head, compute, first lines, top, limit, lines
description: The head compute keeps the first lines of the table and discards the others.

# head (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `head` to keep only the first lines of a table, typically after [`sort`](sort.html) to keep the top entries: the processes that use the most CPU, the largest tables of a database. To keep the last lines instead, use [`tail`](tail.html).

## Syntax

In a tool, where a parameter sets how many lines the assistant gets:

```yaml
tools:
  topProcesses:
    description: Lists the processes that use the most CPU, with their PID and CPU percentage.
    parameters:
      count:
        type: integer
        description: How many processes to return, 1 to 999
        default: 10
        pattern: '[1-9][0-9]{0,2}'
    sources:
      processes:
        type: wmi
        query: SELECT Name, IDProcess, PercentProcessorTime FROM Win32_PerfFormattedData_PerfProc_Process WHERE Name <> '_Total' AND Name <> 'Idle'
        namespace: root\CIMv2
        computes:
        - type: sort
          column: 3
          numeric: true
          descending: true
        - type: head
          lines: ${param::count}
    result:
      source: ${source::processes}
      columns: [ name, pid, cpuPercent ]
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `head`. |
| `lines` | Yes | None | How many lines to keep, from the first one: an integer, 0 or more, or a macro that gives one, such as `${param::count}` in a tool. When the table holds fewer lines, it is kept whole. Any other value leaves the table unchanged and logs a warning. |

## Table Transformation Example

With `lines: 2`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | Name | PID | CPU |
>   | --- | --- | --- |
>   | sqlservr | 2140 | 63 |
>   | w3wp | 5012 | 21 |
>   | svchost | 880 | 4 |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Name | PID | CPU |
>   | --- | --- | --- |
>   | sqlservr | 2140 | 63 |
>   | w3wp | 5012 | 21 |

## Recommended Pattern

- Put `head` after [`sort`](sort.html) to keep the top lines, and after the filters ([`keepOnlyMatchingLines`](keep-only-matching-lines.html), [`excludeMatchingLines`](exclude-matching-lines.html)), so that the lines it keeps are the ones that matter.
- In a tool, let a parameter set `lines`, bounded by its `pattern`.

## Common Mistakes

- Forgetting that a header line counts as a line: a command whose output starts with a header keeps it among the first lines. Remove it with [`excludeMatchingLines`](exclude-matching-lines.html) when it is not wanted.
- Expecting `lines: 0` to keep everything: it keeps no line.
