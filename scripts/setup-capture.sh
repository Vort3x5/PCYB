#!/usr/bin/env bash
# Jednorazowa konfiguracja: lokalna kopia tcpdump z CAP_NET_RAW (nix store jest RO).
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

need_cmd tcpdump
mkdir -p "$PCYB_RUN/bin"

DEST="$PCYB_RUN/bin/tcpdump"
SRC="$(command -v tcpdump)"
cp -f "$SRC" "$DEST"
chmod 755 "$DEST"

if getcap "$DEST" 2>/dev/null | grep -q 'cap_net_raw'; then
  echo "OK — $DEST już ma CAP_NET_RAW"
else
  if ! command -v setcap >/dev/null; then
    echo "Brak setcap (pakiet libcap / iproute2)." >&2
    exit 1
  fi
  echo "Ustawiam CAP_NET_RAW na $DEST (sudo)…"
  if ! sudo setcap cap_net_raw,cap_net_admin=eip "$DEST"; then
    echo "setcap nieudane. Ręcznie:" >&2
    echo "  sudo setcap cap_net_raw,cap_net_admin=eip $DEST" >&2
    exit 1
  fi
fi

# Szybki smoke-test (1 pakiet albo timeout)
lf="$PCYB_RUN/capture-smoke.log"
if timeout 2 "$DEST" -i lo -n -c 1 -w /dev/null >/dev/null 2>"$lf"; then
  echo "capture OK — używaj ./scripts/start-monitor.sh"
  exit 0
fi

# timeout bez pakietu też kończy się 124 — to nadal znaczy, że socket się otworzył
if grep -qi 'permission\|CAP_NET_RAW\|Operation not permitted' "$lf"; then
  echo "Nadal brak uprawnień — sprawdź getcap $DEST" >&2
  cat "$lf" >&2
  exit 1
fi

echo "capture OK (brak ruchu na lo w 2s — to normalne)"
echo "  binary: $DEST"
getcap "$DEST" || true
