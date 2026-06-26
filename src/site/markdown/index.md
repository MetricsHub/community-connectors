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
> The **official implementation guide** is the [Connector Developer Guide](developer-guide/index.html).
> Use it as the single source of truth for connector structure, detection, sources, computes, mapping, and testing.

## Who This Site Is For

- Developers adding monitoring support for new platforms
- Contributors maintaining existing connectors
- Reviewers validating connector quality, consistency, and compatibility

## What You Will Find Here

- A complete developer guide in `developer-guide/...`
- Generated library views:
  - [Supported Platforms](supported-platforms.html)
  - [Connectors Directory](connectors-directory.html)

## Recommended Learning Path

If you are new to connector development, read in this order:

1. [Developer Guide Home](developer-guide/index.html)
2. [Quick Start](developer-guide/quick-start.html)
3. [YAML Structure](developer-guide/yaml-structure.html)
4. [Design Principles](developer-guide/design-principles.html)
5. [Detection](developer-guide/detection/index.html)
6. [Sources](developer-guide/sources/index.html)
7. [Computes](developer-guide/computes/index.html)
8. [Mapping, Metrics, and Semconv](developer-guide/mapping-metrics-semconv.html)
9. [Integration Testing](developer-guide/integration-testing.html)
10. [Legacy and Compatibility](developer-guide/legacy-and-compatibility.html)

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
