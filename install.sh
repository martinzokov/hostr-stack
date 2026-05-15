#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/opt/hostr-stack}"
HOSTR_REPO_URL="${HOSTR_REPO_URL:-https://github.com/martinzokov/hostr-stack.git}"
HOSTR_BRANCH="${HOSTR_BRANCH:-main}"
PROJECT_NAME="${PROJECT_NAME:-hostr-stack}"
ENVIRONMENT_NAME="${ENVIRONMENT_NAME:-production}"
HOSTR_ENV_FILE="${HOSTR_ENV_FILE:-/root/hostr-stack.env}"
DEPLOY_STACK="${DEPLOY_STACK:-1}"
RUN_SMOKE="${RUN_SMOKE:-1}"
BLOCK_DOKPLOY_PORT="${BLOCK_DOKPLOY_PORT:-1}"
DOKPLOY_SETUP_MODE="${DOKPLOY_SETUP_MODE:-auto}"
ADMIN_CREATED=0

log() {
  printf '\n==> %s\n' "$*"
}

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run this installer as root on the VPS." >&2
    exit 1
  fi
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

prompt_tty() {
  local prompt="$1"
  local var_name="$2"
  local value=""
  if [ -r /dev/tty ]; then
    printf '%s' "$prompt" >/dev/tty
    IFS= read -r value </dev/tty
  else
    echo "Cannot prompt without a TTY. Set $var_name and re-run." >&2
    exit 1
  fi
  printf -v "$var_name" '%s' "$value"
}

wait_for_tty_enter() {
  if [ -r /dev/tty ]; then
    printf '%s' "$1" >/dev/tty
    IFS= read -r _ </dev/tty
  else
    echo "Cannot wait for manual setup without a TTY." >&2
    exit 1
  fi
}

random_hex() {
  openssl rand -hex "${1:-16}" | tr -d '\n'
}

random_urlsafe() {
  openssl rand -base64 "${1:-32}" | tr '+/' '-_' | tr -d '=\n'
}

public_ip() {
  local ip=""
  ip="$(curl -fsS --max-time 10 https://api.ipify.org 2>/dev/null || true)"
  if [ -z "$ip" ]; then
    ip="$(hostname -I | awk '{print $1}')"
  fi
  [ -n "$ip" ] || {
    echo "Could not detect public IPv4. Set ROOT_DOMAIN and DOKPLOY_DOMAIN explicitly." >&2
    exit 1
  }
  printf '%s\n' "$ip"
}

set_env_value() {
  local file="$1"
  local key="$2"
  local value="$3"
  if grep -q "^${key}=" "$file"; then
    perl -0pi -e "s|^${key}=.*$|${key}=${value}|m" "$file"
  else
    printf '\n%s=%s\n' "$key" "$value" >> "$file"
  fi
}

sql_quote() {
  python3 -c 'import sys; print("'"'"'" + sys.argv[1].replace("'"'"'", "'"'"''"'"'") + "'"'"'")' "$1"
}

install_packages() {
  log "Installing base packages"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y ca-certificates curl git openssl python3 python3-bcrypt perl iptables
}

ensure_repo() {
  local script_dir=""
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P || true)"

  if [ -n "$script_dir" ] && [ -f "$script_dir/install.sh" ] && [ -x "$script_dir/bin/hostr-stack" ]; then
    cd "$script_dir"
    return
  fi

  log "Cloning hostr-stack into $INSTALL_DIR"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  if [ -d "$INSTALL_DIR/.git" ]; then
    git -C "$INSTALL_DIR" fetch --all --prune
    git -C "$INSTALL_DIR" checkout "$HOSTR_BRANCH"
    git -C "$INSTALL_DIR" pull --ff-only
  else
    git clone "${HOSTR_REPO_URL}" "$INSTALL_DIR"
    git -C "$INSTALL_DIR" checkout "$HOSTR_BRANCH"
  fi
  cd "$INSTALL_DIR"
}

install_dokploy() {
  if docker service ls --format '{{.Name}}' 2>/dev/null | grep -qx dokploy; then
    log "Dokploy already installed"
    return
  fi

  log "Installing Dokploy"
  curl -sSL https://dokploy.com/install.sh | sh
}

