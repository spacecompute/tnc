---
name: sle
description: Reference SLE (Space Link Extension) protocol concepts — services, providers, SIIDs, delivery modes, ISP1 transport, and Yamcs SLE plugin configuration.
argument-hint: [services | providers | siid | delivery | cltu | rcf | raf | config | yamcs]
---

# SLE (Space Link Extension) Reference

Answer SLE protocol questions based on `$ARGUMENTS`. Default to `services` overview if no argument given.

## SLE Protocol Overview

SLE (Space Link Extension) is the CCSDS standard (CCSDS 913.1-B) for ground-to-ground transfer of space link data between agencies. It allows a mission control center to receive telemetry and send telecommands through ground stations operated by other agencies (e.g., DSN, ESTRACK) without direct RF access.

```
Spacecraft ──RF──> Ground Station ──SLE──> Mission Control (Yamcs)
                   (DSN/ESTRACK/    ISP1/TCP    (SLE user)
                    agency ground)
```

## SLE Services

| Service | Direction | Full Name | Purpose |
|---------|-----------|-----------|---------|
| RCF | TM (return) | Return Channel Frames | Deliver TM frames filtered by spacecraft ID and virtual channel |
| RAF | TM (return) | Return All Frames | Deliver all TM frames from a physical channel (no VC filtering) |
| ROCF | TM (return) | Return Operational Control Fields | Deliver OCF data extracted from TM frames |
| CLTU | TC (forward) | Command Link Transmission Unit | Accept telecommand data units for RF uplink |
| FSP | TC (forward) | Forward Space Packet | Accept space packets for uplink (less common) |

### RCF vs RAF

- **RCF** (Return Channel Frames): Filters by SCID and optionally VCID. Most common for missions that share a physical channel or want VC-level filtering.
- **RAF** (Return All Frames): Delivers everything on the physical channel. Used when the ground station serves a single mission or when all frames are needed.

Most missions use RCF for operational telemetry.

### CLTU Service

CLTU (Command Link Transmission Unit) is the standard SLE forward service for telecommanding. The mission control system sends CLTUs to the ground station, which modulates them onto the RF uplink.

```
Yamcs TC → CLTU SLE service → Ground Station → RF uplink → Spacecraft
```

Each CLTU wraps a TC transfer frame with:
- **Start sequence**: acquisition pattern for the spacecraft receiver
- **TC data**: one or more coded TC transfer frames
- **Tail sequence**: marks end of CLTU
- **BCH encoding**: error detection per code block (optional, mission-dependent)

## SIID (Service Instance Identifier)

The SIID uniquely identifies an SLE service instance. Format is a dot-separated path:

```
sagr=<agreement>.spack=<service-pack>.{fsl-fg|rsl-fg}=<functional-group>.{cltu|rcf|raf|rocf}=<instance>
```

Components:
- `sagr` — Service Agreement identifier (assigned by the providing agency)
- `spack` — Service Package (often per-station or per-pass)
- `fsl-fg` / `rsl-fg` — Forward/Return Service Link Functional Group
- `cltu` / `rcf` / `raf` / `rocf` — Service instance name

Example: `sagr=21.spack=d34-PASS0000.rsl-fg=1.rcf=onlt00`

### SIID Patterns

| Pattern | Meaning |
|---------|---------|
| `PASS0000` | Static placeholder — same SIID every pass |
| `PASS####` | Per-pass — SIID changes each scheduled contact (requires automation) |
| `-PERM` | Permanent — always-on service instance |
| `DEFAULT-PASS` | Shared across all stations (common for CLTU) |

## Delivery Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| **Timely online** | Delivers frames in real-time; drops frames if consumer is slow | Live operations, low-latency monitoring |
| **Complete online** | Buffers and delivers all frames; backpressure if consumer is slow | Primary TM capture, no data loss |
| **Offline** | Retrieves stored data from a past time range | Playback, gap-fill, historical data retrieval |

Timely mode is preferred for real-time displays; complete mode for science data capture.

## ISP1 Transport Protocol

SLE uses the Internet SLE Protocol (ISP1, CCSDS 913.1-B) over TCP:

