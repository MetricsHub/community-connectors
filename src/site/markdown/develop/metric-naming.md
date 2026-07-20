keywords: metric naming, attribute naming, semantic conventions, opentelemetry, semconv, domains
description: The metric and attribute naming rules every MetricsHub connector must follow: domain-oriented names, attribute-driven dimensions, and OpenTelemetry alignment.

# Metric and Attribute Naming

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

MetricsHub is not a raw metric exporter: it is a **semantic normalization layer** aligned with OpenTelemetry. Connectors normalize vendor-specific data into a consistent model. These rules are mandatory for every connector.

All connectors:

- **MUST** use [OpenTelemetry semantic conventions](https://opentelemetry.io/docs/specs/semconv/) whenever they exist.
- **MUST** reuse existing MetricsHub metric names before introducing new ones.
- **MUST** extend conventions in a consistent, structured, attribute-driven way.
- **MUST NOT** invent metric names directly from SNMP MIBs, REST payloads, or vendor documentation.

Where to check what already exists:

1. The semconv dictionaries in this repository: `src/main/connector/semconv/` (`Hardware`, `System`, `Storage`, `Database`) — see [Reuse and Configuration](reuse-and-configuration.html).
2. The metrics emitted by existing connectors (search `src/main/connector/` for the measurement you need).
3. The [OpenTelemetry semantic conventions](https://opentelemetry.io/docs/specs/semconv/).

## Core Principles

### Metrics Are Domain-Oriented

Metric names follow a structured namespace: `<domain>.<subsystem>.<measurement>` — for example `hw.temperature`, `system.cpu.utilization`, `db.server.connections`, `storage.io`. The **first segment defines the domain**:

| Domain | Scope |
| --- | --- |
| `hw` | Physical hardware components |
| `system` | OS-level metrics |
| `process` | Process-level metrics |
| `db` | Database server metrics |
| `storage` | Storage systems and arrays |
| `http` | HTTP services |
| `tcp` / `udp` | Network protocol metrics |
| `firewall` | Firewall appliances |
| `ssl` | SSL/TLS components |
| `service` | Logical services (load balancers, app services) |

Never mix domains: process metrics do not belong in `system`, hardware metrics do not belong in `storage`.

### Attributes Over Metric Explosion

If you are about to create `hw.disk.read.bytes` and `hw.disk.write.bytes` — stop. Model the variant as an **attribute**:

```text
system.disk.io{disk.io.direction="read"}
system.disk.io{disk.io.direction="write"}
```

Attributes represent dimensions:

- Direction: `read`, `write`, `receive`, `transmit`
- State: `used`, `free`, `idle`
- Type: `physical_disk`, `gpu`, `controller`
- Protocol: `tcp`, `udp`, `nfs_v4`
- Limit type: `high.critical`, `low.degraded`
- Cache state: `hit`, `miss`

Metric names represent **what is measured**, not its variants.

### Reuse Before Extending

Before creating a new metric:

1. Search the semconv dictionaries and existing connectors.
2. Check OpenTelemetry semantic conventions.
3. Check whether an attribute can model your case.

Reusable measurement patterns: `*.limit`, `*.usage`, `*.utilization`, `*.operations`, `*.operation_time`, `*.io`, `*.errors`, `*.status`, `*.size`, `*.connections`, `*.sessions`.

## Domain Guidelines

### `hw` — Hardware

Physical components: CPU, GPU, memory modules, physical disks, fans, power supplies, batteries, enclosures, network interfaces, tape drives.

| Pattern | Meaning |
| --- | --- |
| `hw.status` | Component health (stateSet: `ok`, `degraded`, `failed`) |
| `hw.temperature` / `hw.temperature.limit` | Temperature and thresholds |
| `hw.power` / `hw.power.limit` | Power consumption and thresholds |
| `hw.errors` | Hardware error count |
| `hw.network.io` | Interface traffic |

Wrong: `dellFanCriticalTemperature`. Correct:

```text
hw.temperature{hw.type="fan"}
hw.temperature.limit{limit_type="high.critical", hw.type="fan"}
```

Vendor detail goes in attributes (`hw.status{hw.type="controller", netapp.storage.type="node"}`) — never in the metric name.

### `system` — Operating System

Use state/direction attributes, never name variants:

```text
system.cpu.time{system.cpu.state="user"}
system.memory.usage{system.memory.state="used"}
system.disk.io{disk.io.direction="read"}
system.filesystem.usage{system.filesystem.state="used"}
```

Do **not** create `system.cpu.user_time` or `system.cpu.idle_percent`.

### `process` — Processes

`process.cpu.time`, `process.memory.usage`, `process.disk.io{disk.io.direction="read"}`, `process.thread.count`. Never mix process metrics into `system`.

### `db` — Databases

Structured as `db.server.*` (models the database instance, not the host):

```text
db.server.connections
db.server.current_connections{db.connection.state="active"}
db.server.cache.operations{db.cache.state="hit"}
db.server.queries{db.query.state="slow"}
db.server.storage.io{db.io.direction="read"}
```

Vendor-specific extensions are acceptable **only** for vendor-unique functionality, with the vendor after `db.server.`: `db.server.mariadb.galera_replication.status`, `db.server.postgresql.replication.lag`. Never `mysql_connections_total`.

### `storage` — Storage Systems

SAN/NAS/arrays: `storage.io{storage.type="volume"}`, `storage.operations{storage.io.direction="read"}`, `storage.usage{storage.provisioning.state="used"}`, `storage.status`. Vendor variants via attributes: `storage.io{netapp.storage.type="aggregate"}`.

### `http`, `tcp`, `udp` — Network Services

Follow OpenTelemetry network conventions: `http.server.requests`, `http.server.errors`, `tcp.server.packets{tcp.method="SYN"}`, `udp.server.io`. Use attributes (`http.method.type`, `protocol.version`, `network.io.direction`) — never `http_get_requests`.

### `firewall`

`firewall.sessions`, `firewall.connections`, `firewall.vpn.io`, `firewall.ssl.io`, with `protocol`, `direction`, `tunnel.phase` attributes. Vendor between domain and measurement when structural: `firewall.palo_alto.vsys.sessions`.

## Vendor-Specific Metrics

1. **Prefer attributes**: if the vendor detail is a variant, model it as `storage.io{vendor.attribute="value"}`.
2. **Vendor namespace only for structural differences**: `db.server.mariadb.galera_replication.status`.
3. **Never encode the vendor in the root metric name**: `netapp_volume_read_latency` is wrong; `storage.latency{netapp.storage.type="volume"}` is right.

## Limits, Usage, Utilization

Strict semantic meanings — do not mix them:

| Metric | Meaning |
| --- | --- |
| `*.limit` | Upper bound of the corresponding metric: a total capacity (`system.memory.limit`, `system.filesystem.limit`), a link/design speed (`hw.network.bandwidth.limit`), or an alerting threshold qualified by `limit_type` (`hw.temperature.limit{limit_type="high.critical"}`) |
| `*.usage` | Absolute used value |
| `*.utilization` | Ratio between 0 and 1 (unit `1`) — always convert percentages, e.g. with `percent2Ratio($n)` |
| `*.size` | Total size |
| `*.operations` | Count of operations |
| `*.operation_time` | Time spent performing operations |
| `*.io` | Volume of data transferred |

## Attribute Naming

Attributes follow OpenTelemetry-style dotted notation: `system.cpu.state`, `db.cache.state`, `storage.io.direction`, `network.transport`, `limit_type`, `error.type`. Use `error.type` in non-hardware domains and `hw.error.type` for hardware errors. Keep casing and naming consistent with existing connectors.

## What NOT To Do

- Do not mirror SNMP OID or MIB entry names.
- Do not encode units in metric names (declare `unit` in the metric metadata instead).
- Do not create one metric per state — use a `stateSet` or state attribute.
- Do not duplicate direction in the metric name.
- Do not create vendor-prefixed root metrics.

## Decision Tree

When implementing a connector:

1. Identify the domain.
2. Search existing metric names (semconv dictionaries, existing connectors, OTel).
3. Reuse the measurement pattern.
4. Use attributes for variants.
5. Introduce a vendor namespace only if structurally required.
6. Validate against OpenTelemetry semantics.

When unsure, default to: a generic metric, rich attributes, no vendor prefix.

> [!IMPORTANT]
> If you find yourself copying a vendor metric name directly, you are almost certainly doing it wrong.
