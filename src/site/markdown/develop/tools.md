keywords: tools, mcp, llm, ai agent, connector tools
description: How to declare tools in a connector so that an AI assistant can run them on monitored hosts through the MetricsHub MCP server.

# tools (Section)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `tools` to give an AI assistant an operation on the monitored host that is not a metric: list the running processes with their counters, read a log, reboot a server. A tool reuses what the connector already knows (the protocol, the credentials, the queries, the parsing) without creating any monitor.

The **MetricsHub Agent** exposes every tool as an MCP tool named `<connectorId>_<toolName>` (for example `WindowsProcess_listProcesses`), so an assistant connected to the agent discovers it with the connector.

A tool is:

- **Sources and computes**, exactly like a monitor job's: the same source types, the same computes, the same `${source::...}` references.
- **Parameters** the assistant fills in, substituted with `${param::<name>}` in the sources and computes.
- **A result**: the table of one of the sources, optionally with column names.

## Syntax

```yaml
tools:
  listProcesses:
    description: Lists the running processes with their CPU time and memory, optionally filtered by name.
    parameters:
      matchName:
        type: string
        description: Regular expression matching the process name, e.g. ^java (empty for all processes)
        default: ''
        # Only matched against the rows: any value on one line
        pattern: '.*'
    sources:
      processes:
        type: wmi
        namespace: root\CIMv2
        query: SELECT ProcessId, Name, WorkingSetSize, KernelModeTime FROM Win32_Process
        computes:
        - type: keepOnlyMatchingLines
          column: 2
          regExp: ${param::matchName}
    result:
      source: ${source::processes}
      columns: [ pid, name, workingSetBytes, kernelTime ]
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `tools` | No | None | Object containing the named tools of the connector. |
| `<toolName>.description` | Yes | None | What the tool does, as read by the assistant. Say what it returns and when to use it. |
| `<toolName>.parameters` | No | None | Object of named parameters (see below). |
| `<toolName>.destructive` | No | `false` | `true` when the tool changes the state of the host: a reboot, a command, a write. See the Destructive Tools section below. |
| `<toolName>.sources` | Yes | None | Named sources with their computes, like a monitor job's `sources`. |
| `<toolName>.executionOrder` | No | Dependency order | Explicit source order, like a monitor job's. |
| `<toolName>.result.source` | Yes | None | Reference of the source whose table is returned, e.g. `${source::processes}`. |
| `<toolName>.result.columns` | No | None | Names of the table columns, in order, so that the rows read as records. |

### Parameters

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | No | `string` | `string`, `integer`, `number` or `boolean`. Enforced: an `integer` is a whole number (`5`, `5.0` and `5e0` are all `5`), a `boolean` is `true` or `false`. The value is substituted as text. |
| `description` | No | None | What the value is for. Give an example. |
| `required` | No | `false` | Whether the assistant must supply the value. A parameter the sources reference must be `required` or have a `default` (`''` for an optional text), or the tool is refused. |
| `default` | No | None | The value used when the assistant does not supply one. It must satisfy the `type`, `pattern` and `enum`. |
| `pattern` | No | Default pattern for a `string` without `enum` | A Java regular expression the **whole** value must match. A `string` declaring neither a `pattern` nor an `enum` takes the default pattern: letters, digits and `_ . @ : -` (see Validation and Review). |
| `enum` | No | None | The only values accepted, each of the parameter's `type`, e.g. `[ TERM, KILL, HUP ]`. |

The invocation arguments replace `${param::<name>}` in the tool's sources and computes, exactly where a mono-instance collect replaces `${attribute::<name>}`. The `enum` is advertised in the tool's JSON schema and the `pattern` in the parameter's description. Every argument is checked against `type`, `pattern` and `enum` before the tool runs: an invalid argument is reported to the assistant and nothing runs.

## Validation and Review

An argument comes from an AI assistant, and through it from whatever the assistant read: treat it as untrusted. Inserted as is into a command line, a value such as `sshd; reboot` would run a command of its own, and `' OR 1=1 --` would rewrite a query. MetricsHub validates every argument before the tool runs. Where the sources insert it, and what the command does with it, is checked when the connector is reviewed.

### What MetricsHub Checks

An invalid argument is reported to the assistant, and nothing runs.

