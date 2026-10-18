#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
need_cmd python3
[[ -f "$ROOT/lab/exploit/out/Exploit.class" ]] || ./scripts/build-all.sh
start_bg http python3 -m http.server "$PCYB_HTTP_PORT" --bind "$PCYB_HTTP_HOST" \
  --directory "$ROOT/lab/exploit/out"
wait_port "$PCYB_HTTP_HOST" "$PCYB_HTTP_PORT" 10
echo "HTTP payload: http://${PCYB_HTTP_HOST}:${PCYB_HTTP_PORT}/Exploit.class"
