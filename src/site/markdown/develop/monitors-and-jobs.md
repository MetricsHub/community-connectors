keywords: monitors, jobs, discovery, collect, simple, multiInstance, monoInstance, keys, instance identity
description: How monitors, jobs, and instance identity work: simple vs discovery/collect, multiInstance vs monoInstance, keys, conditionalCollection, and legacyTextParameters.

# Monitors and Jobs

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

A **monitor** defines how MetricsHub discovers and collects metrics for one type of component: `fan`, `disk`, `battery`, `enclosure`, `network`, etc. Each monitor produces **instances** — one per physical or logical component found — and each instance is exported as one OpenTelemetry Resource.

This page explains the job models (`simple` vs `discovery` + `collect`), instance identity (`keys`), collect modes (`multiInstance` vs `monoInstance`), and the collect-only mapping features (`conditionalCollection`, `legacyTextParameters`).

## Monitor Anatomy

```yaml
monitors:
  <monitorType>:            # e.g. fan, disk, battery
    keys: [ id ]            # optional, default: [ id ]
    metrics: {}             # optional, monitor-level metric metadata overrides
    simple: {}              # EITHER a simple job...
    discovery: {}           # ...OR a discovery job
    collect: {}             #    plus a collect job
```

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `keys` | No | `[ id ]` | Attributes that uniquely identify each instance. See [Instance Identity](#Instance_Identity:_keys). |
| `metrics` | No | None | Metric metadata (unit, description, type) overriding connector-level definitions for this monitor. |
| `simple` | One of | None | Single job executed in both the discovery and collect phases. |
| `discovery` / `collect` | One of | None | Two-phase model: inventory runs less often, metric collection runs on every cycle. |

## Choosing a Job Model

| Situation | Use |
| --- | --- |
| One request returns attributes **and** metrics together (typical REST APIs, SQL queries) | `simple` |
| Inventory is expensive (full SNMP table walk, WMI enumeration) but metrics are cheap to fetch separately | `discovery` + `collect` |
| Collection requires running a command **per instance** (e.g. `smartctl -H /dev/sda`) | `discovery` + `collect` with `type: monoInstance` |

> [!TIP]
> Prefer `simple` unless you have a concrete reason to split. A `simple` job is easier to read, and MetricsHub still runs it at both discovery and collect frequencies.

## The `simple` Job

One pipeline produces both attributes and metrics; each mapped row creates (or refreshes) one instance and collects its metrics at the same time.

```yaml
monitors:
  fan:
    simple:
      sources:
        fans:
          type: http
          path: /api/fans
          computes:
          - type: json2Csv
            entryKey: /records
            properties: /id;/name;/status;/rpm
      mapping:
        source: ${source::fans}
        attributes:
          id: $2
          name: $3
        metrics:
          hw.status{hw.type="fan"}: $4
          hw.fan.speed: $5
```

## The `discovery` Job

Discovery inventories the components: it identifies instances and sets their **attributes** (identity, model, topology). It runs less often than collect.

```yaml
monitors:
  enclosure:
    discovery:
      sources:
        source(1):
          type: snmpTable
          oid: 1.3.6.1.2.1.33.1.1
          selectColumns: "1,2,3,5"
      mapping:
        source: ${source::monitors.enclosure.discovery.sources.source(1)}
        attributes:
          id: $4
          vendor: $1
          model: $2
          type: UPS
          name: "${awk::sprintf(\"Enclosure: (%s %s)\", $1, $2)}"
```

Conventions observed across the connector library:

- `id` is the stable technical identifier (serial number, device index, WWN) — it must not change between cycles.
- `name` is the human-facing label, often built with `${awk::sprintf(...)}`.
- `hw.parent.type` (and `hw.parent.id` when needed) attach the instance to its parent in the hardware topology; omit for top-level monitors like `enclosure`.
- Attributes starting with `__` (e.g. `__display_id`, `__device_type_option`) are internal: they are available to later jobs via `${attribute::...}` but are not exported.
- A discovery `mapping` may also set slowly-changing metrics (e.g. `hw.temperature.limit` thresholds) that do not need collection on every cycle.

## The `collect` Job

Collect gathers the frequently-changing metrics for the instances that discovery created. It must declare its mode with `type`:

```yaml
    collect:
      type: multiInstance   # or monoInstance
      sources: {}
      mapping: {}
```

### `multiInstance`: one run for all instances

The job executes **once**; its final table must contain **one row per instance**. The `mapping` re-maps the key attributes (by default `id`) so the engine can match each row to the right discovered instance:

```yaml
monitors:
  logical_disk:
    discovery:
      # ... maps attributes including id: $1
    collect:
      type: multiInstance
      sources:
        source(1):
          type: commandLine
          commandLine: CHCP 437&&DISKPART.EXE /S ${file::listVolume.txt}
          computes:
          - type: awk
            script: ${file::diskPart.awk}
            keep: ^MSHW;
            separators: ;
            selectColumns: 2,8
          - type: duplicateColumn
            column: 2
          - type: translate
            column: 2
            translationTable: ${translation::LogicalDiskTranslationTable}
      mapping:
        source: ${source::monitors.logical_disk.collect.sources.source(1)}
        attributes:
          id: $1              # matches rows to instances discovered with the same id
        metrics:
          hw.status{hw.type="logical_disk"}: $2
        legacyTextParameters:
          StatusInformation: $3
```

Rows whose key values match no discovered instance are ignored; instances with no matching row simply get no new metric values this cycle.

### `monoInstance`: one run per instance

The job executes **once for each discovered instance**. Sources can inject that instance's attributes with `${attribute::<name>}` — this is the mode to use when collection requires a per-device command or request:

```yaml
monitors:
  physical_disk:
    discovery:
      # ... maps attributes including id (e.g. /dev/sda) and __device_type_option
    collect:
      type: monoInstance
      sources:
        source(1):
          type: commandLine
          commandLine: "/usr/sbin/smartctl -H ${attribute::id} ${attribute::__device_type_option}"
          computes:
          - type: awk
            script: "${file::physical_disk_smart_health.awk}"
            keep: ^MSHW;
            separators: ;
            selectColumns: 2
          - type: translate
            column: 1
            translationTable: "${translation::PhysicalDiskPredictedFailureTranslationTable}"
      mapping:
        source: ${source::monitors.physical_disk.collect.sources.source(1)}
        metrics:
          hw.status{hw.type="physical_disk", state="predicted_failure"}: $1
```

Because the run is already bound to one instance, the mapping does not need to re-map `id`.

> [!WARNING]
> `monoInstance` multiplies the number of requests by the number of instances. Keep the per-instance sources minimal, and prefer `multiInstance` whenever a single bulk query can return all instances at once.

## Instance Identity: `keys`

`keys` (monitor level, default `[ id ]`) defines which attributes uniquely identify an instance. The engine uses it to:

- match `multiInstance` collect rows to discovered instances
- recognize the same instance across discovery cycles (instead of creating duplicates)

Use several keys when one attribute is not unique by itself:

```yaml
monitors:
  db_session:
    keys: [ db.user.name, db.server.application_name ]
```

Every attribute listed in `keys` must be mapped in the discovery (or `simple`) `mapping.attributes`, and re-mapped in a `multiInstance` collect `mapping.attributes`.

## Job Properties Reference

| Property | Jobs | Required | Description |
| --- | --- | --- | --- |
| `sources` | all | Yes | Named sources forming the job's table pipeline. See [Sources](sources/index.html). |
| `mapping` | all | Yes | Turns the final table into instances, attributes, and metrics. See [Mapping, Metrics, and Semconv](mapping-metrics-semconv.html). |
| `type` | `simple`, `collect` | Yes for `collect` | `multiInstance` or `monoInstance`. Required on `collect` jobs; optional on `simple` jobs (many connectors declare `type: multiInstance` there for clarity). |
| `executionOrder` | all | No | Array of source names forcing a specific order. By default the engine runs a job's sources sequentially, ordered by their `${source::...}` dependencies; use `executionOrder` only when a dependency is invisible to the engine, and list **every** source of the job. |

## Collect-Only Mapping Features

### `conditionalCollection`

Only collect a metric when the referenced value is non-empty. Typical when a device reports some sensors only under certain conditions:

```yaml
mapping:
  source: ${source::monitors.temperature.collect.sources.source(1)}
  metrics:
    hw.temperature: $5
  conditionalCollection:
    hw.temperature: $5   # skip hw.temperature when column 5 is empty
```

### `legacyTextParameters`

Free-text values attached to the instance, inherited from the legacy hardware connector model — most commonly `StatusInformation`, the human-readable explanation of the current status:

```yaml
mapping:
  metrics:
    hw.status{hw.type="battery"}: $2
  legacyTextParameters:
    StatusInformation: $3
```

Use it for status detail text only; anything numeric or enumerable belongs in `metrics` or `attributes`.

## Common Mistakes

- Declaring a `collect` job without `type` — always state `multiInstance` or `monoInstance`.
- Forgetting to re-map `id` (or the other `keys`) in a `multiInstance` collect mapping, so no row matches any instance and no metric is ever collected.
- Mapping an unstable value (rotating index, display label) as `id`, which creates duplicate instances at every discovery cycle.
- Using `monoInstance` with expensive sources on monitors that can have dozens of instances.
- Putting heavy inventory work in `collect` instead of `discovery` — collect runs on every cycle.

## Community Examples

- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml) — two-phase monitors with `multiInstance` collect, translations, and `legacyTextParameters`
- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml) — `multiInstance` collect re-mapping `id`
- [SmartMonLinux](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/SmartMonLinux/SmartMonLinux.yaml) — `monoInstance` collect with `${attribute::...}` per-instance commands
- [PostgreSQL](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/PostgreSQL/PostgreSQL.yaml) — multi-attribute `keys`
