keywords: jmx source, mbeans, objectName, keyProperties
description: Reference for JMX source usage, including wildcard ObjectName and key property extraction.

# jmx (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `jmx` for Java-based products exposing metrics through MBeans.

This source is central for JVM/database connectors such as Cassandra.

## Syntax

```yaml
sources:
  cacheRequests:
    type: jmx
    objectName: org.apache.cassandra.metrics:type=Cache,scope=*,name=Requests
    attributes:
    - Count
    keyProperties:
    - scope
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `jmx`. |
| `objectName` | Yes | None | MBean ObjectName pattern. |
| `attributes` | Conditionally | `[]` | Attribute names to fetch. |
| `keyProperties` | Conditionally | `[]` | ObjectName key properties to emit as extra columns. |
| `resultContent` | No | Runtime-dependent | Compatibility property in schema snapshots; usually not needed for JMX source declarations. |
| `executeForEachEntryOf` | No | None | Fan-out execution context. |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Force raw serialization before next stages. |

At least one of `attributes` or `keyProperties` must be non-empty.

## Recommended Pattern

- Keep one logical metric family per source.
- Use wildcard ObjectNames (`scope=*`) plus `keyProperties` for multi-instance monitors.
- Normalize units in computes (`divide`, `multiply`) before mapping.

## Common Mistakes

- Fetching too many attributes in one source.
- Ignoring ObjectName dimensions and losing instance identity.
- Relying on unstable attribute naming across product versions without fallback.

## Community Examples

- [Cassandra](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/Cassandra/Cassandra.yaml)
