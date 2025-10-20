keywords: encode, base64, string
description: Use the "encode" compute operation to apply an encoding (e.g., Base64) to a selected column.

# `encode`

Use the `Encode` compute to encode the text value in the selected column.

**Supported encodings:**
- `base64` — encodes values using Base64.
- `url` — encodes values using URL encoding.

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
Example:

The following example encodes the contents of column 2 using Base64:

```yaml
computes:
  - type: encode
    column: 2
    encoding: base64
```