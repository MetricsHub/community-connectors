keywords: sql source, jdbc query, database connectors
description: Reference for SQL source usage in JDBC-based connectors.

# sql (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `sql` when metrics come from relational databases (MySQL, PostgreSQL, MariaDB, and similar).

Each SQL query result row becomes a table row for mapping.

## Syntax

```yaml
sources:
  tableStats:
    type: sql
    query: |
      SELECT schemaname, relname, n_live_tup
      FROM pg_stat_user_tables
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `sql`. |
| `query` | Yes | None | SQL query to execute. |
| `database` | No | Connector/JDBC default | Optional database/schema target when supported by runtime. |
| `executeForEachEntryOf` | No | None | Fan-out execution context. |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

## Recommended Pattern

- Select only columns you map.
- Alias output columns consistently for readability.
- Keep heavy analytics in SQL only when it improves clarity and performance.

## Common Mistakes

- `SELECT *` on large system tables.
- Returning unstable row ordering without key attributes.
- Mixing time-unit conversions across SQL and compute layers.

## Community Examples

- [PostgreSQL](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/PostgreSQL/PostgreSQL.yaml)
- [MariaDB](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/MariaDB/MariaDB.yaml)
- [MySQL](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/MySQL/MySQL.yaml)

> [!NOTE]
> Some schema snapshots include additional SQL source fields not used by current community connectors. Use community connector patterns as the canonical style for new SQL connectors.
