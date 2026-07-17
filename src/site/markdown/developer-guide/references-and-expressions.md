keywords: references, expressions, source reference, translation reference, protocol reference
description: Complete reference syntax for source/file/translation/constants/protocol expressions used in MetricsHub connector YAML.

# References and Expressions

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

Connectors use references to wire data across sections and runtime contexts.

## Source References

Use `${source::...}` to reference a source output table.

```yaml
leftTable: ${source::monitors.network.discovery.sources.ports}
rightTable: ${source::monitors.network.discovery.sources.aliases}
```

### Relative vs Absolute

- Prefer absolute paths when crossing monitor/job boundaries.
- Relative forms are acceptable for local same-job references.

## Column and Entry References

Column references are positional and 1-based:

```yaml
attributes:
  id: $1
  name: $2
```

These positions refer to the current table shape at that pipeline stage.

- `$1` = first column of the current row
- `$2` = second column of the current row
- `$3` = third column of the current row

If computes add, remove, or reorder columns, these references must be updated accordingly.

The example below shows the same row as a table and as serialized text:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Table
>
>   | $1 | $2 | $3 |
>   | --- | --- | --- |
>   | disk01 | SSD | ok |
>
>   In this row, `$1` is `disk01`, `$2` is `SSD`, and `$3` is `ok`.
>
> - <span class="fa-regular fa-file-lines"></span> Serialized Text
>
>   ```text
>   disk01;SSD;ok;
>   ```

## File References

Use `${file::<relative-path>}` for embedded scripts/files in connector folder.

```yaml
script: ${file::fan-info.awk}
commandLine: /bin/sh ${file::collector.sh}
```

## Translation References

Use `${translation::<tableName>}` with `translate`/`arrayTranslate`/`perBitTranslation`.

```yaml
translationTable: ${translation::SensorStatusTable}
```

## Constant References

Use `${constant::<constantName>}` for reusable literal values.

```yaml
hw.parent.id: ${constant::_DEVICE_ID}
```

## Protocol and Resource Attribute References

```yaml
value: ${protocol::jmx.port}
header: "Authorization: Bearer ${resource.attribute::api.token}"
```

- `${protocol::<type>.<property>}` accesses configured protocol data.
- `${resource.attribute::<key>}` accesses host/resource-level attributes.

## Mono-Instance Attribute References

Use `${attribute::<key>}` in mono-instance contexts: `monoInstance` collect jobs run once per discovered instance, and this reference injects that instance's attributes (as mapped during discovery) into the source. See [Monitors and Jobs](monitors-and-jobs.html).

```yaml
commandLine: /bin/sh ${file::detail.sh} ${attribute::id}
```

## Inline AWK Expressions

Use `${awk::...}` for concise expression-level formatting.

```yaml
name: ${awk::sprintf("%s (%s)", $2, $3)}
```

## Serialization Side Effects (Advanced but Important)

Tables are internally list-of-list-of-strings, but many transformations pass through semicolon-separated serialized rows.
Because semicolon is the column separator, appending `;value` to a column payload can effectively create a new materialized column once the row is re-parsed.

Example:

```text
# original row
node01;ClusterA;ok

# after append on column 2 with value ';PowerStore'
node01;ClusterA;PowerStore;ok
```

Use this behavior intentionally and carefully; it is powerful but easy to misuse.

> [!TIP]
> Keep inline AWK expressions short.
> Move heavier logic into AWK compute scripts for maintainability.

## Common Mistakes

- broken source paths when refactoring monitor names
- using relative source references where absolute references are required
- mixing positional columns after compute pipeline changes without remapping
- embedding secrets directly instead of protocol/resource references
