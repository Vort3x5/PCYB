#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

INDEX="$PCYB_EVIDENCE/INDEX.md"
{
  echo "# Evidence"
  echo
  echo "Generated: $(date -Is)"
  echo
  echo "## Files"
  echo
  find "$PCYB_EVIDENCE" -maxdepth 1 -type f | sort | while read -r f; do
    echo "- \`$(basename "$f")\` ($(wc -c <"$f") bytes)"
  done
  echo
  echo "## pwned.txt"
  echo
  if [[ -f "$PCYB_EVIDENCE/pwned.txt" ]]; then
    echo '```'
    cat "$PCYB_EVIDENCE/pwned.txt"
    echo '```'
  elif [[ -f "$PCYB_EVIDENCE/pwned-attack.txt" ]]; then
    echo '```'
    cat "$PCYB_EVIDENCE/pwned-attack.txt"
    echo '```'
  else
    echo "(brak)"
  fi
} >"$INDEX"

echo "Wrote $INDEX"
ls -la "$PCYB_EVIDENCE"
