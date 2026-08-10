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

# Copy crontab from read-only mount to the crond directory.
# Copying instead of mounting directly preserves host file ownership.
# Busybox crond requires root-owned, 0600 crontab files.
if [ -f /tmp/crontab.in ]; then
    cp /tmp/crontab.in "${CRONTAB}"
    chown root:root "${CRONTAB}"
    chmod 0600 "${CRONTAB}"
fi

# syslogd captures crond's syslog() calls (which include cron job output)
# and writes them to /dev/stdout so Docker logging driver picks them up.
busybox syslogd -O /dev/stdout

exec "$@"
