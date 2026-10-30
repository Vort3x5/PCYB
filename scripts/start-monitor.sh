#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

PCAP="$PCYB_EVIDENCE/lab-$(date +%Y%m%d-%H%M%S).pcap"
FILTER="tcp port ${PCYB_LDAP_PORT} or tcp port ${PCYB_HTTP_PORT} or tcp port ${PCYB_LISTEN_PORT} or tcp port ${PCYB_MC_SERVER_PORT}"
STATUS="$PCYB_EVIDENCE/tcpdump-status.txt"
echo "$FILTER" >"$PCYB_EVIDENCE/tcpdump-filter.txt"

capture_bin() {
  if [[ -x "$PCYB_RUN/bin/tcpdump" ]]; then
    echo "$PCYB_RUN/bin/tcpdump"
  elif command -v tcpdump >/dev/null; then
    command -v tcpdump
  else
    return 1
  fi
}

write_status() {
  cat >"$STATUS" <<EOF
time: $(date -Is)
state: $1
pcap: ${2:-}
binary: ${3:-}
detail: ${4:-}
filter: $FILTER
hint: bez CAP_NET_RAW uruchom: ./scripts/setup-capture.sh
EOF
}

if is_running tcpdump; then
  echo "tcpdump already running pid=$(cat "$(pidfile tcpdump)")"
  write_status running "(existing)" "$(capture_bin 2>/dev/null || true)" "already running"
else
  BIN="$(capture_bin)" || BIN=""
  if [[ -z "$BIN" ]]; then
    write_status missing "" "" "tcpdump not in PATH (nix develop?)"
    echo "tcpdump niedostępny — $STATUS" >&2
  else
    lf="$(logfile tcpdump)"
    pf="$(pidfile tcpdump)"
    # FILTER jako osobne argumenty (nie jeden string w cudzysłowiu)
    # shellcheck disable=SC2086
    (
      cd "$ROOT"
      nohup "$BIN" -i lo -n -U -w "$PCAP" $FILTER >"$lf" 2>&1 &
      echo $! >"$pf"
    )
    sleep 0.6
    if is_running tcpdump && [[ -f "$PCAP" ]]; then
      echo "tcpdump → $PCAP (pid=$(cat "$pf") bin=$BIN)"
      write_status ok "$PCAP" "$BIN" "capturing"
    else
      rm -f "$pf"
      detail="start failed"
      [[ -f "$lf" ]] && detail="$(tr '\n' ' ' <"$lf" | head -c 400)"
      write_status failed "$PCAP" "$BIN" "$detail"
      echo "tcpdump NIE działa — brak .pcap ($STATUS)" >&2
      echo "  log: $lf" >&2
      [[ -f "$lf" ]] && tail -n 5 "$lf" >&2 || true
      echo "  naprawa: ./scripts/setup-capture.sh" >&2
      echo "  albo: sudo $BIN -i lo -n -U -w $PCAP '$FILTER'" >&2
    fi
  fi
fi

cat >"$PCYB_EVIDENCE/monitor-notes.txt" <<EOF
filter: $FILTER
status: $STATUS
listener: $(logfile listener)
ldap: $(logfile ldap)
http: $(logfile http)
victim: $PCYB_EVIDENCE/victim-log4j2.log
strace: ./scripts/run-strace-victim.sh
mc-feed: ./scripts/start-mc-feed.sh
EOF
echo "notes → $PCYB_EVIDENCE/monitor-notes.txt"

if [[ -f "$STATUS" ]] && grep -q '^state: failed\|^state: missing' "$STATUS"; then
  exit 1
fi
