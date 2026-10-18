#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
need_java

MODE="${1:-flag}" # flag | patched
API="${LOG4J_API_JAR:-$PCYB_VENDOR/log4j-api-2.14.1.jar}"
CORE="${LOG4J_CORE_JAR:-$PCYB_VENDOR/log4j-core-2.14.1.jar}"
PAYLOAD="$(jndi_payload)"

[[ -f "$ROOT/lab/vulnerable/out/VulnerableLogger.class" ]] || ./scripts/build-all.sh
rm -f "$PCYB_EVIDENCE/pwned.txt"

cd "$ROOT"
case "$MODE" in
  flag)
    echo "Mitigation: -Dlog4j2.formatMsgNoLookups=true (still Log4j 2.14.1)"
    java \
      -Dlog4j2.formatMsgNoLookups=true \
      -Dcom.sun.jndi.ldap.object.trustURLCodebase=true \
      -Dlog4j2.configurationFile="$ROOT/lab/vulnerable/out/log4j2.xml" \
      -cp "$ROOT/lab/vulnerable/out:$API:$CORE" \
      VulnerableLogger "$PAYLOAD" | tee "$PCYB_EVIDENCE/mitigated-flag-stdout.txt"
    ;;
  patched)
    SAFE_API="${LOG4J_API_SAFE_JAR:?set by nix develop}"
    SAFE_CORE="${LOG4J_CORE_SAFE_JAR:?set by nix develop}"
    echo "Mitigation: Log4j 2.17.1 jars"
    mkdir -p "$ROOT/lab/mitigated/out"
    javac -cp "$SAFE_API:$SAFE_CORE" -d "$ROOT/lab/mitigated/out" \
      "$ROOT/lab/vulnerable/VulnerableLogger.java"
    cp "$ROOT/lab/vulnerable/log4j2.xml" "$ROOT/lab/mitigated/out/"
    java \
      -Dcom.sun.jndi.ldap.object.trustURLCodebase=true \
      -Dlog4j2.configurationFile="$ROOT/lab/mitigated/out/log4j2.xml" \
      -cp "$ROOT/lab/mitigated/out:$SAFE_API:$SAFE_CORE" \
      VulnerableLogger "$PAYLOAD" | tee "$PCYB_EVIDENCE/mitigated-patched-stdout.txt"
    ;;
  *)
    echo "usage: $0 [flag|patched]" >&2
    exit 2
    ;;
esac

if [[ -f "$PCYB_EVIDENCE/pwned.txt" ]]; then
  echo "FAIL — mitigation did not hold; pwned.txt exists" >&2
  cat "$PCYB_EVIDENCE/pwned.txt" >&2
  exit 1
fi

echo "OK — no RCE marker (mitigation held)"
