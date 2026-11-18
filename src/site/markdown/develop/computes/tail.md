keywords: tail, compute, last lines, latest, limit, lines
description: The tail compute keeps the last lines of the table and discards the others.

# tail (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `tail` to keep only the last lines of a table, typically the latest entries of a log or of an event list, once filtered. To keep the first lines instead, use [`head`](head.html).

Filtering first and keeping the last lines next returns the latest matching entries of the whole input, which `tail -n` on the host cannot do: it reads the last lines of the file, and the filter then keeps the few matching ones among them.

## Syntax

```yaml
sources:
  errors:
    type: commandLine
    commandLine: cat /opt/app/logs/server.log
    keep: ERROR
    computes:
    - type: toTable
    - type: tail
      lines: 20
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `tail`. |
| `lines` | Yes | None | How many lines to keep, up to the last one: an integer, 0 or more, or a macro that gives one, such as `${param::lines}` in a tool. When the table holds fewer lines, it is kept whole. Any other value leaves the table unchanged and logs a warning. |

## Table Transformation Example

With `lines: 2`:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input
>
>   | Line |
>   | --- |
>   | 10:02 ERROR Connection refused |
>   | 10:15 ERROR Timeout |
>   | 10:31 ERROR Disk full |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Line |
>   | --- |
>   | 10:15 ERROR Timeout |
>   | 10:31 ERROR Disk full |

## Recommended Pattern

- Filter first (the `keep` and `exclude` of a [`commandLine`](../sources/command-line.html) source, [`keepOnlyMatchingLines`](keep-only-matching-lines.html), [`excludeMatchingLines`](exclude-matching-lines.html)), then keep the last lines.
- Put `tail` after [`sort`](sort.html) to keep the bottom lines, e.g. the smallest values of an ascending sort.
- In a tool, let a parameter set `lines`, bounded by its `pattern`.

## Common Mistakes

- Expecting `tail` to read less of a file: the source reads the whole output first. For a very large file where only the last lines matter, the command's own option (`tail -n` on Linux) reads less.
- Expecting `lines: 0` to keep everything: it keeps no line.
