#!/bin/bash
# Replace old REDIS block (CONF_REDIS/DATA_REDIS) with new keys
set -e

ENV="$1"

# Already applied? (has REDIS_CONF, not CONF_REDIS)
grep -q '^REDIS_CONF=' "$ENV" && ! grep -q '^CONF_REDIS=' "$ENV" && exit 0

echo "[003] Updating REDIS block"

# Remove old block if present
if grep -q '###> REDIS' "$ENV"; then
    sed -i '/^###> REDIS/,/^###< REDIS/d' "$ENV"
fi

# Insert new block before RABBITMQ section
sed -i '/^###> RABBITMQ/i ###> REDIS\nREDIS_CONF=./config/redis/redis.conf\nREDIS_DATA=./data/redis/\nREDIS_MAX_MEMORY=512mb\n# After 3600 sec at least 100 keys changed\nREDIS_SAVE_1="3600 100"\nREDIS_SAVE_2="600 500"\n###< REDIS\n' "$ENV"
