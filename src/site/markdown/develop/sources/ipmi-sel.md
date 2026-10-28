keywords: ipmiSel source, system event log, sel, hardware events, ipmi
description: Reference for the ipmiSel source, which returns the IPMI System Event Log entries added since the previous poll.

# ipmiSel (Source)

<!-- MACRO{toc|fromDepth=2|toDepth=3|id=toc} -->

## When To Use

Use `ipmiSel` to report the hardware events a BMC logged in its System Event Log (SEL) between two polls: a power supply failure, a memory ECC error, an intrusion, a fan failure... even when the sensor is back to normal by the time the `ipmi` source reads it.

The source only returns the entries added since its previous poll, one row per entry. The first poll locates the end of the log without reading it and returns nothing; a restart of the agent starts again with an empty first poll. When the log is cleared on the BMC, the entries logged after the clear are returned from the first one.

## Syntax

```yaml
sources:
  selEvents:
    type: ipmiSel
    maxEventsPerPoll: 50
```

## Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `type` | Yes | None | `ipmiSel`. |
| `maxEventsPerPoll` | No | `50` | Maximum entries returned by one poll; the entries left out come with the next poll. Use `-1` for unlimited. |
| `executeForEachEntryOf` | No | None | Execute with fan-out context from another source. |
| `computes` | No | `[]` | Post-processing computes. |
| `forceSerialization` | No | `false` | Serialize execution via a per-connector, per-host lock (see the Sources overview). Default `false`. |

## Output

One row per entry, in the order of the log:

```
recordId;timestamp;sensorType;sensorNumber;sensorName;entity;eventType;description;direction;generatorId;oem
```

| Column | Content |
| --- | --- |
| `recordId` | The SEL record ID, decimal. |
| `timestamp` | Seconds since the epoch, UTC; empty for the entries logged before the BMC had the time. Some BMCs keep their SEL clock in local time without saying so. |
| `sensorType` | The sensor type of a system event: `Temperature`, `PowerSupply`, `Memory`, `Fan`, `PhysicalSecurity`...; `Oem C0h` for an OEM sensor type; empty for an OEM record. |
| `sensorNumber` | The sensor number, 2 uppercase hexadecimal digits; empty for an OEM record. |
| `sensorName` | The name of the sensor that logged the event, from the SDR repository (`PS1 Status`); empty when no sensor matches. |
| `entity` | The entity of that sensor, as in the `ipmi` source device lines (`Power Supply 1`); empty when no sensor matches. |
| `eventType` | The event/reading type code, 2 uppercase hexadecimal digits (`01` threshold, `6F` sensor-specific); empty for an OEM record. |
| `description` | The event in words: `Power Supply Failure detected`, `Upper Critical - going high`, `Uncorrectable ECC`...; `OEM data ...` for an OEM record. |
| `direction` | `Assertion` or `Deassertion`; empty for an OEM record. |
| `generatorId` | The generator ID of a system event, 4 uppercase hexadecimal digits; empty for an OEM record. |
| `oem` | For an OEM record: the manufacturer ID as 6 uppercase hexadecimal digits when the record carries one, then its data bytes in hexadecimal, space-separated. |

Example:

```
17;1761640530;PowerSupply;0A;PS1 Status;Power Supply 1;6F;Power Supply Failure detected;Assertion;0020;
18;1761640531;Fan;21;Fan 2;Fan Device 2;01;Lower Critical - going low;Assertion;0020;
19;;;;;;;OEM data 01 02 03 04 05 06;;;000157 01 02 03 04 05 06
```

## Recommended Pattern

- Keep a bounded `maxEventsPerPoll`: a BMC that logs a burst (a flapping sensor) is drained over several polls.
- Filter on `sensorType`, `eventType` and `direction` with computes before mapping, and key the monitor on `entity` to attach the event to the device the `ipmi` source discovered.
- Prefer `description` over the event data bytes: it is the wording of `ipmiutil`, the same on every BMC.

> [!NOTE]
> A `discovery` or `simple` job that reads an `ipmiSel` source, directly or through `${source::...}` references, never removes its instances: the source only returns the entries added since the previous poll, so a missing row does not mean a missing entity (see [When Instances Are Removed](../monitors-and-jobs.html#when-instances-are-removed)).

## Common Mistakes

- Expecting the backlog of the log on the first poll: it is skipped by design (the `ExecuteIpmiQuery` MCP tool reads the whole log, or the last `since` duration).
- Reading the sensor name of an OEM record: only system events (record type `02h`) carry a sensor.
- Comparing `timestamp` with the agent clock on a BMC whose SEL clock is in local time, or not set (`timestamp` empty).

## Related

- [ipmi](./ipmi.html) for the sensors, FRUs and chassis status.
- [ipmiRaw](./ipmi-raw.html) to read the SEL information (`netFn: 0x0A`, `command: 0x40`) or clear the log.
