#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
need_java

API="${LOG4J_API_JAR:-$PCYB_VENDOR/log4j-api-2.14.1.jar}"
CORE="${LOG4J_CORE_JAR:-$PCYB_VENDOR/log4j-core-2.14.1.jar}"
[[ -f "$API" && -f "$CORE" ]] || {
  echo "Log4j jars missing — run ./scripts/fetch-vendor.sh" >&2
  exit 1
}
[[ -f "$PCYB_VENDOR/marshalsec.jar" ]] || ./scripts/build-marshalsec.sh

echo "==> compile vulnerable logger"
mkdir -p "$ROOT/lab/vulnerable/out"
javac -cp "$API:$CORE" -d "$ROOT/lab/vulnerable/out" \
  "$ROOT/lab/vulnerable/VulnerableLogger.java"
cp "$ROOT/lab/vulnerable/log4j2.xml" "$ROOT/lab/vulnerable/out/"

echo "==> compile exploit payload"
mkdir -p "$ROOT/lab/exploit/out"
javac -d "$ROOT/lab/exploit/out" "$ROOT/lab/exploit/Exploit.java"

# Patched jars optional (mitigation demo)
if [[ -n "${LOG4J_API_SAFE_JAR:-}" && -f "${LOG4J_API_SAFE_JAR}" ]]; then
  mkdir -p "$ROOT/lab/mitigated/out"
  javac -cp "$LOG4J_API_SAFE_JAR:${LOG4J_CORE_SAFE_JAR}" -d "$ROOT/lab/mitigated/out" \
    "$ROOT/lab/vulnerable/VulnerableLogger.java"
  cp "$ROOT/lab/vulnerable/log4j2.xml" "$ROOT/lab/mitigated/out/"
  echo "==> mitigated class compiled against Log4j 2.17.1"
fi

echo "OK build"
