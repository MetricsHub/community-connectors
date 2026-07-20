keywords: connector sources, source pipeline, table model, mapping
description: How source execution works in MetricsHub connectors and full source type reference.

# Sources

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## What A Source Produces

In MetricsHub connectors, a source produces a **table**. Internally, this is a list of rows, where each row is a list of strings.

Most compute operations modify one table column at a time, which is why they usually require `column:`.

`mapping.source` also expects a table, and **each row creates one monitor instance** exported as one OpenTelemetry Resource:

- Row cells are mapped to attributes and metrics with `$1`, `$2`, `$3`, and so on.
- If your table has 20 rows, you get 20 instances for a `multiInstance` monitor.

Example logical table:

| id | name | status |
| --- | --- | --- |
| psu01 | PSU 1 | ok |
| psu02 | PSU 2 | failed |

Equivalent serialized form:

```text
psu01;PSU 1;ok
psu02;PSU 2;failed
```

## Serialization Details You Must Know

The engine often materializes/de-materializes tables from semicolon-separated text. This is the reason some transformations can look unusual but still work.

For example, if a compute appends `;42` to column 2, it can effectively create a new column after rematerialization.

> [!WARNING]
> This behavior is powerful but easy to abuse. Prefer explicit computes (`duplicateColumn`, `append`, `prepend`, `extract`, `json2Csv`) over fragile "inject a semicolon" tricks unless you truly need them.

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

Sources inside one job run **sequentially, never in parallel**. Their order is derived automatically from the `${source::...}` references between them: a source always runs after the sources it references. The same applies within `beforeAll` and `afterAll`.

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
    # (json2Csv prepends an entry column, so the link is column 2)
    type: http
    path: /redfish/v1/Chassis
    computes:
    - type: json2Csv
      entryKey: /Members
      properties: /@odata.id
  details:
    type: http
    path: $2                     # bound to column 2 of each row of "members"
    executeForEachEntryOf:
      source: ${source::monitors.enclosure.discovery.sources.members}
      concatMethod: json_array
```

For each row of the referenced table, the engine clones the enclosing source, replaces `$1`, `$2`, ... (**1-based** column references, `$$` escapes a literal `$`) in all its string properties (`path`, `commandLine`, `header`, ...), executes it, and concatenates the results:

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `source` | Yes | None | Reference to the source whose table drives the loop. |
| `concatMethod` | No | `list` | How per-entry results are combined (see below). |
| `sleep` | No | None | Milliseconds to pause after each entry — throttles chatty APIs. |

`concatMethod` values:

- `list` — stack every entry's rows/text (classic table union).
- `json_array` — join the raw JSON results with commas and wrap them in `[ ... ]`, ready for a single `json2Csv`.
- `json_array_extended` — like `json_array`, but merges the driving row's own columns into each JSON entry, so downstream computes can correlate result and origin.
- custom object `{ concatStart: "...", concatEnd: "..." }` — wrap each entry's raw result; both wrappers may themselves use `$n`.

See [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml) for extensive real usage of `json_array` and `json_array_extended`.

## `forceSerialization`

Every source (and detection criterion) accepts `forceSerialization: true`. It wraps the execution in a per-connector, per-host lock so that force-serialized operations of the same connector never run concurrently on the same host.

Use it only when the target device or agent genuinely cannot handle concurrent requests (single-session management controllers, fragile SNMP/IPMI stacks). If the lock cannot be acquired in time, the source silently yields an **empty table** — overuse degrades both performance and reliability.

## Minimal End-To-End Example

```yaml
beforeAll:
  interfaces:
    type: commandLine
    commandLine: ip -o link show | awk -F': ' '{print $2}'

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
            script: '/:/{gsub(/:/,"",$1); print $1 ";" $2}'
      mapping:
        source: ${source::monitors.network.simple.sources.rxBytes}
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
- [jmx](./jmx.html)
- [snmpGet](./snmp-get.html)
- [snmpTable](./snmp-table.html)
- [sql](./sql.html)
- [static](./static.html)
- [tableJoin](./table-join.html)
- [tableUnion](./table-union.html)
- [wbem](./wbem.html)
- [wmi](./wmi.html)
