#!/usr/bin/env bash
# Faza 2 (blue): analiza oficjalnego pcapa od prowadzacej + playbook IR.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

OUT="${1:-$ROOT/evidence/faza2}"
PCAP_DEFAULT="$ROOT/res/faza2-instructor/PCYB_Faza2_26Z_25.pcap"
PCAP="${PCYB_FAZA2_PCAP:-$PCAP_DEFAULT}"

mkdir -p "$OUT"

if [[ ! -f "$PCAP" ]]; then
  echo "Brak pcapa Fazy 2: $PCAP" >&2
  echo "Wroz pakiet od prowadzacej, np.:" >&2
  echo "  unzip -o PCYB_Faza2_26Z_25.zip -d res/faza2-instructor" >&2
  exit 1
fi

if ! command -v tshark >/dev/null; then
  echo "Potrzebny tshark (wejdź: nix develop)" >&2
  exit 1
fi

echo "== analiza pcapa =="
python3 "$ROOT/scripts/analyze-faza2-pcap.py" "$PCAP" --out "$OUT"

echo "== playbook / reguly =="
cp -f "$ROOT/faza2/playbooks/ir-qakbot.md" "$OUT/ir-qakbot.md"
cp -f "$ROOT/faza2/detections/suricata-qakbot.rules" "$OUT/suricata-qakbot.rules"
cp -f "$ROOT/faza2/detections/iocs.txt" "$OUT/iocs.txt"
cp -f "$PCAP" "$OUT/PCYB_Faza2_26Z_25.pcap" 2>/dev/null || ln -sfn "$PCAP" "$OUT/PCYB_Faza2_26Z_25.pcap"

{
  echo "# Faza 2 - blue (pcap od prowadzacej)"
  echo
  echo "Wygenerowano: $(date -Is)"
  echo
  echo "## Pliki"
  echo
  find "$OUT" -maxdepth 1 -type f -o -maxdepth 1 -type l | sort | while read -r f; do
    echo "- \`$(basename "$f")\`"
  done
  echo
  echo "## Skrót detekcji"
  echo
  if [[ -f "$OUT/detections.md" ]]; then
    head -n 40 "$OUT/detections.md"
  fi
} >"$OUT/INDEX.md"

echo
echo "OK - $OUT"
ls -la "$OUT"
