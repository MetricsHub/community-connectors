keywords: metricshub cli, local testing, debugging, emulation, snmpsim, record, replay, patch directory
description: Run and debug your connector locally with the metricshub CLI: patch directory, forced connectors, verbosity, protocol emulation, and record/replay.

# Run and Debug Locally

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

Before writing [integration tests](integration-testing.html), run your connector for real. The core development loop is:

1. Edit the connector YAML.
2. Run `metricshub` against the device (or an emulator).
3. Inspect detection, discovered instances, and metric values; fix; repeat.

The `metricshub` CLI ships with every MetricsHub installation.

## Basic Invocation

```bash
metricshub <hostname> -t <type> <protocol flags> [-u <user> [-p <password>]] [options]
```

- `<hostname>` — the resource to monitor (`localhost` works, see below).
- `-t` / `--type` — the resource type. Accepted tokens include `linux` (`lin`), `windows` (`win`), `network` (`switch`), `storage` (`san`, `array`), `management` (`mgmt`, `oob`), `aix`, `hpux`, `solaris`, `tru64`, `vms`, `other`. Abbreviations like `sto` or `net` are **not** accepted.
- Protocol flags enable and configure each protocol: `--snmp [1|2]` (`--community`, `--snmp-port`), `--snmpv3`, `--http`/`--https` (`--http-port`), `--ssh`, `--wmi`, `--winrm`, `--wbem`, `--ipmi`, `--jdbc`, `--jmx` — each with its own `--<protocol>-username`/`--<protocol>-password`/`--<protocol>-timeout` variants. At least one protocol is required.
- `-u`/`--username` and `-p`/`--password` set the global credentials; `-p` with no value prompts interactively.

## Developer Essentials

| Option | Purpose |
| --- | --- |
| `-pd`, `--patch-directory <dir>` | Load connector YAML from a local directory **on top of** the bundled connectors. Point it at `src/main/connector` so your working copy is the one that runs. |
| `-c`, `--connectors <list>` | Connector selection: `+Id` forces the connector (skips auto-detection), bare `Id` stages only it for detection, `!Id` excludes it, `#tag` / `!#tag` stage/exclude whole categories. |
| `-v`, `-vv`, `-vvv`, `-vvvv` | Verbosity: WARN, INFO, DEBUG, TRACE. Use `-vvv` to watch each detection criterion and source execute. |
| `-s`, `--sequential` | Disable parallelism — easier-to-read logs while debugging. |
| `-l`, `--list` | List the available connectors. |
| `-m`, `--monitors` | Restrict monitor types (`+disk,!memory`). |

The standard development invocation, from the repository root:

```bash
metricshub my-device --type storage --https --http-port 8443 -u admin -p \
  -pd src/main/connector -c +MyConnector -vvv
```

This forces your work-in-progress connector (`+MyConnector`) from your source tree (`-pd`) with DEBUG logging.

For a connector that declares [variables](reuse-and-configuration.html), pass values with `--additional-connector`:

```bash
metricshub my-host -t linux --ssh -u monitor -p \
  --additional-connector systemdProcess --uses LinuxProcess -F matchName=systemd
```

## What to Verify in the Output

- `metricshub.connector.status` is `ok` — detection passed and jobs ran.
- Discovered instances are coherent: expected count, stable `id` values, no self-referential `hw.parent.id`, real serial numbers.
- Metric names, units, and attributes follow the [naming rules](metric-naming.html).
- Status metrics resolve to `ok` / `degraded` / `failed` — if you see raw vendor codes, a translation table is missing or misreferenced.
- Re-run twice: the second discovery must find the **same** instances (no duplicates from unstable keys).

If detection fails, run with `-vvv` and read the criteria evaluation: each criterion logs what was executed, what came back, and why it matched or failed.

## Testing Without the Real Device

### Command-Line Connectors: the `localhost` Trick

When the target host is `localhost`, MetricsHub executes `commandLine` sources **locally as the current user** — no SSH connection is made (the `--ssh` flag and credentials merely enable the protocol for detection):

```bash
metricshub localhost -t linux --ssh -u any -p any -pd src/main/connector -c +MyConnector
```

To emulate a device, put stub scripts that print realistic output (and exit codes) ahead of the real binaries on your `PATH`, or point the connector's command at a local script while developing.

### SNMP Connectors: snmpsim

Use [snmpsim](https://github.com/etingof/snmpsim) to simulate an SNMP agent from a walk recording:

```bash
# Terminal 1: serve the recorded data
snmpsim-command-responder --data-dir=./snmp-data --agent-udpv4-endpoint=127.0.0.1:1161

# Terminal 2: point MetricsHub at the simulator
metricshub localhost -t network --snmp 2 --community public --snmp-port 1161 \
  -pd src/main/connector -c +MyConnector -vvv
```

To capture a walk from a real device, use the `snmpcli` tool that ships with MetricsHub:

```bash
snmpcli my-device --walk 1.3.6.1 --community public --version v2c > snmp-data/my-device.snmpwalk
```

(`snmpcli ... --walk <oid> -rec` alternatively saves `<oid>.walk` into the MetricsHub logs directory.)

### HTTP/REST Connectors: a Quick Emulator

A small FastAPI app is usually enough to emulate a REST API:

```python
# emulator.py — run with: uvicorn emulator:app --host 0.0.0.0 --port 8080
from fastapi import FastAPI
app = FastAPI()

@app.get("/api/v1/inventory/fans")
def fans():
    return {"fans": [
        {"id": "fan-01", "name": "Fan 1", "status": "ok", "rpm": 7230},
        {"id": "fan-02", "name": "Fan 2", "status": "failed", "rpm": 0},
    ]}
```

```bash
metricshub localhost -t storage --http --http-port 8080 -u guest -p guest \
  -pd src/main/connector -c +MyConnector -vvv
```

Keep emulators deterministic, and commit them with the connector's integration-test resources so reviewers can reproduce your results — see [Contributing](contributing.html).

## Record and Replay

Once the connector works, capture the real protocol exchanges so they can replay forever without the device:

- `metricshub ... -rec` (`--record`) writes every source and criterion result as YAML into protocol subfolders (`http/`, `ssh/`, `wmi/`, ...) under the MetricsHub logs directory.
- `metricshub ... -e <dir>` (`--emulate`) replays a recorded directory instead of contacting the device.
- SNMP walks are captured with `snmpcli --walk` (above), not with `--record`.

These recordings become the `src/it/resources/<ConnectorId>/emulation/` content of your replay integration test — the full workflow is on the [Integration Testing](integration-testing.html) page.

## Common Pitfalls

- Forgetting `-pd src/main/connector`: the **bundled** copy of the connector runs instead of your edited one, and your changes seem to have no effect.
- Using `-t sto` or `-t net`: not accepted — write `storage` / `network`.
- Testing detection only with `+MyConnector`: forcing skips auto-detection, so also run once with `-c MyConnector` (bare id) to verify the criteria actually match.
- Unstable instance `id`s that create duplicates on the second run — watch for it before recording test resources.
