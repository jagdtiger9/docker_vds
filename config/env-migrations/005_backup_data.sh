#!/bin/bash
# Add BACKUP_DATA var
set -e

ENV="$1"

grep -q '^BACKUP_DATA=' "$ENV" && exit 0

echo "[005] Adding BACKUP_DATA"

sed -i '/^XDEBUG_DATA=/a BACKUP_DATA=./data/backup/' "$ENV"
