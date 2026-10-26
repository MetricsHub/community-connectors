keywords: monitors, jobs, discovery, collect, simple, multiInstance, monoInstance, keys, instance identity
description: How monitors, jobs, and instance identity work: simple vs discovery/collect, multiInstance vs monoInstance, keys, conditionalCollection, and legacyTextParameters.

# Monitors and Jobs

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

A **monitor** defines how MetricsHub discovers and collects metrics for one type of component: `fan`, `disk`, `battery`, `enclosure`, `network`, etc. Each monitor produces **instances** — one per physical or logical component found — and each instance is exported as one OpenTelemetry Resource.

This page explains the job models (`simple` vs `discovery` + `collect`), instance identity (`keys`), collect modes (`multiInstance` vs `monoInstance`), and two additional mapping features (`conditionalCollection`, `legacyTextParameters`).

## Monitor Anatomy

```yaml
monitors:
  <monitorType>:            # e.g. fan, disk, battery
    keys: [ id ]            # optional, default: [ id ]
    # removalDelay: 15m     # optional, default: 0; only when no inventory exists (see removalDelay)
    metrics: {}             # optional, monitor-level metric metadata overrides
    simple: {}              # EITHER a simple job...
    discovery: {}           # ...OR a discovery job
    collect: {}             #    plus a collect job
```

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `keys` | No | `[ id ]` | Attributes that uniquely identify each instance. See [Instance Identity](#instance-identity-keys). |
| `removalDelay` | No | `0` | How long an instance is kept after the last run that returned it: a duration (`30s`, `15m`, `1h`, `1d`) or a number of seconds. See [`removalDelay`](#removaldelay). |
| `metrics` | No | None | Metric metadata (unit, description, type) overriding connector-level definitions for this monitor. |
| `simple` | One of | None | Single job executed in both the discovery and collect phases. |
| `discovery` / `collect` | One of | None | Two-phase model: inventory runs less often, metric collection runs on every cycle. |

## Choosing a Job Model

| Situation | Use |
| --- | --- |
| One request returns attributes **and** metrics together (typical REST APIs, SQL queries) | `simple` |
| Inventory is expensive (full SNMP table walk, WMI enumeration) but metrics are cheap to fetch separately | `discovery` + `collect` |
| Collection requires running a command **per instance** (e.g. `smartctl -H /dev/sda`) | `discovery` + `collect` with `type: monoInstance` |
| The source that returns the metrics omits some instances (idle, disconnected, not reporting) | `discovery` (inventory) + `collect` (metrics): a row missing from a `collect` job never removes the instance |

> [!TIP]
> Prefer `simple` unless you have a concrete reason to split. A `simple` job is easier to read, and MetricsHub still runs it at both discovery and collect frequencies.

## The `simple` Job

One pipeline produces both attributes and metrics; each mapped row creates (or refreshes) one instance and collects its metrics at the same time.

Because the job runs on every collect, an instance that disappears is removed at the next collect, when a trusted run no longer returns it. See [When Instances Are Removed](#when-instances-are-removed).

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

An instance that disappears is removed at the next discovery cycle (every 30 collects by default, about 1 hour), when a trusted discovery run no longer returns it. The `collect` job never removes instances. See [When Instances Are Removed](#when-instances-are-removed).

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

Collect gathers the frequently-changing metrics for the instances that discovery created. Its mode is selected with `type`:

```yaml
    collect:
      type: multiInstance   # or monoInstance
      sources: {}
      mapping: {}
```

When `type` is omitted, the engine defaults to **`monoInstance`**. Always declare it explicitly: an accidental `monoInstance` on a multi-instance monitor silently changes how (and how often) the job runs.

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

### When Instances Are Removed

From MetricsHub Community 3.9.08, a `discovery` or `simple` job removes the instances it no longer returns. At the end of each **trusted** run, the engine removes the instances of the job's monitor type, created by this connector, that the run did not create or refresh:

| Job | An instance that disappears is removed |
| --- | --- |
| `simple` | at the next collect |
| `discovery` | at the next discovery cycle (every 30 collects by default, about 1 hour) |
| `collect` | never: a missing row only leaves the instance without new values |

A run is trusted only when all of these hold:

- **Every source answered.** A source that had data and comes back empty (most failures return an empty result too) is retried once; if it is still empty, it has not answered for this run. This only covers the run in which the source first comes back empty: the next run finds no previous data, does not retry, and counts the empty result as answered. Sources read through `${source::...}` references (from `beforeAll` or another job) count too: one that did not answer the last time it ran makes the job untrusted.
- **At least one instance was mapped.** A job whose table is empty, or whose rows all lack the `keys` attributes, removes nothing.
- **The connector status is OK.**
- **The run finished in time**: no job timeout (`jobTimeout`), no interruption, and every job of the parallel pool completed.
- **No source is incremental**: a job that reads an [`eventLog`](sources/event-log.html) source or a [`file`](sources/file.html) source in `LOG` mode, directly, through its mapping source, or through source references, never removes its instances.

Otherwise the run only creates and refreshes instances, as before: a source that has just stopped answering, a job that maps nothing, a failing or stopped connector, or a timed-out run never removes anything. Neither does a monitor type excluded from the resource's monitors, since its job does not run.

A source that stays empty or keeps failing is only covered for one run. From the next run, it counts as answered: if the job still maps other rows (from another source of a [`tableUnion`](sources/table-union.html), for example), the instances built from the rows of that source are removed. When a source can stay empty for long, keep the rows of the instances with a [`defaultRightLine`](sources/table-join.html#writing-defaultrightline), or set [`removalDelay`](#removaldelay).

These instances are never removed:

- the endpoint host
- the `connector` monitors
- on connectors tagged `hardware`, the types that take part in missing-device detection: `battery`, `blade`, `cpu`, `disk_controller`, `enclosure`, `fan`, `gpu`, `memory`, `network`, `other_device`, `physical_disk`, `power_supply`, `robotics`, `tape_drive`. A vanished instance of these types is kept and reported missing (`hw.status{hw.type="<type>", state="present"}` = `0`). The other types of a `hardware` connector (`temperature`, `voltage`, `led`, `lun`, `logical_disk`, `vm`, ...) are removed like any other.

What this means for connector authors:

- The rules above only catch whole failures. A row dropped for any other reason looks exactly like an entity that disappeared, and its instance is removed: a filter on a state or a value, an inner `tableJoin` against a source that misses some entities, a failed fan-out entry. Build the rows that create the instances from an inventory: see [Build Instances from an Inventory](design-principles.html#9-build-instances-from-an-inventory).
- An unstable `id` no longer only duplicates instances: the old instance is removed and a new one is created at every run, which restarts its counters and `rate()` state.
- A removed instance is no longer exported; its series ends without a final data point. If the entity comes back, it is created again with fresh counters.

### `removalDelay`

`removalDelay` (monitor level, next to `keys`) keeps an instance for a given time after the last run that returned it:

```yaml
monitors:
  replication:
    keys: [ id ]
    removalDelay: 15m
    simple:
      # ...
```

- The value is a duration (`30s`, `15m`, `1h`, `1d`, or combined such as `1h30m`) or a number of seconds. The default `0` removes the instance at the first trusted run that misses it. A negative value is rejected when the connector is loaded.
- A trusted run removes the instance once the time since the last run that returned it exceeds the delay. The delay is wall-clock time, checked only at the end of a trusted run: a `discovery` job runs about once an hour by default, so a delay shorter than one discovery cycle keeps nothing. Use two discovery cycles or more (for example `2h`) to survive one missed cycle.
- It is inherited and can be overridden through [`extends`](reuse-and-configuration.html), and it is also available for the custom monitors of `metricshub.yaml`.
- MetricsHub versions older than 3.9.08 ignore it, so declaring it does not break a connector on an older agent.

Use `removalDelay` only when no inventory exists: entities defined by their activity (sessions, connected replicas, running queries), or as a stopgap until the connector reads an inventory.

## Job Properties Reference

| Property | Jobs | Required | Description |
| --- | --- | --- | --- |
| `sources` | all | Yes | Named sources forming the job's table pipeline. See [Sources](sources/index.html). |
| `mapping` | all | Yes | Turns the final table into instances, attributes, and metrics. See [Mapping, Metrics, and Semconv](mapping-metrics-semconv.html). |
| `type` | `simple`, `collect` | No | `multiInstance` or `monoInstance`. When omitted on a `collect` job, defaults to `monoInstance` — declare it explicitly in new connectors. |
| `executionOrder` | all | No | Array of source names forcing a specific order. By default the engine runs a job's sources sequentially, ordered by their `${source::...}` dependencies; use `executionOrder` only when a dependency is invisible to the engine, and list **every** source of the job. |

## Additional Mapping Features

### `conditionalCollection`

Only collect a metric when the referenced value is non-empty — typical when a device reports some sensors or counters only under certain conditions.

Declare it in the **`discovery`** (or `simple`) mapping: the availability check happens while discovering the instance, so the engine knows which metrics to collect for it. The metric's actual value stays in the `collect` mapping:

```yaml
    discovery:
      mapping:
        source: ${source::monitors.physical_disk.discovery.sources.source(1)}
        attributes:
          id: $1
        metrics:
          hw.physical_disk.size: $6
        conditionalCollection:
          hw.errors{hw.type="physical_disk"}: $9   # collect hw.errors only for disks reporting an error counter
    collect:
      type: multiInstance
      mapping:
        source: ${source::monitors.physical_disk.collect.sources.source(1)}
        attributes:
          id: $1
        metrics:
          hw.errors{hw.type="physical_disk"}: $9
```

See [WinStorageSpaces](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/WinStorageSpaces/WinStorageSpaces.yaml) for a real two-phase example, or [LinuxIpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/ipmi/LinuxIpmiTool/LinuxIpmiTool.yaml) for the `simple`-job form.

### `legacyTextParameters`

Free-text values attached to the instance, inherited from the legacy hardware connector model — most commonly `StatusInformation`, the human-readable explanation of the current status. Declared in the **`collect`** (or `simple`) mapping, alongside the metrics it explains:

```yaml
mapping:
  metrics:
    hw.status{hw.type="battery"}: $2
  legacyTextParameters:
    StatusInformation: $3
```

Use it for status detail text only; anything numeric or enumerable belongs in `metrics` or `attributes`.

## Common Mistakes

- Omitting `type` on the `collect` job of a multi-instance monitor — the engine then defaults to `monoInstance`, silently changing the execution model. State `multiInstance` or `monoInstance` explicitly.
- Forgetting to re-map `id` (or the other `keys`) in a `multiInstance` collect mapping, so no row matches any instance and no metric is ever collected.
- Mapping an unstable value (rotating index, display label) as `id`, which creates a new instance at every discovery cycle (from MetricsHub Community 3.9.08, the previous one is removed, so its counters restart every time).
- Using `monoInstance` with expensive sources on monitors that can have dozens of instances.
- Putting heavy inventory work in `collect` instead of `discovery` — collect runs on every cycle.
- Filtering on a state or a value (`Enabled` only, `up` only, non-zero readings only, `virsh list` without `--all`) in a `discovery` or `simple` job. The instance is removed as soon as its state changes, which hides the very failure the state should report. Keep every row and map the state.
- Joining the inventory with an inner `tableJoin` (no `defaultRightLine`) against a per-entity or optional source: an entity missing from the right table is removed. Keep the inventory on the left and add a `defaultRightLine`.
- Building the instances from a fan-out (`executeForEachEntryOf`) whose failed entry drops the row: the source still answers, the run is trusted, and the instances of that entity are removed. Join the result back onto the inventory.

## Community Examples

- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml) — two-phase monitors with `multiInstance` collect, translations, and `legacyTextParameters`
- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml) — `multiInstance` collect re-mapping `id`
- [SmartMonLinux](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/SmartMonLinux/SmartMonLinux.yaml) — `monoInstance` collect with `${attribute::...}` per-instance commands
- [PostgreSQL](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/PostgreSQL/PostgreSQL.yaml) — multi-attribute `keys`
