keywords: design principles, best practices, connector quality, performance
description: Practical design principles for writing efficient, robust, and maintainable MetricsHub connectors.

# Design Principles

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

This page defines the default engineering bar for connector contributions.

## 1. Determinism Over Cleverness

A connector should behave predictably across runs and environments.

- Use stable IDs, not display labels, for `attributes.id`.
- Keep detection based on deterministic signatures.
- Avoid brittle regexes tied to formatting noise.

## 2. Cost-Aware Detection

Detection should be ordered from cheapest to most expensive.

- cheap protocol/table existence check first
- authenticated/product-specific check next
- expensive data pulls last (if needed at all)

For HTTP detection, prefer status checks when body parsing is unnecessary.

## 3. Reuse Data, Do Not Re-fetch

Use source composition to minimize remote calls:

- `beforeAll` for login/bootstrap/shared data
- `copy` for branching
- `tableJoin` and `tableUnion` for composition, `textUnion` to parse several command outputs together
- `internalDbQuery` for dedup/aggregation when joins alone are not enough

## 4. Normalize Early

Perform status and unit normalization before mapping:

- `translate` for status/code dictionaries
- `convert` for format conversions
- `divide` / `multiply` for units
- `keepOnlyMatchingLines` / `excludeMatchingLines` early to reduce volume

## 5. Make Mapping Boring

Good mapping is mostly straightforward column assignment.

```yaml
mapping:
  source: ${source::sensors}
  attributes:
    id: $1
    name: $2
  metrics:
    hw.status{hw.type="fan"}: $3
    hw.fan.speed: $4
```

If mapping is doing heavy parsing, push that logic back into computes.

## 6. Prefer Modern Connector Style

For new or heavily revised connectors:

