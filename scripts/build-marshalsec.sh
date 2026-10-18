#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/vendor"
SRC="$VENDOR/marshalsec-src"
mkdir -p "$VENDOR"

if ! command -v mvn >/dev/null || ! command -v java >/dev/null; then
  echo "Need java + mvn. Enter the lab shell first:" >&2
  echo "  nix develop" >&2
  exit 1
fi

if [[ ! -d "$SRC/.git" ]]; then
  rm -rf "$SRC"
  git clone --depth 1 https://github.com/mbechler/marshalsec.git "$SRC"
fi

echo "Building marshalsec (maven)…"
(
  cd "$SRC"
  mvn -q -DskipTests package
)

JAR="$(find "$SRC/target" -name 'marshalsec-*-SNAPSHOT-all.jar' -o -name 'marshalsec-*-all.jar' | head -n1 || true)"
if [[ -z "$JAR" ]]; then
  # fallback: any jar in target
  JAR="$(find "$SRC/target" -maxdepth 1 -name 'marshalsec-*.jar' ! -name '*-sources.jar' | head -n1 || true)"
fi
if [[ -z "$JAR" || ! -f "$JAR" ]]; then
  echo "ERROR: marshalsec jar not found under $SRC/target" >&2
  ls -la "$SRC/target" >&2 || true
  exit 1
fi

cp -f "$JAR" "$VENDOR/marshalsec.jar"
echo "OK: $VENDOR/marshalsec.jar"
