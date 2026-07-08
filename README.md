# Mission Control Systems

Container images and Helm charts for spacecraft mission control systems.

## Repository layout

| Directory | Description |
|-----------|-------------|
| [containers/](containers/) | Dockerfiles for base images — see [containers/README.md](containers/README.md) |
| [helm/](helm/) | Helm charts for Kubernetes deployment — see [helm/README.md](helm/README.md) |

## CI

- [build-images.yaml](.github/workflows/build-images.yaml) — builds multi-arch container images on push to `main`
- [publish-charts.yaml](.github/workflows/publish-charts.yaml) — lints and publishes Helm charts to GHCR on push to `main`

## Local development

Requires [Task](https://taskfile.dev), [act](https://github.com/nektos/act), and [Helm](https://helm.sh).

```bash
task build              # build all container images via act
task build:yamcs        # build one image
task build:dry          # validate workflow without building
task helm:lint          # lint all Helm charts
task helm:template      # render all chart templates locally
```
