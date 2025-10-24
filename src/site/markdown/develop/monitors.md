keywords: develop, monitors
description: How to configure a monitor in a connector file to discover and collect metrics for a specific resource.

# Monitors

<!-- MACRO{toc|fromDepth=1|toDepth=2|id=toc} -->

A monitor defines how **MetricsHub** collects metrics for a specific resource in your target platform.

For each monitor, you must specify:

* its name
* the `sources` to be used by **MetricsHub** to collect metrics
* how the collected metrics are mapped (`mapping`) to **MetricsHub**’s monitoring model

On this page, you will learn how to configure a monitor in your connector file to collect metrics for a specific resource.

## Prerequisites

Before configuring your monitor(s), you should have:

* created your connector file `<your-connector-name>.yaml` and stored it under `metrics-hub/connectors/<connector-folder>`
* configured the [connector general settings](./connector.md), including its name, general information, targeted platform, instrumentation layer, and other metadata parameters.
* configured the [detection criteria](./detection/index.md).

## Procedure

### Step 1 - Configure Your Monitor

While configuring your monitor, you can choose between two strategies:

* **Running separate discovery and collect jobs**.
  **MetricsHub** will run the `discovery` job first to identify the resources to monitor, then the `collect` job to gather metrics from those resources
* **Using a single simple job that performs both steps**.
  MetricsHub** will discover resources and collect their metrics in a single step.

#### Option 1 - Running separate discovery and collect jobs

Paste the following section in your connector file:

```yaml
connector:
  # ...
monitors:
  <monitorName>: # <object>
    keys: # <string-array> | Only for monitors with multiInstance collect or simple job | Default: [ id ]
    discovery: # <object>
      executionOrder: # <string-array> | Optional
      sources: # <object>
    collect: # <object>
      type: # <string> | possible values [ multiInstance, monoInstance ]
      executionOrder: # <string-array> | Optional
      sources: # <object>
```

Then:

* replace `<monitorName>` with the actual monitor name
* define the `keys` parameter: Use it to identify each instance when multiple instances of the resource exist. By default, it references the `[ id ]` array. To use different identifiers, replace `[ id ]` with your own array of keys.
* configure the `discovery` job:
  * optionally specify the `executionOrder`
  * declare the `sources` as documented on the [Sources](./sources/index.md) page
* define the `collect` job:
  * set the `type`:
    * * `monoInstance` when only one instance exists
    * `multiInstance` when multiple instances may exist.
* define the `sources` as documented on the [Sources](./sources/index.md) page.

#### Option 2 - Using a single simple job

Paste the following section in your connector file:

```yaml
connector:
  # ...
monitors:
  <monitorName>: # <object>
    keys: # <string-array> | Default: [ id ]
    simple: # <object>
      executionOrder: # <string-array> | Optional
      sources: # <object>
```

Then:

* replace `<monitorName>` with the actual monitor name
* Define the `keys` parameter. By default, it references the `[ id ]` array. To use different identifiers for your resources, replace `[ id ]` with your own array of keys.
* define the `sources` as documented on the [Sources](./sources/index.md) page.

##### Example extracted from the IPMI connector (MetricsHub/connectors/hardware/IpmiTool/IpmiTool.yaml)

```yaml
monitors:
  enclosure:
    keys: [ id ]
    discovery:
      sources:
        source(1):
          type: ipmi
          computes:
          - type: awk
            script: ${esc.d}{file::enclosure.awk}
    collect:
      type: multiInstance
      sources:
        source(1):
          type: ipmi
          computes:
          - type: awk
            script: ${esc.d}{file::enclosure.awk}

```

### Step 2 - Map Collected Metrics and Attributes

Paste the `mapping` section in your connector file:

```yaml
connector:
  # ...

monitors:
  <monitorType>: # <object>
    <job>: # <object>
      # ...
      mapping:
        source: ${esc.d}{source::monitors.temperature.discovery.sources.source(1)}
        attributes:
          <key>: # <string>
        metrics:
          <key>: # <string>
        conditionalCollection:
          <key>: # <string> # Only collect if <key> evaluates to an non-empty value
```

This section allows mapping the collected data to MetricsHub’s monitoring model:

* Under `attributes`, define intrinsic information about the monitor (for example, its name, identifier, or serial number) using key–value pairs
* Under `metrics`, define the metrics collected from the resource
* Under `conditionalCollection`, specify the mapping keys that must have a non-empty value to enable the collection of their corresponding metrics.

You can also use the following mapping functions:
  
* `fakeCounter` to simulate a counter operation based on a value expressed as a rate
* `rate` to calculate a rate from counter values.

##### Example

```yaml
mapping:
  source: ${esc.d}{source::monitors.temperature.simple.sources.source(1)}
  attributes:
    id: ${esc.d}2
    sensor_location: ${esc.d}3
  metrics:
    hw.temperature: ${esc.d}5
  conditionalCollection:
    hw.temperature: ${esc.d}5 # Only collect if hw.temperature has a value
```

### Step 3 - Define the OpenTelemetry Metrics Metadata to be Collected

Add the `metrics` section to your connector file to describe the OpenTelemetry metrics metadata (name, unit, description, and type) that your monitor will collect and export:

```yaml
connector:
  # ...

metrics:
  <metricName>: # <object>
    unit: # <string>
    description: # <string>
    type: # oneOf [ <enum>, <object> ] | possible values for <enum> [ Gauge, Counter, UpDownCounter ]
      stateSet: # <string-array>
      output: # <enum> | possible values [ Gauge, Counter, UpDownCounter ] | Optional | Default: UpDownCounter
```

##### Example extracted from the Hardware semconv connector (MetricsHub/connectors/semconv/Hardware.yaml)

```yaml
metrics:
  hw.temperature:
    description: Temperature of the component.
    type: Gauge
    unit: Cel
  hw.status:
    description: 'Operational status: 1 (true) or 0 (false) for each of the possible states.'
    type:
      stateSet:
      - degraded
      - failed
      - ok  

```

### Step 4 - (Optional) Override Connector-Level metrics

If you want a monitor's metrics to override the default connector-level metrics, include the following section:

```yaml
connector:
# ...

monitors:
  <monitorType>: # <object>
    metrics:
      <metricName>: # <object>
        unit: # <string>
        description: # <string>
        type: # oneOf [ <enum>, <object> ] | possible values for <enum> [ Gauge, Counter, UpDownCounter ]
          stateSet: # <string-array>
          output: # <enum> | possible values [ Gauge, Counter, UpDownCounter ] | Optional | Default: UpDownCounter
```

##### Example

```yaml
monitors:
  voltage:
    metrics:
      hw.voltage:
        unit: V
        description: Per-instance voltage with monitor override
        type: Gauge
```
