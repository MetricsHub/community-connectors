keywords: decode, base64, string
description: Use the "decode" compute operation to reverse an encoding (e.g., Base64) applied to a selected column.

# `decode`

The `Decode` compute reverses an encoding previously applied to the values in the selected column.
It can be used to retrieve the original text from Base64 or other supported encodings.

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
          - type: decode
            column: # <number>
            encoding: # <string> # e.g., base64
```