- **Initiator**: The SLE user (mission control / Yamcs) — opens the TCP connection
- **Responder**: The SLE provider (ground station) — listens for connections
- **Authentication**: Username/password pairs for both initiator and responder
- **Heartbeat**: Keepalive mechanism to detect connection loss

### Credentials

Each SLE binding requires two credential pairs:

| Role | Who | Fields |
|------|-----|--------|
| Initiator | Mission control (Yamcs) | `initiatorId`, `myUsername`, `myPassword` |
| Responder | Ground station | `responderPortId`, `peerUsername`, `peerPassword` |

Passwords are typically hex-encoded strings.

## Yamcs SLE Plugin

The `yamcs-sle` plugin provides SLE connectivity in Yamcs. Maven dependency:

```xml
<dependency>
    <groupId>org.yamcs</groupId>
    <artifactId>yamcs-sle</artifactId>
    <version>${yamcs-sle.version}</version>
</dependency>
```

### Configuration Files

| File | Purpose |
|------|---------|
| `sle.yaml` | SLE provider definitions (credentials, endpoints, SIIDs) |
| `yamcs.<instance>.yaml` | Data link definitions binding to SLE providers |

### Provider Configuration (sle.yaml)

```yaml
providers:
  - name: STATION-NAME
    sleVersion: 2              # SLE protocol version (1-5, typically 2)
    type: initiator            # or responder
    authenticationMode: ALL    # NONE, BIND, or ALL
    initiatorId: "my-mission"
    responderPortId: "STATION-TLM"
    myUsername: "my-mission"
    myPassword: "hex-encoded"
    peerUsername: "station-id"
    peerPassword: "hex-encoded"
    returnTimeoutSec: 300
    forwardLinkConfiguration:
      - endpoint:
          host: 192.168.1.100
          port: 5112
    returnLinkConfiguration:
      - endpoint:
          host: 192.168.1.200
          port: 5305
```

### Data Link Configuration (yamcs.instance.yaml)

TM link (RCF):
```yaml
- name: tm-sle-station
  class: org.yamcs.sle.TmSleLink
  sleProvider: STATION-NAME
  deliveryMode: rtnCompleteOnline   # rtnTimelyOnline, rtnCompleteOnline, rtnOffline
  rcfServiceInstanceId: "sagr=X.spack=STATION.rsl-fg=1.rcf=onlt00"
  frameType: TM                     # TM or AOS
  spacecraftId: <SCID>
  frameLength: <bytes>
  errorDetection: CRC16             # CRC16, CRC32, or NONE
  virtualChannels:
    - vcId: 0
    - vcId: 1
```

TC link (CLTU):
```yaml
- name: tc-sle-station
  class: org.yamcs.sle.TcSleLink
  sleProvider: STATION-NAME
  cltuServiceInstanceId: "sagr=X.spack=DEFAULT-PASS.fsl-fg=1.cltu=cltu0"
  spacecraftId: <SCID>
  maxFrameLength: <bytes>
  virtualChannel: 0
```

### Delivery Mode Values

| Yamcs Config Value | SLE Mode |
|-------------------|----------|
| `rtnTimelyOnline` | Timely online (real-time, may drop) |
| `rtnCompleteOnline` | Complete online (buffered, no loss) |
| `rtnOffline` | Offline (historical retrieval) |

## Operational Workflow (Generic)

1. Ground ops schedules a pass on a station
2. Operator enables the station's TM + TC links in Yamcs Links UI
3. Links bind to the station using pre-configured SIIDs and endpoints
4. After pass, operator disables both links
5. No configuration file editing, no Yamcs restart required

This per-station link model eliminates manual YAML editing between passes.

## Topics

- **services**: SLE service types (RCF, RAF, CLTU, ROCF, FSP)
- **providers**: How to configure SLE providers in Yamcs
- **siid**: Service Instance Identifier format and patterns
- **delivery**: Timely vs complete vs offline delivery modes
- **cltu**: CLTU commanding service details
- **rcf**: Return Channel Frames service
- **raf**: Return All Frames service
- **config**: Yamcs SLE configuration file structure
- **yamcs**: yamcs-sle plugin setup and Maven dependency
