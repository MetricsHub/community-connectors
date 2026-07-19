keywords: design principles, best practices, connector quality, performance
description: Practical design principles for writing efficient, robust, and maintainable MetricsHub connectors.

# Design Principles

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

This page defines the default engineering bar for connector contributions.

## 1. Determinism Over Cleverness

A connector should behave predictably across runs and environments.

- Use stable IDs, not display labels, for `attributes.id`.
- Keep detection based on deterministic signatures.
- Avoid brittle regexes tied to formatting noise.

## 2. Cost-Aware Detection

Detection should be ordered from cheapest to most expensive.

- cheap protocol/table existence check first
- authenticated/product-specific check next
- expensive data pulls last (if needed at all)

For HTTP detection, prefer status checks when body parsing is unnecessary.

## 3. Reuse Data, Do Not Re-fetch

Use source composition to minimize remote calls:

- `beforeAll` for login/bootstrap/shared data
- `copy` for branching
- `tableJoin` and `tableUnion` for composition
- `internalDbQuery` for dedup/aggregation when joins alone are not enough

## 4. Normalize Early

Perform status and unit normalization before mapping:

- `translate` for status/code dictionaries
- `convert` for format conversions
- `divide` / `multiply` for units
- `keepOnlyMatchingLines` / `excludeMatchingLines` early to reduce volume

## 5. Make Mapping Boring

Good mapping is mostly straightforward column assignment.

```yaml
mapping:
  source: ${source::sensors}
  attributes:
    id: $1
    name: $2
  metrics:
    hw.status{hw.type="fan"}: $3
    hw.fan.speed: $4
```

If mapping is doing heavy parsing, push that logic back into computes.

## 6. Prefer Modern Connector Style

For new or heavily revised connectors:

- prefer explicit source names (`ports`, `inventory`, `clusterInfo`)
- prefer `simple` jobs when two-phase behavior is not required
- prefer canonical type names (`commandLine`, `json2Csv`, `xml2Csv`)

## 7. Design for Reviewability

Reviewers should infer behavior quickly.

- Keep source pipelines short and coherent.
- Use comments only where they explain non-obvious transforms.
- Group related monitors and avoid copy-paste drift.

## 8. Validate with Replay Tests

No connector change is complete until replay test behavior is understood.

- update emulation inputs when behavior intentionally changes
- update expected output only for deliberate semantic changes
- keep expected payload stable and host-normalized

## Anti-Patterns To Avoid

- many scalar queries where one table query would do
- long replacement chains instead of translation tables
- IDs derived from mutable names
- hidden dependency on locale-specific output text
