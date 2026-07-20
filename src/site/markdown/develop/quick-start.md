keywords: quick start, connector developer guide, connector yaml, new connector, connector workflow
description: The starting point for developing a MetricsHub connector: what a connector is, how MetricsHub runs it, and the shortest reliable path from idea to validated connector.

# Quick Start

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

This is the starting point of the **Connector Developer Guide**, the canonical reference for contributing connectors to `metricshub-community-connectors`. This page explains what a connector is, how MetricsHub executes it, and the shortest reliable path from idea to validated connector.

**Audience:** new contributors adding a first connector, maintainers extending existing ones, reviewers, and AI coding agents.

**Prerequisites:** comfort with YAML and regular expressions, basic understanding of monitoring pipelines and OpenTelemetry metric concepts, and the ability to run Maven builds and the `metricshub` CLI locally.

> [!IMPORTANT]
> Treat this guide as implementation documentation, not conceptual marketing content.
> It is intentionally opinionated toward patterns that scale in real connector libraries.

## What a Connector Is

A connector is a **single YAML file**. It lives in its own directory, and **the file is named after that directory**:

```text
src/main/connector/<category>/<ConnectorId>/<ConnectorId>.yaml
```

The file name (without `.yaml`) is the **connector ID** — the identifier used everywhere else: to force the connector on the command line (`-c +DiskPart`), to name its integration-test resources (`src/it/resources/DiskPart/`), and in `supersedes` lists. Typical categories are `hardware`, `system`, and `database`.

The connector directory can also hold **additional resources** used by the connector — AWK scripts, HTTP header files, embedded shell scripts or command input files — referenced from the YAML with `${file::<name>}` and shipped with the connector:

```text
src/main/connector/hardware/DiskPart/
├── DiskPart.yaml       # the connector itself (file name = directory name = connector ID)
├── diskPart.awk        # AWK script, referenced as ${file::diskPart.awk}
└── listVolume.txt      # command input file, referenced as ${file::listVolume.txt}
```

Connector YAML is source material: it is compiled when the project is built, shipped with MetricsHub, and loaded by the runtime. During development, the `metricshub` CLI can also load it directly from your source tree (see [Run and Debug Locally](run-and-debug.html)).

## How MetricsHub Runs Connectors

To monitor a host or resource, users configure a _resource_ and its protocols — usually not a connector name:

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

1. **Detection**: MetricsHub evaluates the loaded connectors and keeps only the applicable ones.
2. **Discovery**: the expensive inventory logic, run less often — `beforeAll` (if defined), all monitor `discovery` jobs (or `simple` jobs), then `afterAll` (if defined).
3. **Collect**: the frequent metric collection logic, run repeatedly — `beforeAll`, all monitor `collect` jobs (or `simple` jobs), then `afterAll`.

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

## Step 1 - Define Scope First

Before writing YAML, lock these decisions:

- target platform(s)
- protocol(s) you will use (`snmp`, `http`, `wmi`, `wbem`, `sql`, `commandLine`, etc.)
- resource types to expose (enclosure, fan, network, filesystem, db server, ...)
- metrics and attributes expected by users

> [!TIP]
> Start with one monitor and one high-value metric path.
> Expand only after first replay test passes.

## Step 2 - Create the Connector Directory and YAML File

Create the connector directory and its main YAML file, both named after your connector ID:

```text
src/main/connector/<category>/<ConnectorId>/<ConnectorId>.yaml
```

Add supporting files (AWK scripts, header files, ...) to the same directory as you need them.

## Step 3 - Write a Minimal Connector Skeleton

Use this baseline and adapt progressively:

