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
        description: Regular expression on the process name, e.g. ^java
        default: .*
        # Any value: a regular expression the compute applies, never a command or a query
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
| `type` | No | `string` | `string`, `integer`, `number` or `boolean`. Enforced: `integer` accepts `-?[0-9]+` only, `boolean` accepts `true` or `false`. The value is substituted as text. |
| `description` | No | None | What the value is for. Give an example. |
| `required` | No | `false` | Whether the assistant must supply the value. A parameter without `default` and not `required` is simply absent. |
| `default` | No | None | The value used when the assistant does not supply one. It must satisfy the `type`, `pattern` and `enum`. |
| `pattern` | No | None | A regular expression the **whole** value must match, e.g. `[\w@.-]+`. |
| `enum` | No | None | The only values accepted, e.g. `[ TERM, KILL, HUP ]`. |

The invocation arguments replace `${param::<name>}` in the tool's sources and computes, exactly where a mono-instance collect replaces `${attribute::<name>}`. `pattern` and `enum` are advertised to the assistant in the tool's JSON schema, and every argument is checked against `type`, `pattern` and `enum` before the tool runs: an invalid argument is reported to the assistant and nothing runs.

## Escaping and Validation

An argument comes from an AI assistant, and through it from whatever the assistant read: treat it as untrusted. Inserted as is into a command line, a value such as `sshd; reboot` runs a command of its own, and `' OR 1=1 --` rewrites a query. MetricsHub therefore enforces three rules.

**A free-text parameter must be inserted escaped.** A `string` parameter with neither `pattern` nor `enum` is free text. Insert it with `${esc(<type>)::param::<name>}`, which escapes the value for the syntax around it. Otherwise the tool is refused when the agent loads it, and a warning names the parameter.

| Escape | Insert the value | Escaping |
| --- | --- | --- |
| `bash` (or `linux`) | Between single quotes of a POSIX shell command: `'${esc(bash)::param::x}'` | `'` becomes `'\''` |
| `powershell` | Between single quotes of a PowerShell command: `'${esc(powershell)::param::x}'` | `'` (and `‘ ’ ‚ ‛`) doubled |
| `sql` | Between single quotes of a SQL query | `\` doubled, `'` doubled |
| `wql` | Between quotes of a WQL query | `\`, `'` and `"` preceded with `\` |
| `json` | Between double quotes of a JSON string | `\`, `"`, newlines and tabs escaped |
| `xml` | In XML text or an attribute | `&`, `<`, `>`, `"`, `'` as entities |
| `url` | In a URL path or query string | Percent-encoded, `/` included |
| `regex` | In a regular expression, to match the value literally | `\Q...\E` |
| `cmd` (or `windows`) | In a `cmd.exe` command | `^` before `& \| < > ( ) % "`: not reliable inside quotes, prefer `powershell` or a `pattern` |

The escape only covers the inside of the quotes: the quotes themselves are written in the connector, as in `'${esc(bash)::param::service}'`. Without them, `esc(bash)` protects nothing.

**A constrained parameter may be inserted as is.** A parameter with an `enum`, a `pattern`, or an `integer`, `number` or `boolean` type is validated before it is inserted, so `${param::<name>}` is accepted. Write a `pattern` that excludes the characters that matter where the value lands, for example `[\w@.-]+` for a systemd unit. A `pattern: '.*'` explicitly accepts any value: use it only where the value is data, like the regular expression of a `keepOnlyMatchingLines` compute, never in a command line, a query or an `awk` script.

**An argument may not contain `%{` or `${`.** The credential macros (`%{PASSWORD}`), the source references and the other `${...}` references are resolved after the arguments are inserted, so an argument holding one would reveal its value to the assistant. Such an argument is refused, whatever the parameter.

```yaml
tools:
  serviceLogs:
    description: Returns the last lines of the journal of a systemd service. Use it when a service fails or restarts.
    parameters:
      service:
        description: The systemd unit, e.g. sshd.service
        required: true
      lines:
        type: integer
        description: How many lines to return
        default: 100
      priority:
        description: The lowest priority to return
        default: info
        enum: [ emerg, alert, crit, err, warning, notice, info, debug ]
    sources:
      journal:
        type: commandLine
        commandLine: journalctl --no-pager -n ${param::lines} -p ${param::priority} -u '${esc(bash)::param::service}'
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
- Constrain every parameter you can with an `enum`, a `pattern` or a numeric type; escape the others with `esc(...)`.
- Keep the result small and tabular: filter with computes, name the columns.
- Mark anything that writes as `destructive: true`, even a harmless-looking `identify` LED.

## Common Mistakes

- Using `${param::...}` in a `mapping`: tools have no mapping.
- Forgetting `result`: the tool has nothing to return.
- Leaving `destructive` unset on a tool that acts on the host.
- Inserting a free-text parameter with `${param::...}`: the tool is refused. Use `${esc(<type>)::param::...}` or constrain the parameter.
- Writing `${esc(bash)::param::...}` without the single quotes around it, or inside double quotes: the value is not protected.
- Returning raw command output without a parsing compute: the assistant gets a single-column table of lines.
