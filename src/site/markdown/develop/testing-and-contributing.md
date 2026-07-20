keywords: testing, contributing, validation, workflow, quality
description: Overview of the connector validation and contribution workflow: local runs, replay integration tests, and the pull-request process.

# Testing and Contributing

A connector is done when it has been proven to work and can be maintained by others. This section walks through that path, in order:

1. **[Run and Debug Locally](run-and-debug.html)** — the core development loop: run your connector with the `metricshub` CLI against the real device or an emulator, force it with `-pd`/`-c +Id`, and inspect detection, discovered instances, and metric values with `-vvv`.
2. **[Integration Testing](integration-testing.html)** — freeze the behavior: record the protocol exchanges, build the `config`/`emulation`/`expected` resources, and register the connector in the replay integration tests so `mvn verify` guards it forever.
3. **[Contributing](contributing.html)** — ship it: what a connector pull request must contain, the CI gates it must pass, and the review checklist maintainers apply.

For connectors migrated from older formats, [Legacy and Compatibility](legacy-and-compatibility.html) lists the legacy syntax you may encounter and its canonical replacements.

> [!TIP]
> Budget roughly as much time for testing resources as for the connector itself. A connector without a replay integration test will regress silently — the test is what lets strangers refactor your connector safely.
