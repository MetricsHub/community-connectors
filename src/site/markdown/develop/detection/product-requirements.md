keywords: detection, productRequirements, version gating, engineVersion, kmVersion
description: Reference for the productRequirements detection criterion: engine version gating semantics and the legacy kmVersion field.

# Detection by Product Requirements

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When to Use

Use `productRequirements` to gate a connector on the MetricsHub engine version, preventing a connector that relies on newer engine features from being selected on older installations.

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: productRequirements
      engineVersion: 1.0.15
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `productRequirements`. |
| `engineVersion` | No | None | MetricsHub engine version required by the connector (numeric segments, e.g. `1.0.15`). |
| `kmVersion` | No | None | Legacy field inherited from PATROL Knowledge Module connectors. It is carried in the model but **never evaluated**: a criterion with only `kmVersion` always succeeds. |

## Runtime Behavior

- If `engineVersion` is absent or blank, the criterion succeeds.
- If `engineVersion` is present, the criterion succeeds only when the required version is **strictly lower** than the running engine version (`required < running`).

> [!WARNING]
> The comparison is strict: `engineVersion: 1.0.15` **fails** on an engine running exactly `1.0.15`. Until this changes, set `engineVersion` to the last version that does *not* support what you need (i.e. read it as "requires an engine newer than X"), and verify against the engine version you actually target.

## Recommended Pattern

- Use `productRequirements` as the first or second criterion (after `deviceType`): it is free to evaluate.
- Keep version requirements minimal and justified — gate only on features the connector genuinely uses.
- Do not add `kmVersion` to new connectors; it is documentation-only legacy syntax (see [Legacy and Compatibility](../legacy-and-compatibility.html)).

## Common Mistakes

- Expecting `engineVersion: X` to succeed on engine version `X` — equality fails (see above).
- Believing `kmVersion` enforces anything: it is ignored at runtime.
- Gating on a version "to be safe" without an actual feature dependency, which silently disables the connector for users on slightly older engines.

## Community Examples

- [HyperV](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/HyperV/HyperV.yaml) and [Redfish](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/Redfish/Redfish.yaml) carry legacy `kmVersion` criteria (always-succeeding markers inherited from their PATROL ancestry).
