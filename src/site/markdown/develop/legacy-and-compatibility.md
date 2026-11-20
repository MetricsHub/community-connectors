keywords: legacy syntax, compatibility, aliases, migration
description: Canonical versus legacy connector syntax, compatibility notes, and practical migration guidance.

# Legacy and Compatibility

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

The connector library contains historical syntax variants.
This page explains what to use now and how to migrate safely.

> [!IMPORTANT]
> New connectors should use canonical modern syntax.
> Legacy forms are documented to maintain existing connectors safely.

## Canonical vs Legacy Forms

| Area | Canonical | Legacy Variant(s) | Recommendation |
| --- | --- | --- | --- |
| Detection type | `commandLine` | `commandline` | Use `commandLine` in new code. |
| Compute type | `json2Table` | `json2Csv`, `json2csv` | Use `json2Table`. The legacy names are rejected (`DEPRECATED_SYNTAX`). |
| Compute type | `xml2Csv` | `xml2csv` | Use `xml2Csv` in new code. |
| Compute type | `keepOnlyMatchingLines` | `KeepOnlyMatchingLines` | Use canonical casing. |
| TableJoin WBEM | `keyType: Wbem` | `isWbemKey: true` | Prefer `keyType`; keep legacy only when needed. |
| HTTP result content | `http_status` | `httpStatus` (older docs) | Use `http_status` in docs and new connectors. |
| Union of texts | `type: textUnion` with `texts` | `type: tableUnion` with `tables` of texts | Use `textUnion`. The legacy form is rejected (`TABLE_UNION_OF_TEXTS`). |
| Table literal | List of rows: `[ [ a, b ], [ c, d ] ]` | `;` string: `"a;b\nc;d"` | Use the list of rows in `tables`, `leftTable` and `rightTable`. The legacy form is rejected (`STRING_LITERAL_ROWS`). |
| Static value | List of cells or list of rows: `value: [ a, b ]` | `;` string: `value: "a;b"`, or a string that references a source | Write a list; read another source with a `copy`. A string is rejected. |
| Default right line | List of cells: `defaultRightLine: [ "", unknown ]` | `;` string: `defaultRightLine: ";unknown;"` | Write a list. A string is rejected. |
| Hard-coded table where a source is read | A `static` source, and its reference | A literal in `mapping.source`, `copy.from`, `executeForEachEntryOf.source`, a tool `result.source` or the `source` of an `internalDbQuery` table | Move the table to a `static` source. A literal is rejected (`NOT_A_REFERENCE`). |
| AWK input | No property: an `awk` reads its source as it is | `input` (compute), `inputFormat` (source) | Remove them: they are rejected (`DEPRECATED_SYNTAX`). |
| AWK output filtering | The script selects its lines, and prints one argument per cell with `output: table` | `keep`, `exclude`, `separators`, `selectColumns` (compute), `separators` (source) | Remove them: they are rejected (`DEPRECATED_SYNTAX`). |
| Embedded file in an AWK script | A variable: `variables: { header: "${file::header.txt}" }` | `${file::header.txt}` written in the script | Pass the file through `variables`. A reference written in a script does not give the text of the file: inside a script that is an embedded file, it stays as text; anywhere in an inline script, it makes MetricsHub run that file as the whole script instead of the inline text. |
| AWK JSON function | `json2Table(json, entryKey, properties, rows)` | `json2csv(args)`, which returned `;`-joined lines | Use `json2Table`: `json2csv` no longer exists. |
| JSON parsing | No property: `json2Table` reads a payload of 64 KiB or more as events | `parsingMode` | Remove it: it is rejected (`DEPRECATED_SYNTAX`). |

