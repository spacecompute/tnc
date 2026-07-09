# Mission Control Systems

Base container images and Helm charts for spacecraft mission control.

## Critical Conventions

- Container paths: `/opt/{service}/` — yamcs, openmct, jupyter, jsle
- Entrypoints: `COPY entrypoint.sh /entrypoint.sh` + `CMD ["/entrypoint.sh"]`
- Entrypoint scripts: explicit `cd /opt/<service>` — WORKDIR not guaranteed via Helm ConfigMap
- Helm charts: ConfigMap-based entrypoints, `extraEnv`/`extraVolumes`/`extraVolumeMounts` extension points
- Commit messages: past tense, area-based sections, no AI co-authored-by trailers
- No spacecraft names in base repo — use "myspacecraft" for examples

## Common Tasks

```
task build              # build all container images locally
task build:yamcs        # build one image locally
task act:build          # build all images via act (CI workflow)
task act:build:dry      # validate workflow without building
task helm:lint          # lint all Helm charts
task helm:template      # render all chart templates locally
```

## Reference

- [CONTRIBUTING.md](../CONTRIBUTING.md) — commit conventions, review process
- [ARCHITECTURE.md](../ARCHITECTURE.md) — container paths, deployment methods, image strategy
