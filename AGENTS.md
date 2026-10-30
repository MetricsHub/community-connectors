# Instructions for AI Agents

## Connector Tools

A connector may declare tools under its `tools:` section: operations an AI assistant runs on a host through the MetricsHub Agent, advertised as `<connectorId>_<toolName>`. The connector developer guide describes the section itself (`src/site/markdown/develop/tools.md`).

When you add, rename or change such a tool, document it in the user documentation as well, in the `MetricsHub/metricshub-doc` repository, page `docs/integrations/ai-agent-integration.md`, section "Connector tools": the advertised name, each parameter (type, required or default value) and a one-line description of what the tool returns. A tool that changes the state of the host is declared `destructive: true` and marked as such there.
