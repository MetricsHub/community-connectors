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
