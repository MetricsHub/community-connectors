keywords: mapping, metrics, semconv, attributes, helper functions
description: Learn how to map source data to attributes/metrics, reuse semantic conventions, and apply mapping helper functions consistently.

# Mapping, Metrics, and Semconv

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

This page explains how raw source columns become structured telemetry exported as OpenTelemetry Resources and metrics.

## Mapping Block Overview

```yaml
mapping:
  source: ${source::monitors.fan.simple.sources.sensors}
  attributes:
    id: $1
    name: $2
    hw.parent.type: enclosure
    hw.parent.id: 0
  metrics:
    hw.status{hw.type="fan"}: $3
    hw.fan.speed: $4
  conditionalCollection:
    hw.fan.speed: $4
```

## From Table Rows to OpenTelemetry Resources

`mapping.source` resolves to a table.

For a `multiInstance` monitor, each row of that table is treated as one instance of the monitor type. At export time, that instance becomes one OpenTelemetry Resource.

- `attributes` populate the Resource attributes that identify and describe that instance.
- `metrics` define the metric values attached to that Resource.
- Metric labels written in the metric key, such as `hw.status{hw.type="fan"}`, are metric-specific attributes, not Resource attributes.

## One Row = One Monitor Instance

`mapping.source` must resolve to a source table.
For multi-instance jobs, **each row creates one instance** of the monitor, and that instance is exported as one OpenTelemetry Resource.

Example input table:

Here, `$1` through `$5` refer to the first through fifth columns of each row.

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Table View
>
>   | $1 | $2 | $3 | $4 | $5 |
>   | --- | --- | --- | --- | --- |
>   | fan01 | Fan A | ok | 10200 | Nominal |
>   | fan02 | Fan B | failed | 0 | Not spinning |
>
> - <span class="fa-regular fa-file-lines"></span> Serialized Text
>
>   ```text
>   fan01;Fan A;ok;10200;Nominal
>   fan02;Fan B;failed;0;Not spinning
>   ```

With mapping:

```yaml
attributes:
  id: $1
  name: $2
metrics:
  hw.status{hw.type="fan"}: $3
  hw.fan.speed: $4
```

two monitor instances are produced, one for `fan01`, one for `fan02`. In practice, this means two OpenTelemetry Resources are exported:

- Resource 1: attributes such as `id=fan01` and `name=Fan A`, with metrics attached from `$3` and `$4`
- Resource 2: attributes such as `id=fan02` and `name=Fan B`, with metrics attached from `$3` and `$4`

## Property Semantics

| Property | Purpose |
| --- | --- |
| `source` | Table used as mapping input. |
| `attributes` | Resource attributes exported on the OpenTelemetry Resource. |
| `metrics` | Metric expressions and values attached to that Resource. |
| `conditionalCollection` | Gate collection when key value is empty/invalid. |

## Defining Metric Metadata (`metrics:` Section)

The top-level `metrics:` section declares the **metadata** of each metric your connector emits — not its values (those come from `mapping.metrics`). A metric definition has exactly three properties:

```yaml
metrics:
  hw.fan.speed:
    description: Fan speed.
    type: Gauge
    unit: rpm
  hw.enclosure.energy:
    description: Energy consumed by the enclosure.
    type: Counter
    unit: J
  hw.status:
    description: 'Operational status: 1 (true) or 0 (false) for each of the possible states.'
    type:
      stateSet: [ degraded, failed, ok ]
```

| Property | Default | Description |
| --- | --- | --- |
| `unit` | `""` | Unit following OpenTelemetry/UCUM conventions (`Cel`, `J`, `By`, `rpm`, `1`, ...). |
| `description` | `""` | Human-readable description exported with the metric. |
| `type` | `Gauge` | Either an instrument enum — `Gauge`, `Counter`, `UpDownCounter` — or a state-set object (below). |

For status metrics, `type` takes the object form:

```yaml
type:
  stateSet: [ degraded, failed, ok ]   # the possible states
  output: UpDownCounter                # optional, default: UpDownCounter
```

Each state becomes a boolean time series (1 = active). Your `translate` computes must therefore produce exactly the state names declared in `stateSet` — see [Reuse and Configuration](reuse-and-configuration.html) for translation tables.

## Semconv Reuse Strategy

You rarely write `metrics:` definitions yourself. The connectors under `src/main/connector/semconv/` (`Hardware`, `System`, `Storage`, `Database`) are **metric metadata dictionaries** — pure `metrics:` maps aligned with OpenTelemetry semantic conventions. Inherit the relevant one:

```yaml
extends:
- ../../semconv/Hardware
```

and every `hw.*` metric you emit in `mapping.metrics` automatically carries the official unit, description, and type. Only declare a local `metrics:` entry when:

- you introduce a metric that no semconv dictionary defines (check them first — and check OpenTelemetry semantic conventions before inventing a name), or
- you deliberately need to override the inherited metadata.

## Metric Metadata Precedence

1. Connector-level `metrics` (usually inherited from a semconv connector via `extends`)
2. Monitor-level `metrics` override — each monitor may carry its own `metrics:` map with the same shape (only when needed)

Use monitor-level overrides sparingly and document why.

## Mapping Helper Functions

Frequently used helper functions include:

- `fakeCounter(value)`
- `rate(value)`
- `milliVolt2Volt(value)`
- `megaBit2Byte(value)`
- `mebiByte2Byte(value)`
- `megaHertz2Hertz(value)`
- `percent2Ratio(value)`
- `boolean(value)`
- `legacyLinkStatus(value)`

Example:

```yaml
metrics:
  hw.enclosure.energy: fakeCounter($7)
  hw.network.bandwidth.limit: megaBit2Byte($18)
```

## Labeling and Attribute Discipline

- Keep labels stable and semantically meaningful.
- Do not create ad-hoc labels that explode cardinality.
- Use existing key conventions before introducing new ones.

The full naming rules — domains, attribute-driven dimensions, vendor handling — are on [Metric and Attribute Naming](metric-naming.html).

## Recommended Pattern

- Normalize and filter in computes first.
- Keep mapping shallow and easy to review.
- Prefer explicit resource topology attributes (`hw.parent.*`) where relevant.

## Common Mistakes

- mapping directly from unnormalized vendor statuses
- using mutable display names as identifiers
- introducing new metric names where existing semconv names already apply
- forgetting that column positions change when computes alter table shape
