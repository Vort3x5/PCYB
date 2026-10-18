#!/usr/bin/env bash
# Linkuje / pobiera jary do ./vendor
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/vendor"
mkdir -p "$VENDOR"

link_or_copy() {
  local src="$1" dest="$2"
  if [[ -f "$dest" ]]; then
    echo "exists: $dest"
    return 0
  fi
  if [[ -n "$src" && -f "$src" ]]; then
    ln -sf "$src" "$dest"
    echo "linked: $dest -> $src"
  else
    return 1
  fi
}

echo "==> Log4j 2.14.1 (vulnerable)"
if ! link_or_copy "${LOG4J_API_JAR:-}" "$VENDOR/log4j-api-2.14.1.jar"; then
  curl -fsSL -o "$VENDOR/log4j-api-2.14.1.jar" \
    "https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-api/2.14.1/log4j-api-2.14.1.jar"
  echo "downloaded: log4j-api-2.14.1.jar"
fi
if ! link_or_copy "${LOG4J_CORE_JAR:-}" "$VENDOR/log4j-core-2.14.1.jar"; then
  curl -fsSL -o "$VENDOR/log4j-core-2.14.1.jar" \
    "https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-core/2.14.1/log4j-core-2.14.1.jar"
  echo "downloaded: log4j-core-2.14.1.jar"
fi

echo "==> Minecraft dedicated server 1.16.5"
MC_SHA1="1b557e7b033b583cd9f66746b7a9ab1ec1673ced"
MC_URL="https://piston-data.mojang.com/v1/objects/${MC_SHA1}/server.jar"
MC_DEST="$VENDOR/minecraft-server-1.16.5.jar"
if ! link_or_copy "${MINECRAFT_SERVER_JAR:-}" "$MC_DEST"; then
  curl -fsSL -o "$MC_DEST" "$MC_URL"
  echo "downloaded: $(basename "$MC_DEST")"
fi
if command -v sha1sum >/dev/null; then
  got="$(sha1sum "$MC_DEST" | awk '{print $1}')"
  if [[ "$got" != "$MC_SHA1" ]]; then
    echo "ERROR: Minecraft jar sha1 mismatch (got $got, want $MC_SHA1)" >&2
    exit 1
  fi
fi

echo "==> marshalsec (build if missing)"
if [[ ! -f "$VENDOR/marshalsec-0.0.3-SNAPSHOT-all.jar" && ! -f "$VENDOR/marshalsec.jar" ]]; then
  "$ROOT/scripts/build-marshalsec.sh"
else
  echo "exists: marshalsec jar in vendor/"
fi

echo
echo "Vendor ready:"
ls -lh "$VENDOR"
echo
echo "Verify tools: ./scripts/verify-env.sh"
