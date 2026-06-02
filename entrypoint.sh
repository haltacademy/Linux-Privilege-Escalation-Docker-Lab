#!/bin/bash

# Detect GID of docker.sock if mounted
if [ -S /var/run/docker.sock ]; then
    DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    # Check if a group with this GID already exists
    EXISTING_GROUP=$(getent group | grep ":$DOCKER_GID:" | cut -d: -f1)
    if [ -n "$EXISTING_GROUP" ]; then
        usermod -aG "$EXISTING_GROUP" student
    fi
    # Create group and add student if it doesn't exist
    groupadd -g "$DOCKER_GID" docker_host 2>/dev/null || true
    usermod -aG docker_host student 2>/dev/null || true
fi

# Start the cron daemon in the background for world-writable, PATH injection, and NFS simulation cron jobs
service cron start

# Execute the CMD (which is /usr/sbin/sshd -D)
exec "$@"
