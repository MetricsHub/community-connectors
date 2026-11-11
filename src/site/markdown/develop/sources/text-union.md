keywords: textUnion source, concatenate texts, command outputs, awk
description: Reference for the textUnion source, which concatenates the texts of several sources into one text.

# textUnion (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `textUnion` to concatenate the texts of several sources into one text, typically the outputs of several commands that one `awk` script parses in one pass. MetricsHub Community 3.9.09 or later.

The result is a text. Convert it before anything that reads a table (the `mapping`, a `tableJoin`, a `tableUnion`, a table compute): end the chain with a `toTable`, or declare `output: table` on the `awk` that parses it.

To concatenate the rows of tables, use [tableUnion](./table-union.html).

## Syntax

```yaml
sources:
  version:
    type: commandLine
    commandLine: show version
  environment:
    type: commandLine
    commandLine: show environment
  outputs:
    type: textUnion
    texts:
    - ${source::version}
    - ${source::environment}
    computes:
    - type: awk
      script: ${file::parse-show.awk}
    - type: toTable
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `textUnion`. |
| `texts` | Yes | None | Ordered list of the sources to concatenate, each written as exactly one `${source::...}` reference. A literal, or a reference with other text around it, is rejected when the connector loads. |
| `computes` | No | `[]` | Post-union processing pipeline. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

## How The Texts Are Joined

- Each member starts on a new line: a line feed is added between two members only when the text so far does not end with one, so the join never adds a blank line.
- The blank lines of each member are kept. A script can end a section on a blank line of a command output (`NF == 0`).
- CRLF line endings become LF.
- An empty member, or one that returned nothing or failed, adds nothing.

| Member | Text |
| --- | --- |
| `version` | `v1.2` and a line feed |
| `environment` | empty |
| `status` | `ok`, no final line feed |
| `fans` | `fan1 ok` and CRLF |

gives:

```text
v1.2
ok
fan1 ok
```

A blank line does not mark where one member ends and the next starts: to tell the outputs apart, match a line of each output.

## Recommended Pattern

- List command outputs, `http` bodies or `awk` results that one script parses together.
- Leave the members as texts: no `toTable` in a member, which would give the union `;`-separated rows instead of the command output.
- When another source also needs a member as a table, give it a [`copy`](./copy.html) of that member with its own `toTable`, so the member stays a text.
- Convert the union explicitly (`toTable`, or `awk` with `output: table`) before any table consumer.

## Common Mistakes

- Using `tableUnion` for command outputs: it still joins them the same way, but it is reported (`TABLE_UNION_OF_TEXTS`, see [Strict Content Types](../design-principles.html#strict-content-types)).
- A table as a member (`snmpTable`, `wmi`, a source ending in `toTable`): it is joined as [toText](../computes/to-text.html) writes it and reported (`TABLE_FEEDS_TEXT`). Write the `toText` in that source.
- Mapping the union, or joining it, without a conversion: it is reported (`TEXT_FEEDS_TABLE`). In this release, a `textUnion` read as a table, or interpolated in a string field, still behaves like a `tableUnion` of the same texts: MetricsHub appends a `toTable` to it when its members are command or `awk` outputs. Do not rely on it: a later release rejects a text read as a table.
