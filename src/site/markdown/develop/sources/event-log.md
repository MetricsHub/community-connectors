keywords: event log, windows
description: The "eventLog" source retrieves data from Windows Event Logs for MetricsHub.

# Event Log (Source)

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
          type: eventLog
          logName: # <string>
          eventIds: # <string-array>
          sources: # <string-array>
          levels: # <enum-array> | possible values: [ Error, Warning, Information, Audit Success, Audit Failure ] or codes 1-5
          maxEventsPerPoll: # <integer>
          forceSerialization: # <boolean>
          executeForEachEntryOf: # <object>
            source: # <string>
            concatMethod: # oneOf [ <enum>, <object> ] | possible values for <enum> : [ list, json_array, json_array_extended ]
              concatStart: # <string>
              concatEnd: # <string>
          computes: # <compute-object-array>
```
