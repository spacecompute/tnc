#!/usr/bin/env bash

# If running as root (Docker Compose), fix bind-mount ownership and drop privileges.
# If already non-root (Kubernetes with runAsUser), run directly.

# Stop any leftover Yamcs process from a previous unclean shutdown
pkill -f 'yamcs' 2>/dev/null || true

if [ "$(id -u)" = "0" ]; then
    # Only chown writable paths — skip read-only bind mounts (etc/, mdb/,
    # displays/, functions/, decoders/) to avoid changing host file ownership.
    mkdir -p /opt/yamcs/log

    chown -R "${SERVICE_UID}:${SERVICE_GID}" \
        /opt/yamcs/yamcs-data \
        /opt/yamcs/cache \
        /opt/yamcs/lib \
        /opt/yamcs/log \
        /opt/yamcs/var \
        2>/dev/null || true

    # Shared volumes: set group to shared GID and setgid bit so new files
    # inherit the shared group. In Kubernetes, fsGroup handles this instead.
    if [ -n "${SHARED_GID}" ]; then
        for dir in /opt/yamcs/incoming /opt/yamcs/scripts; do
            chgrp -R "${SHARED_GID}" "${dir}" 2>/dev/null || true
            chmod -R g+rwX "${dir}" 2>/dev/null || true
            find "${dir}" -type d -exec chmod g+s {} + 2>/dev/null || true
            setfacl -R -d -m g::rwX "${dir}" 2>/dev/null || true
        done
    fi

    exec gosu "${SERVICE_UID}:${SERVICE_GID}" "$0" "$@"
fi

# Shared volumes: relax umask so new files are group-writable.
# Only affects this service process — root setup phase keeps 0022.
[ -n "${SHARED_GID}" ] && umask 0002

# Explicit cd — WORKDIR is not guaranteed when overridden via Helm ConfigMap
cd /opt/yamcs

# Compile mission-specific decoders into a JAR (if decoder sources are mounted)
if [ -d /opt/yamcs/decoders ] && ls /opt/yamcs/decoders/*.java 1>/dev/null 2>&1; then
    echo "Compiling mission decoders..."
    BUILD_DIR=/tmp/decoder-build
    rm -rf ${BUILD_DIR}
    mkdir -p ${BUILD_DIR}/META-INF/services

    # Plugin registration for Yamcs plugin discovery
    echo "com.example.myproject.JupyterPlugin" > ${BUILD_DIR}/META-INF/services/org.yamcs.Plugin
    echo "com.example.myproject.ServicesPlugin" >> ${BUILD_DIR}/META-INF/services/org.yamcs.Plugin

    # Plugin property files (required by Yamcs PluginManager)
    for PLUGIN in com.example.myproject.JupyterPlugin com.example.myproject.ServicesPlugin; do
        mkdir -p ${BUILD_DIR}/META-INF/yamcs/${PLUGIN}
        printf "name=myproject\nversion=1.0.0-SNAPSHOT\n" > ${BUILD_DIR}/META-INF/yamcs/${PLUGIN}/plugin.properties
    done

    # Compile all .java files against Yamcs classpath
    javac -cp "/opt/yamcs/lib/*" \
          -d ${BUILD_DIR} \
          /opt/yamcs/decoders/*.java

    # Package into JAR and place on classpath
    jar cf /opt/yamcs/lib/ext/mission-decoders.jar -C ${BUILD_DIR} .
    rm -rf ${BUILD_DIR}
    echo "Mission decoders compiled successfully."
fi

# Start yamcsd
mkdir -p /opt/yamcs/var/run
/opt/yamcs/bin/yamcsd --etc-dir /opt/yamcs/etc --data-dir /opt/yamcs/yamcs-data &
echo $! > /opt/yamcs/var/run/pid

tail -f /dev/null
