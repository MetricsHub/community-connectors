keywords: detection, criteria, connector matching, developer guide
description: Detection lifecycle, execution semantics, and criterion selection strategy for MetricsHub connectors.

# Detection Criteria

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## Detection in the Runtime Lifecycle

Detection is the first phase of monitoring one resource. Connectors have already been compiled and loaded by MetricsHub; detection decides which of them actually apply to the configured resource.

Users usually configure a resource and its protocols, not a connector name. For example:

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

MetricsHub evaluates the loaded connectors against that resource and keeps only the applicable ones.

## How Connector Selection Works

A connector is considered applicable only if all of the following are true:

- the runtime can execute the connector with the protocols configured on the resource (for example, `commandLine` requires SSH, WMI, or WinRM, while `http` requires HTTP)
- `connector.detection.appliesTo` contains the resource `host.type` configured by the user
- every criterion in `connector.detection.criteria` succeeds
- the connector is not superseded by another applicable connector through `connector.detection.supersedes`

## Detection Properties Reference

```yaml
connector:
  detection:
    connectionTypes: [ remote, local ]
    appliesTo: [ Linux ]
    supersedes: [ GenericConnector ]
    disableAutoDetection: false
    onLastResort: temperature
    tags: [ hardware, linux ]
    criteria:
    - type: ...
```

| Property | Required | Description |
| --- | --- | --- |
| `connectionTypes` | No | `remote`, `local`, or both: whether the connector works against a remote host, the local machine MetricsHub runs on, or either. When omitted, defaults to **both**. |
| `appliesTo` | Yes | Resource `host.type` values the connector supports (e.g. `Linux`, `Windows`, `Network`, `Storage`, `OOB`). |
| `criteria` | Yes | Ordered list of checks; all must succeed. |
| `supersedes` | No | Connector IDs this connector replaces: when both match, the superseded one is dropped. |
| `disableAutoDetection` | No | `true` excludes the connector from automatic detection entirely; users must select it explicitly (`connectors: [ +YourConnector ]`). Use for connectors that depend on user-configured [variables](../reuse-and-configuration.html) or are intrusive. |
| `onLastResort` | No | A monitor type (e.g. `temperature`, `enclosure`). The connector is activated only if no other detected connector already discovers that monitor type — the fallback pattern for generic connectors (see [lmsensors](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/lmsensors/lmsensors.yaml)). |
| `tags` | No | Free-form labels (`hardware`, `linux`, `database`, ...). Users can include/exclude connectors in bulk with `#tag` / `!#tag` in their `connectors:` configuration; the `hardware` tag also drives the engine's hardware-specific post-processing. |

Individual criteria additionally accept `forceSerialization: true` — see the `forceSerialization` section of [Sources](../sources/index.html) for semantics.

## Execution Semantics

- No detection block, or an empty criteria list: connector does not match.
- At least one criterion failed: connector does not match.
- All criteria succeeded: connector matches.
- Criterion order matters for cost and troubleshooting readability.

## Result Matching Basics

Most criteria support `expectedResult`.
When present, it is evaluated as a regular expression.

When `expectedResult` is not provided, behavior depends on criterion type, but usually means "non-empty result is enough".

## Table Serialization Model

Several criteria (`wmi`, `wbem`, `sql`) evaluate query results as a serialized table:

- Internal table shape: `List<List<String>>`
- Serialization: one row per line, columns separated by semicolons (`;`)

`jmx` is the exception: its results are name-value pairs, serialized as `=`-separated lines — see [Detection by JMX](jmx.html).

For example, the below table:

| id | state | value |
| --- | --- | --- |
| disk0 | ok | 42 |
| disk1 | failed | 0 |

Will be serialized as the below text form, for evaluating the regular expression in `expectedResult`:

```text
disk0;ok;42
disk1;failed;0
```

This model is shared with source/compute pipelines, so semicolon manipulations can change effective columns when data is rematerialized as a table.

> [!TIP]
> Prefer regexes that explicitly account for semicolon separators and line boundaries when matching table-backed criteria.

## Ordering Strategy (Cheap to Expensive)

Recommended order inside `connector.detection.criteria`:

1. `deviceType` / `productRequirements`
2. Very cheap protocol probes (`snmpGetNext`, lightweight `http` status check)
3. Deeper semantic checks (`wmi`, `wbem`, `sql`, `jmx`, heavy `commandLine`)
