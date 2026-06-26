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

Several criteria (`wmi`, `wbem`, `sql`, `jmx`) evaluate query results as a serialized table:

- Internal table shape: `List<List<String>>`
- Serialization: one row per line, columns separated by semicolons (`;`)

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