A connector that uses a legacy form marked rejected above does not load: these forms are checked when the connector loads, together with the other rules of the [Strict Content Types](design-principles.html#strict-content-types).

## Version History

The reference pages of this guide describe the current syntax. What changed, and from which version of MetricsHub Community:

| Version | Change |
| --- | --- |
| 3.9.01 | The AWK function `asorti(source, dest)`. |
| 3.9.08 | A trusted run of a `discovery` or `simple` job removes the instances it no longer returns (see [When Instances Are Removed](monitors-and-jobs.html#when-instances-are-removed)), and `removalDelay` delays the removal. Earlier versions ignore `removalDelay`, so declaring it does not break a connector on an older agent. |
| 3.9.09 | The `json2Table` name (formerly `json2Csv`), the `json2List` compute, the `textUnion` source, the table literals written as lists of rows, `maxParallel` on `executeForEachEntryOf`, and the gawk functions of the AWK scripts, whose names become reserved. |
| 3.9.09 | The strict content types are checked when a connector loads, and every legacy form marked rejected above makes it fail to load. |
| 3.9.09 | `static.value` and `defaultRightLine` are lists only, and a text result always has LF line endings. |
| 3.9.09 | An `awk` text result is exactly what the script printed: earlier versions ended each line with `;`, and removed it again from a line whose only `;` it was where the text is referenced (`${source::...}`, `authenticationToken`). The token of `authenticationToken` is the whole first line, `;` included: earlier versions took the text up to its first `;`. `$0` of an `awk` source over a table is the cells joined with `FS`. |
| 3.9.09 | `properties` of `json2Table` and `xml2Csv` can be a YAML list: earlier versions accept only a string with a `;` between the properties. |
| 3.9.09 | `json2Table` puts each value whole in its cell and ignores `separator`: earlier versions cut a value with a line feed into extra rows, and a value with the separator into extra cells. |
| 3.9.09 | `json2Table` reads a payload of 64 KiB or more as a stream of JSON events, and `parsingMode` is rejected. 3.9.08 loads every payload as a tree unless the compute sets `parsingMode: events`; earlier versions always load a tree. |
| 3.9.09 | A `${file::...}` reference written in the content of an embedded file is no longer resolved, and `executeHttpRequest` no longer reads the file that a `${file::...}` header names. A variable of an `awk` whose value is one `${file::...}` reference holds the text of that file: pass the file through `variables`. |
| 3.9.09 | A mapping without `source` is the [simple mapping](monitors-and-jobs.html#the-simple-mapping): it maps a single instance, or the connector does not load when a value reads a column or a key attribute is missing or is not a plain constant. Earlier versions skip such a mapping in a `discovery` or `simple` job (warning "No instance tables found") and fail on it in a `collect` job. |
| 3.9.09 | A mapping value that is exactly one `${source::...}` reference is the text of that source as is: earlier versions read that text as mapping syntax, like any other value. |

## Rare/Legacy Features Still Documented

The guide includes low-usage/legacy constructs for completeness:

- compute types: `encode`, `decode`

They are not preferred for new connectors unless there is a strong compatibility reason.

## Migration Strategy

1. Normalize one category at a time (types, then fields, then expressions).
2. Keep behavior equivalent while refactoring.
3. Use replay IT to verify no unintended telemetry changes.
4. Document any intentional output changes in PR description.

## Example Migration

Before:

```yaml
- type: commandline
```

After:

```yaml
- type: commandLine
```

Before:

```yaml
- type: json2csv
```

After:

```yaml
- type: json2Table
```

Before:

```yaml
outputs:
  type: tableUnion
  tables:
  - ${source::version}
  - ${source::environment}
```

After:

```yaml
outputs:
  type: textUnion
  texts:
  - ${source::version}
  - ${source::environment}
```

Before:

```yaml
rightTable: "in;ac;AC Input\nout;ac;AC Output"
```

After:

```yaml
rightTable: [ [ in, ac, AC Input ], [ out, ac, AC Output ] ]
```

Before:

```yaml
- type: awk
  input: table
  script: ${file::parse.awk}
```

After:

```yaml
- type: awk
  script: ${file::parse.awk}
```

## Compatibility Review Checklist

- canonical names used in modified sections
- no hidden semantic changes in mapping values
- replay expected output updated only when intended
- legacy syntax retained only where justified
