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

## Semconv Reuse Strategy

Use `extends` to inherit standard metric definitions from semconv connectors.

Typical pattern:

```yaml
extends:
- ../../semconv/Hardware
```

This keeps metric metadata consistent across connectors.

## Metric Metadata Precedence

1. Connector-level `metrics` defaults
2. Monitor-level `metrics` override (only when needed)

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

## Recommended Pattern

- Normalize and filter in computes first.
- Keep mapping shallow and easy to review.
- Prefer explicit resource topology attributes (`hw.parent.*`) where relevant.

## Common Mistakes

- mapping directly from unnormalized vendor statuses
- using mutable display names as identifiers
- introducing new metric names where existing semconv names already apply
- forgetting that column positions change when computes alter table shape
