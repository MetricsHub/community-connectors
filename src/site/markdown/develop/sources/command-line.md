keywords: commandLine source, os commands, source parsing
description: Full reference for the commandLine source with parsing, filtering, and fan-out patterns.

# commandLine (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `commandLine` when the target data is easiest to obtain from a command line, shell script, or batch. When relying on command lines, the connector requires the user to configure a protocol in MetricsHub that supports remote command line execution, like SSH or WMI and WinRM for Windows systems.

It is often preferred to use actual APIs, like REST APIs or SNMP, to extract metrics from a system. But command line utilities remain a strong source of data, especially on Linux-based systems.

The specified command line is executed on the monitored host (typically a remote system) through the protocol configured by the user in MetricsHub, unless the `executeLocally` property is set to `true`.

The output of the command is captured and converted to a table, following a few extraction properties, like `separators`, `selectColumns`, and `keep` (see below descriptions).

## Syntax

```yaml
sources:
  cpuInfo:
    type: commandLine
    commandLine: cat /proc/stat
    keep: ^cpu[0-9] # Keep only lines that start with cpuN
    selectColumns: 1,2,3,4,5,6 # Keep the columns from 1 to 6 (default separator: blank spaces)
    computes:
    - type: awk
      script: '{ sub("cpu","",$1); print $1 ";" $2/100 ";" $3/100 ";" $4/100 ";" $5/100 ";" $6/100 }'
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `commandLine`. |
| `commandLine` | Yes | None | Command to execute. |
| `timeout` | No | Connector/runtime default | Command timeout in seconds. |
| `executeLocally` | No | `false` | Run on local agent instead of remote target. |
| `beginAtLineNumber` | No | None | Keep lines starting at this 1-based line index. |
| `endAtLineNumber` | No | None | Keep lines up to this 1-based line index. |
| `keep` | No | None | Regex to keep matching lines. |
| `exclude` | No | None | Regex to drop matching lines. |
| `separators` | No | whitespace/tab | Input split regex used before `selectColumns`. |
| `selectColumns` | No | None | Column selection expression (`1,2,4`, ranges, `ID` for SNMP-style indexes). |
| `executeForEachEntryOf` | No | None | Run once per row of another source table. |
| `computes` | No | `[]` | Post-processing pipeline. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

## Recommended Pattern

- Return the smallest possible dataset from the command.
- Normalize early to semicolon-separated rows.
- Use `executeForEachEntryOf` for controlled fan-out instead of huge one-shot scripts.
- Keep command portability in mind (`bash` vs `PowerShell` differences).

## Common Mistakes

- Parsing human-readable command output that changes by locale.
- Missing timeout on long-running commands.
- Relying on column positions that are not stable across OS versions.
- Splitting with weak separators and then compensating with fragile AWK.

## Community Examples

- [Linux](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Linux/Linux.yaml)
- [LinuxFile](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/LinuxFile/LinuxFile.yaml)
- [WindowsFile](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/WindowsFile/WindowsFile.yaml)
- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml)
