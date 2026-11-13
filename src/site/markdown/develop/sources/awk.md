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
    script: |
      BEGIN { FS=";"; OFS=";" }
      NF >= 3 { print $1, $2, tolower($3) }
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `awk`. |
| `script` | Yes | None | Inline AWK script or `${file::...}` reference. No other reference is replaced in a script: pass values through `variables`, see [Compilation](#compilation). |
| `input` | No | Empty | Input text, or a single source reference such as `${source::beforeAll.inventoryRaw}`: the script reads that source as it is at run time, a table structured (each row is a record whose cells are `$1..$NF`, and `$0` is the row as the reference gives it: cells joined with `;`, the trailing `;` kept unless the row has a single cell), a text the traditional way (lines split on `FS`). A reference inside a longer text (a template such as `MODE;${source::raw}`) is replaced by the source's text: it must reference a text, a table there is reported (`TABLE_INTERPOLATED`, see [Strict Content Types](../design-principles.html#strict-content-types)). |
| `inputFormat` | No | None | Deprecated and ignored: an input that is a single source reference is read as that source is. Still accepted so that existing connectors load, and reported (`DEPRECATED_SYNTAX`): remove it. |
| `output` | No | `text` | What the script produces: `text` (the printed lines as they are, which MetricsHub splits on `;` with a `toTable` where they are read as a table, see the [content types](../computes/index.html#content-types)) or `table` (each `print a, b, c` is one row; a `print` without argument is one row of the record's fields `$1..$NF`, while `print $0` is the row as the reference gives it, in one cell; `printf` text is split into rows on `ORS` and into cells on `OFS`, so a `printf` row sets `OFS = SUBSEP`). See the [`awk` compute](../computes/awk.html#table-input-and-output). |
| `variables` | No | `{}` | Map of AWK variable names to values. Source references become arrays of rows, lists and maps become arrays, other values become scalars. See [Variables](#variables). |
| `separators` | No | None | Compatibility property; usually unnecessary for source-level AWK. |
| `keep` | No | None | Schema-compatibility filter property; prefer compute-level filtering. |
| `exclude` | No | None | Schema-compatibility filter property; prefer compute-level filtering. |
| `selectColumns` | No | None | Schema-compatibility selection property; prefer compute-level selection. |
| `executeForEachEntryOf` | No | None | Run once per row from another source table. |
| `computes` | No | `[]` | Optional post-processing computes. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

> [!TIP]
> If you need `keep`, `exclude`, `separators`, or `selectColumns` behavior, prefer compute-level `awk` in the source `computes` pipeline.

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
    variables:
      hostname: ${resource.attribute::host.name}
      someConstant: "365.25"
      aTable: ${source::monitors.disk.discovery.sources.raw}
    script: |
      BEGIN {
        for (row = 0; row < length(aTable); row++) {
          print aTable[row][0] ";" aTable[row][2] ";" hostname ";" (someConstant * 2)
        }
      }
```

For a row `disk0;SSD;100` and hostname `server01`, the output is `disk0;100;server01;730.5`. No `input` is needed here: the `BEGIN` block reads the table variable directly. By contrast, `input: ${source::...}` feeds that source to the script's normal record processing: its rows as records for a table, its lines for a text.

If a referenced source produced text, MetricsHub splits it into rows on line feeds and into cells on `;`, as [toTable](../computes/to-table.html) does with its default separator. Such a variable is reported (`TEXT_FEEDS_TABLE`): end the referenced source with an explicit `toTable`. An empty or unavailable source becomes an empty array (`length(aTable) == 0`); an unavailable source also logs an error. A variable declared without a value is exposed as an empty scalar.

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

A source script can also query the monitored resource. Each `execute...` function takes an array holding the properties of the corresponding source, and returns its result as text: the body of the response, or the rows of a table joined with `;`.

| Function | Runs |
| --- | --- |
| `executeHttpRequest(args)` | An [http](./http.html) source: `args["method"]`, `args["path"]`, `args["header"]`, `args["body"]`, `args["resultContent"]`, ... |
| `executeHttpJsonRequest(args, response)` | The same request, with its result parsed as JSON into the `response` array. See [Read JSON](#read-json). |
| `executeSnmpGet(args)` | An [snmpGet](./snmp-get.html) source: `args["oid"]`. |
| `executeSnmpTable(args)` | An [snmpTable](./snmp-table.html) source: `args["oid"]`, `args["selectColumns"]`. |
| `executeWbemRequest(args)` | A [wbem](./wbem.html) source: `args["query"]`, `args["namespace"]`. |
| `executeWmiRequest(args)` | A [wmi](./wmi.html) source: `args["query"]`, `args["namespace"]`. |
| `executeIpmiRequest()` | An [ipmi](./ipmi.html) source. |
| `getVariable(name)` | The value of a connector variable. |
| `json2Table(json, entryKey, properties, rows)` | Fills `rows` with the entries of a JSON document. See [Read JSON](#read-json). |
| `json2List(json, list)` | Fills `list` with every value of a JSON document, indexed by its path. See [Read JSON](#read-json). |

### Read JSON

Three functions read a JSON document without flattening it to text. Each one fills the array given as its last argument, as `split()` does, and returns the number of elements it holds. The array is emptied first.

**`executeHttpJsonRequest(args, response)`** runs the request and gives the whole document. A JSON object is an array indexed by its keys, a JSON array is an array indexed from 0. A string is a string, a number is a number, `true` and `false` are 1 and 0, and `null` is an empty string. When the result is not a JSON object or array, `response` stays empty and a warning is logged.

```awk
BEGIN {
  args["method"] = "get"
  args["path"] = "/api/v1/systems"
  executeHttpJsonRequest(args, response)
  for (i = 0; i < length(response["items"]); i++) {
    print response["items"][i]["id"], response["items"][i]["status"]["health"]
  }
}
```

**`json2Table(json, entryKey, properties, rows)`** extracts rows from a JSON text, as the [json2Table](../computes/json2csv.html) compute does. `properties` is a `;`-separated list. `rows[i][0]` is the path of the entry and `rows[i][1]` its first property: both indexes start at 0. A cell holds its value whole, even when the value holds a `;` or a line feed. An optional fifth argument, `"events"`, selects the events parsing mode for large documents.

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

## Sandbox

A script runs in a sandbox, in the `awk` source, in the `awk` compute and in `${awk::...}` expressions. It cannot:

- run a command: `system()`, `"command" | getline`, `print | "command"`;
- read or write a file: `getline < "file"`, `print > "file"`, `printf >> "file"`;
- include another script with `@include`.

A script that holds one of these statements is rejected as a whole, even when the statement would never run. To wait between two requests, call `sleep(seconds)`. To reach the monitored resource, call the `execute...` functions.

## Compilation

MetricsHub compiles the scripts when it loads the connector. A script that does not compile (a syntax error, a statement the sandbox rejects, an unknown function) is logged then as an error, with the connector, the source and the line, and its source or compute gives no result.

A script is code, so MetricsHub replaces no reference in it: a `${param::days}`, `${attribute::id}` or `${source::...}` written in a script stays there as text, and is reported when the connector loads. Give the script such a value through [`variables`](#variables), and read it by name:

```yaml
- type: awk
  variables:
    days: ${param::days}
  script: |
    END { if (!count) print "No event in the last " days " days" }
```

A `${file::...}` reference is not concerned: as the whole `script` value it names the script, and inside a script it names an embedded file passed to a function, such as the `header` of `executeHttpRequest`.

## Recommended Pattern

- Emit semicolon-separated rows from the script.
- Keep source-level AWK focused on one transformation concern.
- Move complex business logic to dedicated `.awk` files with `${file::...}`.

## Common Mistakes

- Mixing source acquisition and heavy parsing into one unreadable AWK script.
- Returning irregular row widths that break mapping.
- Using source-level `awk` where a simple `commandLine` + compute `awk` would be clearer.
- Treating a source-table variable as CSV text or using one-based indexes: the first cell is `aTable[0][0]`, unlike AWK record fields `$1`, `$2`, etc.

## Community Examples

No current community connector uses source-level `awk` directly.

Relevant AWK-heavy connectors (compute-level AWK patterns):

- [Linux](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/system/Linux/Linux.yaml)
- [DiskPart](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/DiskPart/DiskPart.yaml)
- [GenericUPS](https://github.com/metricshub/community-connectors/blob/main/src/main/connector/hardware/GenericUPS/GenericUPS.yaml)
