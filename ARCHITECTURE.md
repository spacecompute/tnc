# Architecture

Base container images and Helm charts for spacecraft mission control systems. Downstream mission-specific repos extend these with XTCE databases, display configs, procedures, and compose orchestration.

## Service Topology

| Service | Default Port | Base Image | Description |
|---------|-------------|------------|-------------|
| Yamcs | 8090 | maven:3.9.9-eclipse-temurin-17 | Mission control server — telemetry, commanding, archiving |
| OpenMCT | 9000 | ubuntu:25.04 + Node.js 24 | Web telemetry UI with Yamcs plugin |
| JupyterHub | 8000 | jupyterhub:5 | Collaborative procedure execution (Python, Ruby, Perl, R, Gnuplot, Octave) |
| jSLE | 5100 | maven:3.9.9-eclipse-temurin-17 | Space Link Extension provider for ground station connectivity |

## Container Path Convention

All services install to `/opt/<service>/` inside the container:

| Service | Container Path | WORKDIR |
|---------|---------------|---------|
| Yamcs | `/opt/yamcs/` | `/opt/yamcs/` |
| OpenMCT | `/opt/openmct/` | `/opt/openmct/` |
| JupyterHub | `/opt/jupyter/` | `/opt/jupyter/` |
| jSLE | `/opt/jsle/` | `/opt/jsle/` |

## Entrypoint Pattern

Every Containerfile follows the same entrypoint convention:

```dockerfile
COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
```

Each Containerfile sets `USER ${SERVICE_UID}:${SERVICE_GID}` as the default (non-root). Each `entrypoint.sh` includes a `gosu` guard: when Docker Compose sets `user: "0:0"` to fix bind-mount ownership, the entrypoint drops back to the service user via `gosu`; when already non-root (default `USER` or Kubernetes `runAsUser`), it runs directly. The explicit `cd` ensures correctness when `WORKDIR` is overridden via Helm ConfigMap:

```bash
#!/usr/bin/env bash
if [ "$(id -u)" = "0" ]; then
    chown -R "${SERVICE_UID}:${SERVICE_GID}" /opt/<service> 2>/dev/null || true
    exec gosu "${SERVICE_UID}:${SERVICE_GID}" "$0" "$@"
fi
cd /opt/<service>
<start command>
```

Helm charts inject the entrypoint via a ConfigMap volume mount at `/entrypoint.sh` (subPath), allowing mission-specific overrides without rebuilding the image.

## Container Images

Published as multi-arch (amd64/arm64) OCI images to GitHub Container Registry:

```
ghcr.io/spacecompute/mission-control-systems/yamcs
ghcr.io/spacecompute/mission-control-systems/openmct
ghcr.io/spacecompute/mission-control-systems/jupyter
ghcr.io/spacecompute/mission-control-systems/sle
```

### Build-Time ARGs

All Containerfiles accept proxy and source ARGs:

| ARG | Purpose | Runtime ENV |
|-----|---------|-------------|
| `MAVEN_HTTPS_PROXY` | Maven proxy settings | Yes |
| `HTTPS_PROXY` | HTTPS proxy | Yes |
| `HTTP_PROXY` | HTTP proxy | Yes |
| `NO_PROXY` | Proxy exclusions | Yes |
| `DEPLOYMENT_ENVIRO` | Deployment environment label | Yes |
| `GIT_URL` | Source repository to clone | Yes (for `docker inspect`) |
| `GIT_COMMIT` | Branch/tag/commit to clone | Yes (for `docker inspect`) |

`GIT_URL` and `GIT_COMMIT` are consumed at build time by `RUN git clone` and persisted as ENV for image provenance. They are not runtime configuration — do not expose them in Helm charts.

## Helm Charts

Published as OCI artifacts to GHCR:

```bash
helm install yamcs oci://ghcr.io/spacecompute/mission-control-systems/charts/yamcs
```

### Extension Points

Every chart exposes these values for mission-specific customization:

| Value | Purpose |
|-------|---------|
| `image.repository` / `image.tag` | Use a mission-specific image |
| `env.*` | Proxy and deployment environment variables |
| `extraEnv` | Inject additional environment variables |
| `extraVolumes` / `extraVolumeMounts` | Mount XTCE databases, procedures, configs |
| `resources` | Set CPU/memory requests and limits |
| `nodeSelector` / `tolerations` / `affinity` | Control pod scheduling |

### ConfigMap Entrypoint Injection

Each chart includes a ConfigMap that mirrors the container's `entrypoint.sh`. The deployment mounts it at `/entrypoint.sh` via subPath, and sets `command: ["/entrypoint.sh"]`. Missions override by replacing the ConfigMap content or mounting their own entrypoint via `extraVolumes`/`extraVolumeMounts`.

## CI Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `build-images.yaml` | Push to `main` (containers/ changes) | Build and push multi-arch container images |
| `publish-charts.yaml` | Push to `main` (helm/ changes) | Lint and publish Helm charts as OCI artifacts |
| `.gitlab-ci.yml` | Push/MR (mirrors both GitHub workflows) | GitLab CI/CD equivalent of both workflows above |

## Extension Model

Mission-specific repos extend this base repo:

1. **Custom image** — `FROM ghcr.io/spacecompute/mission-control-systems/yamcs`, add XTCE, config, decoders
2. **Helm override** — `helm install ... -f myspacecraft-yamcs.yaml` with custom `image.repository`, `extraVolumes`
3. **Compose orchestration** — Docker Compose for local development with volume mounts for mission data
4. **Entrypoint override** — Mount a custom `entrypoint.sh` via ConfigMap or volume to change startup behavior
