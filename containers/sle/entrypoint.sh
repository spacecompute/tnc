#!/usr/bin/env bash

# If running as root (Docker Compose), fix bind-mount ownership and drop privileges.
# If already non-root (Kubernetes with runAsUser), run directly.
if [ "$(id -u)" = "0" ]; then
    chown -R "${SERVICE_UID}:${SERVICE_GID}" /opt/jsle /storage/data1 2>/dev/null || true
    exec gosu "${SERVICE_UID}:${SERVICE_GID}" "$0" "$@"
fi

# Explicit cd — WORKDIR is not guaranteed when overridden via Helm ConfigMap
cd /opt/jsle
mvn ${MAVEN_HTTPS_PROXY} exec:java -Dmaven.repo.local=/opt/jsle/.m2/repository