```yaml
# Reuse metric definitions from semantic conventions
extends:
- ../../semconv/Hardware

# Connector properties
connector:
  displayName: Example Device (REST)
  platforms: Example Platform
  reliesOn: Example REST API
  version: 1.0
  information: Monitors device sensors through REST endpoints.

  # Detection criteria must all match for the connector to be
  # activated on the targeted platform
  detection:
    connectionTypes: [ remote ]
    appliesTo: [ Storage ]
    criteria:
    - type: http
      method: GET
      path: /api/version
      expectedResult: ^v?[0-9]

# This is executed before monitor jobs in a discovery or collect cycle
beforeAll:
  session:
    type: http
    method: POST
    path: /api/login

# Monitor types (or "classes")
monitors:
  # Find and monitor all enclosures
  enclosure:
    # "Simple" job (used in both discovery and collect when you do not split the workflow)
    simple:
      sources:
        # One single data source: HTTP GET /api/enclosure
        inventory:
          type: http
          method: GET
          path: /api/enclosure
          # Post-processing of the HTTP data source:
          # Convert the JSON body into a table
          computes:
          - type: json2Csv
            entryKey: /records
            properties: /id;/name;/model;/serial;/status
      # Mapping: one enclosure instance per row in ${source::inventory}
      # Each enclosure instance is exported as an OpenTelemetry Resource
      mapping:
        source: ${source::inventory}
        # Attributes attached to each resource
        # (json2Csv prepends an entry column, so the first property is $2)
        attributes:
          id: $2
          name: $3
          model: $4
          serial_number: $5
        # Metrics attached to the resource
        metrics:
          hw.status{hw.type="enclosure"}: $6

# This is executed after monitor jobs in a discovery or collect cycle
# Useful for session close and cleanup
afterAll:
  logout:
    type: http
    method: POST
    path: /api/logout
```

## Step 4 - Normalize Early

In source computes:

- filter irrelevant rows early (`keepOnlyMatchingLines`, `excludeMatchingLines`)
- normalize status values (`translate`)
- normalize units before mapping (`divide`, `multiply`, helper functions)

This keeps mapping declarative and easier to review.

## Step 5 - Validate the Table You Expect

Your `mapping.source` is a table. For each row, MetricsHub creates one monitor instance, and that instance is exported as one OpenTelemetry Resource.

Within that row, columns are referenced by position:

- `$1` = first column
- `$2` = second column
- `$3` = third column
- `$4` = fourth column

The example below shows the same source output as a table and as serialized text:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Table View
>
>   | $1 | $2 | $3 | $4 |
>   | --- | --- | --- | --- |
>   | fan01 | Fan A | ok | 10200 |
>   | fan02 | Fan B | failed | 0 |
>
>   In this table, `$1` is the fan identifier, `$2` the display name, `$3` the status, and `$4` the RPM.
>
> - <span class="fa-regular fa-file-lines"></span> Serialized Text
>
>   When serialization is needed, the engine uses one row per line and semicolon-separated columns:
>
>   ```text
>   fan01;Fan A;ok;10200
>   fan02;Fan B;failed;0
>   ```

Then mapping like:

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

produces two fan instances (`fan01`, `fan02`), one per row. For each row, the mapping reads `$1`, `$2`, `$3`, and `$4` from that row only, exports the mapped attributes on the corresponding OpenTelemetry Resource, and attaches the mapped metrics to that Resource.

## Step 6 - Add Replay Integration Test Resources

Before recording test resources, run the connector for real against your device or an emulator — see [Run and Debug Locally](run-and-debug.html).

Create:

```text
src/it/resources/<ConnectorId>/config/metricshub.yaml
src/it/resources/<ConnectorId>/emulation/
```

Then:

- add `<ConnectorId>` to the parameterized values in `src/it/java/org/metricshub/connector/it/ConnectorReplayIT.java`
- generate `expected/expected-gen.json` with the `writeExpectedJson` helper, review it, and rename it to `expected.json`

See [Integration Testing](integration-testing.html) for the full recording and generation workflow.

## Step 7 - Review Checklist

- detection is deterministic and cheap-first
- no avoidable duplicate remote calls
- mapping keys/labels are stable
- semconv metrics reused where possible
- connector passes replay IT expectations

## Common Mistakes

- building a very large connector before first passing test
- using unstable display strings as resource `id`
- overusing custom AWK when built-in computes are enough
- adding legacy aliases in new connector code

## Where to Go Next

- [Connector Structure](connector-structure.html) — the full YAML anatomy
- [Monitors and Jobs](monitors-and-jobs.html) — the job model in depth
- [Reuse and Configuration](reuse-and-configuration.html) — `extends`, constants, variables, translations
- [Detection](detection/index.html), [Sources](sources/index.html), [Computes](computes/index.html) — per-type references
- [Testing and Contributing](testing-and-contributing.html) — from local runs to a merged pull request
