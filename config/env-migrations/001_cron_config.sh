#!/bin/bash
# Rename CONF_CRON → CRON_CONFIG, inline hosts_crontab into crontab file
set -e

ENV="$1"

# Already applied?
grep -q '^CRON_CONFIG=' "$ENV" && ! grep -q '^CONF_CRON=' "$ENV" && exit 0

echo "[001] Renaming CONF_CRON → CRON_CONFIG"

# Remove old key
sed -i '/^CONF_CRON=/d' "$ENV"

# Add new key after DATA_XDEBUG line
if ! grep -q '^CRON_CONFIG=' "$ENV"; then
    sed -i '/^DATA_XDEBUG=/a CRON_CONFIG=./config/cron/crontab' "$ENV"
fi
