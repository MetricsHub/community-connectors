keywords: awk, compute, JAWK, script, parsing, variables, arrays, keep, selectColumns
description: Runs an AWK script over the source result with optional scalar and source-table variables, then rebuilds the table with line filtering and column selection.

# awk (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use the `awk` compute for parsing jobs that simpler computes cannot express: reshaping free-form command output into semicolon-separated rows, correlating multi-line records, or computing derived values. The script receives the source's current result as its input, as it is: a text (e.g. `commandLine` output) is read the traditional way, one record per line split on `FS`; a table is read structured, one record per row, one field per cell. Its printed output becomes the new result.

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
| `input` | No | None | Deprecated and ignored: the script reads the source result as it is (a text the traditional way, a table structured). Still accepted so that existing connectors load, and reported (`DEPRECATED_SYNTAX`): remove it. To read a table as `;`-separated lines, write a [toText](./to-text.html) before the `awk`. |
| `output` | No | `text` | What the script produces: `text` (the printed lines, filtered with `keep`, `exclude`, `separators` and `selectColumns`, each ending with `;`) or `table` (each `print a, b, c` is one row `[a, b, c]`; `printf` text is split into rows on `ORS` and into cells on `OFS`; the filtering properties do not apply). |

## Table Input And Output

The script reads the source result as it is. A text is read the traditional way: each line is a record, split into fields on `FS`. A table is read structured: each row is one record, each cell one field (`$1..$NF`), whatever it contains. `FS` plays no part, and `$0` is only synthesized (cells joined with `OFS`, a space by default) when the script reads it.

To parse a table as text (the `;`-joined line, for instance with `split($0, a, ";")`), write a [toText](./to-text.html) before the `awk`: it serializes each row as `;`-separated cells ending with `;`, and turns a `;` inside a cell into `,`.

By default the script prints text. When the result is read as a table (by a table compute, the `mapping`, ...), the printed lines go through `toTable`, which splits them on `;`: a `;` inside a printed value therefore moves the following columns. MetricsHub inserts this `toTable` when you do not write it, and reports it (`TEXT_FEEDS_TABLE`, see [Strict Content Types](../design-principles.html#strict-content-types)): write the `toTable` after the `awk`, or declare `output: table`.

With `output: table`, each `print` call is one row and its arguments are the cells (`print $1, $2 * 2, "ok"` gives three cells), whatever they contain: `OFS` and `ORS` play no part, and a `;` is a plain character. `print` without argument (or `print $0`) is one row with a single cell holding the whole record: print the fields instead (`print $1, $2, $3`).

The text written by `printf` is split into rows on `ORS` and into cells on `OFS` (the `OFS` in effect when the row began), so a value that holds the `OFS` is split too. Use `printf` for a row whose number of cells varies, with `OFS = SUBSEP` (a character that never appears in data): each value stays one cell, even when it holds a `;`.

```awk
BEGIN { OFS = SUBSEP }
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
      output: table
      script: |
        $3 > 0 { print $1, $2, $3 / 60, "ok" }
```

`output: table` does not depend on the input: a script reading a text can produce a table, and the reverse.

> [!NOTE]
> An `awk` compute that follows a table reads the rows, not `;`-separated lines: `NF` is the number of cells (no trailing empty field), a `;` inside a cell stays in its field, and `$0` is the cells joined with `OFS`. A script written for the `;` lines (`FS = ";"`, `split($0, a, ";")`, `print $0`) needs an explicit `toText` before it. `input: table` is no longer needed: it is ignored and reported (`DEPRECATED_SYNTAX`).

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
```

For a text input `disk0;100` and hostname `server01`, the output table contains `disk0`, `200`, and `server01`. The script uses `split()` to read the input fields and prints semicolon-separated values, which become the table columns when the result is read as a table (see the [content types](./index.html#content-types)). After a table, read the cells as `$1` and `$2` instead of splitting `$0`.

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
- Using `split($0, a, ";")` or `print $0` in a script that follows a table: the fields are the cells already, and `$0` is the cells joined with `OFS` (a space by default), not with `;`. Read `$1..$NF`, or write a `toText` before the `awk` to parse the `;` lines.
- Printing a `;`-joined string with `output: table`: `print $1 ";" $2` gives one cell holding `a;b`, not two cells. Print the values as separate arguments.
- Writing a row with `printf` and `OFS = ";"` with `output: table`: a value holding a `;` becomes two cells. Use `print` with one argument per cell, or set `OFS = SUBSEP` for a `printf` row.
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
