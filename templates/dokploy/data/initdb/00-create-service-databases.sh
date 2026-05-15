#!/usr/bin/env bash
set -euo pipefail

create_database() {
  local db_name="$1"
  psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
    --set db_name="$db_name" <<'SQL'
SELECT format('CREATE DATABASE %I OWNER %I', :'db_name', current_user)
WHERE NOT EXISTS (
  SELECT 1 FROM pg_database WHERE datname = :'db_name'
)
\gexec
SQL
}

create_database logto
create_database umami
