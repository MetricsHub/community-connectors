keywords: develop, beforeAll
description: This section defines the sources to be executed before each monitoring job.

# beforeAll (Section)

Under the **beforeAll** section, define the sources to be executed before all the monitoring jobs to set the connections or perform preparatory actions.

## Format

```yaml
connector:
  # ...

beforeAll:
 <sourceName>: # <object>
```

Each source declared under **beforeAll** must follow the format described on its dedicated page in the [Sources Section](index.md).
