#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

PCAP="$PCYB_EVIDENCE/lab-$(date +%Y%m%d-%H%M%S).pcap"
FILTER="tcp port ${PCYB_LDAP_PORT} or tcp port ${PCYB_HTTP_PORT} or tcp port ${PCYB_LISTEN_PORT} or tcp port ${PCYB_MC_SERVER_PORT}"
echo "$FILTER" >"$PCYB_EVIDENCE/tcpdump-filter.txt"

if command -v tcpdump >/dev/null && ! is_running tcpdump; then
  lf="$(logfile tcpdump)"
  pf="$(pidfile tcpdump)"
  if (cd "$ROOT" && nohup tcpdump -i lo -n -U -w "$PCAP" $FILTER >"$lf" 2>&1 & echo $! >"$pf"); then
    sleep 0.5
    if is_running tcpdump; then
      echo "tcpdump → $PCAP (pid=$(cat "$pf"))"
    else
      rm -f "$pf"
      echo "tcpdump wymaga uprawnień — ręcznie:"
      echo "  sudo tcpdump -i lo -n -w $PCAP '$FILTER'"
    fi
  fi
fi

cat >"$PCYB_EVIDENCE/monitor-notes.txt" <<EOF
filter: $FILTER
listener: $(logfile listener)
ldap: $(logfile ldap)
http: $(logfile http)
victim: $PCYB_EVIDENCE/victim-log4j2.log
strace: ./scripts/run-strace-victim.sh
EOF
echo "notes → $PCYB_EVIDENCE/monitor-notes.txt"
