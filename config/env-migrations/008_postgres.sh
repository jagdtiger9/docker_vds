#!/bin/bash
# Add Postgres service vars: POSTGRES block, PG_EXPORTER_PASSWORD, ADMINER_PORT_MAP
# NOTE: COMPOSE_PROFILES is NOT touched — opting into the `database_pg` profile is a manual edit
set -e

ENV="$1"

# Already applied?
grep -q '^###> POSTGRES$' "$ENV" && exit 0

echo "[008] Adding Postgres vars"

grep -q '^###< DATABASE$' "$ENV"

BLOCK=$(mktemp)
cat > "$BLOCK" <<'EOF'
###> POSTGRES
POSTGRES_USER=postgres
POSTGRES_PASSWORD=
POSTGRES_DB=postgres
PG_CONFIG=./config/postgres/
PG_DATA=./data/postgres/
# Доступ к БД с клиента по умолчанию закрыт
# Например: psql -h 127.0.0.1 --port=5432 -U postgres -d db_name < dump.sql
PG_PORT_MAP=127.0.0.1:5432:5432
###< POSTGRES
EOF
printf '\n' >> "$BLOCK"

sed -i "/^###< DATABASE$/r $BLOCK" "$ENV"
rm -f "$BLOCK"

# Adminer in the pma profile
grep -q '^ADMINER_PORT_MAP=' "$ENV" || \
    sed -i '/^UPLOAD_LIMIT=/a ADMINER_PORT_MAP=8082:8080' "$ENV"

# postgres_exporter credentials
grep -q '^PG_EXPORTER_PASSWORD=' "$ENV" || \
    sed -i '/^CONF_MYSQL_EXPORTER=/a PG_EXPORTER_PASSWORD=' "$ENV"
