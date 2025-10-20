keywords: encode, base64, string
description: Use the "encode" compute operation to apply an encoding (e.g., Base64) to a selected column.

# `encode`

Use the `encode` compute to encode the text of a specific column, using either `base64` or `url` encoding.

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

The following example encodes the content of column `2` using `base64`:

```yaml
computes:
  - type: encode
    column: 2
    encoding: base64
```