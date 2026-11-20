keywords: awk source, jawk, scripting source, variables, arrays
description: Reference for the awk source type (JAWK), scalar, list, map and source-table variables, and when to prefer compute-level AWK.

# awk (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use source-level `awk` when your source itself is a script computation, consuming an explicit `input` string or source reference, or reading source tables through `variables`.

For most connectors, it is cleaner to:

1. collect with `commandLine`, `http`, `wmi`, or `snmp*`,
2. then transform with compute-level `awk`.

## Syntax

```yaml
sources:
  normalizeInventory:
    type: awk
    input: ${source::beforeAll.inventoryRaw}
    output: table
    script: |
      NF >= 3 { print $1, $2, tolower($3) }
```

Here `inventoryRaw` is a table: each of its rows is a record whose cells are `$1..$NF`, and each `print` writes one row.

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `awk`. |
| `script` | Yes | None | Inline AWK script or `${file::...}` reference. No other reference is replaced in a script: pass values through `variables`, see [Compilation](#compilation). |
| `input` | No | Empty | Input text, or a single source reference such as `${source::beforeAll.inventoryRaw}`: the script reads that source as it is at run time, a table structured (each row is a record whose cells are `$1..$NF`, and `$0`, synthesized only when the script reads it, is the cells joined with `FS`, as in the [`awk` compute](../computes/awk.html#table-input-and-output)), a text the traditional way (lines split on `FS`). A reference inside a longer text (a template such as `MODE;${source::raw}`) is replaced by the source's text: it must reference a text, a table there is rejected (`TABLE_INTERPOLATED`, see [Strict Content Types](../design-principles.html#strict-content-types)). |
| `inputFormat` | No | None | Rejected from MetricsHub Community 3.9.09 (`DEPRECATED_SYNTAX`): a connector that sets it does not load. Remove it: an input that is a single source reference is read as that source is. |
| `output` | No | `text` | What the script produces: `text` (the printed lines as they are: write a `toTable` in `computes` to split them on `;` where they are read as a table, see the [content types](../computes/index.html#content-types)) or `table` (each `print a, b, c` is one row; a `print` without argument is one row of the record's fields `$1..$NF`, while `print $0` writes `$0` in one cell; `printf` text is split into rows on `ORS` and into cells on `OFS`, so a `printf` row sets `OFS = SUBSEP`). See the [`awk` compute](../computes/awk.html#table-input-and-output). |
| `variables` | No | `{}` | Map of AWK variable names to values. Source references become arrays of rows, lists and maps become arrays, other values become scalars. See [Variables](#variables). |
| `executeForEachEntryOf` | No | None | Run once per row from another source table. |
| `computes` | No | `[]` | Optional post-processing computes. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

> [!NOTE]
> An `awk` source does not filter or split what its script prints: `keep`, `exclude`, `separators` and `selectColumns` have no effect on it. Filter in the script, and declare `output: table` to write columns.

## Variables

Both AWK sources and [AWK computes](../computes/awk.html#variables) accept a `variables` map. Variables are available by name in the script, including in `BEGIN` blocks, for inline scripts and embedded `.awk` files alike.

| Value | Available in AWK as |
| --- | --- |
| Literal text or a quoted number, such as `"365.25"` | A scalar, usable in string expressions or arithmetic. |
| A resource attribute, monitor attribute, or protocol property reference | A scalar resolved immediately before execution, e.g. `${resource.attribute::host.name}`, `${attribute::id}`, or `${protocol::http.port}`. |
| A source reference, such as `${source::monitors.disk.discovery.sources.raw}` | An array of rows: `aTable[row][column]`, with **zero-based** row and column indexes. `length(aTable)` returns the row count. |
| A YAML list | An array indexed from 0: `aList[0]`, `length(aList)`. See [Lists And Maps](#lists-and-maps). |
| A YAML map | An array indexed by its keys: `aMap["key"]`, `for (key in aMap)`. See [Lists And Maps](#lists-and-maps). |

### Read A Source Table

Assuming `monitors.disk.discovery.sources.raw` has already run and contains at least three columns:

```yaml
sources:
  merged:
    type: awk
    output: table
    variables:
      hostname: ${resource.attribute::host.name}
      someConstant: "365.25"
      aTable: ${source::monitors.disk.discovery.sources.raw}
    script: |
      BEGIN {
        for (row = 0; row < length(aTable); row++) {
          print aTable[row][0], aTable[row][2], hostname, someConstant * 2
        }
      }
```

For a row `disk0`, `SSD`, `100` and hostname `server01`, the script writes the row `disk0`, `100`, `server01`, `730.5`. No `input` is needed here: the `BEGIN` block reads the table variable directly. By contrast, `input: ${source::...}` feeds that source to the script's normal record processing: its rows as records for a table, its lines for a text.

A referenced source must produce a table: a source that ends in text is rejected (`TEXT_FEEDS_TABLE`). End it with a [toTable](../computes/to-table.html), or an `awk` with `output: table`. An empty or unavailable source becomes an empty array (`length(aTable) == 0`); an unavailable source also logs an error. A variable declared without a value is exposed as an empty scalar.

### Lists And Maps

A variable can hold a list or a map, which the script reads as an array. Lists and maps can be nested, and each value they hold is resolved like a variable: an attribute or protocol property reference is replaced, and a source reference becomes that source's table.

```yaml
- type: awk
  script: ${file::xml-rows.awk}
  variables:
    properties:
    - node
    - node-model
    - ""
    - is-node-healthy
    labels:
      vendor: NetApp
      host: ${resource.attribute::host.name}
```

```awk
BEGIN {
  for (i = 0; i < length(properties); i++) {
    print i, properties[i]
  }
  print labels["vendor"], labels["host"]
}
```

A list is indexed from 0, like the rows of a source table. A map is indexed by its keys, in no particular order for `for (key in aMap)`, and `aMap[1]` finds the key `1`. An empty value in a list, such as `""` or a missing value, is an empty string.

Like a scalar variable, an input field or a cell of a source table, a value in a list or a map compares as a number when it looks like one, and as text otherwise: `aList[0] > 9` is true for `"10"`.

## Functions

On top of the AWK language, MetricsHub gives a script its own functions.

### In Every Script

These functions are available to the `awk` source, to the [`awk` compute](../computes/awk.html) and to `${awk::...}` mapping expressions.

| Function | Result |
| --- | --- |
| `bytes2HumanFormatBase2(bytes)` | The size with a binary unit: `1.00 KiB` for `1024`. |
| `bytes2HumanFormatBase10(bytes)` | The size with a decimal unit: `1.00 KB` for `1000`. |
| `mebiBytes2HumanFormat(mebibytes)` | The size with a binary unit, from mebibytes: `2.00 GiB` for `2048`. |
| `megaHertz2HumanFormat(megahertz)` | The frequency with a unit: `3.20 GHz` for `3200`. |
| `join(separator, a, b, ...)` | The values joined with the separator. |
| `base64Encode(text)` | The text encoded in Base64. |
| `asorti(source, destination)` | Fills `destination[1..n]` with the sorted keys of `source` and returns `n`. |
| `sleep(seconds)` | Pauses the script and returns 0. The duration can have a fractional part (`sleep(0.1)` is 100 ms), and one call pauses for 60 seconds at most. |

### In The awk Source

A source script can also query the monitored resource. Each `execute...` function takes an array holding the properties of the corresponding source (`executeIpmiRequest` takes no argument), and returns its result as text: the body of the response, or the rows of a table joined with `;`. `executeHttpJsonRequest` is the exception: it fills an array and returns the HTTP status code.

| Function | Runs |
| --- | --- |
| `executeHttpRequest(args)` | An [http](./http.html) source: `args["method"]`, `args["path"]`, `args["header"]`, `args["body"]`, `args["resultContent"]`, ... The body may be an array: see [Send JSON](#send-json). |
| `executeHttpJsonRequest(args, response)` | The same request, with the body of its response parsed as JSON into the `response` array. Returns the HTTP status code. See [Read JSON](#read-json). |
| `executeSnmpGet(args)` | An [snmpGet](./snmp-get.html) source: `args["oid"]`. |
| `executeSnmpTable(args)` | An [snmpTable](./snmp-table.html) source: `args["oid"]`, `args["selectColumns"]`. |
| `executeWbemRequest(args)` | A [wbem](./wbem.html) source: `args["query"]`, `args["namespace"]`. |
| `executeWmiRequest(args)` | A [wmi](./wmi.html) source: `args["query"]`, `args["namespace"]`. |
| `executeIpmiRequest()` | An [ipmi](./ipmi.html) source. |
| `getVariable(name)` | The value of a connector variable. |
| `json2Table(json, entryKey, properties, rows)` | Fills `rows` with the entries of a JSON document, and returns their number. See [Read JSON](#read-json). |
| `json2List(json, list)` | Fills `list` with every value of a JSON document, indexed by its path, and returns their number. See [Read JSON](#read-json). |

### Read JSON

Three functions read a JSON document without flattening it to text. Each one fills the array given as its last argument, as `split()` does. The array is emptied first.

**`status = executeHttpJsonRequest(args, response)`** runs the request, returns its HTTP status code (`200`, `401`, `404`, ...) and gives the whole document. The status is 0 when the request got no response (the host does not answer, the request times out). The body of an error response is parsed like any other, since it often says what went wrong. `args["resultContent"]` is ignored.

A JSON object is an array indexed by its keys, a JSON array is an array indexed from 0. A string is a string, and `true` and `false` are 1 and 0. A number computes and compares as a number, and prints as the document writes it (`1234567.891`, where AWK would print `1.23457e+06`); the result of a computation prints as any AWK number, with `OFMT`. A `null` is an element without a value: it reads as an empty string, or as an empty array where the script expects an object (`member["Status"]["Health"]`), and `"Status" in member` is true. When the body is not a JSON object or array, `response` stays empty and a warning is logged.

```awk
BEGIN {
  args["method"] = "get"
  args["path"] = "/api/v1/systems"
  if (executeHttpJsonRequest(args, response) != 200) exit
  for (i = 0; i < length(response["items"]); i++) {
    print response["items"][i]["id"], response["items"][i]["status"]["health"]
  }
}
```

The source of this script declares `output: table`: each `print` is one row, and its two arguments are the cells.

**`json2Table(json, entryKey, properties, rows)`** extracts rows from a JSON text, as the [json2Table](../computes/json2csv.html) compute does. `properties` is a `;`-separated list. `rows[i][0]` is the path of the entry and `rows[i][1]` its first property: both indexes start at 0. A cell holds its value whole, even when the value holds a `;` or a line feed.

```awk
{
  args["method"] = "get"
  args["path"] = "/redfish/v1/Chassis/" $1 "/Sensors"
  n = json2Table(executeHttpRequest(args), "/Members", "Id;Reading;Status/Health", rows)
  for (i = 0; i < n; i++) {
    print $1, rows[i][1], rows[i][2], rows[i][3]
  }
}
```

**`json2List(json, list)`** gives every leaf value of a JSON text, indexed by its path, as the [json2List](../computes/json2list.html) compute does: `list["/data/token"]`, `list["/items[0]/name"]`. It is the short way to one value:

```awk
BEGIN {
  args["method"] = "post"
  args["path"] = "/api/login"
  json2List(executeHttpRequest(args), login)
  printf "%s", login["/data/token"]
}
```

> [!NOTE]
> A function cannot return an array to a variable: `rows = json2Table(...)` fails. Pass the array as the last argument.

The former `json2csv(args)` function, which returned the rows as `;`-joined lines, no longer exists: use `json2Table`.

### Send JSON

The body of a request may be an array instead of a text: `executeHttpJsonRequest` and `executeHttpRequest` write it as JSON. Every value is escaped, so a `"` or a `\` in a name or a password cannot break the document, as it does in a body built by joining strings.

```awk
{
  args["method"] = "post"
  args["path"] = "/api/v1/metrics"
  args["body"]["systemId"] = $2
  args["body"]["startDate"] = $3 + 0
  args["body"]["average"] = mkbool(1)
  args["body"]["metrics"][0] = "Reads"
  args["body"]["metrics"][1] = "Writes"
  if (executeHttpJsonRequest(args, response) != 200) next
  print $2, response["result"][0]["Reads"], response["result"][0]["Writes"]
}
```

The request above sends `{"average":true,"metrics":["Reads","Writes"],"startDate":1700000000,"systemId":"000123"}`.

An array is written the way a response is read, the other way round:

| In the array | In the JSON body |
| --- | --- |
| An array whose indexes are 0 to n-1 | An array |
| Any other array, an empty one included | An object, its properties in alphabetical order |
| A number | A number: `3`, never `3.0` |
| A string, and a field or any other text read from the input, even when it looks like a number (`$2` holding `000123`) | A string: `"000123"` |
| `mkbool(1)`, `mkbool(0)`, and a `true` or a `false` read from a response | `true`, `false` |
| An element without a value | An empty string: `""` |

- To send a field as a number, add 0 to it: `$3 + 0`. To send a number as a string, join it with an empty string: `count ""`.
- The result of `split()` is indexed from 1, which makes it an object: copy it to indexes that start at 0 to send an array.
- `null` and an empty array (`[]`) cannot be written. Give the body as a text when the request needs one.
- A decimal read from a response prints as the document writes it because it is a text that computes as a number: sent back as it is, it is a string. Add 0 to send it as a number.
- `Content-Type: application/json` is added to the header of the request, unless `args["header"]` already names a content type, in its text or in the embedded file it refers to.
- A credential macro in a value, such as `%{USERNAME}` or `%{PASSWORD}`, is escaped as JSON when the request replaces it: write the macro alone, without `esc(json)`. A macro that names another escape, such as `${esc(url)::PASSWORD}`, keeps that escape only: its value is not escaped as JSON.
- A value cannot refer to an embedded file: `${file::...}` in a value is not replaced by the content of the file.
- The script keeps its array: `args["body"]` is the same after the call.

## Sandbox

A script runs in a sandbox, in the `awk` source, in the `awk` compute and in `${awk::...}` expressions. It cannot:

- run a command: `system()`, `"command" | getline`, `print | "command"`;
- read or write a file: `getline < "file"`, `print > "file"`, `printf >> "file"`;
- include another script with `@include`.

A script that holds one of these statements is rejected as a whole, even when the statement would never run. To wait between two requests, call `sleep(seconds)`. To reach the monitored resource, call the `execute...` functions, which only an `awk` source has.

## Compilation

MetricsHub compiles a script the first time it runs, and keeps the compiled program for the next runs. A script that does not compile (a syntax error, a statement the sandbox rejects, an unknown function) is logged as an error when its source or compute first runs, with the connector, the source and the line, and that source or compute gives no result. Nothing reports it before: run the connector, or its integration test, after changing a script.

A script is code, so MetricsHub replaces no reference in it: a `${param::days}`, `${attribute::id}` or `${source::...}` written in a script stays there as text, and the script usually does not compile. Give the script such a value through [`variables`](#variables), and read it by name:

```yaml
- type: awk
  variables:
    days: ${param::days}
  script: |
    END { if (!count) print "No event in the last " days " days" }
```

A `${file::...}` reference is not concerned: as the whole `script` value it names the script, and inside a script it names an embedded file passed to a function, such as the `header` of `executeHttpRequest`.

## Recommended Pattern

- Declare `output: table` when the result is read as a table, and print one argument per cell.
- Keep source-level AWK focused on one transformation concern.
- Move complex business logic to dedicated `.awk` files with `${file::...}`.

## Common Mistakes

- Mixing source acquisition and heavy parsing into one unreadable AWK script.
- Returning irregular row widths that break mapping.
- Using source-level `awk` where a simple `commandLine` + compute `awk` would be clearer.
- Treating a source-table variable as CSV text or using one-based indexes: the first cell is `aTable[0][0]`, unlike AWK record fields `$1`, `$2`, etc.

## Community Examples

- [MariaDB](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/database/MariaDB/MariaDB.yaml): in its tools, `awk` sources that read another source through `variables`

Relevant AWK-heavy connectors (compute-level AWK patterns):

- [Linux](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Linux/Linux.yaml)
- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml)
- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
