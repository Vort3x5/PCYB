#!/usr/bin/env python3
"""Śledzi logi labu i ogłasza etapy Log4Shell na czacie Minecraft (perspektywa gracza)."""
from __future__ import annotations

import importlib.util
import os
import sys
import time
from pathlib import Path


def _load_rcon():
    path = Path(__file__).resolve().parent / "mc-rcon.py"
    spec = importlib.util.spec_from_file_location("mc_rcon", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {path}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _read_available(f) -> list[str]:
    lines = []
    while True:
        pos = f.tell()
        line = f.readline()
        if not line:
            f.seek(pos)
            break
        lines.append(line.rstrip("\n"))
    return lines


def main() -> int:
    rcon = _load_rcon()
    root = Path(os.environ.get("PCYB_ROOT", Path(__file__).resolve().parents[1]))
    run = Path(os.environ.get("PCYB_RUN", root / "run"))
    evidence = Path(os.environ.get("PCYB_EVIDENCE", root / "evidence"))

    ldap_log = run / "ldap.log"
    http_log = run / "http.log"
    listener_log = run / "listener.log"
    pwned = evidence / "pwned.txt"

    seen_pwned = pwned.is_file()
    announced: set[str] = set()
    files: dict[str, object] = {}

    def once(key: str, msg: str, color: str = "yellow") -> None:
        if key in announced:
            return
        announced.add(key)
        print(f"[feed] {msg}", flush=True)
        try:
            rcon.announce(msg, color=color)
        except OSError as e:
            print(f"[feed] RCON skip: {e}", flush=True)
        except PermissionError as e:
            print(f"[feed] RCON auth: {e}", flush=True)

    def ensure_open(name: str, path: Path):
        existing = files.get(name)
        if existing is not None:
            return existing
        if not path.is_file():
            return None
        f = path.open("r", errors="replace")
        f.seek(0, os.SEEK_END)
        files[name] = f
        return f

    once("boot", "Live feed ON — czekam na łańcuch Log4Shell…", "aqua")

    while True:
        f = ensure_open("ldap", ldap_log)
        if f:
            for line in _read_available(f):
                low = line.lower()
                if "send ldap" in low or "reference" in low or "connection from" in low:
                    once("ldap", "LDAP: ofiara odpytała JNDI Reference → Exploit", "gold")

        f = ensure_open("http", http_log)
        if f:
            for line in _read_available(f):
                if "Exploit.class" in line:
                    once("http", "HTTP: JVM pobiera złośliwy Exploit.class", "gold")

        f = ensure_open("listener", listener_log)
        if f:
            for line in _read_available(f):
                if "connection from" in line.lower() or "exploit-callback" in line:
                    once("listener", "Callback: Exploit odezwał się na listener :4444", "red")

        if pwned.is_file() and not seen_pwned:
            seen_pwned = True
            once("pwned", "RCE OK — evidence/pwned.txt zapisany", "green")
        elif not pwned.is_file() and seen_pwned:
            # kolejna runda ataku (np. po mitigacji)
            seen_pwned = False
            for k in ("ldap", "http", "listener", "pwned"):
                announced.discard(k)

        time.sleep(0.3)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(0)
