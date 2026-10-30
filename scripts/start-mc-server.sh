#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
need_java

JAR="${MINECRAFT_SERVER_JAR:-$PCYB_VENDOR/minecraft-server-1.16.5.jar}"
[[ -f "$JAR" ]] || {
  echo "Brak MC jar — ./scripts/fetch-vendor.sh" >&2
  exit 1
}

MC_DIR="$ROOT/lab/minecraft"
mkdir -p "$MC_DIR"
[[ -f "$MC_DIR/eula.txt" ]] || echo "eula=true" >"$MC_DIR/eula.txt"

if is_running mc-server; then
  echo "mc-server already running"
  exit 0
fi

echo "Starting Minecraft 1.16.5 in $MC_DIR…"
lf="$(logfile mc-server)"
pf="$(pidfile mc-server)"
(
  cd "$MC_DIR"
  nohup java \
    -Xms1G -Xmx1G \
    -Dcom.sun.jndi.ldap.object.trustURLCodebase=true \
    -Dcom.sun.jndi.rmi.object.trustURLCodebase=true \
    -jar "$JAR" nogui \
    >"$lf" 2>&1 &
  echo $! >"$pf"
)

# Wait for "Done" in log or port open (first boot generates world — can be slow)
echo "Waiting for port ${PCYB_MC_SERVER_PORT}…"
for i in $(seq 1 120); do
  if nc -z "$PCYB_MC_SERVER_HOST" "$PCYB_MC_SERVER_PORT" 2>/dev/null; then
    echo "mc-server up pid=$(cat "$pf") log=$lf"
    echo "Connect a 1.16.5 client (offline) to ${PCYB_MC_SERVER_HOST}:${PCYB_MC_SERVER_PORT}"
    echo "Chat payload: $(jndi_payload)"
    if [[ "${PCYB_MC_FEED:-1}" != "0" ]]; then
      "$ROOT/scripts/start-mc-feed.sh" || echo "mc-feed pominięty (RCON?)" >&2
    fi
    exit 0
  fi
  if grep -q "You need to agree to the EULA" "$lf" 2>/dev/null; then
    echo "EULA not accepted — check $MC_DIR/eula.txt" >&2
    exit 1
  fi
  sleep 2
done
echo "Timeout — see $lf" >&2
tail -n 50 "$lf" >&2 || true
exit 1
