#!/bin/bash
# Add CRON_DUMP_PROJECTS var
set -e

ENV="$1"

grep -q '^CRON_DUMP_PROJECTS=' "$ENV" && exit 0

echo "[006] Adding CRON_DUMP_PROJECTS"

sed -i '/^CRON_CONFIG=/a CRON_DUMP_PROJECTS=./config/cron/projects' "$ENV"
