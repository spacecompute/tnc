---
name: containers
description: Build and manage base container images for mission control services. Multi-arch builds via act, Containerfile conventions, entrypoint patterns.
argument-hint: [build | build:yamcs | build:openmct | build:jupyter | build:sle | act | dry | status]
---

# Container Image Management

Build and manage the base container images. Based on `$ARGUMENTS`. Default to `status` if no argument given.

## Commands

### `build` — Build all container images locally

```bash
task build
```

Builds all four images in parallel using the local container runtime (`CONTAINER_BIN`, defaults to `docker`).

### `build:<service>` — Build one image locally

```bash
task build:yamcs
task build:openmct
task build:jupyter
task build:sle
```

### `act` — Build all images via act (CI workflow)

```bash
task act:build
```

Runs the CI workflow locally via [act](https://github.com/nektos/act).

### `dry` — Validate workflow without building

```bash
task act:build:dry
```

Dry-run of the CI workflow — validates syntax and job structure without actually building images.

### `status` — Show workflow graph

```bash
task act:graph
```

## Images

| Image | Base | Container Path | Start Command |
|-------|------|---------------|---------------|
| yamcs | maven:3.9.9-eclipse-temurin-17 | `/opt/yamcs/` | `mvn yamcs:run` |
| openmct | ubuntu:25.04 + Node.js 24 | `/opt/openmct/` | `npm start` |
| jupyter | jupyterhub:5 | `/opt/jupyter/` | `jupyterhub -f ./jupyterhub_config.py` |
| sle | maven:3.9.9-eclipse-temurin-17 | `/opt/jsle/` | `mvn exec:java` |

## Containerfile Conventions

All Containerfiles follow the same pattern:

1. **Base image** — `FROM <base>`
2. **Proxy ARGs** — `MAVEN_HTTPS_PROXY`, `HTTPS_PROXY`, `HTTP_PROXY`, `NO_PROXY`, `DEPLOYMENT_ENVIRO`
3. **Source ARGs** — `GIT_URL`, `GIT_COMMIT` (build-time only, for `git clone`)
4. **System packages** — `apt-get install` for dev tools
5. **WORKDIR** — set to `/opt/` then clone, then set to `/opt/<service>/`
6. **Build step** — `mvn compile` or `npm install` + `npm run build`
7. **Entrypoint** — `COPY entrypoint.sh /entrypoint.sh` + `CMD ["/entrypoint.sh"]`

### Entrypoint Pattern

Every `entrypoint.sh` includes:
```bash
#!/usr/bin/env bash
# Explicit cd — WORKDIR is not guaranteed when overridden via Helm ConfigMap
cd /opt/<service>
<start command>
```

The explicit `cd` is necessary because Kubernetes `command:` overrides run from `/`, not from `WORKDIR`.

### Build-Time vs Runtime

| Variable | Build-Time | Runtime | Purpose |
|----------|-----------|---------|---------|
| `MAVEN_HTTPS_PROXY` | ARG | ENV | Maven proxy settings |
| `HTTPS_PROXY` | ARG | ENV | HTTPS proxy |
| `HTTP_PROXY` | ARG | ENV | HTTP proxy |
| `NO_PROXY` | ARG | ENV | Proxy exclusions |
| `DEPLOYMENT_ENVIRO` | ARG | ENV | Deployment label |
| `GIT_URL` | ARG | ENV (provenance) | Source repo — NOT runtime config |
| `GIT_COMMIT` | ARG | ENV (provenance) | Branch/tag — NOT runtime config |

`GIT_URL` and `GIT_COMMIT` are consumed at build time by `RUN git clone`. They're persisted as ENV for `docker inspect` provenance only. Do not expose in Helm charts.

## Key Files

| Role | Path |
|------|------|
| Yamcs Containerfile | `containers/yamcs/Containerfile` |
| OpenMCT Containerfile | `containers/openmct/Containerfile` |
| Jupyter Containerfile | `containers/jupyter/Containerfile` |
| SLE Containerfile | `containers/sle/Containerfile` |
| Yamcs Entrypoint | `containers/yamcs/entrypoint.sh` |
| OpenMCT Entrypoint | `containers/openmct/entrypoint.sh` |
| Jupyter Entrypoint | `containers/jupyter/entrypoint.sh` |
| SLE Entrypoint | `containers/sle/entrypoint.sh` |
| CI Workflow | `.github/workflows/build-images.yaml` |

## Multi-Arch Build

CI builds `linux/amd64` and `linux/arm64` manifests, pushed to GHCR:

```
ghcr.io/spacecompute/mission-control-systems/yamcs:latest
ghcr.io/spacecompute/mission-control-systems/openmct:latest
ghcr.io/spacecompute/mission-control-systems/jupyter:latest
ghcr.io/spacecompute/mission-control-systems/sle:latest
```

## Extension Model

These are base images. Mission-specific repos extend them:

```dockerfile
FROM ghcr.io/spacecompute/mission-control-systems/yamcs:latest
COPY myspacecraft.xtce /opt/yamcs/mdb/
COPY yamcs.myspacecraft.yaml /opt/yamcs/etc/
```
