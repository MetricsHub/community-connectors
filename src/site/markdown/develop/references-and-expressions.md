keywords: references, expressions, source reference, translation reference, protocol reference
description: Complete reference syntax for source/file/translation/constants/protocol expressions used in MetricsHub connector YAML.

# References and Expressions

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

Connectors use references to wire data across sections and runtime contexts.

## When References Are Resolved

| Family | Syntax | Resolved |
| --- | --- | --- |
| Load-time substitutions | `${constant::}`, `${var::}` | Inlined once, when the connector is parsed and loaded. |
| Job-time references | `${source::}`, `${file::}`, `${translation::}`, `$1`/`$2` column refs, `${attribute::}`, `${protocol::}`, `${resource.attribute::}`, `${awk::}` | Evaluated during job execution — e.g. `${source::...}` yields the referenced source's current output for that cycle. Relative `${source::}` paths are normalized to their absolute form at load time. |
| Runtime credential macros | `%{USERNAME}`, `%{PASSWORD}`, `%{BASIC_AUTH_BASE64}`, ... | At execution time, per request, from the resource's configured credentials. |

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
>   disk01;SSD;ok
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

## Connector Variable References

Use `${var::<variableName>}` for user-configurable values declared under `connector.variables` (each with a `description` and a `defaultValue`):

```yaml
commandLine: /usr/bin/ps -e -o comm,args | grep -E "${var::matchName}"
```

Variables are substituted at connector load time, from the `defaultValue` or from the user's `additionalConnectors` configuration. Always declare a `defaultValue`: with neither a default nor a configured value, the literal `${var::name}` survives unresolved. See [Reuse and Configuration](reuse-and-configuration.html) for declaration and configuration details.

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

An attribute comes from the monitored host and may hold spaces or quotes, like a file or process name. Escape it for the syntax around it with the same `esc(TYPE)::` prefix as the credential macros, `${esc(TYPE)::attribute::<key>}`, which also applies to `${esc(TYPE)::resource.attribute::<key>}` and to the tool parameters, `${esc(TYPE)::param::<name>}`:

```yaml
commandLine: /bin/sh ${file::detail.sh} ${esc(bash)::attribute::id}
query: SELECT Name FROM Win32_Service WHERE Name = '${esc(wql)::attribute::name}'
```

In a `commandLine`, `${esc(bash)::attribute::<key>}`, `${esc(bash)::resource.attribute::<key>}` and `${esc(bash)::param::<name>}` are not escaped in place: the value is assigned to a shell variable at the start of the command, and the reference becomes that variable, quoted for where it lands (in or out of single or double quotes), so that the shell expands it as one word, neither parsed, split nor globbed. This assumes a POSIX shell: do not use them in a command run by `cmd.exe`. A value that would form a credential macro (`%{...}`) with the text around it is not inserted.

## Inline AWK Expressions

Use `${awk::...}` for concise expression-level formatting.

```yaml
name: ${awk::sprintf("%s (%s)", $2, $3)}
```

## References in Compute Attributes

### Format

A compute attribute can reference:

#### A resource attribute

```yaml
${resource.attribute::<attribute-key>}
```

#### A protocol property

```yaml
${protocol::<protocol-type>.<property>}
```

#### A source content

```yaml
${source::<source-name>}
```

### Examples

#### Replace a value with a protocol property

The following example replaces the value `PORT` in column `1` with the HTTP port configured for the protocol:

```yaml
sources:
  source(1):
    type: http
    path: /api/device
    computes:
      - type: replace
        column: 1
        existingValue: "PORT"
        newValue: ${protocol::http.port}
```

#### Append content from another source

The following example appends the content of another source to the value in column `1`:

```yaml
sources:
  source(1):
    type: http
    path: /api/device
    computes:
      - type: append
        column: 1
        value: " - ${source::monitors.enclosure.simple.sources.source_discovery}"
```

#### Reference a resource attribute

The following example keeps only the lines whose value in column `3` matches the URL built from the `host.name` resource attribute:

