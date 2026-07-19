keywords: connector structure, yaml structure, connector schema, connector anatomy
description: Full connector YAML anatomy with top-level sections, responsibilities, and recommended ordering for maintainable MetricsHub connectors.

# Connector Structure

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

Use this page as the authoritative map of connector YAML sections.

## Top-Level Sections

```yaml
extends: []
constants: {}

connector: {}
sudoCommands: []

metrics: {}
beforeAll: {}
monitors: {}
translations: {}
afterAll: {}
```

## How MetricsHub Executes This YAML

This YAML is compiled when the project is built, shipped with MetricsHub, and loaded by the runtime.

For one configured resource, MetricsHub uses the sections in this order:

1. Detection phase: `connector.detection` decides whether the connector applies to the resource.
2. Discovery phase: `beforeAll`, then every monitor `discovery` job or `simple` job, then `afterAll`.
3. Collect phase: `beforeAll`, then every monitor `collect` job or `simple` job, then `afterAll`.

Discovery runs less often and is the right place for heavy inventory work. Collect runs repeatedly and should stay lightweight. Monitor jobs within discovery and collect can run in parallel.

## Section Responsibilities

| Section | Required | Purpose |
| --- | --- | --- |
| `extends` | No | Reuse shared semconv/header connectors. |
| `constants` | No | Reusable literals and flags. |
| `connector` | Yes | Identity, metadata, detection, variables. |
| `sudoCommands` | No | Whitelisted elevated local commands. |
| `metrics` | No | Metric metadata defaults used by mappings. |
| `beforeAll` | No | Shared setup/login/prefetch sources executed before monitor jobs in discovery and collect phases. |
| `monitors` | Yes | Discovery/collection logic and mappings executed after the connector has passed detection. |
| `translations` | No | Central status/code translation tables. |
| `afterAll` | No | Cleanup/logout sources executed after monitor jobs in discovery and collect phases. |

`extends`, `constants`, `connector.variables`, `translations`, and `sudoCommands` are covered in depth in [Reuse and Configuration](reuse-and-configuration.html).

## `connector` Object (Core Metadata)

```yaml
connector:
  displayName: Example Device (SNMP)
  platforms:
  - SNMP
  - VendorX
  reliesOn: SNMP
  version: 1.0
  information: Monitors enclosure and network ports.
  variables: {}
  detection: {}
```

| Property | Required | Notes |
| --- | --- | --- |
| `displayName` | Yes | Human-facing connector name. |
| `platforms` | Yes | Platform grouping used in generated docs. |
| `reliesOn` | Recommended | Main instrumentation layer. |
| `version` | Recommended | Connector version. |
| `information` | Recommended | What is monitored and constraints. |
| `variables` | No | Optional defaults configurable by users. |
| `detection` | Yes | Criteria used to select connector. |

## `detection` Object

```yaml
detection:
  connectionTypes: [ remote, local ]
  appliesTo: [ Network ]
  supersedes: [ LegacyConnector ]
  criteria:
  - type: snmpGetNext
    oid: 1.3.6.1.2.1.2.2.1
```

## `monitors` Object

Each monitor can define either:

- `simple` job (single workflow executed in both discovery and collect), or
- `discovery` + `collect` jobs (two-phase workflow)

```yaml
monitors:
  network:
    keys: [ id ]
    simple:
      type: multiInstance
      sources: {}
      mapping: {}
```

> [!TIP]
> Prefer `simple` unless you need a true two-phase model with separate discovery semantics.

See [Monitors and Jobs](monitors-and-jobs.html) for the complete job model: `discovery`/`collect` splits, `multiInstance` vs `monoInstance`, instance identity (`keys`), `conditionalCollection`, and `legacyTextParameters`.

## Table Data Model (Important)

Connector pipelines are table-based end to end.

- A source typically outputs rows and columns.
- Computes generally transform rows/columns.
- Mapping expects a table and uses column references (`$1`, `$2`, ...).

Internally, a table is represented as `List<List<String>>`. The example below shows the same data in its internal form, as a logical table, and as serialized text:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Table
>
>   | $1 | $2 | $3 | $4 |
>   | --- | --- | --- | --- |
>   | eth0 | Uplink 1 | ok | 1000000000 |
>   | eth1 | Uplink 2 | degraded | 1000000000 |
>
> - <span class="fa-solid fa-code"></span> Internal
>
>   ```json
>   [
>     ["eth0", "Uplink 1", "ok", "1000000000"],
>     ["eth1", "Uplink 2", "degraded", "1000000000"]
>   ]
>   ```
>
> - <span class="fa-regular fa-file-lines"></span> Serialized Text
>
>   ```text
>   eth0;Uplink 1;ok;1000000000
>   eth1;Uplink 2;degraded;1000000000
>   ```

This serialization detail explains why operations that append semicolon-delimited strings can effectively materialize extra columns after parsing.

## `mapping` Block Inside Jobs

`mapping` is the bridge between a source table and exported telemetry. Each row of the mapped table represents one monitor instance. That instance is exported as one OpenTelemetry Resource, with attributes from `attributes` and metrics from `metrics`.

```yaml
mapping:
  source: ${source::ports}
  attributes:
    id: $1
    name: $2
  metrics:
    hw.status{hw.type="network"}: $3
    hw.network.io{direction="receive"}: $4
  conditionalCollection:
    hw.network.io{direction="receive"}: $4
```

## Recommended Ordering in Real Files

1. `extends`
2. `constants`
3. `connector`
4. optional `metrics`
5. optional `beforeAll`
6. `monitors`
7. optional `translations`
8. optional `afterAll`

This ordering improves review speed and consistency.

## Common Mistakes

- mixing monitor-specific constants into global section without reuse
- creating multiple near-identical sources instead of branching from `copy`
- writing mapping before normalizing values in computes
