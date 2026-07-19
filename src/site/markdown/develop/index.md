keywords: connector developer guide, metricshub, connector yaml, detection, sources, computes
description: Official developer guide for MetricsHub connectors. Learn structure, best practices, and validation workflow for building production-ready connectors.

# Connector Developer Guide

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

This guide is the canonical reference for contributing connectors to `metricshub-community-connectors`.

It explains:

- how connectors are organized and composed
- how MetricsHub selects and executes connectors at runtime
- how to design robust detection logic
- how to build efficient source/compute pipelines
- how to map attributes and metrics consistently with OpenTelemetry semconv
- how to validate changes with replay integration tests

> [!IMPORTANT]
> Treat this guide as implementation documentation, not conceptual marketing content.
> It is intentionally opinionated toward patterns that scale in real connector libraries.

## Audience

- New contributors adding a first connector
- Maintainers refactoring or extending existing connectors
- Reviewers checking correctness, consistency, and long-term maintainability
- AI coding agents

## Prerequisites

- Comfortable with YAML and regular expressions
- Basic understanding of monitoring pipelines and OpenTelemetry metric concepts
- Ability to run local validation commands and replay tests in the repository

## How MetricsHub Uses Connectors

Connector YAML in this repository is source material. When the project is built, connectors are compiled, shipped with MetricsHub, and loaded by the runtime. Connector YAML can be loaded dynamically with the `metricshub` CLI and with a specific configuration option.

To monitor a given host or resource with MetricsHub, users usually configure a _resource_ and its protocols, not a connector identifier. For example:

```yaml
resources:
  myHost:
    attributes:
      host.name: my-host
      host.type: Windows
    protocols:
      wmi:
        username: Administrator
        password: encryptedPassword
```

For each configured resource, MetricsHub executes connectors in three phases:

1. Detection: MetricsHub evaluates the loaded connectors and keeps only the applicable ones
2. Discovery: MetricsHub runs the expensive inventory logic less often
   - `beforeAll` if defined
   - all monitor `discovery` jobs, or `simple` jobs when no discovery/collect split is defined
   - `afterAll` if defined
3. Collect: MetricsHub runs the frequent metric collection logic repeatedly
   - `beforeAll` if defined
   - all monitor `collect` jobs, or `simple` jobs when no discovery/collect split is defined
   - `afterAll` if defined

Monitor jobs within a phase can run in parallel; the sources inside one job run sequentially, in dependency order. See [Detection](detection/index.html) for connector selection rules, [Monitors and Jobs](monitors-and-jobs.html) for the job model, and [Sources](sources/index.html) for source execution details.

## Core Mental Model: Connectors Are Table Pipelines

Most connector logic is table-oriented:

- most sources output a **table**
- most computes transform a **table**
- mapping consumes a **table**
- each mapped row becomes one monitor instance exported as one OpenTelemetry Resource

Internally, tables are represented as a **list of lists of strings**. The example below shows the same data in its internal form, as a table, and as serialized text:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Table View
>
>   | id | name | status | rpm |
>   | --- | --- | --- | --- |
>   | fan01 | Fan 1 | ok | 12500 |
>   | fan02 | Fan 2 | failed | 0 |
>
> - <span class="fa-solid fa-code"></span> Internal
>
>   ```json
>   [
>     ["fan01", "Fan 1", "ok", "12500"],
>     ["fan02", "Fan 2", "failed", "0"]
>   ]
>   ```
>
> - <span class="fa-regular fa-file-lines"></span> Serialized Text
>
>   When serialization is needed, the engine uses one row per line and semicolon-separated columns:
>
>   ```text
>   fan01;Fan 1;ok;12500
>   fan02;Fan 2;failed;0
>   ```

This is why many compute operations are column-based (`column: N`).

When a table is used in `mapping`, each row represents one instance of the monitor type. That instance is exported as an OpenTelemetry Resource with attributes from the mapping, and its metrics are attached to that Resource.

## Example: Minimal but Realistic Connector Shape

```yaml
# Reuse the hardware metrics definitions from Otel semantic conventions
extends:
- ../../semconv/Hardware

connector:
  displayName: Example Platform (REST)
  platforms: Example Platform
  reliesOn: Example REST API
  version: 1.0
  information: Monitors enclosure and fan sensors.
  # Detection phase
  detection:
    connectionTypes: [ remote ]
    appliesTo: [ Storage ]
    criteria:
    - type: http
      method: GET
      path: /api/version
      expectedResult: ^2\\.

# This is executed before all discovery, collect, and simple jobs
beforeAll:
  login:
    type: http
    method: POST
    path: /api/login

monitors:
  fan:
    # This is a simple job (will be executed in both discovery and collect phases)
    simple:
      type: multiInstance
      keys: [ id ]
      sources:
        # One source: an HTTP GET /api/fans
        # Response is like: { records: [ { "id": "0", "name": "Fan 0", "status": "ok", "rpm": 7230 } ] }
        fans:
          type: http
          method: GET
          path: /api/fans
          computes:
          # One post-processing step: convert the JSON result to a table
          # (json2Csv prepends an entry column, so /id lands in column 2)
          - type: json2Csv
            entryKey: /records
            properties: /id;/name;/status;/rpm
      # How we map results to OpenTelemetry Resources, Metrics, and Attributes
      mapping:
        source: ${source::fans} # Each row of this table will create a separate Otel Resource
        # This defines the Otel Attributes of each Otel Resource (from each line in the table)
        attributes:
          id: $2
          name: $3
        # This defines the Otel Metrics associated to the Otel Resources (from each line in the table)
        metrics:
          hw.status{hw.type="fan"}: $4 # hw.type="fan" is a Metric Attribute
          hw.fan.speed: $5

# This is executed after the entire discovery or collect phase is completed
afterAll:
  logout:
    type: http
    method: POST
    path: /api/logout
```
