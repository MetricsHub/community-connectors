keywords: metricshub, community connectors, connector development, yaml, opentelemetry
description: Start here to build, test, and contribute MetricsHub community connectors. Includes the official connector developer guide and generated connector reference pages.
title: MetricsHub Community Connectors

# MetricsHub Community Connectors

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

This repository contains **MetricsHub community connectors** and their documentation.
It is the entry point for developers who want to:

- create a new connector
- improve an existing connector
- learn the connector model used by MetricsHub

> [!IMPORTANT]
> The **official implementation guide** is the [Connector Developer Guide](develop/index.html).
> Use it as the single source of truth for connector structure, detection, sources, computes, mapping, and testing.

## Who This Site Is For

- Developers adding monitoring support for new platforms
- Contributors maintaining existing connectors
- Reviewers validating connector quality, consistency, and compatibility

## What You Will Find Here

- A complete developer guide in `develop/...`
- Generated library views:
  - [Supported Platforms](supported-platforms.html)
  - [Connectors Directory](connectors-directory.html)

## Recommended Learning Path

If you are new to connector development, read in this order:

1. [Developer Guide Home](develop/index.html)
2. [Quick Start](develop/quick-start.html)
3. [Connector Structure](develop/connector-structure.html)
4. [Monitors and Jobs](develop/monitors-and-jobs.html)
5. [Reuse and Configuration](develop/reuse-and-configuration.html)
6. [References and Expressions](develop/references-and-expressions.html)
7. [Design Principles](develop/design-principles.html)
8. [Detection](develop/detection/index.html)
9. [Sources](develop/sources/index.html)
10. [Computes](develop/computes/index.html)
11. [Mapping, Metrics, and Semconv](develop/mapping-metrics-semconv.html)
12. [Metric and Attribute Naming](develop/metric-naming.html)
13. [Run and Debug Locally](develop/run-and-debug.html)
14. [Integration Testing](develop/integration-testing.html)
15. [Contributing](develop/contributing.html)
16. [Legacy and Compatibility](develop/legacy-and-compatibility.html)

## Repository Layout (Developer View)

```text
src/main/connector/           Connector YAML files and embedded scripts/files
src/site/markdown/            Documentation source (this site)
src/it/resources/             Replay integration test resources
src/it/java/                  Replay integration test code
```

## Contribution Workflow (High Level)

1. Implement or update connector YAML under `src/main/connector/...`
2. Add or update replay test data under `src/it/resources/<ConnectorId>/...`
3. Register/update IT execution in `src/it/java/...`
4. Validate locally (`mvn clean site`, then `mvn verify` when relevant)
5. Open a PR with clear behavior changes and evidence

> [!TIP]
> For new work, prefer modern patterns documented in the guide:
> explicit source names, reusable `beforeAll` data, deterministic detection, and clear normalization pipelines.

## External Links

- Repository: [metricshub/community-connectors](https://github.com/metricshub/community-connectors)
- MetricsHub Website: [metricshub.com](https://metricshub.com)
