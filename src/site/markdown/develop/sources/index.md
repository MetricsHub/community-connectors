keywords: connector sources, source pipeline, table model, mapping
description: How source execution works in MetricsHub connectors and full source type reference.

# Sources

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## What A Source Produces

In MetricsHub connectors, a source produces a **table** or a text (`commandLine`, `http`, `file`, `ipmi`, `textUnion`, and `snmpGet` and `awk` without `output: table`, see the [content types](../computes/index.html#content-types)). A text is turned into a table by its computes where a table is read; a `${source::...}` reference in a string field (a value of a simple mapping, for instance) is replaced by the text. Internally, a table is a list of rows, where each row is a list of strings.

Most compute operations modify one table column at a time, which is why they usually require `column:`.

`mapping.source` is a reference to a source that ends in a table (anything else does not load, `NOT_A_REFERENCE`: a hard-coded table belongs in a [static](./static.html) source), and **each row creates one monitor instance** exported as one OpenTelemetry Resource (a `type: simple` mapping has no `source`, reads no table and maps a single instance, see [The Simple Mapping](../monitors-and-jobs.html#the-simple-mapping)):

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
- The `execute...` functions of an [awk](./awk.html#in-the-awk-source) source end each line with `;`, and keep a `;` and a line break inside a cell.
- A source with `executeForEachEntryOf` and a `json_array`, `json_array_extended` or custom `concatMethod` reads the table of an entry as `toText` writes it.

A table referenced in a string field (`${source::...}`) is rejected (`TABLE_INTERPOLATED`); a referenced text is taken as it is, without its final line feeds. An [awk](./awk.html) source whose `input` is a reference to a table reads it structured, as the `awk` compute does: `$0` is the cells joined with `FS`.

Only a conversion (`toTable`, `json2Table`, `json2List`, `xml2Csv`, an `awk` with `output: table`) or a source with `output: table` (`awk`, `snmpGet`) turns text back into a table: if a compute appends `;42` to column 2, the cell holds `;42` at its end and the table keeps its columns. Add a column with [insertColumn](../computes/insert-column.html) or [duplicateColumn](../computes/duplicate-column.html).

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

With `list`, the result has the type of the source: a text for `http`, `commandLine` or `snmpGet` (the entries' texts joined with a line feed), a table for `snmpTable`, `wmi`, `sql`, an `snmpGet` with `output: table`, ... (the entries' rows). With `json_array`, `json_array_extended` and a custom object, the result is text: an entry that returns a table contributes its text as [toText](../computes/to-text.html) writes it (see [Serialization Details](#serialization-details-you-must-know)).

> [!NOTE]
> With [`continueOnFailure: true`](#continueonfailure), a failed entry adds nothing to the result (without it, a failed entry makes the source fail): `list` keeps the rows of the other entries, and `json_array` / `json_array_extended` still wrap the other results in `[ ... ]`. The source then counts as not answered, so the jobs that read it do not remove the instances of the failed entity (see [When Instances Are Removed](../monitors-and-jobs.html#when-instances-are-removed)).

See [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml) for extensive real usage of `json_array` and `json_array_extended`.

## `forceSerialization`

Every source (and detection criterion) accepts `forceSerialization: true`. It wraps the execution in a per-connector, per-host lock so that force-serialized operations of the same connector never run concurrently on the same host.

Use it only when the target device or agent genuinely cannot handle concurrent requests (single-session management controllers, fragile SNMP/IPMI stacks). If the lock cannot be acquired in time, the source fails (see [`continueOnFailure`](#continueonfailure)) — overuse degrades both performance and reliability.

## `continueOnFailure`

Every source accepts `continueOnFailure: true|false`, `false` by default.

A source **fails** when its request is not executed:

- an exception, a timeout or an interruption;
- no configuration for its protocol on the host, or no extension for the source;
- an error answer of the protocol: an HTTP error status, a WMI or WBEM error (invalid class or namespace), an SQL error, an SNMP error.

An answer is not a failure, even an empty one: a command that prints nothing, an empty table, an `snmpGet` whose OID has no value, a command that exits with a non-zero code. A source that reads a failed source (a `copy`, a `tableJoin`, a `tableUnion`, a `${source::...}` reference) fails as well. The error says what failed and why, and is logged.

- **`false` (default):** a failure interrupts the processing.
  - In a monitor job (`discovery`, `collect`, `simple`), the computes of the source, the next sources of the job and the mapping are skipped. Discovery keeps the existing instances; collect leaves their metrics unset for this cycle.
  - In a [tool](../tools.html), the tool stops, and its result is the error, which the LLM receives.
  - With `executeForEachEntryOf`, a failed entry makes the source fail.
- **`true`:** the source gives the empty result of its type (an empty text for a text source, an empty table otherwise), its computes run (an `awk` runs its `BEGIN` and `END` blocks), and the job goes on. With `executeForEachEntryOf`, a failed entry adds nothing to the result. Either way, the source counts as not answered: the jobs that read it do not remove instances.

Set `continueOnFailure: true` on a source whose failure is part of the design, and on the sources of its job that it reads (their failure stops the job before it runs):

- the source feeds the right side of a [`tableJoin`](./table-join.html) with a `defaultRightLine`, or a [`tableUnion`](./table-union.html) of a monitor job: a missing part leaves the rest. Only with a blank `defaultRightLine` (the values of the missing rows stay unset): not the right side of a join whose `defaultRightLine` holds a value (`0`, `ok`, a label: "absent means none"), since a failure would publish that value for every row. Not the inputs of a union in a [tool](../tools.html): a failed input should give the LLM its error, not a partial or empty result. Not a source that the mapping (or the tool's result) also needs through anything else, such as the left side of a join, a login in `beforeAll`, or the only source of a union completed by hard-coded rows: its failure leaves nothing to map and must stop the job;
- the source has `executeForEachEntryOf`, and an entry may fail while the others answer. Not in a tool, unless it is an optional right side as above: a failed entry should give the LLM its error;
- the source only feeds other jobs (a source of the `enclosure` discovery that the other monitors read): the mapping of its job does not read it, directly or through other sources of the job, and its failure would skip that mapping for nothing.

Never set it on a source read, directly or through other sources, by an `awk` that prints a row on an empty input (a total of `0`, an `ok` status, a fallback instance from its `BEGIN` or `END` block): that row is right for an empty answer (no LUN: 0 bytes subscribed), not for a failure. Without the flag, a failure stops the job before the `awk` runs.

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
