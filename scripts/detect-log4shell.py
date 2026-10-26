#!/usr/bin/env python3
"""Skan evidence/ (i opcjonalnie pcap) pod kątem wskaźników Log4Shell."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_IOCS = ROOT / "faza2" / "detections" / "iocs.txt"

TEXT_GLOBS = ("*.log", "*.txt", "*.md", "*.out", "*.json")


def load_iocs(path: Path) -> list[str]:
    patterns: list[str] = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        patterns.append(line)
    return patterns


def scan_text_file(path: Path, patterns: list[str]) -> list[dict]:
    hits: list[dict] = []
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        return [{"file": str(path), "error": str(e)}]

    def rel(p: Path) -> str:
        try:
            return str(p.relative_to(ROOT))
        except ValueError:
            return str(p)

    for i, line in enumerate(text.splitlines(), 1):
        ll = line.lower()
        for pat in patterns:
            if pat.lower() in ll:
                hits.append(
                    {
                        "source": "text",
                        "file": rel(path),
                        "line": i,
                        "pattern": pat,
                        "snippet": line.strip()[:240],
                    }
                )
                break
    if path.name in {"pwned.txt", "pwned-attack.txt"} and path.stat().st_size > 0:
        hits.append(
            {
                "source": "artifact",
                "file": rel(path),
                "line": 0,
                "pattern": "RCE marker file",
                "snippet": text[:240],
            }
        )
    return hits


def scan_tree(evidence: Path, patterns: list[str]) -> list[dict]:
    hits: list[dict] = []
    if not evidence.is_dir():
        return hits
    for pat in TEXT_GLOBS:
        for path in sorted(evidence.rglob(pat)):
            if path.is_file():
                hits.extend(scan_text_file(path, patterns))
    return hits


def scan_pcap(pcap: Path) -> list[dict]:
    """Wyciąga z pcap wskazówki LDAP/HTTP przez tshark (jeśli dostępny)."""
    hits: list[dict] = []
    which = subprocess.run(
        ["bash", "-lc", "command -v tshark"], capture_output=True, text=True
    )
    if which.returncode != 0 or not which.stdout.strip():
        hits.append(
            {
                "source": "pcap",
                "file": str(pcap),
                "line": 0,
                "pattern": "tshark missing",
                "snippet": "pominięto analizę pcap",
            }
        )
        return hits

    # frames to/from lab ports + strings
    cmd = [
        which.stdout.strip(),
        "-r",
        str(pcap),
        "-Y",
        "tcp.port == 1389 or tcp.port == 8888 or tcp.port == 4444 or http or ldap",
        "-T",
        "fields",
        "-e",
        "frame.number",
        "-e",
        "ip.src",
        "-e",
        "ip.dst",
        "-e",
        "tcp.dstport",
        "-e",
        "http.request.uri",
        "-c",
        "50",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        hits.append(
            {
                "source": "pcap",
                "file": str(pcap),
                "line": 0,
                "pattern": "tshark error",
                "snippet": (proc.stderr or proc.stdout)[:240],
            }
        )
        return hits

    for line in proc.stdout.splitlines():
        if not line.strip():
            continue
        hits.append(
            {
                "source": "pcap",
                "file": str(pcap.name),
                "line": 0,
                "pattern": "lab-port / http / ldap frame",
                "snippet": line.strip()[:240],
            }
        )

    # byte search for jndi in stream
    strings = subprocess.run(
        [which.stdout.strip(), "-r", str(pcap), "-n", "-q", "-z", "follow,tcp,ascii,0"],
        capture_output=True,
        text=True,
    )
    blob = (strings.stdout or "") + (proc.stdout or "")
    if re.search(r"\$\{jndi:", blob, re.I):
        hits.append(
            {
                "source": "pcap",
                "file": str(pcap.name),
                "line": 0,
                "pattern": "${jndi:",
                "snippet": "wykryto ciąg JNDI w analizie tshark",
            }
        )
    return hits


def severity(hits: list[dict]) -> str:
    keys = {h.get("pattern", "") for h in hits}
    if any("RCE marker" in k or "pwned" in k.lower() for k in keys):
        return "critical"
    if any("jndi" in k.lower() for k in keys):
        return "high"
    if hits:
        return "medium"
    return "none"


def write_report(out_dir: Path, hits: list[dict], evidence: Path) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    sev = severity(hits)
    data = {
        "evidence_dir": str(evidence),
        "severity": sev,
        "hit_count": len(hits),
        "hits": hits,
    }
    json_path = out_dir / "detections.json"
    json_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    md = out_dir / "detections.md"
    lines = [
        "# Detekcja Log4Shell",
        "",
        f"- Katalog: `{evidence}`",
        f"- Liczba trafień: **{len(hits)}**",
        f"- Ocena: **{sev}**",
        "",
        "| Źródło | Plik | Linia | Wzorzec | Fragment |",
        "|--------|------|-------|---------|----------|",
    ]
    for h in hits:
        snip = h.get("snippet", "").replace("|", "\\|")
        lines.append(
            f"| {h.get('source','')} | `{h.get('file','')}` | {h.get('line','')} "
            f"| `{h.get('pattern','')}` | {snip} |"
        )
    if not hits:
        lines.append("")
        lines.append("Brak trafień — uruchom najpierw `./scripts/run-full-lab.sh`.")
    md.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return md


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "evidence",
        nargs="?",
        default=str(ROOT / "evidence"),
        help="katalog z artefaktami Fazy 1",
    )
    ap.add_argument("--iocs", default=str(DEFAULT_IOCS))
    ap.add_argument(
        "--out",
        default=str(ROOT / "evidence" / "faza2"),
        help="katalog wyjściowy raportu detekcji",
    )
    ap.add_argument("--pcap", action="append", default=[], help="opcjonalny plik pcap")
    args = ap.parse_args()

    evidence = Path(args.evidence).resolve()
    patterns = load_iocs(Path(args.iocs))
    hits = scan_tree(evidence, patterns)

    pcaps = [Path(p) for p in args.pcap]
    pcaps += sorted(evidence.glob("*.pcap"))
    for pcap in pcaps:
        if pcap.is_file():
            hits.extend(scan_pcap(pcap))

    out = Path(args.out).resolve()
    report = write_report(out, hits, evidence)
    print(f"severity={severity(hits)} hits={len(hits)}")
    print(f"report={report}")
    return 0 if hits else 2


if __name__ == "__main__":
    sys.exit(main())
