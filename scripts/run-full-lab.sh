#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

cd "$ROOT"
./scripts/lab-topology.sh localhost >/dev/null
# shellcheck source=/dev/null
source "$ROOT/.lab-net/localhost.env"

./scripts/stop-lab.sh >/dev/null 2>&1 || true
rm -f "$PCYB_EVIDENCE/pwned.txt"

echo "== build =="
./scripts/fetch-vendor.sh
./scripts/build-all.sh

echo "== monitoring + infra =="
./scripts/start-monitor.sh || true
./scripts/start-http-payload.sh
./scripts/start-ldap.sh
./scripts/start-listener.sh

echo "== vulnerable trigger =="
./scripts/run-vulnerable.sh
cp -f "$PCYB_EVIDENCE/pwned.txt" "$PCYB_EVIDENCE/pwned-attack.txt"

echo "== capture =="
if [[ -f "$(logfile listener)" ]]; then
  cp "$(logfile listener)" "$PCYB_EVIDENCE/listener-capture.txt" || true
fi
cp "$(logfile ldap)" "$PCYB_EVIDENCE/ldap-server.log" 2>/dev/null || true

echo "== mitigation =="
rm -f "$PCYB_EVIDENCE/pwned.txt"
./scripts/run-mitigated.sh flag
rm -f "$PCYB_EVIDENCE/pwned.txt"
if [[ -n "${LOG4J_CORE_SAFE_JAR:-}" ]]; then
  ./scripts/run-mitigated.sh patched
fi

echo "== evidence =="
./scripts/collect-evidence.sh

echo
echo "OK — evidence/ oraz docs/SCENARIO.md"
echo "Minecraft: ./scripts/start-mc-server.sh"
./scripts/stop-lab.sh
