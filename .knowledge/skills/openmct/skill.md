---
name: openmct
description: Reference OpenMCT web telemetry UI — base image, Helm chart, Yamcs plugin, display configuration, and extension points.
argument-hint: [build | helm | config | displays | extend]
---

# OpenMCT Web Telemetry UI

Reference for the OpenMCT base image and Helm chart. Based on `$ARGUMENTS`. Default to overview if no argument given.

## Overview

[OpenMCT](https://github.com/nasa/openmct) is NASA's open-source web-based telemetry visualization framework. This repo builds a base image with the [openmct-yamcs](https://github.com/akhenry/openmct-yamcs) plugin pre-installed, connecting OpenMCT to a Yamcs backend.

## Base Image

```
ghcr.io/spacecompute/mission-control-systems/openmct:latest
```

| Property | Value |
|----------|-------|
| Base | `ubuntu:25.04` + Node.js 24 (via nvm) |
| Default Source | `https://github.com/akhenry/openmct-yamcs.git` (master) |
| Container Path | `/opt/openmct/` |
| Default Port | 9000 |
| Start Command | `npm start` |

### Build

```bash
task build:openmct
```

### Containerfile

```
containers/openmct/Containerfile
containers/openmct/entrypoint.sh
containers/openmct/index.js
containers/openmct/webpack.dev.mjs
```

The Containerfile installs nvm + Node.js, clones openmct-yamcs, runs `npm install` and `npm run build:example:master`.

## Helm Chart

```bash
helm install openmct oci://ghcr.io/spacecompute/mission-control-systems/charts/openmct
```

### Environment Variables (values.yaml)

| Value | Default | Purpose |
|-------|---------|---------|
| `env.YAMCS_INSTANCE` | `myproject` | Yamcs instance name to connect to |
| `env.YAMCS_PROCESSOR` | `realtime` | Yamcs processor name |
| `env.YAMCS_FOLDER` | `myproject` | Root folder in OpenMCT tree |
| `env.MAVEN_HTTPS_PROXY` | `""` | Proxy settings |
| `env.HTTPS_PROXY` | `""` | HTTPS proxy |
| `env.HTTP_PROXY` | `""` | HTTP proxy |
| `env.NO_PROXY` | `""` | Proxy exclusions |
| `env.DEPLOYMENT_ENVIRO` | `""` | Deployment environment label |

### Extension Points

| Value | Purpose |
|-------|---------|
| `image.repository` / `image.tag` | Use a mission-specific OpenMCT image |
| `extraEnv` | Inject additional environment variables |
| `extraVolumes` / `extraVolumeMounts` | Mount display definitions, custom plugins |
| `resources` | CPU/memory requests and limits |

### ConfigMap Entrypoint

```bash
#!/usr/bin/env bash
# Explicit cd — WORKDIR is not guaranteed when overridden via Helm ConfigMap
cd /opt/openmct
pkill -f node
pkill -f npm
npm start
tail -f /dev/null
```

## Plugin Configuration

### index.js

The `index.js` file configures OpenMCT plugins, including the Yamcs connection:

```javascript
const defined = (val, fallback) =>
    typeof val !== "undefined" && val !== null ? val : fallback;

const defined = (val, fallback) =>
    typeof val !== "undefined" && val !== null ? val : fallback;

const YAMCS_INSTANCE = defined(process.env.YAMCS_INSTANCE, "myproject");
const YAMCS_FOLDER = defined(process.env.YAMCS_FOLDER, YAMCS_INSTANCE);
```

Mission repos override `index.js` via volume mount to customize plugins and display behavior.

### webpack.dev.mjs

Controls the webpack dev server configuration (port, proxy settings). Override via volume mount for custom build behavior.

## Display Integration

OpenMCT supports JSON-based display layouts. Mission repos mount displays via `extraVolumes`:

```yaml
extraVolumeMounts:
  - name: displays
    mountPath: /opt/openmct/example/displays

extraVolumes:
  - name: displays
    configMap:
      name: myspacecraft-displays
```

## Extending the Base Image

```dockerfile
FROM ghcr.io/spacecompute/mission-control-systems/openmct:latest

# Add mission-specific plugin config
COPY index.js /opt/openmct/example/index.js

# Add display definitions
COPY displays/ /opt/openmct/example/displays/

# Add custom webpack config
COPY webpack.dev.mjs /opt/openmct/.webpack/webpack.dev.mjs
```

## Key Files

| Role | Path |
|------|------|
| Containerfile | `containers/openmct/Containerfile` |
| Entrypoint | `containers/openmct/entrypoint.sh` |
| Plugin Config | `containers/openmct/index.js` |
| Webpack Config | `containers/openmct/webpack.dev.mjs` |
| Helm Chart | `helm/openmct/` |

## Dependencies

- Requires a running Yamcs instance for telemetry data
- In Kubernetes, the OpenMCT pod should depend on Yamcs being healthy
- In Docker Compose, use `service_healthy` condition on the Yamcs service
