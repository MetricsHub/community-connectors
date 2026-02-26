keywords: develop, afterAll
description: This section defines the sources to be executed after each monitoring job.

# afterAll (Section)

Under the **afterAll** section, define the sources to be executed after all monitoring jobs to properly finalize monitoring processes (closing sessions, cleaning up temporary resources, or any other post-monitoring task).

## Format

```yaml
connector:
  # ...

afterAll:
 <sourceName>: # <object>
```

Each source declared under **afterAll** must follow the format described on its dedicated page in the [Sources Section](index.md).
