#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
need_cmd python3

cat >"$PCYB_RUN/listener.py" <<'PY'
import os, socket, sys
host = os.environ.get("PCYB_LISTEN_HOST", "127.0.0.1")
port = int(os.environ.get("PCYB_LISTEN_PORT", "4444"))
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind((host, port))
s.listen(5)
print(f"listening on {host}:{port}", flush=True)
while True:
    c, addr = s.accept()
    print(f"connection from {addr}", flush=True)
    try:
        data = c.recv(4096)
        sys.stdout.buffer.write(data)
        sys.stdout.flush()
    finally:
        c.close()
PY

start_bg listener python3 "$PCYB_RUN/listener.py"
wait_port "$PCYB_LISTEN_HOST" "$PCYB_LISTEN_PORT" 10
echo "Listener on ${PCYB_LISTEN_HOST}:${PCYB_LISTEN_PORT} (log: $(logfile listener))"