dokploy_container() {
  docker ps --filter name=dokploy.1 --format '{{.ID}}' | head -n 1
}

dokploy_postgres_container() {
  docker ps --filter name=dokploy-postgres --format '{{.ID}}' | head -n 1
}

wait_for_dokploy() {
  log "Waiting for Dokploy app"
  local container=""
  for _ in $(seq 1 60); do
    container="$(dokploy_container || true)"
    if [ -n "$container" ] && docker exec "$container" curl -fsS --max-time 5 http://127.0.0.1:3000/api/health >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  echo "Dokploy did not become healthy in time." >&2
  exit 1
}

write_traefik_config() {
  log "Configuring Dokploy HTTPS at https://$DOKPLOY_DOMAIN"
  mkdir -p /etc/dokploy/traefik/dynamic
  touch /etc/dokploy/traefik/dynamic/acme.json
  chmod 600 /etc/dokploy/traefik/dynamic/acme.json

  cat >/etc/dokploy/traefik/traefik.yml <<EOF
global:
  sendAnonymousUsage: false
providers:
  swarm:
    exposedByDefault: false
    watch: true
  docker:
    exposedByDefault: false
    watch: true
    network: dokploy-network
  file:
    directory: /etc/dokploy/traefik/dynamic
    watch: true
entryPoints:
  web:
    address: :80
  websecure:
    address: :443
    http3:
      advertisedPort: 443
    http:
      tls:
        certResolver: letsencrypt
api:
  insecure: true
certificatesResolvers:
  letsencrypt:
    acme:
      email: $ADMIN_EMAIL
      storage: /etc/dokploy/traefik/dynamic/acme.json
      httpChallenge:
        entryPoint: web
EOF

  cat >/etc/dokploy/traefik/dynamic/middlewares.yml <<'EOF'
http:
  middlewares:
    redirect-to-https:
      redirectScheme:
        scheme: https
        permanent: true
EOF

  cat >/etc/dokploy/traefik/dynamic/dokploy.yml <<EOF
http:
  routers:
    dokploy-router-app:
      rule: Host(\`$DOKPLOY_DOMAIN\`) && PathPrefix(\`/\`)
      service: dokploy-service-app
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
    dokploy-router-app-http:
      rule: Host(\`$DOKPLOY_DOMAIN\`) && PathPrefix(\`/\`)
      service: dokploy-service-app
      entryPoints:
        - web
      middlewares:
        - redirect-to-https
  services:
    dokploy-service-app:
      loadBalancer:
        servers:
          - url: http://dokploy:3000
        passHostHeader: true
EOF
}

ensure_traefik() {
  if docker ps -a --format '{{.Names}}' | grep -qx dokploy-traefik; then
    log "Reusing Dokploy Traefik container"
    if docker service ls --format '{{.Name}}' | grep -qx dokploy-traefik; then
      docker service rm dokploy-traefik >/dev/null 2>&1 || true
    fi
    docker restart dokploy-traefik >/dev/null
    return
  fi

  if docker service ls --format '{{.Name}}' | grep -qx dokploy-traefik; then
    docker service update --force dokploy-traefik >/dev/null
    return
  fi

  log "Starting Traefik for Dokploy"
  docker service create \
    --name dokploy-traefik \
    --constraint 'node.role==manager' \
    --publish published=80,target=80,mode=host \
    --publish published=443,target=443,mode=host \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock,readonly \
    --mount type=bind,source=/etc/dokploy/traefik,target=/etc/dokploy/traefik \
    --network dokploy-network \
    traefik:v3.1 \
    --configFile=/etc/dokploy/traefik/traefik.yml >/dev/null
}

wait_for_dokploy_https() {
  log "Waiting for Dokploy HTTPS"
  for _ in $(seq 1 60); do
    if curl -fsS --max-time 10 "https://$DOKPLOY_DOMAIN/api/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  echo "Dokploy HTTPS did not become reachable at https://$DOKPLOY_DOMAIN." >&2
  exit 1
}

create_admin_if_needed() {
  local pg
  pg="$(dokploy_postgres_container)"
  local count
  count="$(docker exec "$pg" psql -U dokploy -d dokploy -Atc 'select count(*) from "user";')"
  if [ "$count" != "0" ]; then
    rotate_existing_admin_password
    return
  fi

  log "Creating Dokploy admin account"
  local app payload
  app="$(dokploy_container)"
  payload="$(python3 - <<PY
import json
print(json.dumps({"email": "$ADMIN_EMAIL", "password": "$ADMIN_PASSWORD", "name": "Hostr Admin"}))
PY
)"
  printf '%s' "$payload" | docker exec -i "$app" curl -fsS \
    -X POST http://127.0.0.1:3000/api/auth/sign-up/email \
    -H 'content-type: application/json' \
    --data-binary @- >/dev/null
  ADMIN_CREATED=1
}

bcrypt_password() {
  PASSWORD="$1" python3 - <<'PY'
import bcrypt
import os

password = os.environ["PASSWORD"].encode()
print(bcrypt.hashpw(password, bcrypt.gensalt(rounds=10)).decode())
PY
}

rotate_existing_admin_password() {
  log "Dokploy admin already exists; rotating first admin password for auto-mode"
  local pg user_id user_email password_hash account_id
  pg="$(dokploy_postgres_container)"
  user_id="$(docker exec "$pg" psql -U dokploy -d dokploy -Atc 'select id from "user" order by created_at asc limit 1;')"
  user_email="$(docker exec "$pg" psql -U dokploy -d dokploy -Atc "select email from \"user\" where id = $(sql_quote "$user_id");")"
  [ -n "$user_id" ] && [ -n "$user_email" ] || {
    echo "Could not discover existing Dokploy admin user." >&2
    exit 1
  }

  ADMIN_EMAIL="$user_email"
  password_hash="$(bcrypt_password "$ADMIN_PASSWORD")"
  account_id="hostr-account-$(random_hex 8)"

  docker exec -i "$pg" psql -U dokploy -d dokploy >/dev/null <<SQL
update account
set password = $(sql_quote "$password_hash"), updated_at = now()
where user_id = $(sql_quote "$user_id") and provider_id = 'credential';

insert into account (id, account_id, provider_id, user_id, password, "is2FAEnabled", created_at, updated_at)
select $(sql_quote "$account_id"), $(sql_quote "$user_id"), 'credential', $(sql_quote "$user_id"), $(sql_quote "$password_hash"), false, now(), now()
where not exists (
  select 1 from account where user_id = $(sql_quote "$user_id") and provider_id = 'credential'
);
SQL

  ADMIN_CREATED=1
}

bootstrap_dokploy_data() {
  log "Creating Dokploy API key, project, and environment"
  local pg user_id org_id key_hash key_id project_id environment_id now
  local user_sql project_name_sql project_sql environment_name_sql
  pg="$(dokploy_postgres_container)"
  user_id="$(docker exec "$pg" psql -U dokploy -d dokploy -Atc 'select id from "user" order by created_at asc limit 1;')"
  user_sql="$(sql_quote "$user_id")"
  org_id="$(docker exec "$pg" psql -U dokploy -d dokploy -Atc "select organization_id from member where user_id = $user_sql and role = 'owner' order by created_at asc limit 1;")"
  [ -n "$user_id" ] && [ -n "$org_id" ] || {
    echo "Could not discover Dokploy owner user/organization." >&2
    exit 1
  }

  API_KEY="$(random_urlsafe 48)"
  key_hash="$(API_KEY="$API_KEY" python3 - <<'PY'
import base64, hashlib, os
digest = hashlib.sha256(os.environ["API_KEY"].encode()).digest()
print(base64.urlsafe_b64encode(digest).decode().rstrip("="))
PY
)"
  key_id="hostr-api-$(random_hex 8)"
  project_name_sql="$(sql_quote "$PROJECT_NAME")"
  environment_name_sql="$(sql_quote "$ENVIRONMENT_NAME")"
  project_id="$(docker exec "$pg" psql -U dokploy -d dokploy -Atc "select \"projectId\" from project where name = $project_name_sql limit 1;")"
  [ -n "$project_id" ] || project_id="hostr-$(random_hex 6)"
  project_sql="$(sql_quote "$project_id")"
  environment_id="$(docker exec "$pg" psql -U dokploy -d dokploy -Atc "select \"environmentId\" from environment where \"projectId\" = $project_sql and name = $environment_name_sql limit 1;")"
  [ -n "$environment_id" ] || environment_id="env-$(random_hex 6)"
  now="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"

  docker exec -i "$pg" psql -U dokploy -d dokploy >/dev/null <<SQL
insert into project ("projectId", name, description, "createdAt", env, "organizationId")
values ($(sql_quote "$project_id"), $(sql_quote "$PROJECT_NAME"), 'hostr-stack automated project', $(sql_quote "$now"), '', $(sql_quote "$org_id"))
on conflict ("projectId") do update set name = excluded.name;

insert into environment ("environmentId", name, description, "createdAt", "projectId", env, "isDefault")
values ($(sql_quote "$environment_id"), $(sql_quote "$ENVIRONMENT_NAME"), 'hostr-stack automated environment', $(sql_quote "$now"), $(sql_quote "$project_id"), '', true)
on conflict ("environmentId") do update set name = excluded.name, "isDefault" = true;

insert into apikey (id, name, start, prefix, key, enabled, rate_limit_enabled, request_count, created_at, updated_at, metadata, config_id, reference_id)
values ($(sql_quote "$key_id"), 'hostr-stack-cli', $(sql_quote "${API_KEY:0:6}"), null, $(sql_quote "$key_hash"), true, true, 0, now(), now(), $(sql_quote "{\"organizationId\":\"$org_id\"}"), 'default', $(sql_quote "$user_id"));
SQL

  DOKPLOY_ENVIRONMENT_ID="$environment_id"
}

manual_dokploy_setup() {
  log "Waiting for manual Dokploy setup"
  cat <<EOF

Open Dokploy and complete setup manually:

  https://$DOKPLOY_DOMAIN

Create:
1. The first admin account.
2. A Dokploy API key.
3. A project, for example "$PROJECT_NAME".
4. An environment, for example "$ENVIRONMENT_NAME".

Then paste the API key and environment ID back here.
EOF

  wait_for_tty_enter "Press Enter when the Dokploy admin, API key, project, and environment are ready..."

  API_KEY="${DOKPLOY_API_KEY:-}"
  DOKPLOY_ENVIRONMENT_ID="${DOKPLOY_ENVIRONMENT_ID:-}"

  while [ -z "$API_KEY" ]; do
    prompt_tty "Dokploy API key: " API_KEY
  done
  while [ -z "$DOKPLOY_ENVIRONMENT_ID" ]; do
    prompt_tty "Dokploy environment ID: " DOKPLOY_ENVIRONMENT_ID
  done

  local entered_email=""
  prompt_tty "Dokploy admin email (optional, press Enter to keep $ADMIN_EMAIL): " entered_email
  if [ -n "$entered_email" ]; then
    ADMIN_EMAIL="$entered_email"
  fi

  log "Verifying manual Dokploy API access"
  curl -fsS "https://${DOKPLOY_DOMAIN%/}/api/trpc/project.all" \
    -H "x-api-key: $API_KEY" >/dev/null
  ADMIN_CREATED=0
}

configure_dokploy_access() {
  case "$DOKPLOY_SETUP_MODE" in
    auto)
      create_admin_if_needed
      bootstrap_dokploy_data
      ;;
    manual)
      manual_dokploy_setup
      ;;
    *)
      echo "Unknown DOKPLOY_SETUP_MODE=$DOKPLOY_SETUP_MODE. Use auto or manual." >&2
      exit 1
      ;;
  esac
}

write_runtime_env() {
  log "Writing runtime deployment env to $HOSTR_ENV_FILE"
  umask 077
  cat >"$HOSTR_ENV_FILE" <<EOF
DOKPLOY_URL=https://$DOKPLOY_DOMAIN
DOKPLOY_DOMAIN=$DOKPLOY_DOMAIN
DOKPLOY_ADMIN_EMAIL=$ADMIN_EMAIL
DOKPLOY_API_KEY=$API_KEY
DOKPLOY_ENVIRONMENT_ID=$DOKPLOY_ENVIRONMENT_ID
ROOT_DOMAIN=$ROOT_DOMAIN
EOF
}

configure_hostr_env() {
  log "Configuring hostr-stack .env"
  ./bin/hostr-stack init --domain "$ROOT_DOMAIN"
  set_env_value .env DOKPLOY_DOMAIN "$DOKPLOY_DOMAIN"
  set_env_value .env DOKPLOY_API_KEY "$API_KEY"
  set_env_value .env DOKPLOY_ENVIRONMENT_ID "$DOKPLOY_ENVIRONMENT_ID"
  set_env_value .env DOKPLOY_COMPOSE_NAME "hostr-app"
  set_env_value .env HOSTR_STACK_ROOT "$(pwd)"
  set_env_value .env APP_IMAGE "${APP_IMAGE:-hostr-nextjs-starter:latest}"
  set_env_value .env APP_PULL_POLICY "${APP_PULL_POLICY:-never}"
  set_env_value .env APP_BUILD_CONTEXT "${APP_BUILD_CONTEXT:-./apps/nextjs-starter}"
  set_env_value .env APP_DOCKERFILE "${APP_DOCKERFILE:-Dockerfile}"
}

deploy_stack() {
  if [ "$DEPLOY_STACK" != "1" ]; then
    log "Skipping stack deploy because DEPLOY_STACK=$DEPLOY_STACK"
    return
  fi

  log "Deploying hostr-stack"
  ./bin/hostr-stack validate
  ./bin/hostr-stack deploy
  if [ "$RUN_SMOKE" = "1" ]; then
    ./bin/hostr-stack smoke
  fi
}

block_raw_dokploy_port() {
  if [ "$BLOCK_DOKPLOY_PORT" != "1" ]; then
    return
  fi

  log "Blocking external raw Dokploy port 3000"
  iptables -N DOCKER-USER 2>/dev/null || true
  iptables -C DOCKER-USER -p tcp --dport 3000 -j DROP 2>/dev/null || \
    iptables -I DOCKER-USER -p tcp --dport 3000 -j DROP
}

main() {
  need_root
  install_packages

  local ip dashed_ip
  ip="$(public_ip)"
  dashed_ip="${ip//./-}"

  ROOT_DOMAIN="${ROOT_DOMAIN:-$dashed_ip.nip.io}"
  DOKPLOY_DOMAIN="${DOKPLOY_DOMAIN:-dokploy.$ROOT_DOMAIN}"
  ADMIN_EMAIL="${ADMIN_EMAIL:-admin@$ROOT_DOMAIN}"
  ADMIN_PASSWORD="${ADMIN_PASSWORD:-$(random_urlsafe 24)}"

  ensure_repo
  install_dokploy
  need docker
  wait_for_dokploy
  write_traefik_config
  ensure_traefik
  wait_for_dokploy_https
  configure_dokploy_access
  write_runtime_env
  configure_hostr_env
  deploy_stack
  block_raw_dokploy_port

  cat <<EOF

hostr-stack install complete.

Dokploy: https://$DOKPLOY_DOMAIN
App:     https://app.$ROOT_DOMAIN
Auth:    https://auth.$ROOT_DOMAIN
Admin:   https://auth-admin.$ROOT_DOMAIN
Umami:   https://umami.$ROOT_DOMAIN
Mail:    https://mail.$ROOT_DOMAIN
EOF

  if [ "$ADMIN_CREATED" = "1" ]; then
    cat <<EOF
Store these Dokploy admin credentials now. They are shown once and are not
written to disk by this installer.

Dokploy admin email:    $ADMIN_EMAIL
Dokploy admin password: $ADMIN_PASSWORD

EOF
  else
    cat <<'EOF'
Dokploy already had an admin user, so this installer did not change or print an
admin password. Use your existing Dokploy admin credentials, or run
scripts/reset-vps.sh first for a completely fresh install.

EOF
  fi

  cat <<EOF
Deployment API values without the admin password were written to:
  $HOSTR_ENV_FILE
EOF
}

main "$@"
