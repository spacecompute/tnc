---
name: yamcs
description: Reference Yamcs mission control server — base image, Helm chart, configuration, entrypoint, and extension points.
argument-hint: [build | helm | config | links | mdb | extend]
---

# Yamcs Mission Control Server

Reference for the Yamcs base image and Helm chart. Based on `$ARGUMENTS`. Default to overview if no argument given.

## Overview

[Yamcs](https://yamcs.org) is an open-source mission control system for telemetry, commanding, and archiving. This repo provides the base container image and Helm chart; mission-specific repos extend them with XTCE databases, instance configs, and custom decoders.

## Base Image

```
ghcr.io/spacecompute/mission-control-systems/yamcs:latest
```

| Property | Value |
|----------|-------|
| Base | `maven:3.9.9-eclipse-temurin-17` |
| Default Source | `https://github.com/yamcs/quickstart` (master) |
| Container Path | `/opt/yamcs/` |
| Default Port | 8090 |
| Start Command | `/opt/yamcs/bin/yamcsd --etc-dir /opt/yamcs/etc --data-dir /opt/yamcs/yamcs-data` |

### Build

```bash
task build:yamcs
```

### Containerfile

```
containers/yamcs/Containerfile
containers/yamcs/entrypoint.sh
```

The Containerfile clones the Yamcs quickstart, builds a distribution via `mvn package yamcs:bundle`, and extracts `bin/yamcsd` + `lib/*.jar`. Build-time ARGs (`GIT_URL`, `GIT_COMMIT`) control which repo and branch to clone.

## Helm Chart

```bash
helm install yamcs oci://ghcr.io/spacecompute/mission-control-systems/charts/yamcs
```

### Chart Files

```
helm/yamcs/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── configmap.yaml      # Entrypoint script
    ├── _helpers.tpl
    ├── hpa.yaml
    ├── ingress.yaml
    ├── serviceaccount.yaml
    └── NOTES.txt
```

### Environment Variables (values.yaml)

| Value | Default | Purpose |
|-------|---------|---------|
| `env.HTTPS_PROXY` | `""` | HTTPS proxy |
| `env.HTTP_PROXY` | `""` | HTTP proxy |
| `env.NO_PROXY` | `""` | Proxy exclusions |
| `env.DEPLOYMENT_ENVIRO` | `""` | Deployment environment label |

### Extension Points

| Value | Purpose |
|-------|---------|
| `image.repository` / `image.tag` | Use a mission-specific Yamcs image |
| `extraEnv` | Inject additional environment variables |
| `extraVolumes` / `extraVolumeMounts` | Mount XTCE databases, instance configs, decoders |
| `resources` | CPU/memory requests and limits |

### ConfigMap Entrypoint

The chart includes a ConfigMap that mirrors `containers/yamcs/entrypoint.sh`:

```bash
#!/usr/bin/env bash
# Explicit cd — WORKDIR is not guaranteed when overridden via Helm ConfigMap
cd /opt/yamcs
/opt/yamcs/bin/yamcsd --etc-dir /opt/yamcs/etc --data-dir /opt/yamcs/yamcs-data &
echo $! > /opt/yamcs/var/run/pid
tail -f /dev/null
```

## Yamcs Configuration

Yamcs uses YAML-based configuration files:

| File | Purpose |
|------|---------|
| `yamcs.yaml` | Global server config (security, web interface, plugins) |
| `yamcs.<instance>.yaml` | Per-instance config (data links, MDB, services) |
| `sle.yaml` | SLE provider definitions (if using yamcs-sle plugin) |

### Instance Config Structure

```yaml
services:
  - class: org.yamcs.archive.XtceTmRecorder
  - class: org.yamcs.archive.ParameterRecorder
  - class: org.yamcs.archive.CommandHistoryRecorder

dataLinks:
  - name: tm-in-udp
    class: org.yamcs.tctm.UdpTmDataLink
    port: 10015
  - name: tc-out-udp
    class: org.yamcs.tctm.UdpTcDataLink
    host: localhost
    port: 10025

mdb:
  - type: xtce
    spec: mdb/myspacecraft.xtce
```

### MDB (Mission Database)

Yamcs uses XTCE 1.2 XML for telemetry and telecommand definitions. Mission repos mount XTCE files via `extraVolumes`:

```yaml
extraVolumeMounts:
  - name: xtce
    mountPath: /opt/yamcs/mdb

extraVolumes:
  - name: xtce
    configMap:
      name: myspacecraft-xtce
```

### Data Links

Common data link types:

| Class | Direction | Transport |
|-------|-----------|-----------|
| `UdpTmDataLink` | TM in | UDP |
| `UdpTcDataLink` | TC out | UDP |
| `TmSleLink` | TM in | SLE (RCF/RAF) |
| `TcSleLink` | TC out | SLE (CLTU) |
| `TmFileLink` | TM in | File playback |

### Datalink Naming Convention

```
{type}-{mode}-{dir}-{transport}
```

Examples: `tm-rt-in-udp`, `tc-rt-out-udp`, `tm-sle-incoming-file`

## Extending the Base Image

```dockerfile
FROM ghcr.io/spacecompute/mission-control-systems/yamcs:latest

# Add mission database
COPY myspacecraft.xtce /opt/yamcs/mdb/

# Add instance config
COPY yamcs.myspacecraft.yaml /opt/yamcs/etc/

# Add custom decoders (compiled at startup by entrypoint.sh)
COPY decoders/ /opt/yamcs/decoders/
```

## API

Yamcs exposes a REST + WebSocket API on its default port:

| Endpoint | Purpose |
|----------|---------|
| `/api/server/info` | Server version and status |
| `/api/links/<instance>` | Data link status |
| `/api/processors/<instance>/<processor>` | Processor info |
| `/api/archive/<instance>:executeSql` | StreamSQL queries |

## Key References

- [Yamcs Documentation](https://docs.yamcs.org)
- [Yamcs HTTP API](https://docs.yamcs.org/yamcs-http-api/)
- [Yamcs SQL Format](https://docs.yamcs.org/yamcs-server-manual/sql-format/)
