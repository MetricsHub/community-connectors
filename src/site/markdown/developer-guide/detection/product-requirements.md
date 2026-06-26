keywords: detection, productRequirements, version gating
description: Reference for productRequirements detection criterion and compatibility notes.

# Detection by Product Requirements

## When to Use

Use `productRequirements` to gate a connector on minimum platform/runtime capabilities.
This is typically used to prevent loading connectors requiring newer MetricsHub features.

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
| `type` | Yes | - | `productRequirements`. |
| `engineVersion` | No | none | Minimum MetricsHub engine version required by the connector. |

## Runtime Behavior

- If `engineVersion` is absent/blank: criterion succeeds.
- If `engineVersion` is present: runtime compares required version against running engine version.
- Current comparison is strict (`required < running`), so equality is not treated as success.

## Recommended Pattern

- Use `productRequirements` as the first or second criterion (after `deviceType`).
- Keep version requirements minimal and justified.
