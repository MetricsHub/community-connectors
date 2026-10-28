keywords: ipmiRaw source, raw command, netfn, oem command, ipmi
description: Reference for the ipmiRaw source, which sends one raw IPMI command and returns its completion code and response bytes.

# ipmiRaw (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `ipmiRaw` for what the `ipmi` source does not read from the SDR: Get Device ID (manufacturer, product, firmware revision), Get SEL Info (log usage), and the OEM commands of a vendor (Supermicro power consumption, Dell, Lenovo, HPE extensions). It replaces `ipmitool raw` in the connectors that used it through a command line.

## Syntax

```yaml
sources:
  deviceId:
    type: ipmiRaw
    netFn: 0x06
    command: 0x01
  selInfo:
    type: ipmiRaw
    netFn: 0x0A
    command: 0x40
  oemPower:
    type: ipmiRaw
    netFn: 0x30
    command: 0x89
    data: 0x0A 0x02 0x00
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `ipmiRaw`. |
| `netFn` | Yes | None | The network function of the request: an even number from `0x00` to `0x3E` (`0x06` App, `0x0A` Storage, `0x04` Sensor/Event, `0x00` Chassis, `0x2E` and `0x30`-`0x3E` OEM). |
| `command` | Yes | None | The command byte. |
| `data` | No | None | The request bytes, separated with spaces. |
| `executeForEachEntryOf` | No | None | Execute with fan-out context from another source. |
| `computes` | No | `[]` | Post-processing computes. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

`netFn`, `command` and each `data` byte are decimal, or hexadecimal with the `0x` prefix. Macros (`${esc.d}`, `${source::...}`, attributes) apply to the three properties.

## Output

One row:

```
completionCode;data
```

| Column | Content |
| --- | --- |
| `completionCode` | The completion code as 2 uppercase hexadecimal digits: `00` for success, `C1` invalid command, `CC` invalid data, `D4` insufficient privilege level... |
| `data` | The response bytes in uppercase hexadecimal, space-separated; empty when the response carries none. |

A non-zero completion code is returned, not an error of the source: the connector decides what it means (an OEM command refused by another vendor's BMC is not a failure). A connection, authentication or timeout failure is an error of the source, as for the `ipmi` source.

Example, Get Device ID on a Supermicro X11:

```
00;20 01 03 02 02 BF 57 01 00 00 00 00 00 00 00 00
```

## Recommended Pattern

- Check `completionCode` with a compute before parsing `data`.
- Parse `data` with an `awk` compute (`split($2, bytes, " ")`) and convert the bytes with `strtonum("0x" bytes[i])`.
- Keep one `ipmiRaw` source per command: the responses are recorded and replayed by the request bytes.

## Common Mistakes

- Writing the bytes without a separator (`0x0A02`): each byte is one number.
- Sending an odd `netFn`: the odd values are the response network functions.
- Expecting bridged (IPMB) or SOL traffic: only a request to the BMC itself is supported.

## Related

- [ipmi](./ipmi.html) for the sensors, FRUs and chassis status.
- [ipmiSel](./ipmi-sel.html) for the System Event Log entries.
