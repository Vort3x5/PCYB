#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

for name in mc-server victim-strace tcpdump listener ldap http; do
  stop_name "$name"
done

# orphans listening on lab ports
for port in "$PCYB_LDAP_PORT" "$PCYB_HTTP_PORT" "$PCYB_LISTEN_PORT" "$PCYB_MC_SERVER_PORT" 25575; do
  if command -v fuser >/dev/null; then
    fuser -k "${port}/tcp" 2>/dev/null || true
  fi
done

echo "lab stopped"
