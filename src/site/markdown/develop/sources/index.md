keywords: connector sources, source pipeline, table model, mapping
description: How source execution works in MetricsHub connectors and full source type reference.

# Sources

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## What A Source Produces

In MetricsHub connectors, a source produces a **table**, or a text that its computes turn into a table (`commandLine`, `http`, `file`, `ipmi`, `awk`, `textUnion`, see the [content types](../computes/index.html#content-types)). Internally, a table is a list of rows, where each row is a list of strings.

Most compute operations modify one table column at a time, which is why they usually require `column:`.

`mapping.source` is a reference to a source that ends in a table (anything else does not load, `NOT_A_REFERENCE`: a hard-coded table belongs in a [static](./static.html) source), and **each row creates one monitor instance** exported as one OpenTelemetry Resource:

- Row cells are mapped to attributes and metrics with `$1`, `$2`, `$3`, and so on.
- If your table has 20 rows, you get 20 instances for a `multiInstance` monitor.

Example logical table:

| id | name | status |
| --- | --- | --- |
| psu01 | PSU 1 | ok |
| psu02 | PSU 2 | failed |

## Serialization Details You Must Know

A source result is either text or a table (see the [content types](../computes/index.html#content-types)). A text has LF line endings, whatever produced it: a CRLF becomes LF. A table stays a table from one step to the next: it becomes a text only where a text is expected, and is then written one line per row, the cells joined with `;`:

```text
psu01;PSU 1;ok;
psu02;PSU 2;failed;
```

- A [toText](../computes/to-text.html) ends each line with `;`, turns a `;` inside a cell into `,`, and a line break inside a cell into a space: each row is one line.
- `$0` of an [awk](./awk.html) source whose `input` is a reference to a table ends the line with `;`, except when that trailing `;` is its only one (typically a row of a single cell), and keeps a `;` and a line break inside a cell. A table referenced in a string field is rejected (`TABLE_INTERPOLATED`); a referenced text gives its lines as they are, with the same exception for a line whose only `;` is its last character.
- The `execute...` functions of an [awk](./awk.html#in-the-awk-source) source end each line with `;`, and keep a `;` and a line break inside a cell.
- A source with `executeForEachEntryOf` and a `json_array`, `json_array_extended` or custom `concatMethod` reads the table of an entry as `toText` writes it.

Only a conversion (`toTable`, `json2Table`, `json2List`, `xml2Csv`, an `awk` with `output: table`) turns text back into a table: if a compute appends `;42` to column 2, the cell holds `;42` at its end and the table keeps its columns. Add a column with [insertColumn](../computes/insert-column.html) or [duplicateColumn](../computes/duplicate-column.html).

## Where Sources Run in the Connector Lifecycle

This page describes the source execution that happens after a connector has passed detection.

MetricsHub runs sources in two recurring phases:

1. Discovery phase
   - `beforeAll` sources run first, if defined
   - all monitor `discovery` jobs run, or `simple` jobs when no discovery/collect split is defined
   - `afterAll` sources run last, if defined
2. Collect phase
   - `beforeAll` sources run first, if defined
   - all monitor `collect` jobs run, or `simple` jobs when no discovery/collect split is defined
   - `afterAll` sources run last, if defined

Discovery runs less often, so it is the right place for heavier inventory work. Collect runs repeatedly and should stay lightweight. Monitor jobs within a phase can run in parallel.

Within each source, source-level options are applied and then `computes` run in order.

## Source Ordering Within a Job

Sources inside one job run **sequentially, never in parallel**. Their order is derived automatically from the `${source::...}` references between them: a source always runs after the sources it references. The sources that reference no other source of the job run first, then those that reference only these, and so on; within each of these levels, the sources run in the order in which they are declared. The same applies within `beforeAll` and `afterAll`.

When the reference graph cannot express a required order (e.g. an implicit dependency on device state), force it with `executionOrder` on the job:

```yaml
collect:
  type: multiInstance
  executionOrder: [ reset, status, counters ]
  sources:
    reset: ...
    status: ...
    counters: ...
```

> [!WARNING]
> `executionOrder` must list **every** source of the job, each exactly once. A missing or unknown name makes the whole job fail. Prefer relying on automatic dependency ordering; no community connector currently needs `executionOrder`.

## Fan-Out with `executeForEachEntryOf`

Any source can be executed **once per row of another source's table**. This is the standard pattern for REST APIs where a collection endpoint returns links that must each be fetched:

```yaml
sources:
  members:
    # Table of members, one row each: <entry>;/redfish/v1/Chassis/1
    # (json2Table prepends an entry column, so the link is column 2)
    type: http
    path: /redfish/v1/Chassis
    computes:
    - type: json2Table
      entryKey: /Members
      properties: [ /@odata.id ]
  details:
    type: http
    path: $2                     # bound to column 2 of each row of "members"
    executeForEachEntryOf:
      source: ${source::members}
      concatMethod: json_array
```

For each row of the referenced table, the engine clones the enclosing source, replaces `$1`, `$2`, ... (**1-based** column references, `$$` escapes a literal `$`) in all its string properties (`path`, `commandLine`, `header`, ...), executes it, and concatenates the results:

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `source` | Yes | None | Reference to the source whose table drives the loop. It must be a source reference (`NOT_A_REFERENCE`: a hard-coded table belongs in a [static](./static.html) source) and a table: a text there is rejected (`TEXT_FEEDS_TABLE`). |
| `concatMethod` | No | `list` | How per-entry results are combined (see below). |
| `sleep` | No | None | Milliseconds to pause after each entry — throttles chatty APIs. |
| `maxParallel` | No | None (one entry at a time) | Maximum number of entries executed concurrently (capped at 50). Results are still concatenated in the row order. |

Entries run one at a time by default. Set `maxParallel` when each entry is slow and the target handles concurrent requests well, for example a WMI query that takes seconds per disk: with `maxParallel: 8`, 8 disks cost the time of one query instead of 8. `maxParallel` is ignored, and the entries run one at a time, when `sleep` is set, when the source has [`forceSerialization: true`](#forceserialization), or when the host is configured with `sequential: true`. Don't set it for devices that dislike bursts of requests.

`concatMethod` values:

- `list` — stack every entry's rows/text (classic table union).
- `json_array` — join the raw JSON results with commas and wrap them in `[ ... ]`, ready for a single `json2Table`.
- `json_array_extended` — like `json_array`, but merges the driving row's own columns into each JSON entry, so downstream computes can correlate result and origin.
- custom object `{ concatStart: "...", concatEnd: "..." }` — wrap each entry's raw result; both wrappers may themselves use `$n`.

With `list`, the result has the type of the source: a text for `http` or `commandLine` (the entries' texts joined with a line feed), a table for `snmpGet`, `wmi`, `sql`, ... (the entries' rows). With `json_array`, `json_array_extended` and a custom object, the result is text: an entry that returns a table contributes its text as [toText](../computes/to-text.html) writes it (see [Serialization Details](#serialization-details-you-must-know)).

> [!WARNING]
> A failed entry adds nothing to the result: `list` keeps the rows of the other entries, and `json_array` / `json_array_extended` still wrap the other results in `[ ... ]`. The source looks answered, so when it feeds the mapping of a `discovery` or `simple` job, the run is trusted and the instances of the failed entity are removed (see [When Instances Are Removed](../monitors-and-jobs.html#when-instances-are-removed)). Join the result back onto the inventory with a [`tableJoin`](./table-join.html) and a `defaultRightLine`, or set [`removalDelay`](../monitors-and-jobs.html#removaldelay) when no inventory exists.

See [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml) for extensive real usage of `json_array` and `json_array_extended`.

## `forceSerialization`

Every source (and detection criterion) accepts `forceSerialization: true`. It wraps the execution in a per-connector, per-host lock so that force-serialized operations of the same connector never run concurrently on the same host.

Use it only when the target device or agent genuinely cannot handle concurrent requests (single-session management controllers, fragile SNMP/IPMI stacks). If the lock cannot be acquired in time, the source silently yields an **empty table** — overuse degrades both performance and reliability.

## Minimal End-To-End Example

```yaml
beforeAll:
  interfaces:
    type: commandLine
    commandLine: "ip -o link show | awk -F': ' '{print $2}'"

monitors:
  network:
    simple:
      type: multiInstance
      sources:
        rxBytes:
          type: commandLine
          commandLine: cat /proc/net/dev
          computes:
          - type: awk
            output: table
            script: '/:/ { gsub(/:/, "", $1); print $1, $2 }'
      mapping:
        source: ${source::rxBytes}
        attributes:
          id: $1
          network.interface.name: $1
        metrics:
          system.network.io{network.io.direction="receive"}: $2
```

## Schema Note

Official schema: <https://www.schemastore.org/metricshub-connector.json>

> [!NOTE]
> Some properties used by production connectors and runtime code can evolve faster than SchemaStore snapshots. If you see a mismatch, validate against current connector usage and runtime behavior.

## Source Pages

- [beforeAll](./before-all.html)
- [afterAll](./after-all.html)
- [awk](./awk.html)
- [commandLine](./command-line.html)
- [copy](./copy.html)
- [eventLog](./event-log.html)
- [file](./file.html)
- [http](./http.html)
- [internalDbQuery](./internal-db-query.html)
- [ipmi](./ipmi.html)
- [ipmiRaw](./ipmi-raw.html)
- [ipmiSel](./ipmi-sel.html)
- [jmx](./jmx.html)
- [snmpGet](./snmp-get.html)
- [snmpTable](./snmp-table.html)
- [sql](./sql.html)
- [static](./static.html)
- [tableJoin](./table-join.html)
- [tableUnion](./table-union.html)
- [textUnion](./text-union.html)
- [wbem](./wbem.html)
- [wmi](./wmi.html)
