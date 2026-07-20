keywords: extends, constants, variables, translations, sudoCommands, header connector, inheritance, reuse
description: Connector-level building blocks for reuse and configuration: extends inheritance and merge rules, constants, connector variables, translation tables, and sudo commands.

# Reuse and Configuration

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

This page covers the connector-level building blocks that let connectors **share logic** (`extends`, constants, translations) and let users **configure behavior** (connector variables, sudo commands).

## Load-Time Resolution Order

When a connector is parsed, the engine resolves its building blocks in this order:

1. `extends` — parent connectors are merged in
2. `${var::name}` — connector variables are substituted (defaults or user-configured values)
3. `${source::...}` and other references are resolved to absolute paths
4. `${constant::name}` — constants are inlined, then the `constants` section is dropped

All of the above happens **once, at load time**. Runtime credential macros (`%{USERNAME}`, `%{PASSWORD}`, ...) are different: they are resolved at execution time, per request — see [References and Expressions](references-and-expressions.html).

## `extends`: Connector Inheritance

A connector can inherit from one or more parent connectors:

```yaml
extends:
- ../../semconv/Hardware          # metric metadata dictionary
- ../MIB2-header/MIB2-header      # shared detection + monitors
```

Paths are resolved **relative to the connector's own directory**, and `.yaml` is appended automatically. Parents may themselves extend other connectors (chained inheritance is fully resolved). The `extends` key is stripped from the compiled connector.

### Merge Rules

Parents are merged in list order, then the child is merged last — **the child always wins over all parents**, and a later parent wins over an earlier one. The merge is a structural deep merge:

| Node kind | Merge behavior |
| --- | --- |
| Objects (maps: `monitors`, `metrics`, `translations`, `sources`, `mapping.attributes`, ...) | Deep-merged **key by key**. Redefining one key overrides that entry only; sibling keys survive. |
| Arrays of objects (`detection.criteria`, `computes`, ...) | Child items are **appended after** the parent's items. |
| Arrays of scalars (`keys`, `appliesTo`, `sudoCommands`, ...) | Child array **replaces** the parent's array entirely. |
| Scalars | Child value overrides the parent's. |

> [!WARNING]
> Arrays of objects are **appended, never replaced**: if a parent source defines `computes`, your child's `computes` run *in addition to* the parent's — you cannot remove or reorder inherited criteria or computes, only add after them. If you need a genuinely different pipeline, do not inherit that subtree.

### Semconv Connectors

The files under `src/main/connector/semconv/` (`Hardware`, `System`, `Storage`, `Database`) contain **only a `metrics:` map** — no detection, no monitors. They are metric metadata dictionaries: unit, description, and instrument type for each standard metric name, aligned with OpenTelemetry semantic conventions.

Extend the relevant one so your metrics automatically carry the official metadata; only declare a local `metrics:` entry when you introduce a metric the semconv file does not define. See [Mapping, Metrics, and Semconv](mapping-metrics-semconv.html).

### Header Connectors

When several connectors share the same collection logic (e.g. the same SNMP tables or the same command parsing), factor it into a **header connector** — a partial connector holding the shared `detection.criteria`, `monitors`, and `translations`, not usable on its own. Each real connector then extends the header and adds only its identity and detection targeting:

```yaml
# MIB2.yaml
extends:
- ../../semconv/Hardware
- ../MIB2-header/MIB2-header
connector:
  displayName: MIB-2 Standard SNMP Agent
  platforms: SNMP
  detection:
    appliesTo: [ Network ]
    supersedes: [ ... ]
```

Headers are best **parameterized with constants**: the header references `${constant::...}` placeholders and each child supplies the values (see below). This is cleaner than overriding inherited sources.

Community examples: [MIB2-header](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/MIB2-header/MIB2-header.yaml) with [MIB2](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/MIB2/MIB2.yaml); [LinuxNetwork-header](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/LinuxNetwork/LinuxNetwork-header/LinuxNetwork-header.yaml) with [LinuxIPNetwork](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/LinuxNetwork/LinuxIPNetwork/LinuxIPNetwork.yaml).

## `constants`

Top-level map of reusable literals, referenced as `${constant::name}` anywhere in the connector:

```yaml
constants:
  GLOBAL_COMMAND_LINE: /sbin/ip a
  COLLECT_COMMAND_LINE: /sbin/ip -s link show dev ${attribute::id}
```

Constants are inlined at load time by plain text substitution, and the `constants` section is then removed from the compiled connector.

