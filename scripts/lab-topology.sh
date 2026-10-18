#!/usr/bin/env bash
# Topologia: plan | localhost | up | down | status
# Adresy: bridge 10.42.0.1, mc-server .10, mc-client .20, attacker .30
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$ROOT/.lab-net"
BRIDGE=pcyb-br0
PREFIX=10.42.0
HOST_IP="${PREFIX}.1"

ip_for() {
  case "$1" in
    mc-server) echo "${PREFIX}.10" ;;
    mc-client) echo "${PREFIX}.20" ;;
    attacker) echo "${PREFIX}.30" ;;
    *) echo "unknown role: $1" >&2; return 1 ;;
  esac
}

reexec_root() {
  local cmd="$1"
  if [[ "${EUID}" -eq 0 ]]; then
    return 0
  fi
  if command -v sudo >/dev/null; then
    exec sudo -- "$0" "$cmd"
  fi
  echo "Root/sudo required for netns mode." >&2
  echo "On this machine use: $0 localhost" >&2
  exit 1
}

cmd_plan() {
  cat <<EOF
PCYB lab network plan
=====================
Bridge: ${BRIDGE}  ${HOST_IP}/24

  Role         IP              Netns name
  -----------  --------------  -------------
  mc-server    $(ip_for mc-server)/24   pcyb-mc-server
  mc-client    $(ip_for mc-client)/24   pcyb-mc-client
  attacker     $(ip_for attacker)/24    pcyb-attacker

Same-host fallback (no root): ports in ${STATE}/localhost.env
  MC server      127.0.0.1:25565
  LDAP (attack)  127.0.0.1:1389
  HTTP (payload) 127.0.0.1:8888
  listener       127.0.0.1:4444

Bring up isolated netns (on a machine with sudo):
  sudo $0 up
EOF
}

cmd_localhost() {
  mkdir -p "$STATE"
  cat >"$STATE/localhost.env" <<EOF
export PCYB_TOPO=localhost
export PCYB_MC_SERVER_HOST=127.0.0.1
export PCYB_MC_SERVER_PORT=25565
export PCYB_LDAP_HOST=127.0.0.1
export PCYB_LDAP_PORT=1389
export PCYB_HTTP_HOST=127.0.0.1
export PCYB_HTTP_PORT=8888
export PCYB_LISTEN_HOST=127.0.0.1
export PCYB_LISTEN_PORT=4444
EOF
  for role in mc-server mc-client attacker; do
    cat >"$STATE/${role}.env" <<EOF
export PCYB_ROLE=${role}
export PCYB_TOPO=localhost
export PCYB_IP=$(ip_for "$role")
# shellcheck disable=SC1091
source "$STATE/localhost.env"
EOF
  done
  echo "Wrote $STATE/localhost.env and role env files."
  echo "Source before work:  source $STATE/attacker.env"
}

create_role_ns() {
  local role="$1"
  local ip="$2"
  local ns="pcyb-${role}"
  local veth_h="v-${role}-h"
  local veth_n="v-${role}-n"

  ip netns add "$ns"
  ip link add "$veth_h" type veth peer name "$veth_n"
  ip link set "$veth_n" netns "$ns"
  ip link set "$veth_h" master "$BRIDGE"
  ip link set "$veth_h" up

  ip -n "$ns" link set lo up
  ip -n "$ns" link set "$veth_n" name eth0
  ip -n "$ns" addr add "${ip}/24" dev eth0
  ip -n "$ns" link set eth0 up
  ip -n "$ns" route add default via "$HOST_IP"
  echo "up: $ns ($ip)"
}

cmd_up() {
  reexec_root up
  mkdir -p "$STATE"
  if ip link show "$BRIDGE" &>/dev/null; then
    echo "Bridge $BRIDGE already exists — run: $0 down"
    exit 1
  fi
  ip link add "$BRIDGE" type bridge
  ip addr add "${HOST_IP}/24" dev "$BRIDGE"
  ip link set "$BRIDGE" up

  for role in mc-server mc-client attacker; do
    create_role_ns "$role" "$(ip_for "$role")"
  done

  echo "netns" >"$STATE/mode"
  cmd_plan
  echo
  echo "Enter a role:  sudo ip netns exec pcyb-attacker bash"
}

cmd_down() {
  reexec_root down
  for role in mc-server mc-client attacker; do
    ip netns del "pcyb-${role}" 2>/dev/null || true
    ip link del "v-${role}-h" 2>/dev/null || true
  done
  ip link del "$BRIDGE" 2>/dev/null || true
  rm -f "$STATE/mode"
  echo "topology down"
}

cmd_status() {
  echo "=== bridge ==="
  ip link show "$BRIDGE" 2>/dev/null || echo "(no $BRIDGE)"
  echo "=== netns ==="
  ip netns list 2>/dev/null | grep pcyb || echo "(no pcyb netns)"
  echo "=== localhost fallback ==="
  if [[ -f "$STATE/localhost.env" ]]; then
    cat "$STATE/localhost.env"
  else
    echo "(not configured — run: $0 localhost)"
  fi
}

case "${1:-}" in
  plan) cmd_plan ;;
  localhost) cmd_localhost ;;
  up) cmd_up ;;
  down) cmd_down ;;
  status) cmd_status ;;
  -h|--help|help) cmd_plan; exit 0 ;;
  "") cmd_plan ;;
  *) echo "unknown: $1" >&2; exit 1 ;;
esac
