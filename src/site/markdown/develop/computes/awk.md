keywords: awk, compute, JAWK, script, parsing, variables, arrays, output
description: Runs an AWK script over the source result with optional scalar, list, map and source-table variables, and gives what the script prints as a text or as a table.

# awk (Compute)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use the `awk` compute for parsing jobs that simpler computes cannot express: turning free-form command output into rows, correlating multi-line records, or computing derived values. The script receives the source's current result as its input, as it is: a text (e.g. `commandLine` output) is read the traditional way, one record per line split on `FS`; a table is read structured, one record per row, one field per cell. Its printed output becomes the new result.

MetricsHub embeds **JAWK**, a Java implementation of the AWK language, with a few MetricsHub utility functions and the GNU awk (`gawk`) functions listed in [Functions](#functions). JAWK implements only part of gawk: do not assume that a gawk feature or function that is not listed there is available.

This compute transforms an existing source's result. If the script itself *is* the source (computing over an explicit `input`), use the [`awk` source](../sources/awk.html) instead.

## Syntax

```yaml
sources:
  volumes:
    type: commandLine
    commandLine: cmd /c ${file::diskpart.bat}
    computes:
    # Each print of the script is one row
    # ID;Label;Letter;VolumeType;FileSystem;Size;Status;MoreInformation
    - type: awk
      script: ${file::diskPart.awk}
      output: table
```

`script` may also be written inline as a YAML block scalar (see LinuxService for a real example).

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `awk`. |
| `script` | Yes | None | The AWK script: an embedded-file reference `${file::script.awk}` (a file next to the connector), or the script text itself, typically as a YAML block scalar (`script: \|`). |
| `variables` | No | `{}` | Map of AWK variable names to values. Source references become arrays of rows, lists and maps become arrays, other values become scalars. See [Variables](#variables). |
| `output` | No | `text` | What the script produces: `text` (the printed lines, exactly as the script prints them) or `table` (each `print a, b, c` is one row `[a, b, c]`; a `print` without argument is one row of the record's fields `$1..$NF`; `printf` text is split into rows on `ORS` and into cells on `OFS`). |

The script selects its lines and its columns itself: the `awk` compute has no `keep`, `exclude`, `separators`, `selectColumns` or `input` property, and a connector that sets one does not load (`DEPRECATED_SYNTAX`, see [Legacy and Compatibility](../legacy-and-compatibility.html)).

## Table Input And Output

The script reads the source result as it is. A text is read the traditional way: each line is a record, split into fields on `FS`. A table is read structured: each row is one record, each cell one field (`$1..$NF`), whatever it contains. `FS` does not split the row, and `$0` is only synthesized when the script reads it: the cells joined with the `FS` in effect when the row was read (a space by default), or with `OFS` once the script assigns a field or `NF`.

To parse a table as text (the `;`-joined line, for instance with `split($0, a, ";")`), write a [toText](./to-text.html) before the `awk`: it serializes each row as `;`-separated cells ending with `;`, and turns a `;` inside a cell into `,`.

By default the script prints text. To read the result as a table (by a table compute, the `mapping`, ...), write a `toTable` after the `awk`, or declare `output: table`: MetricsHub inserts no conversion, and a text read as a table is rejected when the connector loads (`TEXT_FEEDS_TABLE`, see [Strict Content Types](../design-principles.html#strict-content-types)). The `toTable` splits the printed lines on `;`: a `;` inside a printed value therefore moves the following columns.

With `output: table`, each `print` call is one row and its arguments are the cells (`print $1, $2 * 2, "ok"` gives three cells), whatever they contain: `OFS` and `ORS` play no part, and a `;` is a plain character. `print` without argument (and a pattern without action) writes the record's fields `$1..$NF` as the cells, as the script left them: assigned fields and a changed `NF` included, a record without fields giving one empty cell. `$2 != "" { print }` keeps the rows whose second cell is not empty, and `{ $3 = toupper($3); print }` rewrites a column. `print $0` is one row with a single cell holding the whole record.

The text written by `printf` is split into rows on `ORS` and into cells on `OFS` (the `OFS` in effect when the row began), so a value that holds the `OFS` is split too. Use `printf` for a row built piece by piece, with `OFS = SUBSEP` (a character that never appears in data): each value stays one cell, even when it holds a `;`. To write the record's fields, a `print` without argument is simpler.

```awk
BEGIN { OFS = SUBSEP }
{ printf "%s", $1; for (i = 3; i <= NF; i += 2) printf "%s%s", OFS, $i; printf "\n" }
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
> An `awk` compute that follows a table reads the rows, not `;`-separated lines: `NF` is the number of cells (no trailing empty field), a `;` inside a cell stays in its field, and `$0` is the cells joined with `FS` (a space by default). A script written for the `;` lines (`FS = ";"`, `split($0, a, ";")`, `print $0`) needs an explicit `toText` before it.

## Variables

AWK computes accept the same `variables` map as [AWK sources](../sources/awk.html#variables): literals and resolved resource/monitor attributes or protocol properties become scalars, source references become arrays accessed as `aTable[row][column]` with **zero-based** indexes, and [YAML lists and maps](../sources/awk.html#lists-and-maps) become arrays. Variables are available before `BEGIN` runs and work with both inline scripts and embedded `.awk` files.

For example, scale the second value of each input row and add the hostname:

```yaml
computes:
  - type: awk
    output: table
    variables:
      hostname: ${resource.attribute::host.name}
      scale: "2"
    script: |
      { print $1, $2 * scale, hostname }
```

For the input row `disk0`, `100` (a table row, or the text line `disk0 100`) and hostname `server01`, the result row holds `disk0`, `200`, and `server01`: with `output: table`, each argument of `print` is one cell (see [Table Input And Output](#table-input-and-output)).

To access another source's table, add a variable such as `aTable: ${source::monitors.disk.discovery.sources.raw}` and read `aTable[0][0]` for its first cell or `length(aTable)` for its row count. Ensure that source has already run. The compute still receives its current source result as normal AWK input; variables provide additional data. See the [source-table example and empty-source behavior](../sources/awk.html#variables).

## Functions

Besides the POSIX AWK functions (`length`, `substr`, `split`, `sprintf`, `tolower`...), a script can call:

| Functions | Description |
| --- | --- |
| `join(separator, value, ...)` | The values joined with the separator: `join(" ", $2, $3)`. |
| `base64Encode(text)` | The Base64 encoding of the UTF-8 text. |
| `bytes2HumanFormatBase2(bytes)`, `bytes2HumanFormatBase10(bytes)` | A size in bytes as text with 2 decimals and a binary (`1.00 GiB`) or decimal (`1.00 GB`) unit. |
| `mebiBytes2HumanFormat(mebibytes)` | A size in MiB as text: `1.00 TiB`. |
| `megaHertz2HumanFormat(megahertz)` | A frequency in MHz as text: `4.00 GHz`. |
| `sleep(seconds)` | Pauses the script and returns 0, or -1 for a negative duration. The duration can have a fractional part (`sleep(0.1)` is 100 ms), and one call pauses for 60 seconds at most. |
| `asort`, `asorti` | Sort an array by value or by index (`n = asorti(ids, sorted)`). |
| `gensub(regexp, replacement, how [, target])` | The substituted text, with `\\1`..`\\9` back-references, without changing the target. |
| `patsplit(string, array [, fieldpat [, seps]])` | Split a string by the content of its fields rather than by separators. |
| `strtonum(text)` | A number from decimal, `0x` hexadecimal or `0` octal text. |
| `systime()`, `mktime(datespec [, utc])`, `strftime([format [, timestamp [, utc]]])` | The current time, a `"YYYY MM DD HH MM SS"` date as seconds since the epoch, and a timestamp formatted with `strftime(3)` conversions. |
| `typeof(x)`, `isarray(x)`, `mkbool(x)` | The type of a value, whether it is an array, and a boolean value. |
| `bindtextdomain`, `dcgettext`, `dcngettext` | gawk's message translation functions. With no message catalog, they return the text untranslated. |

The names of the gawk functions are reserved: a script cannot name a variable or a function `asort`, `asorti`, `gensub`, `patsplit`, `strtonum`, `systime`, `mktime`, `strftime`, `typeof`, `isarray`, `mkbool`, `bindtextdomain`, `dcgettext` or `dcngettext`.

An [`awk` source](../sources/awk.html) can also run sources and convert JSON: `executeHttpRequest`, `json2Table(json, entryKey, properties, rows)`, `getVariable`...

## Table Transformation Example

The `diskPart.awk` script of the [Syntax](#syntax) example reads the output of DiskPart and, for each volume, calls `print volumeID, displayID, letter, type, fs, size, status, info`:

> [!TABS]
>
> - <span class="fa-regular fa-file-lines"></span> Input (raw command output)
>
>   ```text
>     Volume ###  Ltr  Label        Fs     Type        Size     Status     Info
>     ----------  ---  -----------  -----  ----------  -------  ---------  --------
>     Volume 0     C   System       NTFS   Partition    237 GB  Healthy    Boot
>     Volume 1     D   Data         NTFS   Partition    931 GB  Healthy
>   ```
>
> - <span class="fa-solid fa-table-list"></span> Result
>
>   | ID | Label | Letter | VolumeType | FileSystem | Size | Status | MoreInformation |
>   | --- | --- | --- | --- | --- | --- | --- | --- |
>   | 0 | C: - System | C: | | NTFS | 254476812288 | Healthy | Volume Information: Boot |
>   | 1 | D: - Data | D: | | NTFS | 999653638144 | Healthy | |

With `output: table`, each `print` is one row and each of its arguments one cell, an empty one included. The script prints nothing for the other lines (the header, the dashes): the result needs no marker column and no `toTable`.

## Functions And Sandbox

A compute script can call the MetricsHub functions available [in every script](../sources/awk.html#in-every-script): `bytes2HumanFormatBase2`, `join`, `base64Encode`, `sleep`, and the others. The functions that query the monitored resource (`executeHttpRequest`, ...) belong to the [`awk` source](../sources/awk.html#in-the-awk-source) only.

A script runs in a [sandbox](../sources/awk.html#sandbox): it cannot run a command (`system()`, `"command" | getline`), nor read or write a file (`getline < "file"`, `print > "file"`).

MetricsHub [compiles the script the first time it runs](../sources/awk.html#compilation), and logs a script that does not compile then. It replaces no `${param::...}`, `${attribute::...}` or `${source::...}` written in a script. A `${file::...}` written in a script does not give the text of the file: inside a script that is an embedded file, it stays as text; anywhere in an inline script, it makes MetricsHub run that file as the whole script instead of the inline text. Pass each of these values through [`variables`](#variables).

## Recommended Pattern

- Declare `output: table` when the result is read as a table, and print one argument per cell (`print id, name, status`): this is what the community connectors do (DiskPart, lmsensors, SmartMonLinux).
- Print the same number of cells in every row, so mapping stays predictable.
- Keep long scripts in dedicated `.awk` embedded files referenced with `${file::...}`; reserve inline block scalars for short scripts.
- Put the `awk` compute first in the pipeline, then refine with cheaper computes (`translate`, `keepOnlyMatchingLines`...).

## Common Mistakes

- Naming a variable or a function after a gawk function (`gensub`, `asort`, `strftime`...): these names are reserved, and the script does not compile.
- Relying on a gawk feature or function that [Functions](#functions) does not list: JAWK implements only part of gawk.
- Using `split($0, a, ";")` or `print $0` in a script that follows a table: the fields are the cells already, and `$0` is the cells joined with `FS` (a space by default), with no trailing `;`. Read `$1..$NF`, or write a `toText` before the `awk` to parse the `;` lines.
- Printing a `;`-joined string with `output: table`: `print $1 ";" $2` gives one cell holding `a;b`, not two cells. Print the values as separate arguments.
- Writing a row with `printf` and `OFS = ";"` with `output: table`: a value holding a `;` becomes two cells. Use `print` with one argument per cell, a `print` without argument for the record's fields, or set `OFS = SUBSEP` for a `printf` row.
- A script that prints nothing empties the table, and every downstream compute and mapping silently gets no rows.
- Confusing zero-based source-table array indexes (`aTable[0][0]`) with one-based AWK record fields (`$1`).

## Community Examples

- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml)
- [lmsensors](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/lmsensors/lmsensors.yaml)
- [LinuxService](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/LinuxService/LinuxService.yaml) (inline script)

From `DiskPart`, included directly from the connector source:

<!-- MACRO{snippet|id=awkCompute|file=src/main/connector/hardware/DiskPart/DiskPart.yaml} -->
