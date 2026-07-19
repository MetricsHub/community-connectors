keywords: quick start, connector workflow, new connector
description: End-to-end quick start to create a new MetricsHub connector with modern structure, mapping, and replay test validation.

# Quick Start

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

This page gives the shortest reliable path from idea to validated connector.

## Step 0 - Understand the Runtime Model

The connector YAML you write in this repository is compiled when the project is built. The compiled connectors are shipped with MetricsHub and loaded at runtime.

Users usually configure a resource and its protocols, not a connector name. MetricsHub then selects the applicable connectors automatically during detection, runs discovery less often for heavy inventory, and runs collect repeatedly for ongoing metric collection.

## Step 1 - Define Scope First

Before writing YAML, lock these decisions:

- target platform(s)
- protocol(s) you will use (`snmp`, `http`, `wmi`, `wbem`, `sql`, `commandLine`, etc.)
- resource types to expose (enclosure, fan, network, filesystem, db server, ...)
- metrics and attributes expected by users

> [!TIP]
> Start with one monitor and one high-value metric path.
> Expand only after first replay test passes.

## Step 2 - Create Connector Folder

Create a connector folder under:

```text
src/main/connector/<scope>/<ConnectorId>/
```

Typical scopes:

- `hardware`
- `system`
- `database`

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
  information: Monitors device sensors through REST endpoints.

  # Detection criteria must all match for the connector to be
  # activated on the targeted platform
  detection:
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

## Step 4.1 - Validate the Table You Expect

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

## Step 5 - Add Replay Integration Test Resources

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

## Step 6 - Review Checklist

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
