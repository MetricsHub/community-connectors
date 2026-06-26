keywords: detection, commandLine, os command
description: Reference for the commandLine detection criterion in MetricsHub connectors.

# Detection by Command Line

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When to Use

Use `commandLine` when the most reliable fingerprint is available through a shell command output.
Typical cases are Unix/Linux tools (`uname`, `ipmitool`, vendor CLIs) and host-side utility checks.

## Syntax

```yaml
connector:
  detection:
    criteria:
    - type: commandLine
      commandLine: /usr/bin/uname
      expectedResult: Linux
      errorMessage: Not a Linux host
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | - | `commandLine` |
| `commandLine` | Yes | - | Command string to execute. Must be non-blank. |
| `expectedResult` | No | none | Regex used to validate command output. |
| `executeLocally` | No | `false` | Run on the agent host instead of remote target. |
| `timeout` | No | protocol default | Timeout in seconds. Must be `> 0` when provided. |
| `errorMessage` | No | none | Connector-authored failure context (for logs/reporting). |
| `forceSerialization` | No | `false` | Guarantees operations are performed sequentially against one host. |

## Runtime Behavior

- Command is executed on the targeted system through the configured protocols (SSH, WMI, or WinRM).
- The output (_stdout_ and _stderr_) of the command is captured. Result matching is case-insensitive and multiline.
- If regex matches: criterion succeeds.
- If regex does not match: criterion fails.

See below example on how command output is matched with `expectedResult`:

> [!TABS]
>
> - <span class="fa-regular fa-circle-check"></span> Criterion
>
>   ```yaml
>   - type: commandLine
>     commandLine: uname
>     expectedResult: Linux
>   ```
>
> - <span class="fa-solid fa-terminal"></span> Result
>
>   ```text
>   Linux
>   ```
>
>   ✅ The criterion passes because the command output matches `expectedResult: Linux`.

### Executing the command on the agent with `executeLocally`

When `executeLocally` is set to true, the command is not executed on the targeted host, but on the monitoring agent, where MetricsHub is running. This is useful for executing a specific utility to gather information from a system that doesn't have a proper shell (like the `SMCli` utility to connect to old IBM storage systems).

> [!IMPORTANT]
> Indicate clearly in the description and in the `reliesOn` field the prerequisites: the binary the command is referring to must be installed on the system where MetricsHub is running.

With `executeLocally: true`, you can use the following macros in the command line, to specify the targeted system:

| Macro | Description |
|-------|-------------|
| `${HOSTNAME}` or `%{HOSTNAME}` | Will be replaced by the actual hostname configured by the user. |
| `${USERNAME}` or `%{USERNAME}`| Will be replaced by the username configured with the `osCommand` protocol in the MetricsHub configuration. |
| `${PASSWORD}` or `%{PASSWORD}`| Will be replaced by the password configured with the `osCommand` protocol in the MetricsHub configuration. |

## Recommended Pattern

- Keep detection commands lightweight and deterministic.
- Prefer explicit binary paths when possible (`/usr/bin/uname`) to avoid side effects of `$PATH`.
- Keep regex specific enough to avoid false positives but try to make use to handle future versions of the targeted platform (don't be too strict by expecting a specific version number in the command output).
- Set a timeout for tools that can block (`ipmitool`, vendor CLIs).

## Common Mistakes

- Using a heavy discovery command as detection.
- Using an over-broad regex like `.*` or too restrictive like `version: 3\.5\..*$`.
- Depending on locale-dependent output without normalization.

## Examples

Community example (`system/Linux/Linux.yaml`):

```yaml
connector:
  detection:
    criteria:
    - type: commandLine
      commandLine: uname
      expectedResult: GNU/Linux
      errorMessage: Not a Linux host.
```
