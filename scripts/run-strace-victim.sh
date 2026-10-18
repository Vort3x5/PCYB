#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
need_cmd strace
need_java

OUT="$PCYB_EVIDENCE/victim.strace"
echo "strace → $OUT"
# Assumes attack infra already running (http/ldap/listener).
strace -f -o "$OUT" -e trace=network,file,process \
  ./scripts/run-vulnerable.sh
echo "OK $OUT ($(wc -l <"$OUT") lines)"
