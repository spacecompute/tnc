---
name: jupyter
description: Reference JupyterHub multi-language kernel environment — base image, Helm chart, kernel support, procedure execution model, and extension points.
argument-hint: [build | helm | kernels | procedures | extend]
---

# JupyterHub Multi-Language Environment

Reference for the JupyterHub base image and Helm chart. Based on `$ARGUMENTS`. Default to overview if no argument given.

## Overview

JupyterHub with Real-Time Collaboration (RTC) for collaborative procedure execution. The base image includes multiple language kernels for mission operations flexibility.

## Base Image

```
ghcr.io/spacecompute/mission-control-systems/jupyter:latest
```

| Property | Value |
|----------|-------|
| Base | `quay.io/jupyterhub/jupyterhub:5` |
| Container Path | `/opt/jupyter/` |
| Default Port | 8000 |
| Start Command | `jupyterhub -f ./jupyterhub_config.py` |

### Build

```bash
task build:jupyter
```

### Containerfile

```
containers/jupyter/Containerfile
containers/jupyter/entrypoint.sh
containers/jupyter/jupyterhub_config.py
containers/jupyter/requirements.txt
```

## Installed Kernels

| Language | Kernel | Package |
|----------|--------|---------|
| Python | ipykernel | (built-in with JupyterHub) |
| Ruby | iruby | `gem install iruby` |
| Perl | IPerl | `cpanm Devel::IPerl` |
| R | IRkernel | `install.packages('IRkernel')` |
| Gnuplot | gnuplot_kernel | `pip install gnuplot_kernel` |
| Octave | octave_kernel | `pip install octave_kernel` |

## Core Infrastructure

Baked into the base image:

- `jupyterlab` — JupyterLab web interface
- `jupyter-collaboration` — Real-Time Collaboration (RTC)
- `jupyterhub-idle-culler` — Auto-shutdown idle kernels

## Helm Chart

```bash
helm install jupyter oci://ghcr.io/spacecompute/mission-control-systems/charts/jupyter
```

### Extension Points

| Value | Purpose |
|-------|---------|
| `image.repository` / `image.tag` | Use a mission-specific Jupyter image |
| `extraEnv` | Inject environment variables (Yamcs URL, mission name) |
| `extraVolumes` / `extraVolumeMounts` | Mount procedures, requirements, config |
| `resources` | CPU/memory requests and limits |

The jupyter chart uses `extraEnv` only (no `env.*` section) — missions inject all environment variables through `extraEnv`.

### ConfigMap Entrypoint

```bash
#!/usr/bin/env bash
# Explicit cd — WORKDIR is not guaranteed when overridden via Helm ConfigMap
cd /opt/jupyter
jupyterhub -f ./jupyterhub_config.py
tail -f /dev/null
```

## JupyterHub Configuration

The `jupyterhub_config.py` controls:
- Authentication (default: no auth for local dev)
- Spawner settings (notebook directory, default URL)
- Idle culler timeout
- RTC settings

Mission repos override via volume mount:

```yaml
extraVolumeMounts:
  - name: config
    mountPath: /opt/jupyter/jupyterhub_config.py
    subPath: jupyterhub_config.py

extraVolumes:
  - name: config
    configMap:
      name: myspacecraft-jupyter-config
```

## Requirements

The base image supports an optional `requirements.txt` for Python packages. Mission repos provide their own:

```yaml
extraVolumeMounts:
  - name: requirements
    mountPath: /opt/jupyter/requirements.txt
    subPath: requirements.txt
```

Common packages for mission operations:
- `yamcs-client` — Yamcs Python API
- `ccsdspy` — CCSDS packet parsing
- `numpy`, `matplotlib`, `plotly` — Data visualization
- `pandas`, `polars` — Data analysis
- `ipywidgets` — Operator confirmation gates

## Procedure Execution Model

- **Server-side execution** — procedures run in JupyterHub containers
- **Single-threaded** — one procedure at a time (serial execution)
- **RTC** — all operators see the same notebook execution in real-time
- **Debug + stop points** — Jupyter native breakpoints / cell-by-cell
- **Operator gates** — ipywidgets buttons for critical command confirmation
- **Procedure stacks** — `%run ./subproc.ipynb` for nested calls

## Extending the Base Image

```dockerfile
FROM ghcr.io/spacecompute/mission-control-systems/jupyter:latest

# Add mission-specific Python packages
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Add JupyterHub config
COPY jupyterhub_config.py /opt/jupyter/jupyterhub_config.py

# Add procedures
COPY procedures/ /srv/procedures/
```

## Key Files

| Role | Path |
|------|------|
| Containerfile | `containers/jupyter/Containerfile` |
| Entrypoint | `containers/jupyter/entrypoint.sh` |
| JupyterHub Config | `containers/jupyter/jupyterhub_config.py` |
| Requirements | `containers/jupyter/requirements.txt` |
| Helm Chart | `helm/jupyter/` |

## Dependencies

- Typically connects to a Yamcs instance via `yamcs-client` Python package
- In Kubernetes, the Jupyter pod may depend on Yamcs being healthy
- In Docker Compose, use `service_healthy` condition on the Yamcs service
