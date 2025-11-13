keywords: develop, integration tests
description: Learn how to write integration tests for community connectors in MetricsHub.

## Writing Integration Tests

To create a new integration test, follow these steps:

## 1. Prepare IT Resources Structure

Create the connector-specific resources folder under `src/it/resources/` e.g., `src/it/resources/Linux/`.

Under this folder, create the following subfolders:

| Folder      | Description                                      |
| ----------- | ------------------------------------------------ |
| `config`    | Contains `metricshub.yaml` used for replay       |
| `emulation` | Contains recorded sources and criteria           |
| `expected`  | Contains `expected.json`, the expected IT output |

> **Important:** You must name the connector-specific resources folder exactly as the connector identifier configured in the `metricshub.yaml` (e.g., for `+Linux` in `metricshub.yaml` create `src/it/resources/Linux/`).

## 2. Prepare the `emulation` Folder

### Generate Recorded Data

Use the [MetricsHub CLI](https://metricshub.com/docs/latest/appendix/cli.html) with the `--record` option to capture the connector’s **sources** and **criteria**:

```bash
metricsHub babbage -t linux --ssh-username userName --ssh-password userPassword -c +Linux --record
```

Recorded files are generated in the default `/logs` directory under the MetricsHub installation folder.

### Special Case for SNMP Connectors

For SNMP connectors, you must run one or more [SNMP walk](https://metricshub.com/docs/latest/troubleshooting/cli/snmp.html#!#example-3-snmp-walk-request) commands on the target device and save each output to a `.walk` file:

```bash
snmpcli dev-01 --walk 1.3.6.1 --community public --version v1 --port 161 --timeout 60 > 1.3.6.1.walk
```

You may generate **multiple `.walk` files** (e.g., for different OIDs or components).

All of them must be placed in the connector’s `src/it/resources/<MyConnectorId>/emulation` folder (e.g. `src/it/resources/MIB2/emulation`) and will be used during emulation mode (IT).

### Copy Recorded Data to `emulation` Folder

Copy the recorded sources and criteria (or SNMP walk files) into the connector’s `src/it/resources/<MyConnectorId>/emulation` folder (e.g. `src/it/resources/MIB2/emulation`).


> **Important:** Rename all files to start with `localhost-` even if they were recorded from another host.

## 3. Prepare the `config` Folder

Add a minimal `metricshub.yaml` config under `src/it/resources/<MyConnectorId>/config` (e.g `src/it/resources/Linux/config`). Example for Linux:

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
      ssh:
        username: user
        password: password
        timeout: 300
    connectors: ["+Linux"]
```

> **Important:** Make sure to set the patch directory to `src/main/connector` so that the connector code is used during the IT.

## 4. Prepare the `expected` Folder

Create the `expected.json` file under `src/it/resources/<MyConnectorId>/expected/`, to generate it follow these steps:

* Create a new unit test to capture the expected JSON using the `saveTelemetryManagerJson` method provided by the `EmulationITBase` class, for example:
  
```java
class ConnectorReplayIT {

	@Test
	void testCapture() throws Exception {
		new EmulationITBase("MyConnector")
			.withServerRecordData()
			.executeStrategies()
			.saveTelemetryManagerJson(Paths.get("target", "expected.json"))
	}
}
```

* Run the IT via maven:

```bash
mvn clean verify -Dtest=ConnectorReplayIT#testCapture
```

* Copy the generated `expected.json` from `target/expected.json` to the connector’s `src/it/resources/<MyConnectorId>/expected` folder.

* Replace all the occurrences of the host name with `localhost` in the `expected.json` file.

> **Note:** When you update the connector code, it is recommended to not regenerate the `expected.json` file unless the expected has fully changed.

## 5. Add the Connector to the Parametrized IT

In `ConnectorReplayIT.java`, add the connector name to the `@ValueSource` annotation:

```java
class ConnectorReplayIT {

	@ParameterizedTest
	@ValueSource(strings = {
		"WinStorageSpaces",
		"MIB2",
		"Lmsensors",
		"Linux",
		"MySql",
		"WbemGenDiskNT",
		"SmartMonLinux",
        "MIB2Switch",
        "MyConnectorId"  // <--- Add your connector here
	})
	void testConnectorReplay(String connectorName) throws Exception {
		new EmulationITBase(connectorName)
			.withServerRecordData()
			.executeStrategies()
			.verifyExpected(connectorName + "/expected/expected.json");
	}
}
```