#!/usr/bin/env bash

# If running as root (Docker Compose), fix bind-mount ownership and drop privileges.
# If already non-root (Kubernetes with runAsUser), run directly.
if [ "$(id -u)" = "0" ]; then
    # Only chown writable paths — skip read-only bind mounts (etc/, mdb/,
    # displays/, functions/, decoders/) to avoid changing host file ownership.
    chown -R "${SERVICE_UID}:${SERVICE_GID}" \
        /opt/yamcs/.m2 \
        /opt/yamcs/yamcs-data \
        /opt/yamcs/src/main/resources \
        /opt/yamcs/target \
        2>/dev/null || true
    exec gosu "${SERVICE_UID}:${SERVICE_GID}" "$0" "$@"
fi

# Explicit cd — WORKDIR is not guaranteed when overridden via Helm ConfigMap
cd /opt/yamcs
mvn ${MAVEN_HTTPS_PROXY} yamcs:run -Dmaven.repo.local=/opt/yamcs/.m2/repository
