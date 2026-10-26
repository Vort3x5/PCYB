#!/usr/bin/env python3
"""Buduje chronologię zdarzeń z evidence/ (Faza 2 — analiza powłamaniowa)."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# 2026-10-18 21:55:40.232  or  time=2026-10-18T21:55:40
TS_RE = re.compile(
    r"(?P<ts>\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z)?)"
)


def events_from_file(path: Path) -> list[dict]:
    out: list[dict] = []
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return out
    try:
        rel = str(path.relative_to(ROOT))
    except ValueError:
        rel = str(path)
    for i, line in enumerate(text.splitlines(), 1):
        m = TS_RE.search(line)
        if not m:
            continue
        kind = "log"
        low = line.lower()
        if "jndi" in low:
            kind = "jndi-lookup"
        elif "ldap" in low or "listening on" in low:
            kind = "ldap"
        elif "pwned" in low or "exploit" in low:
            kind = "exploit"
        elif "mitigation" in low or "formatmsg" in low:
            kind = "mitigation"
        out.append(
            {
                "ts": m.group("ts").replace("T", " ").rstrip("Z"),
                "kind": kind,
                "file": rel,
                "line": i,
                "text": line.strip()[:200],
            }
        )
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("evidence", nargs="?", default=str(ROOT / "evidence"))
    ap.add_argument("--out", default=str(ROOT / "evidence" / "faza2"))
    args = ap.parse_args()

    evidence = Path(args.evidence).resolve()
    events: list[dict] = []
    if evidence.is_dir():
        for path in sorted(evidence.rglob("*")):
            if path.is_file() and path.suffix.lower() in {
                ".log",
                ".txt",
                ".md",
            }:
                if "faza2" in path.parts:
                    continue
                events.extend(events_from_file(path))

    events.sort(key=lambda e: e["ts"])

    out_dir = Path(args.out).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "timeline.json").write_text(
        json.dumps(events, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    lines = [
        "# Timeline incydentu (Log4Shell)",
        "",
        f"Zdarzeń: **{len(events)}**",
        "",
        "| Czas | Typ | Plik | Opis |",
        "|------|-----|------|------|",
    ]
    for e in events:
        t = e["text"].replace("|", "\\|")
        lines.append(f"| {e['ts']} | {e['kind']} | `{e['file']}` | {t} |")
    if not events:
        lines += ["", "_Brak zdarzeń ze znacznikami czasu — uruchom lab i zbierz evidence._"]

    md = out_dir / "timeline.md"
    md.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"events={len(events)} report={md}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
