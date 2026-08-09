#!/bin/bash
# Add MEMCACHED block
set -e

ENV="$1"

# Already applied?
grep -q '###> MEMCACHED' "$ENV" && exit 0

echo "[002] Adding MEMCACHED block"

cat >> "$ENV" << 'BLOCK'

###> MEMCACHED
MEMCACHED_MAX_MEMORY=512
###< MEMCACHED
BLOCK
