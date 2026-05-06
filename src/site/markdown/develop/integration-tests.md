keywords: develop, integration tests
description: Learn how to write integration tests for community connectors in MetricsHub.

## Writing Integration Tests

To create a new integration test, follow these steps:

Reference: [MetricsHub Recording and Emulation Guide](https://github.com/MetricsHub/metricshub-community/blob/main/EMULATION.md)

## 1. Prepare IT Resources Structure

Create the connector-specific resources folder under `src/it/resources/` e.g., `src/it/resources/Linux/`.

Under this folder, create the following subfolders:

| Folder      | Description                                      |
| ----------- | ------------------------------------------------ |
| `config`    | Contains `metricshub.yaml` used for replay       |
| `emulation` | Contains recorded protocol data and emulation files |
| `expected`  | Contains `expected.json`, the expected IT output |

> [!IMPORTANT]
> You must name the connector-specific resources folder exactly as the connector identifier configured in the `metricshub.yaml` (e.g., for `+Linux` in `metricshub.yaml` create `src/it/resources/Linux/`).

## 2. Record and Organize Emulation Data

Use the MetricsHub CLI with the `--record` option to capture protocol exchanges (HTTP requests/responses, SSH commands, WMI queries, etc.):

```bash
metricshub <hostname> -t <type> --ssh-username userName --ssh-password userPassword -c +Linux --record
```

Recorded protocol files are generated in protocol-specific folders under the MetricsHub logs directory:
- Linux: `/opt/metricshub/logs/<protocol>/`
- Windows: `C:\Program Files\MetricsHub\logs\<protocol>\`

Each protocol folder contains an `image.yaml` index file plus response/data files.

Supported protocol folders include: `http`, `snmp`, `ssh`, `wbem`, `jdbc`, `ipmi`, `jmx`, `wmi`

### Special Case for SNMP Connectors

For SNMP connectors, use the `snmpcli` command to record walk files:

```bash
snmpcli dev-01 --walk 1.3.6.1 --community public --version v1 --port 161 --timeout 60 > /opt/metricshub/logs/snmp/1.3.6.1.walk
```

You may generate **multiple `.walk` files** (e.g., for different OIDs or components).

### Organize Emulation Files

Copy the recorded protocol folders (e.g., `http`, `ssh`, `snmp`, etc.) into the connector's `src/it/resources/<MyConnectorId>/emulation` folder, organizing them by protocol:

```
src/it/resources/<MyConnectorId>/emulation/
├── http/
│   ├── image.yaml
│   └── response files...
├── ssh/
│   ├── image.yaml
│   └── response files...
└── snmp/
    ├── 1.3.6.1.walk
    └── other .walk files...
```

## 3. Prepare the `config` Folder

Add a minimal `metricshub.yaml` config under `src/it/resources/<MyConnectorId>/config` (e.g. `src/it/resources/Linux/config`). Example for Linux:

```yaml
otel:
  otel.exporter.otlp.metrics.protocol: noop
patchDirectory: src/main/connector
resources:
  localhost:
    attributes:
      host.name: localhost
      host.type: linux
    protocols:
      emulation:
        ssh:
          directory: src/it/resources/Linux/emulation/ssh
    connectors: [ +Linux ]
```

For protocol-specific emulation directories, configure each protocol under the `emulation` section:
- `http`: for HTTP/HTTPS API calls
- `ssh`: for SSH command execution
- `snmp`: for SNMP queries
- `wbem`: for WBEM/CIM operations
- `jdbc`: for database connections
- `ipmi`: for IPMI commands
- `jmx`: for JMX queries
- `wmi`: for WMI queries

> [!IMPORTANT]
> Make sure to set the `patchDirectory` to the location of your connector source code (e.g., `src/main/connector`) so that the connector code is used during the IT.

## 4. Generate the Expected Output

The `ConnectorReplayIT` class provides a helper method `writeExpectedJson` to generate the expected JSON output for your connector. Follow these steps:

* Call the `writeExpectedJson` method via Maven to generate the expected JSON file:

```bash
mvn clean verify -Dtest=ConnectorReplayIT#writeExpectedJson
```

This will generate `expected-gen.json` in `src/it/resources/<MyConnectorId>/expected/`.

* Review the generated file to ensure it captures the correct telemetry data.

* Rename the generated `expected-gen.json` to `expected.json`:

```bash
mv src/it/resources/<MyConnectorId>/expected/expected-gen.json src/it/resources/<MyConnectorId>/expected/expected.json
```

* Remove dynamic attributes such as `agent.host.name` from the `expected.json` to avoid test failures due to environment differences.

> [!IMPORTANT]
> When modifying the connector code, avoid regenerating the `expected.json` file using the `writeExpectedJson` helper. Instead, manually update the expected file to reflect the specific connector changes. This keeps the expected file stable and ensures it changes only for intentional connector behavior updates. It also allows reviewers to clearly identify and validate the exact expected changes, without noise introduced by the recording process.

## 5. Add the Connector to the IT Tests

In `ConnectorReplayIT.java`, add a new test method for your connector, replacing `MyConnector` with your connector identifier:

```java
@Test
void testMyConnector() throws Exception {
	testConnectorReplay("MyConnector");
}
```

Each test method corresponds to a single connector to minimize merge conflicts and provide clear JUnit output per connector.

For connectors that have specific service criteria (e.g., Windows-only), add the appropriate condition annotation:

```java
@Test
@EnabledOnOs(WINDOWS)
void testMyWindowsConnector() throws Exception {
	testConnectorReplay("MyWindowsConnector");
}
```

## 6. Debugging and Troubleshooting

> [!TIP]
> To debug the integration test, you can run the `ConnectorReplayIT` class in debug mode from your IDE. If you want to generate log files during the test execution, set the `loggerLevel` system property to `debug`, and specify a log directory using `outputDirectory`:

```yaml
otel:
  otel.exporter.otlp.metrics.protocol: noop
patchDirectory: src/main/connector
loggerLevel: debug            # Available logger levels: trace, debug, info, warn, error
outputDirectory: src/it/logs  # Directory where logs will be saved
resources:
  localhost:
    attributes:
      host.name: localhost
      host.type: linux
    protocols:
      emulation:
        ssh:
          directory: src/it/resources/Linux/emulation/ssh
    connectors: [ +Linux ]
```

> [!NOTE]
> Depending on the connector behavior and how MetricsHub executes requests in parallel, you may end up with a recording where the same request is executed twice but returns different results — for example, a temperature value changing between the first and second execution. In such cases, the expected output may randomly differ from one execution to another because requests are not executed in the exact same order that they were recorded.
> If this is the case for now, keep only unique requests in the image. We plan to enhance the framework to add an identifier (optional) to the recorded requests in order to be able to distinguish them during the replay and match them with the expected output, even if they are executed in a different order or multiple times.
 
> [!NOTE]
> Another scenario can also happen due to race conditions: a connector may reference sources that are only available during the second collection cycle. Since MetricsHub runs monitor jobs in parallel, a referenced source might not yet be available during the very first collection. In that case, the integration test may fail even if the expected output was generated successfully at a given execution time T.
> When this happens, the connector design itself should really be reconsidered to avoid such behavior. A source being unavailable for another dependent source is not considered normal, even during the first collection cycle.
