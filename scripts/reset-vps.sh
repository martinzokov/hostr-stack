#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/opt/hostr-stack}"
HOSTR_ENV_FILE="${HOSTR_ENV_FILE:-/root/hostr-stack.env}"
OLD_DOKPLOY_ADMIN_FILE="${OLD_DOKPLOY_ADMIN_FILE:-/root/dokploy-admin.env}"

log() {
  printf '\n==> %s\n' "$*"
}

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run this reset script as root on the VPS." >&2
    exit 1
  fi
}

confirm() {
  if [ "${YES:-0}" = "1" ]; then
    return
  fi

  cat <<'WARNING'
This will reset the VPS Docker/Dokploy state.

It removes:
- all Docker services, containers, images, volumes, and user-defined networks
- Docker Swarm state
- /etc/dokploy
- /opt/hostr-stack by default
- /root/hostr-stack.env and the old /root/dokploy-admin.env file
- the DOCKER-USER raw Dokploy :3000 block rule

Re-run with YES=1 if you are sure.
WARNING
  exit 1
}

remove_docker_state() {
  if ! command -v docker >/dev/null 2>&1; then
    log "Docker is not installed; skipping Docker cleanup"
    return
  fi

  log "Removing Docker services"
  docker service rm $(docker service ls -q) >/dev/null 2>&1 || true

  log "Removing Docker containers"
  docker rm -f $(docker ps -aq) >/dev/null 2>&1 || true

  log "Leaving Docker Swarm"
  docker swarm leave --force >/dev/null 2>&1 || true

  log "Removing Docker volumes"
  docker volume rm $(docker volume ls -q) >/dev/null 2>&1 || true

  log "Removing Docker images"
  docker image rm -f $(docker image ls -aq) >/dev/null 2>&1 || true

  log "Removing user-defined Docker networks"
  for network in $(docker network ls --format '{{.Name}}' | grep -Ev '^(bridge|host|none)$' || true); do
    docker network rm "$network" >/dev/null 2>&1 || true
  done

  log "Pruning remaining Docker state"
  docker system prune -af --volumes >/dev/null 2>&1 || true
}

remove_files() {
  log "Removing Dokploy and hostr-stack files"
  rm -rf /etc/dokploy
  rm -rf "$INSTALL_DIR"
  rm -f "$HOSTR_ENV_FILE" "$OLD_DOKPLOY_ADMIN_FILE"
}

remove_firewall_rule() {
  if ! command -v iptables >/dev/null 2>&1; then
    return
  fi

  log "Removing hostr-stack DOCKER-USER port 3000 block rule"
  while iptables -C DOCKER-USER -p tcp --dport 3000 -j DROP >/dev/null 2>&1; do
    iptables -D DOCKER-USER -p tcp --dport 3000 -j DROP >/dev/null 2>&1 || break
  done
}

main() {
  need_root
  confirm
  remove_firewall_rule
  remove_docker_state
  remove_files

  cat <<'EOF'

VPS reset complete.

You can now run the fresh installer again, for example:

curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/install.sh | bash
EOF
}

main "$@"
