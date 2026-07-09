# Container Images

Multi-arch (amd64/arm64) base images published to GitHub Container Registry.

## Images

| Image | Base | Description |
|-------|------|-------------|
| `ghcr.io/spacecompute/mission-control-systems/yamcs` | maven:3.9.9-eclipse-temurin-17 | [Yamcs](https://yamcs.org) mission control server |
| `ghcr.io/spacecompute/mission-control-systems/openmct` | ubuntu:25.04 + Node.js 24 | [OpenMCT](https://github.com/nasa/openmct) web telemetry UI with Yamcs plugin |
| `ghcr.io/spacecompute/mission-control-systems/jupyter` | jupyterhub:5 | JupyterHub with Python, Ruby, Perl, R, Gnuplot, and Octave kernels |
| `ghcr.io/spacecompute/mission-control-systems/sle` | maven:3.9.9-eclipse-temurin-17 | [jSLE](https://github.com/yamcs/jsle) Space Link Extension provider |

## Usage

```bash
docker pull ghcr.io/spacecompute/mission-control-systems/yamcs:latest
docker pull ghcr.io/spacecompute/mission-control-systems/openmct:latest
docker pull ghcr.io/spacecompute/mission-control-systems/jupyter:latest
docker pull ghcr.io/spacecompute/mission-control-systems/sle:latest
```

These are base images. Mission-specific repos extend them with XTCE databases, display configs, procedures, and compose orchestration.

## Building locally

```bash
task build              # build all images locally
task build:yamcs        # build one image locally
task act:build          # build all images via act (CI workflow)
task act:build:dry      # validate workflow without building
task act:graph          # show workflow DAG
```
