#!/bin/bash
set -e

CRON_UID="${CRON_UID:-82}"
CRON_GID="${CRON_GID:-82}"
CRON_USER="cronuser"
CRONTAB="/etc/crontabs/${CRON_USER}"

# Create group/user at runtime from env vars,
# matching host UID/GID so file operations (logs, dumps) have correct ownership
addgroup -g "${CRON_GID}" crongroup 2>/dev/null || true
adduser -D -s /bin/bash -u "${CRON_UID}" -G crongroup "${CRON_USER}" 2>/dev/null || true

# Install crontab from the volume-mounted file.
# Busybox crond requires root-owned, 0600 crontab files.
if [ -f /etc/crontabs/crontab ]; then
    cp /etc/crontabs/crontab "${CRONTAB}"
    chown root:root "${CRONTAB}"
    chmod 0600 "${CRONTAB}"
fi

exec "$@"