```yaml
sources:
  source(1):
    type: http
    path: /api/hosts
    computes:
      - type: keepOnlyMatchingLines
        column: 3
        valueList: "https://${resource.attribute::host.name}"
```

## Runtime Credential Macros (`%{...}`)

`%{...}` macros inject the resource's configured credentials at **execution time**. They work in HTTP sources and criteria (`url`, `path`, `header`, `body`, `authenticationToken`) and in command lines (SSH/local/WMI):

| Macro | Resolves to |
| --- | --- |
| `%{USERNAME}` | The configured username. |
| `%{PASSWORD}` | The configured password. |
| `%{HOSTNAME}` | The hostname of the resource being monitored. |
| `%{AUTHENTICATIONTOKEN}` | The configured authentication token. |
| `%{PASSWORD_BASE64}` | Base64-encoded password. |
| `%{BASIC_AUTH_BASE64}` | Base64 of `username:password` — ready for `Authorization: Basic %{BASIC_AUTH_BASE64}`. |
| `%{SHA256_AUTH}` | SHA-256 hex digest of the authentication token. |

```yaml
header: "Authorization: Basic %{BASIC_AUTH_BASE64}"
```

To escape the injected value for the surrounding syntax, wrap the macro as `%{esc(TYPE)::MACRO}` where `TYPE` is one of `json`, `xml`, `url`, `regex`, `windows`, `cmd`, `powershell`, `linux`, `bash`, `sql`, `wql`:

```yaml
body: '{ "user": "%{esc(json)::USERNAME}", "password": "%{esc(json)::PASSWORD}" }'
commandLine: mytool --password '%{esc(bash)::PASSWORD}'
```

The same types escape the `${esc(TYPE)::...}` references to attributes and parameters, which are replaced in every field. The credential macros, expanded in HTTP fields and command lines only, are not expanded in a SQL or WQL query nor in the regular expressions of a source: the `sql`, `wql` and `regex` types serve the references there.

Most types escape the **inside** of a string of their syntax, the quotes being written in the connector:

| Type | Write the macro | Escaping |
| --- | --- | --- |
| `bash` (or `linux`) | Between single quotes of a POSIX shell command: `'%{esc(bash)::PASSWORD}'` | `'` becomes `'\''` |
| `powershell` | Between single quotes of a PowerShell command | `'` (and `‘ ’ ‚ ‛`) doubled |
| `cmd` (or `windows`) | In a `cmd.exe` command, **outside** of double quotes | `^` before `^ & \| < > ( ) % "`. Inside double quotes, `cmd.exe` keeps the `^` and still expands `%VAR%`: prefer a PowerShell command with `powershell` |
| `sql` | Between single quotes of a SQL query (references only) | `\` and `'` doubled |
| `wql` | Between single or double quotes of a WQL query (references only) | `\`, `'` and `"` preceded with `\` |
| `json` | Between double quotes of a JSON string | `\`, `"` and the control characters escaped |
| `xml` | In XML character data or a quoted attribute value | `&`, `<`, `>`, `"`, `'` as entities |
| `url` | In a URL, a header or a form | Percent-encoded, `/` included, and a value of dots only |
| `regex` | In a regular expression of the connector (`keep`, `exclude`, `keepOnlyMatchingLines`...), **outside** of a `[...]` character class, where `-` would still form a range (references only) | `\` before `^ $ . * + ? [ ] \` |

The `${esc(bash)::...}` references to attributes and parameters work differently in a command line: see [Mono-Instance Attribute References](#mono-instance-attribute-references). The [tools](tools.html#escaping-and-validation) section lists which escape each field of a tool takes.

> [!WARNING]
> Macro names must be written in full and in uppercase. A misspelled or unknown macro (e.g. `%{BASICAUTH}`) is silently replaced with an **empty string**. Token-based macros (`%{AUTHENTICATIONTOKEN}`, `%{SHA256_AUTH}`) resolve to empty in command lines.

The related `%{SUDO:command}` macro (command elevation) is tied to the connector's `sudoCommands` list — see [Reuse and Configuration](reuse-and-configuration.html).

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