The flagship use case is parameterizing a header connector: `LinuxNetwork-header` runs `${constant::GLOBAL_COMMAND_LINE}`, and each child (`LinuxIPNetwork` with `ip`, `LinuxIfConfigNetwork` with `ifconfig`) supplies its own command through `constants`.

> [!NOTE]
> Constant substitution is a **single, non-recursive pass**: do not chain constants (a constant referencing another constant) and do not expect `${var::...}` inside a constant value to be expanded — variables are resolved *before* constants.

## `connector.variables`

Variables make a connector **user-configurable**. Declare them under `connector.variables`, each with a `description` and a `defaultValue`, and reference them as `${var::name}` anywhere in the connector or its embedded files:

```yaml
connector:
  displayName: Linux - Processes
  variables:
    matchName:
      description: Regular expression pattern to match process names for monitoring.
      defaultValue: .*
  detection:
    disableAutoDetection: true
    ...

monitors:
  process:
    simple:
      sources:
        processes:
          type: commandLine
          commandLine: /usr/bin/ps -e -o comm,args | grep -E "${var::matchName}"
```

Variables are resolved **once, at connector load time**:

- A default instance of the connector always exists with the `defaultValue`s applied, so forcing the connector (`connectors: [ +LinuxProcess ]`) works without any variable configuration.
- Users create additional configured instances in `metricshub.yaml` with `additionalConnectors`:

```yaml
resources:
  prod-web:
    attributes: { host.name: prod-web, host.type: linux }
    protocols:
      ssh: { username: monitor, password: "..." }
    additionalConnectors:
      systemdProcess:          # new connector instance id
        uses: LinuxProcess     # base connector
        variables:
          matchName: systemd
```

> [!IMPORTANT]
> Always provide a `defaultValue`. A variable with no default and no user-configured value is **not** substituted — the literal `${var::name}` string survives into the connector and typically breaks at runtime.

Community examples: [LinuxProcess](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/LinuxProcess/LinuxProcess.yaml), [LinuxService](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/LinuxService/LinuxService.yaml), [LinuxFile](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/LinuxFile/LinuxFile.yaml). Note that all of them pair variables with `disableAutoDetection: true`: a connector whose behavior depends on user input is usually meant to be selected explicitly.

## `translations`

Top-level map of translation tables, consumed by the [`translate`](computes/translate.html), [`arrayTranslate`](computes/array-translate.html), and [`perBitTranslation`](computes/translate-per-bit.html) computes via `${translation::TableName}`:

```yaml
translations:
  PhysicalDiskStatusTranslationTable:
    "3": ok
    "4": degraded
    "5": failed
    default: UNKNOWN
```

Authoring rules:

- Keys are matched **case-insensitively** against the cell value; quote numeric keys so YAML treats them as strings.
- The `default` key is the fallback for unmatched values (`translate` and `arrayTranslate` honor it; `perBitTranslation` ignores it).
- Translate into the exact state names your metric's `stateSet` declares (`ok`, `degraded`, `failed`), so mapping can use the column directly.
- Declare each table once and reference it from every source that needs it; tables inherited via `extends` merge key by key.

## `sudoCommands`

Some Linux/Unix commands need elevation. Declare the commands under top-level `sudoCommands` and prefix their invocations with the `%{SUDO:command}` macro:

```yaml
sudoCommands:
- /usr/bin/sensors

monitors:
  temperature:
    simple:
      sources:
        sensors:
          type: commandLine
          commandLine: "%{SUDO:/usr/bin/sensors} /usr/bin/sensors"
```

At runtime, `%{SUDO:/usr/bin/sensors}` expands to the configured sudo command (`sudo` by default) **only if** the user enabled sudo in their OS-command protocol configuration (`useSudo: true`) *and* whitelisted the command. Otherwise the macro silently expands to an **empty string** and the command runs without elevation — so the command line must remain valid without the prefix (note the pattern above: the macro is a prefix, the real command follows).

Community examples: [lmsensors](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/lmsensors/lmsensors.yaml), [LinuxMultipath](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/LinuxMultipath/LinuxMultipath.yaml), [SmartMonLinux](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/SmartMonLinux/SmartMonLinux.yaml).

## Common Mistakes

- Expecting a child connector to *remove* a parent's detection criterion or compute — object-arrays only append; restructure the hierarchy instead.
- Chaining constants or embedding `${var::}` in a constant value — substitution is a single pass.
- Declaring a variable without `defaultValue`, leaving `${var::name}` unresolved for users who force the connector without configuration.
- Forgetting to whitelist a command in `sudoCommands` while using `%{SUDO:...}` — the macro silently disappears and the command runs unprivileged.
- Duplicating metric definitions locally instead of extending the right `semconv/*` dictionary.
