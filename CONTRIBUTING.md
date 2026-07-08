# Contributing

## Repository Structure

```
mission-control-systems/
├── containers/          # Containerfiles and entrypoints for base images
│   ├── yamcs/           # Yamcs mission control server
│   ├── openmct/         # OpenMCT web telemetry UI
│   ├── jupyter/         # JupyterHub with multi-language kernels
│   └── sle/             # jSLE Space Link Extension provider
├── helm/                # Helm charts for Kubernetes deployment
│   ├── yamcs/
│   ├── openmct/
│   ├── jupyter/
│   └── sle/
├── .github/workflows/   # CI — build-images.yaml, publish-charts.yaml
├── Taskfile.yaml        # Local development tasks
└── CONTRIBUTING.md      # This file
```

## Commit Conventions

Use past tense with area-based sections:

```
<Summary — what changed and why>

<Area>:
- Specific change
- Specific change

<Area>:
- Specific change
```

Example:

```
Standardized container paths to /opt/ and added Helm ConfigMap entrypoints

Containers:
- Updated all WORKDIR paths from /yamcs/ to /opt/yamcs/
- Added COPY entrypoint.sh /entrypoint.sh and CMD to all Containerfiles

Helm:
- Added ConfigMap-based entrypoint templates for all charts
- Updated deployment command and volumeMount to use /entrypoint.sh
```

Rules:
- Past tense: "Added", "Removed", "Updated", "Fixed", "Replaced", "Renamed"
- No `Co-Authored-By` trailers referencing AI tools
- Summary line describes _what changed_, body provides specifics by area

## Pre-Commit Checklist

Before committing, verify:

1. **No AI tool references** — scan for "claude", "anthropic", "co-authored-by" strings
2. **Path consistency** — all container paths use `/opt/{service}/` convention (see `ARCHITECTURE.md`)
3. **Containerfile/Helm alignment** — entrypoint scripts, env vars, and paths match between `containers/` and `helm/`
4. **Helm lint** — `task helm:lint`
5. **Build validation** — `task build:dry`
6. **Documentation** — if paths, variables, or task names changed, check READMEs for stale references

## Code Review

Key things to check:

- Container paths follow `/opt/{service}/` convention (`/opt/yamcs/`, `/opt/openmct/`, `/opt/jupyter/`, `/opt/jsle/`)
- Entrypoint scripts have explicit `cd /opt/<service>` (WORKDIR not guaranteed when overridden via Helm ConfigMap)
- Helm chart env vars match Containerfile `ARG`/`ENV` declarations
- Helm ConfigMap entrypoints match `containers/<service>/entrypoint.sh`
- Build-time ARGs (`GIT_URL`, `GIT_COMMIT`) are not exposed as runtime Helm values

## Getting Started

Requires [Task](https://taskfile.dev), [act](https://github.com/nektos/act), and [Helm](https://helm.sh).

```bash
task                    # list available tasks
task build              # build all container images via act
task build:dry          # validate workflow without building
task helm:lint          # lint all Helm charts
task helm:template      # render all chart templates locally
```