- **Type, enum and pattern.** Every argument must satisfy the `type`, `enum` and `pattern` of its parameter.
- **The default pattern.** A `string` parameter declaring neither an `enum` nor a `pattern` only takes letters, digits and `_ . @ : -`, starting with a letter, a digit or `_`, or nothing: `sshd.service`, `getty@tty1.service`, `db-01.example.com`, `10.0.0.1`, `fe80::1`. Such a value cannot leave a string or a word, in a shell, a query or a URL, nor be read as an option, nor climb a path: `sshd; reboot`, `a b`, `$(id)`, `-delete` and `../etc` are refused. It suits most parameters: names, identifiers, addresses. An empty value, which a `default: ''` gives, leaves no word where it is inserted unquoted in a command line (`--filter ${param::x} file` would make `file` the filter): quote it, `'${param::x}'`, or make the parameter `required`.
- **No macro, no control character.** No argument may contain `%{` or `${`, which would reveal a credential macro such as `%{PASSWORD}`, nor a control character other than a tab or a line break. A value that would form a macro with the text around it, such as `{PASSWORD}` after a `%`, is not inserted.
- **Declared references.** When the agent loads the connector, every reference must name a declared parameter, `required` or with a `default` (`''` for an optional text), and a known escape type: the tool is refused otherwise, rather than run with the reference left in. In a tool, `${attribute::<name>}` is the same as `${param::<name>}`, the arguments being the tool's attributes.

### Wider Values

A parameter that needs more characters (a path, free text, a search pattern) declares its own `pattern`, as narrow as possible, or an `enum`. Insert it with the escape of the field, inside the quotes the connector writes:

