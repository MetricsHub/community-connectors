keywords: detection, jmx, mbean
description: Reference for the JMX detection criterion.

# Detection by JMX

## When to Use

Use `jmx` when connector eligibility is tied to a specific MBean/object name and attribute set.
Typical usage: Java middleware and databases exposing JMX (for example Cassandra).

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: jmx
      objectName: org.apache.cassandra.metrics:type=Storage,name=Load
      attributes:
      - Count
      expectedResult: ^[0-9]
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | - | `jmx`. |
| `objectName` | Yes | - | MBean object name/pattern to query. Must be non-blank. |
| `attributes` | Yes | - | List of attributes read from the MBean. |
| `expectedResult` | No | none | Regex matched against serialized JMX result. |
| `errorMessage` | No | none | Connector-authored failure context (for logs/reporting). |
| `forceSerialization` | No | `false` | Guarantees operations are performed sequentially against one host. |

## Runtime Behavior

JMX query results are treated as a table (`List<Map<String,String>>`) and serialized as `=`-separated name-value pairs before matching.

- No `expectedResult`: success if serialized result is non-empty.
- With `expectedResult`: case-insensitive regex match.

See below example on how a JMX result is converted to text before matching with `expectedResult`:

> [!TABS]
>
> - <span class="fa-regular fa-circle-check"></span> Criterion
>
>   ```yaml
>   - type: jmx
>     objectName: org.apache.cassandra.metrics:type=Storage,name=Load
>     attributes:
>     - Count
>     - Unit
>     expectedResult: Count=[0-9]+
>   ```
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | Count | Unit |
>   | --- | --- |
>   | 123456 | bytes |
>
> - <span class="fa-regular fa-file-lines"></span> Result As Text
>
>   ```text
>   Count=123456
>   Unit=bytes
>   ```
>
>   ✅ The criterion passes because the serialized text contains a line that matches `expectedResult: Count=[0-9]+`.

## Recommended Pattern

- Query one deterministic MBean for detection.
- Request only required attributes.
- Match stable numeric or enum-like values rather than free text.

## Common Mistakes

- Using too many attributes in detection when one is enough.
- Matching volatile values (timestamps, counters with changing format).
- Confusing detection criteria with data collection monitors.

## Examples

Community example (`database/Cassandra/Cassandra.yaml`):

```yaml
connector:
  detection:
    criteria:
    - type: jmx
      objectName: org.apache.cassandra.metrics:type=Storage,name=Load
      attributes:
      - Count
      expectedResult: ^[0-9]
```
