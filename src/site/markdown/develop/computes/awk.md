keywords: awk, compute, JAWK, script, parsing, keep, selectColumns
description: Runs an AWK script over the source result and rebuilds the table from the script's output, with optional line filtering and column selection.

# awk (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use the `awk` compute for parsing jobs that simpler computes cannot express: reshaping free-form command output into semicolon-separated rows, correlating multi-line records, or computing derived values. The script receives the source's current result as its input — the raw text when available (e.g. `commandLine` output), otherwise the table serialized as semicolon-separated lines — and its printed output becomes the new table.

MetricsHub embeds **JAWK**, a Java implementation of the AWK language, extended with a few MetricsHub utility functions. Standard AWK constructs work; do not assume GNU awk (`gawk`) extensions are available.

This compute transforms an existing source's result. If the script itself *is* the source (computing over an explicit `input`), use the [`awk` source](../sources/awk.html) instead.

## Syntax

```yaml
sources:
  volumes:
    type: commandLine
    commandLine: cmd /c ${file::diskpart.bat}
    computes:
    # The script prints: MSHW;ID;Label;Letter;VolumeType;FileSystem;Size;Status
    - type: awk
      script: ${file::diskPart.awk}
      keep: ^MSHW;
      separators: ;
      selectColumns: "2,3,4,5,6,7,8"
```

`script` may also be written inline as a YAML block scalar (see LinuxService for a real example).

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `awk`. |
| `script` | Yes | None | The AWK script: an embedded-file reference `${file::script.awk}` (a file next to the connector), or the script text itself, typically as a YAML block scalar (`script: \|`). |
| `keep` | No | None | Regular expression; only **output** lines of the script that match are kept. |
| `exclude` | No | None | Regular expression; matching **output** lines are discarded. |
| `separators` | No | None | Character(s) splitting each remaining output line into columns. Required for `selectColumns` to have any effect. |
| `selectColumns` | No | None | Comma-separated **1-based** column numbers to keep after splitting with `separators`, e.g. `"2,3,4"`. |

## Table Transformation Example

Suppose `diskPart.awk` prints one `MSHW;`-prefixed line per volume; `keep`, `separators`, and `selectColumns` then clean up its output:

> [!TABS]
>
> - <span class="fa-solid fa-table-list"></span> Input (raw command output)
>
>   | Raw line |
>   | --- |
>   | Volume 0 &nbsp; C &nbsp; System &nbsp; NTFS &nbsp; Partition &nbsp; 237 GB &nbsp; Healthy |
>   | Volume 1 &nbsp; D &nbsp; Data &nbsp; NTFS &nbsp; Partition &nbsp; 931 GB &nbsp; Healthy |
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | ID | Label | Letter | VolumeType | FileSystem | Size | Status |
>   | --- | --- | --- | --- | --- | --- | --- |
>   | 0 | System | C | Partition | NTFS | 254568116160 | Healthy |
>   | 1 | Data | D | Partition | NTFS | 999784378368 | Healthy |

Between the two, the script's serialized output looked like:

```text
MSHW;0;System;C;Partition;NTFS;254568116160;Healthy
MSHW;1;Data;D;Partition;NTFS;999784378368;Healthy
```

The `keep: ^MSHW;` filter drops any stray script output, and `selectColumns` removes the `MSHW` marker column.

## Recommended Pattern

- Prefix intentional output lines with a marker (`MSHW;` by convention) and filter with `keep: ^MSHW;` — this is the standard community pattern (DiskPart, lmsensors, LinuxNetwork).
- Emit semicolon-separated values with a constant column count so mapping stays predictable.
- Keep long scripts in dedicated `.awk` embedded files referenced with `${file::...}`; reserve inline block scalars for short scripts.
- Put the `awk` compute first in the pipeline, then refine with cheaper computes (`translate`, `keepOnlyMatchingLines`...).

## Common Mistakes

- Relying on GNU awk extensions (`gensub`, `asort`, coprocesses...) that JAWK does not provide.
- Setting `selectColumns` without `separators`: the lines are never split, so the selection does nothing.
- Expecting `keep`/`exclude` to filter the script's *input* — they filter its *output*. Filter input inside the script itself.
- A script that prints nothing empties the table, and every downstream compute and mapping silently gets no rows.

## Community Examples

- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml)
- [lmsensors](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/lmsensors/lmsensors.yaml)
- [LinuxService](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/LinuxService/LinuxService.yaml) (inline script)

From `DiskPart`, included directly from the connector source:

<!-- MACRO{snippet|id=awkCompute|file=src/main/connector/hardware/DiskPart/DiskPart.yaml} -->