- prefer explicit source names (`ports`, `inventory`, `clusterInfo`)
- prefer `simple` jobs when two-phase behavior is not required
- prefer canonical type names (`commandLine`, `json2Table`, `xml2Csv`)
- write every conversion between text and table (see [Strict Content Types](#strict-content-types))

## 7. Design for Reviewability

Reviewers should infer behavior quickly.

- Keep source pipelines short and coherent.
- Use comments only where they explain non-obvious transforms.
- Group related monitors and avoid copy-paste drift.

## 8. Validate with Replay Tests

No connector change is complete until replay test behavior is understood.

- update emulation inputs when behavior intentionally changes
- update expected output only for deliberate semantic changes
- keep expected payload stable and host-normalized

## 9. Build Instances from an Inventory

From MetricsHub Community 3.9.08, an instance that a trusted `discovery` or `simple` run no longer returns is removed (see [When Instances Are Removed](monitors-and-jobs.html#when-instances-are-removed)). The rows that create the instances must list every entity that **exists**, not only the ones that are active, healthy, or reporting a value.

- Take the mapping source from an inventory, and attach the statistics to it:
  - keep the inventory as the **left** table of a [`tableJoin`](sources/table-join.html) and set a `defaultRightLine`, so an entity without statistics keeps its row with empty cells (or look the statistics up from the inventory in an `awk` compute);
  - or split the monitor: `discovery` maps the inventory, `collect` maps the statistics. A row missing from a `collect` job never removes anything.
- Do not filter on a state or a value in a job that creates monitors: `Enabled` sensors only, interfaces `up` only, non-zero readings only, sensors that have a reading, `virsh list` without `--all`, `systemctl list-units` (only the units loaded in memory). Filter on a type or a class, and map the state as a metric.
- In a fan-out, a failed request must not drop the entity's row. Join the `executeForEachEntryOf` result back onto the inventory (left table, `defaultRightLine`); in an `awk` script calling `executeHttpRequest`, print the row with empty cells instead of skipping it with `next`.
- Entities defined by their activity (sessions, connected replicas, running queries) have no inventory: set [`removalDelay`](monitors-and-jobs.html#removaldelay) on the monitor, and prefer gauges to `rate()` / `fakeCounter()`, whose state restarts each time the instance is recreated.

## Strict Content Types

Every source result, and the result of every compute, is either a **text** or a **table** (see the [content types](computes/index.html#content-types)). From MetricsHub Community 3.9.09, MetricsHub checks every connector when it loads it and reports each place where a step reads the wrong type, a table is interpolated in a string, or a reference names no source.

> [!IMPORTANT]
> In this release, the findings are only reported: the connector loads and behaves as before, and MetricsHub still inserts the conversions it can (see the [content types](computes/index.html#content-types)). A later release rejects these connectors when it loads them. Write the conversions now.

### Text Sources and Table Sources

What a source produces is the type at the end of its chain, as written:

| Text | Table |
| --- | --- |
| `commandLine`, `http`, `file`, `ipmi`, the `awk` source with the default `output: text`, [`textUnion`](sources/text-union.html), a source with `executeForEachEntryOf` and a `json_array`, `json_array_extended` or custom `concatMethod` | every other source: `snmpTable`, `wmi`, `sql`, `static`, `tableJoin`, `tableUnion`, `internalDbQuery`, the `awk` source with `output: table`, ... |
| a chain ending in `toText` or in an `awk` compute with the default `output: text` | a chain ending in `toTable`, `json2Table`, `xml2Csv`, an `awk` compute with `output: table` or any other compute |

A `copy` produces what the source it copies produces. A `tableUnion` whose members are all texts still produces a text, and is reported (see [Texts in a Union](sources/table-union.html#texts-in-a-union)).

### Table Consumers

These read a table. A text there is reported (`TEXT_FEEDS_TABLE`): end its source with a `toTable`, or an `awk` with `output: table`, a `json2Table` or an `xml2Csv`.

- `leftTable` and `rightTable` of a [`tableJoin`](sources/table-join.html);
- the members of a [`tableUnion`](sources/table-union.html), with their own rules: a union of texts only is reported once (`TABLE_UNION_OF_TEXTS`), a union of texts and tables is reported `MIXED_UNION` plus `TEXT_FEEDS_TABLE` for each text member;
- `mapping.source`;
- the result source of a tool that declares `columns` (see [tools](tools.html));
- the computes that work on columns: every compute but `awk`, `json2Table`, `xml2Csv` and `toTable` (`toText` included);
- the tables of an [`internalDbQuery`](sources/internal-db-query.html);
- the `source` of `executeForEachEntryOf`;
- a `${source::...}` reference in the `variables` of an `awk`.

### Text Consumers

These read a text. A table there is reported (`TABLE_FEEDS_TEXT`): end its source with a [`toText`](computes/to-text.html).

- the members of a [`textUnion`](sources/text-union.html);
- `json2Table`, `xml2Csv` and `toTable`.

An `awk` compute reads either type as it is, and so does an `awk` source whose `input` is a single reference.

### Interpolated Fields

A `${source::...}` reference inside a string field is replaced by the text of that source. These fields must reference texts: a table there is reported (`TABLE_INTERPOLATED`). Convert the table with an explicit `toText` in its source, or extract the value as a text, for example with an `awk` that prints it.

- `url`, `path`, `header`, `body` and `authenticationToken` of an `http` source (see [Authentication Token](sources/http.html#authentication-token));
- the command line of a `commandLine` source, and the other string fields of a source;
- the values of computes, such as the `value` of `append` or `prepend`;
- the fields of a `mapping` other than `source`: attributes, metrics, ...;
- the `input` of an `awk` source written as a template, such as `MODE;${source::raw}`.

The sources that read their references as sources interpolate nothing: `copy`, `static`, `tableUnion`, `textUnion`, `tableJoin`, and an `awk` source whose `input` is a single reference.

### Unresolved References

A `${source::...}` reference to a source the connector does not have is reported (`UNRESOLVED_REFERENCE`), wherever it is: a source, a compute, an `awk` variable, `executeForEachEntryOf`, a mapping or a tool result. MetricsHub looks the reference up exactly as it does when the connector runs: a short reference (`${source::name}`) is made absolute when the connector loads, and one that cannot be made absolute stays short and finds no source. There is no other fallback.

### Rules and Hints

| Rule | Hint | Reported for |
| --- | --- | --- |
| `TEXT_FEEDS_TABLE` | write a toTable | A text read by a table consumer. |
| `TABLE_FEEDS_TEXT` | write a toText | A table read by a text consumer. |
| `TABLE_UNION_OF_TEXTS` | use textUnion | A `tableUnion` whose members are all texts, once per union. |
| `MIXED_UNION` | convert the members to one type | A `tableUnion` of texts and tables, once per union, plus a `TEXT_FEEDS_TABLE` for each text member. |
| `STRING_LITERAL_ROWS` | write a list of rows | A `;` string literal in `tables`, `leftTable` or `rightTable` (see [Writing Table Literals](sources/table-union.html#writing-table-literals)). |
| `TABLE_INTERPOLATED` | interpolate a text | A table referenced in an interpolated field. |
| `UNRESOLVED_REFERENCE` | reference an existing source | A reference to a source the connector does not have. |
| `DEPRECATED_SYNTAX` | remove or rename it | The `json2Csv` compute type (rename it `json2Table`), the ignored `input` of an `awk` compute and `inputFormat` of an `awk` source (remove them). |

Each finding is logged when the connector loads, at WARN, or at INFO for `DEPRECATED_SYNTAX`. The message names the rule, the source, the location, the expected and actual types, and the hint:

```text
Connector MyConnector - Content type check: TEXT_FEEDS_TABLE in ${source::monitors.disk.discovery.sources.disks} at keepColumns #0: expected TABLE, actual TEXT (write a toTable)
```

The location is a compute with its position among the written computes, counted from 0 (`keepColumns #0`, `append #1 value`), a field (`tables[1]`, `leftTable`, `header`, `authenticationToken`, `variables.rows`), a mapping (`monitors.disk.discovery.mapping`, `monitors.disk.discovery.mapping.attributes.name`) or a tool result (`tools.listDisks.result`), followed by `-> ${source::...}` when a reference is at fault. For a mapping or a tool, the source named is the one the mapping or the tool reads.

The monitors defined in the configuration of a resource are checked too, with `(monitors of a resource)` as the connector. For MetricsHub developers, the compute-chain golden check of the engine (`GoldenCheck --report`) prints the same findings for each connector, with the totals per rule.

## Anti-Patterns To Avoid

- many scalar queries where one table query would do
- long replacement chains instead of translation tables
- IDs derived from mutable names
- hidden dependency on locale-specific output text
- filtering the rows that create monitors on a state or a value
- an inner join or a fan-out that drops the row of an entity whose statistics are missing
- a text read as a table, or a table interpolated in a string, without an explicit conversion
