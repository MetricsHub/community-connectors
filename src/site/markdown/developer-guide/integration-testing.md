keywords: integration testing, replay tests, emulation, connector validation
description: Replay integration testing workflow for MetricsHub connectors using config/emulation/expected resources and ConnectorReplayIT.

# Integration Testing

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

Replay integration tests are the primary safety net for connector changes.

## Test Resource Layout

Each connector test dataset is stored under:

```text
src/it/resources/<ConnectorId>/
  config/
    metricshub.yaml
  emulation/
    ... recorded source and criterion payloads ...
  expected/
    expected.json
```

The `<ConnectorId>` folder name must match the connector ID used in replay tests.

## How Replay Works

`ConnectorReplayIT` runs each connector dataset through `EmulationITBase`:

1. load test configuration
2. replay emulated source/criterion responses
3. execute monitoring task
4. compare resulting telemetry with `expected/expected.json`

## Add a New Connector Replay Test

1. Create test resources folder `src/it/resources/<ConnectorId>/...`
2. Fill `config/metricshub.yaml` with minimal config and correct `patchDirectory`
3. Add emulation data files (or SNMP `.walk` files when relevant)
4. Generate and store `expected/expected.json`
5. Add `<ConnectorId>` entry to `ConnectorReplayIT` parameterized list

## Minimal Config Example

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
    connectors: ["+MyConnector"]
```

## Capture Expected Output (Example)

```java
new EmulationITBase("MyConnector")
  .withServerRecordData()
  .executeStrategies()
  .saveTelemetryManagerJson(Paths.get("target", "expected.json"));
```

## Good Practices

- Keep emulation payloads complete for all relevant sources/criteria.
- Normalize hostname values (`localhost`) in expected output.
- Regenerate expected data only when behavior intentionally changes.
- Keep replay dataset and connector changes in same PR.

## Common Mistakes

- forgetting to register connector ID in `ConnectorReplayIT`
- mismatched folder name vs connector ID
- incomplete emulation data that hides runtime regressions
- silently updating expected output without documenting behavioral change
