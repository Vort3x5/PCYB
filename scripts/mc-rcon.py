#!/usr/bin/env python3
"""Minimalny klient RCON Minecraft (1.16.x) — komendy / tellraw dla labu PCYB."""
from __future__ import annotations

import argparse
import os
import socket
import struct
import sys


TYPE_RESPONSE = 0
TYPE_COMMAND = 2
TYPE_LOGIN = 3


def _pkt(req_id: int, req_type: int, payload: str) -> bytes:
    body = struct.pack("<ii", req_id, req_type) + payload.encode("utf-8") + b"\x00\x00"
    return struct.pack("<i", len(body)) + body


def _recv_pkt(sock: socket.socket) -> tuple[int, int, str]:
    hdr = sock.recv(4)
    if len(hdr) < 4:
        raise ConnectionError("RCON: short length header")
    (length,) = struct.unpack("<i", hdr)
    data = b""
    while len(data) < length:
        chunk = sock.recv(length - len(data))
        if not chunk:
            raise ConnectionError("RCON: connection closed")
        data += chunk
    req_id, req_type = struct.unpack("<ii", data[:8])
    payload = data[8:-2].decode("utf-8", errors="replace")
    return req_id, req_type, payload


def rcon_command(
    host: str,
    port: int,
    password: str,
    command: str,
    timeout: float = 5.0,
) -> str:
    with socket.create_connection((host, port), timeout=timeout) as sock:
        sock.settimeout(timeout)
        sock.sendall(_pkt(1, TYPE_LOGIN, password))
        rid, _rtype, _ = _recv_pkt(sock)
        if rid == -1:
            raise PermissionError("RCON: bad password")
        sock.sendall(_pkt(2, TYPE_COMMAND, command))
        _rid, _rtype, payload = _recv_pkt(sock)
        return payload


def tellraw_json(text: str, color: str = "yellow") -> str:
    # Prosty JSON — bez zewnętrznych zależności; escape cudzysłowów.
    safe = (
        text.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
    )
    return (
        'tellraw @a {"text":"[PCYB] ","color":"aqua","extra":[{"text":"'
        + safe
        + '","color":"'
        + color
        + '"}]}'
    )


def announce(text: str, color: str = "yellow") -> str:
    host = os.environ.get("PCYB_MC_RCON_HOST", "127.0.0.1")
    port = int(os.environ.get("PCYB_MC_RCON_PORT", "25575"))
    password = os.environ.get("PCYB_MC_RCON_PASSWORD", "pcyb-lab-rcon")
    return rcon_command(host, port, password, tellraw_json(text, color))


def main() -> int:
    ap = argparse.ArgumentParser(description="PCYB Minecraft RCON")
    ap.add_argument("command", nargs="?", help="komenda serwera (np. list)")
    ap.add_argument("--say", help="ogłoszenie na czacie (tellraw @a)")
    ap.add_argument("--color", default="yellow")
    ap.add_argument("--host", default=os.environ.get("PCYB_MC_RCON_HOST", "127.0.0.1"))
    ap.add_argument("--port", type=int, default=int(os.environ.get("PCYB_MC_RCON_PORT", "25575")))
    ap.add_argument(
        "--password",
        default=os.environ.get("PCYB_MC_RCON_PASSWORD", "pcyb-lab-rcon"),
    )
    args = ap.parse_args()

    if args.say:
        cmd = tellraw_json(args.say, args.color)
    elif args.command:
        cmd = args.command
    else:
        ap.error("podaj command albo --say")

    try:
        out = rcon_command(args.host, args.port, args.password, cmd)
    except OSError as e:
        print(f"RCON niedostępny ({args.host}:{args.port}): {e}", file=sys.stderr)
        return 1
    except PermissionError as e:
        print(str(e), file=sys.stderr)
        return 1

    if out:
        print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
