keywords: awk, compute, JAWK, script, parsing, variables, arrays, keep, selectColumns
description: Runs an AWK script over the source result with optional scalar and source-table variables, then rebuilds the table with line filtering and column selection.

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
| `variables` | No | `{}` | Map of AWK variable names to values. Source references become arrays of rows; other values become scalars. See [Variables](#variables). |
| `keep` | No | None | Regular expression; only **output** lines of the script that match are kept. |
| `exclude` | No | None | Regular expression; matching **output** lines are discarded. |
| `separators` | No | None | Character(s) splitting each remaining output line into columns. Required for `selectColumns` to have any effect. |
| `selectColumns` | No | None | Comma-separated **1-based** column numbers to keep after splitting with `separators`, e.g. `"2,3,4"`. |
| `input` | No | `text` | How the script reads the source result: `text` (the raw text, or the table serialized as `;`-separated lines) or `table` (each row is a record whose cells are `$1..$NF`, nothing is serialized). See [Table input and output](#table-input-and-output). |
| `output` | No | `text` | What the script produces: `text` (the printed lines, re-parsed into a table with `keep`, `exclude`, `separators` and `selectColumns`) or `table` (each `print a, b, c` is one row `[a, b, c]`; `printf` text is split into rows on `ORS` and into cells on `OFS`; the filtering properties do not apply). |

## Table Input And Output

By default the script reads text and prints text, and the printed lines are re-parsed into a table on `;`. A `;` inside a value therefore moves the following columns, in the input as in the output.

With `input: table`, the script reads the table itself: each row is one record, each cell one field (`$1..$NF`), whatever it contains. `FS` plays no part. `$0` is only synthesized (cells joined with `OFS`) when the script reads it.

With `output: table`, each `print` call is one row and its arguments are the cells (`print $1, $2 * 2, "ok"` gives three cells), whatever they contain: `OFS` and `ORS` play no part, and a `;` is a plain character. `print` without argument (or `print $0`) is one row with a single cell holding the whole record: print the fields instead (`print $1, $2, $3`).

The text written by `printf` is split into rows on `ORS` and into cells on `OFS` (the `OFS` in effect when the row began). Use it for a row whose number of cells varies:

```awk
BEGIN { OFS = ";" }
{ printf "%s", $1; for (i = 2; i <= NF; i++) printf "%s%s", OFS, $i; printf "\n" }
```

```yaml
sources:
  fans:
    type: snmpTable
    oid: 1.3.6.1.4.1.674.10892.5.4.700.12.1
    selectColumns: "ID,2,5,6"
    computes:
    - type: awk
      input: table
      output: table
      script: |
        $3 > 0 { print $1, $2, $3 / 60, "ok" }
```

The two properties are independent: a script written for text input can produce a table, and the reverse.

> [!NOTE]
> A script written before `input: table` existed reads text, since the default is `text`: the engine inserts the serialization (`toText`) before an `awk` compute that follows a table source, so existing scripts setting `FS = ";"` keep working. Only a script declaring `input: table` reads the table as records.

## Variables

AWK computes accept the same `variables` map as [AWK sources](../sources/awk.html#variables): literals and resolved resource/monitor attributes or protocol properties become scalars, while source references become arrays accessed as `aTable[row][column]` with **zero-based** indexes. Variables are available before `BEGIN` runs and work with both inline scripts and embedded `.awk` files.

For example, append the hostname and a scaled value to each semicolon-separated input row:

```yaml
computes:
  - type: awk
    variables:
      hostname: ${resource.attribute::host.name}
      scale: "2"
    script: |
      {
        split($0, fields, ";")
        print fields[1] ";" (fields[2] * scale) ";" hostname
      }
    separators: ;
```

For input `disk0;100` and hostname `server01`, the output table contains `disk0`, `200`, and `server01`. The script uses `split()` to read the input fields and prints semicolon-separated values; `separators` splits the printed output into table columns.

To access another source's table, add a variable such as `aTable: ${source::monitors.disk.discovery.sources.raw}` and read `aTable[0][0]` for its first cell or `length(aTable)` for its row count. Ensure that source has already run. The compute still receives its current source result as normal AWK input; variables provide additional data. See the [source-table example and empty-source behavior](../sources/awk.html#variables).

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
- Keeping `FS = ";"` and `split($0, a, ";")` in a script declared with `input: table`: the fields are the cells already, and `$0` is the cells joined with `OFS` (a space by default), not with `;`.
- Printing a `;`-joined string with `output: table`: `print $1 ";" $2` gives one cell holding `a;b`, not two cells. Print the values as separate arguments.
- Setting `selectColumns` without `separators`: the lines are never split, so the selection does nothing.
- Expecting `keep`/`exclude` to filter the script's *input* — they filter its *output*. Filter input inside the script itself.
- A script that prints nothing empties the table, and every downstream compute and mapping silently gets no rows.
- Confusing zero-based source-table array indexes (`aTable[0][0]`) with one-based AWK record fields (`$1`) or `selectColumns` numbers.

## Community Examples

- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml)
- [lmsensors](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/lmsensors/lmsensors.yaml)
- [LinuxService](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/LinuxService/LinuxService.yaml) (inline script)

From `DiskPart`, included directly from the connector source:

<!-- MACRO{snippet|id=awkCompute|file=src/main/connector/hardware/DiskPart/DiskPart.yaml} -->