| Field | Write | Escaping |
| --- | --- | --- |
| `commandLine` run by a POSIX shell | Between single quotes: `'${esc(bash)::param::x}'` | `'` becomes `'\''`: nothing is expanded between single quotes |
| A PowerShell command | Between single quotes, in a command between double quotes: `PowerShell.exe -Command "Get-Service '${esc(powershell)::param::x}'"` | `'` and the typographic quotes doubled. The command reaches PowerShell through `cmd.exe`, whose double quotes keep `& \| < > ^ ( )` literal, but not `"` and `%`: keep these two out of the `pattern` |
| `query` of a `sql` source | Between single quotes: `'${esc(sql)::param::x}'` | `\` and `'` doubled, as MySQL and MariaDB read `\` as an escape. Elsewhere (PostgreSQL, SQL Server, Oracle), keep `\` out of the `pattern`. In a `LIKE` pattern, `%` and `_` stay wildcards |
| `query` of a `wmi` or `wbem` source | Between single or double quotes of a comparison: `'${esc(wql)::param::x}'` | `\`, `'` and `"` preceded with `\`. Not in a `LIKE` pattern, where WQL does not read `\` as an escape |
| `url` or `path` of an `http` source | In the path or the query: `/api/${esc(url)::param::x}` | Percent-encoded, `/` included, the dots of a `.` or `..` segment too |
| `body` of an `http` source | `"${esc(json)::param::x}"` in JSON, `${esc(xml)::param::x}` in XML character data or a quoted attribute, `${esc(url)::param::x}` in a form | `\`, `"` and the control characters for JSON; `& < > " '` as entities for XML, where a quoted attribute still turns tabs and line breaks into spaces (keep them out of the `pattern` there); percent-encoding for a form |
| `keep`, `exclude`, `regExp` | A regular expression: `${param::x}`, with a `pattern` such as `.*`. Text to find in a regular expression of the connector: `${esc(regex)::param::x}`, outside of a `[...]` character class | None for a regular expression, which is only matched against the rows. `esc(regex)` puts `\` before `^ $ . * + ? [ ] \`, so that the text matches literally |

### What the Review Checks

MetricsHub does not read the commands, queries and requests of a connector. The review of every tool checks that each parameter, whatever its pattern, is only data where it lands:

- **Not a command.** Never the name of a command (`${param::x} --version`, after `;`, `|`, `&&`, `if`, `{`, an assignment such as `MODE=x`, a redirection such as `2>&1`), the script of a shell (`sh ${param::x}`), the target of a redirection (`> ${param::x}`), nor a function or alias of the command line.
- **Not code.** Never an argument of a command that runs its arguments as code or as another command: `eval`, `sh -c`, `sudo`, `su`, `ssh`, `env`, `xargs`, `nohup`, `timeout`, `nice`, `chroot`, `prlimit`, `find -exec`, `docker exec`, `awk`, `perl`, `python`, `sed` (whose script runs `e` and writes `w`), `dd` (whose `of=` writes), `tar`, `rsync`, `git`, `man`, `less`... nor the value of an option naming a program (`--to-command=`, `--rsh-command`, `-o ProxyCommand=`). Never inside arithmetic (`$((...))`, `let`, `[[ ... -eq ... ]]`), a variable name (`read`, `printf -v`, `export`), `$(...)`, backquotes, a here-document or a comment.
- **Not an option or an action.** Never completing an option (`-${param::x}` makes `-delete`), and never choosing what a service, package or container manager does: write the action (`systemctl status ${param::x}`, `docker container logs ${param::x}`), or make the parameter an `enum`.
- **Not a destination.** Never the scheme or the host of a URL, which would send the request and its credentials elsewhere: an `enum` only. Never a `file` source path, unless its `pattern` keeps it in a directory without `..`.
- **Escaped where it is wider.** A parameter whose `pattern` lets more than the default through is inserted with the escape of its field, inside the quotes the connector writes, as in the table above, unless it is a regular expression of a compute. A SQL or WQL value sits inside a quoted string, never as a column, a table or a clause.
- **A pattern that matches in one pass.** MetricsHub matches every argument against the `pattern` of its parameter, without a time limit. Use character classes and single quantifiers (`[A-Za-z0-9_./-]{1,255}`), never a quantified group that can match the same text in several ways (`(a+)+`, `(.*a){16}`), whose matching time explodes on a crafted value, nor a repeated alternation (`(x|y)*`), which exhausts the stack on a long value: write `[xy]*`.
- **Destructive when it acts.** Anything that changes the host is `destructive: true`.

```yaml
tools:
  serviceLogs:
    description: Returns the last lines of the journal of a systemd service. Use it when a service fails or restarts.
    parameters:
      service:
        # The default pattern takes unit names: sshd.service, getty@tty1.service
        description: The systemd unit, e.g. sshd.service
        required: true
      lines:
        type: integer
        description: How many lines to return, 1 to 9999
        default: 100
        # A bound: an unbounded count could return the whole journal
        pattern: '[1-9][0-9]{0,3}'
      priority:
        description: The lowest priority to return
        default: info
        enum: [ emerg, alert, crit, err, warning, notice, info, debug ]
    sources:
      journal:
        type: commandLine
        commandLine: journalctl --no-pager -n ${param::lines} -p ${param::priority} -u ${param::service}
    result:
      source: ${source::journal}
```

## References and Order

Sources of a tool are keyed `${source::tools.<toolName>.sources.<sourceName>}`. Inside the tool, a relative reference `${source::<sourceName>}` resolves to the tool's own source, and the sources run in dependency order unless `executionOrder` says otherwise. A tool may also reference the connector's `beforeAll` sources with `${source::beforeAll.<name>}`: they run before the tool, as before a monitor job.

A tool creates no monitor and its tables do not reach the monitor jobs: `mapping` is not allowed under a tool.

## How the Assistant Calls It

The agent adds two parameters to every tool: `hostname`, a list of configured hosts to run it on (**required**), and `poolSize`, the number of hosts run concurrently. The result lists one entry per host, holding the `columns` declared in `result` and the `rows` of the result source, or an `error`.

```json
{
  "hosts": [
    {
      "hostname": "win-01",
      "response": {
        "columns": [ "pid", "name", "workingSetBytes", "kernelTime" ],
        "rows": [ [ "4212", "java.exe", "734003200", "12.5" ] ]
      }
    }
  ]
}
```

## Destructive Tools

A tool that changes the host (power control, a command, a configuration write) must declare `destructive: true`. The agent prefixes its description with `DESTRUCTIVE:`; its own MCP server and chat advertise it only when the agent runs with the JVM flag `-Dmetricshub.mcp.tool.destructive.enabled=true`, while MetricsHub Central receives every tool and applies its own approval policy.

```yaml
tools:
  reboot:
    description: Reboots the server through iLO (graceful shutdown, then power on). Use only when the user explicitly asks for a reboot.
    destructive: true
    parameters:
      resetType:
        description: GracefulRestart (default) or ForceRestart
        default: GracefulRestart
        enum: [ GracefulRestart, ForceRestart ]
    sources:
      reset:
        type: http
        method: post
        path: /redfish/v1/Systems/1/Actions/ComputerSystem.Reset
        header: "Content-Type: application/json"
        body: '{"ResetType": "${param::resetType}"}'
        resultContent: http_status
    result:
      source: ${source::reset}
      columns: [ http_status ]
```

## Recommended Pattern

- Name tools as verbs, without dots: `listProcesses`, `readLog`, `reboot`. A dotted name is refused when the connector loads, since the dot separates the segments of a source reference.
- Write the description for the assistant: what the tool returns, what the parameters mean, when not to use it.
- Give every parameter a `default` or `required: true`, and an example value in its description.
- Keep the default pattern for names and identifiers; use an `enum` or a numeric type where you can; give a wider `pattern` only where needed, with the escape of the field.
- Bound the numbers that size the work or the result (a line count, a time range) with a `pattern` such as `[1-9][0-9]{0,3}`: the type alone accepts any integer.
- Keep the result small and tabular: filter with computes, name the columns.
- Mark anything that writes as `destructive: true`, even a harmless-looking `identify` LED.

## Common Mistakes

- Using `${param::...}` in a `mapping`: tools have no mapping.
- Forgetting `result`: the tool has nothing to return.
- Leaving `destructive` unset on a tool that acts on the host.
- Widening a `pattern` (spaces, quotes, `/`) and inserting the parameter without the escape of its field, or outside the quotes the connector writes.
- Passing a parameter where it is not mere data: see What the Review Checks above.
- Returning raw command output without a parsing compute: the assistant gets a single-column table of lines.
