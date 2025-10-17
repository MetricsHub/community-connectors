keywords: encode, base64, string
description: Use the "encode" compute operation to apply an encoding (e.g., Base64) to a selected column.

# `encode`

The `Encode` compute applies an encoding to all values in the selected column.

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
          computes: # <compute-object-array>
          - type: encode
            column: # <number>
            encoding: # <string> # possible values [ base64, url ]
```