#!/usr/bin/env bash
# Etap 2 — verify the lab shell on a teammate machine.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

check() {
  local label="$1"
  shift
  if "$@"; then
    echo "OK  $label"
  else
    echo "FAIL $label"
    fail=1
  fi
}

echo "workdir: $ROOT"
check "java (jdk11)" bash -c 'java -version 2>&1 | grep -qE "version \"11|11\."'
check "javac" bash -c 'javac -version >/dev/null 2>&1'
check "tcpdump" bash -c 'command -v tcpdump >/dev/null'
check "wireshark/tshark" bash -c 'command -v tshark >/dev/null || command -v wireshark >/dev/null'
check "netcat" bash -c 'command -v nc >/dev/null || command -v netcat >/dev/null'
check "mvn" bash -c 'command -v mvn >/dev/null'
check "LOG4J_CORE_JAR set" bash -c '[[ -n "${LOG4J_CORE_JAR:-}" && -f "$LOG4J_CORE_JAR" ]]'
check "LOG4J_API_JAR set" bash -c '[[ -n "${LOG4J_API_JAR:-}" && -f "$LOG4J_API_JAR" ]]'

if [[ -f "$ROOT/vendor/log4j-core-2.14.1.jar" ]]; then
  check "vendor/log4j-core" test -f "$ROOT/vendor/log4j-core-2.14.1.jar"
else
  echo "WARN vendor/ not populated yet — run ./scripts/fetch-vendor.sh"
fi

if [[ -f "$ROOT/vendor/marshalsec.jar" ]]; then
  check "vendor/marshalsec.jar" test -f "$ROOT/vendor/marshalsec.jar"
else
  echo "WARN marshalsec not built yet — run ./scripts/build-marshalsec.sh"
fi

if [[ "$fail" -ne 0 ]]; then
  echo
  echo "Environment incomplete. Use: nix develop"
  exit 1
fi

echo
echo "Environment OK for Etap 2."
