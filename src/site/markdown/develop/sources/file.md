keywords: file, path, log, flat
description: The "file" source reads content from local or remote files, with incremental reading (LOG mode) or full-file reading (FLAT mode).

# File (Source)

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
          type: file
          paths: # <string-array> | globs are supported (e.g. /opt/metricshub/logs/*.log)
          maxSizePerPoll: # <string> | size in bytes or shorthand (e.g. 5Mb); -1 for unlimited, default 5 MB
          mode: # <enum> | possible values: [ LOG, FLAT ]; default LOG
          forceSerialization: # <boolean>
          executeForEachEntryOf: # <object>
            source: # <string>
            concatMethod: # oneOf [ <enum>, <object> ] | possible values for <enum> : [ list, json_array, json_array_extended ]
              concatStart: # <string>
              concatEnd: # <string>
          computes: # <compute-object-array>
```
