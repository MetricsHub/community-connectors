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
    - type: toTable
    - type: keepOnlyMatchingLines
      column: 3
      regExp: "(ok|degraded|failed)"
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `copy`. |
| `from` | Yes | None | Source reference to duplicate, or an inline table written as `;`-separated text. |
| `computes` | No | `[]` | Additional transforms applied after copy. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

A copy of a text is a text, even when empty. A copy of a table, or of an inline value, is a table, separate from the original: the computes of the copy do not change the original source.

In the example above, `rawSensors` ends with the text of an `awk` compute and only a copy reads it, so it stays text: the copy converts it with its own `toTable`, before `keepOnlyMatchingLines`. Without it, MetricsHub inserts that `toTable` and reports the `keepOnlyMatchingLines` of the copy (`TEXT_FEEDS_TABLE`, see the [content types](../computes/index.html#content-types)).

## Recommended Pattern

- Use `copy` to avoid rerunning expensive protocol calls.
- Keep the original source as the canonical raw dataset.
- Name copies by purpose (`statusView`, `capacityView`, `errorsView`).

## Common Mistakes

- Copying already over-transformed data instead of the raw source.
- Creating deep copy chains (`copy` of `copy` of `copy`) that hurt readability.
- Forgetting that copied tables preserve row/column order, including any quirks.

## Community Examples

- [IpmiTool](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/ipmi/IpmiOverLan/IpmiTool.yaml)
- [AMDRadeon](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/AMDRadeon/AMDRadeon.yaml)
