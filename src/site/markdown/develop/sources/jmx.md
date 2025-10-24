keywords: jmx, java, monitoring
description: The JMX source retrieves information from any resource exposed through JMX, such as Java applications or individual JMX MBeans.

# JMX (Source)

The **JMX** source enables the collection of metrics and attributes from resources that expose their management information through Java Management Extensions (JMX). This source is particularly useful for monitoring Java applications and services that provide JMX interfaces.


```yaml
connector:
  # ...
beforeAll: # <object>
  <sourceKey>: # <source-object>

monitors:
  <monitorType>: # <object>
    <job>: # <object>
      sources: # <object>
        <sourceKey>:
          type: jmx
          objectName: # <string>
          attributes: # <string-array>
          keyProperties: # <string-array>
          forceSerialization: # <boolean>
          computes: # <compute-object-array>
```
