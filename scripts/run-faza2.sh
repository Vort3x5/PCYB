#!/usr/bin/env bash
# Faza 2 (blue/purple): detekcja + timeline + kopie playbooka na podstawie evidence Fazy 1.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

EVIDENCE="${1:-$ROOT/evidence}"
OUT="$EVIDENCE/faza2"
mkdir -p "$OUT"

if [[ ! -d "$EVIDENCE" ]] || [[ -z "$(ls -A "$EVIDENCE" 2>/dev/null | grep -v faza2 || true)" ]]; then
  echo "Brak artefaktów w $EVIDENCE — najpierw: ./scripts/run-full-lab.sh" >&2
  exit 1
fi

echo "== detekcja =="
python3 "$ROOT/scripts/detect-log4shell.py" "$EVIDENCE" --out "$OUT" || true

echo "== timeline =="
python3 "$ROOT/scripts/build-timeline.py" "$EVIDENCE" --out "$OUT"

echo "== playbook =="
cp -f "$ROOT/faza2/playbooks/ir-log4shell.md" "$OUT/ir-log4shell.md"
cp -f "$ROOT/faza2/detections/suricata-log4shell.rules" "$OUT/suricata-log4shell.rules"
cp -f "$ROOT/faza2/detections/iocs.txt" "$OUT/iocs.txt"

# Krótki indeks Fazy 2
{
  echo "# Faza 2 — blue/purple (Log4Shell)"
  echo
  echo "Wygenerowano: $(date -Is)"
  echo
  echo "## Pliki"
  echo
  find "$OUT" -maxdepth 1 -type f | sort | while read -r f; do
    echo "- \`$(basename "$f")\`"
  done
  echo
  echo "## Playbook"
  echo
  echo "Patrz \`ir-log4shell.md\` (containment → eradication → recovery)."
  echo
  if [[ -f "$OUT/detections.md" ]]; then
    echo "## Detekcja (skrót)"
    echo
    head -n 20 "$OUT/detections.md"
  fi
} >"$OUT/INDEX.md"

echo
echo "OK — $OUT"
ls -la "$OUT"
