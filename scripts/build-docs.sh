#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
command -v typst >/dev/null || { echo "Brak typst — nix develop" >&2; exit 1; }
mkdir -p "$ROOT/docs/out"
cd "$ROOT/docs"
typst compile pit-stop.typ out/pit-stop.pdf
typst compile raport-faza1.typ out/raport-faza1.pdf
ls -lh out/*.pdf
