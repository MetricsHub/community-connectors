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
| `texts` | Yes | None | Ordered list of the sources to concatenate, each written as exactly one `${source::...}` reference. A literal, a reference with other text around it, or a reference to a source the connector does not have (`UNRESOLVED_REFERENCE`) is rejected when the connector loads. |
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
- Leave the members as texts: no `toTable` in a member, which would make it a table, rejected as a member (`TABLE_FEEDS_TEXT`).
- When another source also needs a member as a table, give it a [`copy`](./copy.html) of that member with its own `toTable`, so the member stays a text. Without the copy, the other source reads a text as a table, and the connector does not load (`TEXT_FEEDS_TABLE`).
- Convert the union explicitly (`toTable`, or `awk` with `output: table`) before any table consumer.

## Common Mistakes

- Using `tableUnion` for command outputs: the connector does not load (`TABLE_UNION_OF_TEXTS`, see [Strict Content Types](../design-principles.html#strict-content-types)).
- A table as a member (`snmpTable`, `wmi`, a source ending in `toTable`): the connector does not load (`TABLE_FEEDS_TEXT`). Write a [toText](../computes/to-text.html) in that source.
- Mapping the union, or joining it, without a conversion: the connector does not load (`TEXT_FEEDS_TABLE`).
