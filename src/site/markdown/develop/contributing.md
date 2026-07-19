keywords: contributing, pull request, CI, build, review checklist, community connectors
description: How to contribute a connector to metricshub-community-connectors: repository workflow, CI gates, PR content expectations, and the review checklist.

# Contributing

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

This page describes how a connector change travels from your machine to the released connector library.

## Repository Workflow

1. Fork the repository (or create a branch if you have write access) and branch from `main`.
2. Develop and validate locally: [Run and Debug Locally](run-and-debug.html), then [Integration Testing](integration-testing.html).
3. Open a pull request against `main`.
4. CI builds the project on every pull request (Maven build on JDK 25, via the shared `metricshub/workflows` pipeline). The build must pass.
5. After review and merge, `main` is automatically built and deployed to Maven Central; releases are cut by maintainers through the "Release" GitHub Actions workflow.

## What a Connector PR Must Contain

Keep the scope tight: only the files required for the connector change.

- The connector YAML under `src/main/connector/<category>/<ConnectorId>/<ConnectorId>.yaml`, plus its embedded files (`.awk` scripts, header files, ...) in the same folder.
- Integration-test resources under `src/it/resources/<ConnectorId>/` (`config/metricshub.yaml`, `emulation/`, `expected/expected.json`) and the connector's registration in `src/it/java/org/metricshub/connector/it/ConnectorReplayIT.java` — see [Integration Testing](integration-testing.html).
- Any emulator or script used to develop and test the connector, committed alongside the test resources so reviewers and future maintainers can reproduce your results.

Do **not** commit transient artifacts: emulator logs, `__pycache__/`, temporary captures, or working notes.

## Local Build and Quality Gates

```bash
mvn verify
```

This compiles every connector, runs static analysis (PMD, configured by `pmd.xml`), and executes the replay integration tests (`ConnectorReplayIT`, via Failsafe). Run it before opening the PR — it is what CI runs.

Java source files must carry the AGPL-3 license header (the build fails otherwise). If you add or modify Java files:

```bash
mvn license:update-file-header
```

Connector YAML files do not need license headers.

## Writing the PR Description

Reviewers need to reproduce and trust your results. Include:

- **What changed and why** — especially behavior changes: detection, authentication, units, labels, topology.
- **The exact `metricshub` commands you used to test** (host type, protocol flags, `-pd`/`-c` options).
- **Key validation results** — connector status, discovered instances, sample metric values.

Explicit commit messages help too: say what changed in behavior, not just which file was edited.

## Review Checklist

Before requesting review, verify:

- `metricshub.connector.status` is `ok` when run against your emulator or a real device.
- Detection is deterministic and cheap-first — see [Detection](detection/index.html).
- Metric and attribute names follow the [naming rules](metric-naming.html): reuse semconv, attributes over metric explosion, no vendor-prefixed root metrics.
- Units are correct and consistent with existing connectors (declared in metric metadata, never encoded in names).
- `hw.status` values map to the supported states (`ok`, `degraded`, `failed`) through `translations` that actually resolve.
- Topology is coherent: no self-referential `hw.parent.id`, no fabricated instance IDs, `serial_number` contains an actual serial number (not a WWN or unrelated ID).
- Temperature monitors expose limits where applicable (`hw.temperature.limit` with `limit_type` such as `high.degraded` / `high.critical`).
- The replay integration test passes: `mvn verify`.

## Getting Help

- Open a [GitHub issue](https://github.com/metricshub/community-connectors/issues/) for bugs or questions.
- Join the [MetricsHub Slack](https://metricshub.slack.com) to discuss connector design before investing heavily.
