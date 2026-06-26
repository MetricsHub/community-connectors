keywords: detection, sql, database, table serialization
description: Reference for SQL detection criterion and matching behavior on serialized result tables.

# sql (Detection Criterion)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When to Use

Use `sql` for connectors that target a database to collect metrics and verify the connectivity to the database with a simple SQL statement that will help identify the identity of the target (like the database vendor, or version, etc.)

> [!WARNING]
> The `sql` source and detection criterion are shared by all relational database connectors. Each connector must therefore verify that the user's JDBC connection really points to the intended database engine. For example, a connector for MySQL must confirm that the connection targets a MySQL server, and its detection query must be specific enough to succeed only on MySQL.

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: sql
      query: SELECT @@version_comment REGEXP 'mysql' AS is_mysql;
      expectedResult: 1
      errorMessage: Not a MySQL Server
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | - | Must be `sql`. |
| `query` | Yes | - | SQL query used for detection. Must be non-blank. |
| `database` | No | host config database | Optional database name to override user's configuration  |
| `expectedResult` | No | none | Regex matched against serialized SQL result. |
| `errorMessage` | No | none | Connector-authored failure context (for logs/reporting). |
| `forceSerialization` | No | `false` | Guarantees operations are performed sequentially against one host. |

## Runtime Behavior

SQL query results are handled as tables and serialized with semicolons/newlines before matching.

- No `expectedResult`: success if serialized result is non-empty.
- With `expectedResult`: case-insensitive regex match against serialized text.

See below example on how a SQL result set is converted to text before matching with `expectedResult`:

> [!TABS]
>
> - <span class="fa-regular fa-circle-check"></span> Criterion
>
>   ```yaml
>   - type: sql
>     query: SELECT version();
>     expectedResult: ^postgresql
>   ```
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | version |
>   | --- |
>   | PostgreSQL 9.3.10 on x86_64-unknown-linux-gnu, compiled by gcc (Ubuntu 4.8.2-19ubuntu1) 4.8.2, 64-bit |
>
> - <span class="fa-regular fa-file-lines"></span> Result As Text
>
>   ```text
>   PostgreSQL 9.3.10 on x86_64-unknown-linux-gnu, compiled by gcc (Ubuntu 4.8.2-19ubuntu1) 4.8.2, 64-bit;
>   ```
>
>   ✅ The criterion passes because the first serialized row matches `expectedResult: ^postgresql`. One matching row is enough for the criterion to pass.

## Recommended Pattern

- Use one short query that returns a stable boolean/sentinel (`1`, vendor keyword).
- Avoid joins/large scans in detection.
- If your query needs to target a specific "system" database instance, while the user may configure the monitoring of an application-dedicated instance, use the optional `database` override.

## Common Mistakes

- Returning no row (criterion fails when `expectedResult` is absent and result is empty).
- Regex that ignores semicolon-separated serialization for multi-column outputs.
- Using heavy operational queries instead of lightweight identity checks.

## Examples

Example in `database/PostgreSQL/PostgreSQL.yaml`:

```yaml
connector:
  detection:
    criteria:
    - type: sql
      query: SELECT (LOWER(version()) LIKE '%postgresql%')::int AS is_postgresql;
      expectedResult: 1
      errorMessage: Not a PostgreSQL Server.
```
