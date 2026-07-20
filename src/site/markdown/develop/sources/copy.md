keywords: copy source, source reuse, pipeline branching
description: Reference for copy source, used to branch a source table without re-collecting data.

# copy (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `copy` to duplicate an existing source table and apply a different compute pipeline.

This is the cleanest way to branch one expensive dataset into multiple monitor-specific transformations.

## Syntax

```yaml
sources:
  rawSensors:
    type: ipmi
    computes:
    - type: awk
      script: ${file::sdr_formatter.awk}

  sensorStatus:
    type: copy
    from: ${source::monitors.sensor.collect.sources.rawSensors}
    computes:
    - type: keepOnlyMatchingLines
      column: 3
      regExp: "(ok|degraded|failed)"
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `copy`. |
| `from` | Yes | None | Source reference or inline serialized table to duplicate. |
| `computes` | No | `[]` | Additional transforms applied after copy. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

## Recommended Pattern

- Use `copy` to avoid rerunning expensive protocol calls.
- Keep the original source as the canonical raw dataset.
- Name copies by purpose (`statusView`, `capacityView`, `errorsView`).

## Common Mistakes

- Copying already over-transformed data instead of the raw source.
- Creating deep copy chains (`copy` of `copy` of `copy`) that hurt readability.
- Forgetting that copied tables preserve row/column order, including any quirks.

## Community Examples

- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/IpmiTool/IpmiTool.yaml)
- [AMDRadeon](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/AMDRadeon/AMDRadeon.yaml)
