keywords: source
description: Defines how to query the monitored system to retrieve the required data and metrics.

# Sources

<div class="alert alert-warning"><span class="fa-solid fa-person-digging"></span> Documentation under construction...</div>

A source defines how to query the monitored system to retrieve the required data and metrics.

Configure sources under:

* the **[beforeAll](./before-all.md)** section to execute them before any monitoring job
* the **[afterAll](./after-all.md)** section to execute them  after all monitoring jobs
* the **[monitors](../monitors.md)** section to execute them as part of a monitoring job workflow.

## Format

```yaml
connector:
  # ...
beforeAll: # <object>
  <sourceKey>: # <source-object>

monitors:
  <monitorType>: # <object>
    <job>: # <object>
      sources: # <object>
        <sourceKey>: # <source-object>

afterAll: # <object>
  <sourceKey>: # <source-object>

```

Each source must define a set of computes, as described in the [Computes Section](../computes/index.md).
