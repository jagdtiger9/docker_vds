#!/bin/bash
# Rename env vars to match updated compose.yaml schema
# CONF_WORKER → WORKER_CONFIG, DATA_XDEBUG → XDEBUG_DATA, DATA_MYSQL → DB_DATA,
# CONF_MYSQL → DB_CONFIG, DATA_RABBITMQ → RABBITMQ_DATA, CONF_HOSTS → HOSTS_CONFIG,
# DATA_HOSTS → HOSTS_DATA, CONF_LOGGER → LOGGER_CONFIG, CONF_LOG → SYSLOG_CONFIG
set -e

ENV="$1"

# Already applied? Check the first renamed key
grep -q '^WORKER_CONFIG=' "$ENV" && ! grep -q '^CONF_WORKER=' "$ENV" && exit 0

echo "[004] Renaming env vars"

rename_var() {
    local old="$1" new="$2"
    if grep -q "^${old}=" "$ENV" && ! grep -q "^${new}=" "$ENV"; then
        echo "  ${old} → ${new}"
        sed -i "s/^${old}=/${new}=/" "$ENV"
    fi
}

rename_var CONF_WORKER   WORKER_CONFIG
rename_var DATA_XDEBUG   XDEBUG_DATA
rename_var DATA_MYSQL    DB_DATA
rename_var CONF_MYSQL    DB_CONFIG
rename_var DATA_RABBITMQ RABBITMQ_DATA
rename_var CONF_HOSTS    HOSTS_CONFIG
rename_var DATA_HOSTS    HOSTS_DATA
rename_var CONF_LOGGER   LOGGER_CONFIG
rename_var CONF_LOG      SYSLOG_CONFIG
