keywords: legacy syntax, compatibility, aliases, migration
description: Canonical versus legacy connector syntax, compatibility notes, and practical migration guidance.

# Legacy and Compatibility

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

The connector library contains historical syntax variants.
This page explains what to use now and how to migrate safely.

> [!IMPORTANT]
> New connectors should use canonical modern syntax.
> Legacy forms are documented to maintain existing connectors safely.

## Canonical vs Legacy Forms

| Area | Canonical | Legacy Variant(s) | Recommendation |
| --- | --- | --- | --- |
| Detection type | `commandLine` | `commandline` | Use `commandLine` in new code. |
| Compute type | `json2Csv` | `json2csv` | Use `json2Csv` in new code. |
| Compute type | `xml2Csv` | `xml2csv` | Use `xml2Csv` in new code. |
| Compute type | `keepOnlyMatchingLines` | `KeepOnlyMatchingLines` | Use canonical casing. |
| TableJoin WBEM | `keyType: Wbem` | `isWbemKey: true` | Prefer `keyType`; keep legacy only when needed. |
| HTTP result content | `http_status` | `httpStatus` (older docs) | Use `http_status` in docs and new connectors. |

## Rare/Legacy Features Still Documented

The guide includes low-usage/legacy constructs for completeness:

- source types: `eventLog`, `file`
- compute types: `encode`, `decode`

They are not preferred for new connectors unless there is a strong compatibility reason.

## Migration Strategy

1. Normalize one category at a time (types, then fields, then expressions).
2. Keep behavior equivalent while refactoring.
3. Use replay IT to verify no unintended telemetry changes.
4. Document any intentional output changes in PR description.

## Example Migration

Before:

```yaml
- type: commandline
```

After:

```yaml
- type: commandLine
```

Before:

```yaml
- type: json2csv
```

After:

```yaml
- type: json2Csv
```

## Compatibility Review Checklist

- canonical names used in modified sections
- no hidden semantic changes in mapping values
- replay expected output updated only when intended
- legacy syntax retained only where justified
