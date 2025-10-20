keywords: decode, base64, string
description: Use the "decode" compute operation to reverse an encoding (e.g., Base64) applied to a selected column.

# `decode`

Use the `decode` compute operation to reverse the encoding applied to the selected column, using either `base64` or `url` encoding. You can for example use `decode` for retrieving the original text from Base64.

**Supported encodings:**
- `base64` — decodes values using Base64.
- `url` — decodes values using URL encoding.

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
            encoding: # <string> # possible values [ base64, url ]
```

Example:

The following example decodes the content of column `2` using `base64`:

```yaml
computes:
  - type: decode
    column: 2
    encoding: base64
```
