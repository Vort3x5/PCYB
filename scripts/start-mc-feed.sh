#!/usr/bin/env bash
# Ogłoszenia etapów ataku na czacie MC (RCON tellraw) — perspektywa gracza.
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
need_cmd python3

if is_running mc-feed; then
  echo "mc-feed already running pid=$(cat "$(pidfile mc-feed)")"
  exit 0
fi

echo "Waiting for RCON ${PCYB_MC_RCON_HOST}:${PCYB_MC_RCON_PORT}…"
if ! wait_port "$PCYB_MC_RCON_HOST" "$PCYB_MC_RCON_PORT" 60; then
  echo "RCON niedostępne — uruchom najpierw ./scripts/start-mc-server.sh" >&2
  exit 1
fi

# krótki test auth
if ! python3 "$ROOT/scripts/mc-rcon.py" list >/dev/null; then
  echo "RCON auth failed — sprawdź rcon.password w lab/minecraft/server.properties" >&2
  exit 1
fi

start_bg mc-feed python3 "$ROOT/scripts/mc-live-feed.py"
echo "mc-feed → czat gry (log: $(logfile mc-feed))"
echo "Test: python3 scripts/mc-rcon.py --say 'hello from lab'"
