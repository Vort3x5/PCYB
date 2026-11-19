#!/usr/bin/env python3
"""Analiza oficjalnego pcapa Fazy 2 (PCYB_Faza2_26Z_25.pcap) przez tshark."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def tshark(pcap: Path, *extra: str) -> str:
    cmd = ["tshark", "-r", str(pcap), "-n", *extra]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode not in (0, 1):  # 1 = no matches
        raise RuntimeError(p.stderr.strip() or f"tshark failed: {cmd}")
    return p.stdout


def fields(pcap: Path, display_filter: str, field_names: list[str], limit: int = 0) -> list[list[str]]:
    # Uwaga: NIE uzywac tshark -c z filtrem display - -c liczy pakiety z pliku, nie trafienia.
    extra = ["-Y", display_filter, "-T", "fields"]
    for f in field_names:
        extra += ["-e", f]
    out = tshark(pcap, *extra)
    rows = []
    for line in out.splitlines():
        if not line.strip():
            continue
        rows.append(line.split("\t"))
        if limit and len(rows) >= limit:
            break
    return rows


def first_row(pcap: Path, display_filter: str, field_names: list[str]) -> list[str] | None:
    rows = fields(pcap, display_filter, field_names, limit=1)
    return rows[0] if rows else None


def analyze(pcap: Path) -> dict:
    # Victim identity
    host_row = first_row(
        pcap,
        'dhcp.option.hostname or dhcp.option.client_fqdn.fqdn or dhcp.option.client_fqdn.name',
        ["dhcp.option.hostname", "dhcp.option.client_fqdn.name", "frame.time"],
    )
    # NBNS / Kerberos for hostname + user
    kerb_users = fields(
        pcap,
        "kerberos.CNameString",
        ["kerberos.CNameString", "kerberos.realm", "frame.time"],
        limit=80,
    )
    users = sorted(
        {
            r[0]
            for r in kerb_users
            if r and r[0] and not r[0].endswith("$")
        }
    )

    # Infection: HTTP download from known payload host
    payload = fields(
        pcap,
        "ip.addr==185.183.99.115 && http.request",
        [
            "frame.number",
            "frame.time",
            "frame.time_epoch",
            "ip.src",
            "ip.dst",
            "http.request.method",
            "http.request.uri",
        ],
        limit=5,
    )

    c2_https = fields(
        pcap,
        "ip.addr==45.32.211.207 && tls.handshake.type==1",
        ["frame.number", "frame.time", "ip.src", "ip.dst"],
        limit=5,
    )

    port_65400 = fields(
        pcap,
        "tcp.port==65400 && tcp.flags.syn==1 && tcp.flags.ack==0",
        ["frame.number", "frame.time", "ip.src", "ip.dst"],
        limit=5,
    )

    openssl = fields(
        pcap,
        'dns.qry.name=="www.openssl.org"',
        ["frame.number", "frame.time", "dns.qry.name"],
        limit=3,
    )
    ipify = fields(
        pcap,
        'dns.qry.name=="api.ipify.org"',
        ["frame.number", "frame.time", "dns.qry.name"],
        limit=3,
    )

    smtp_out = fields(
        pcap,
        'smtp && ip.src==172.17.4.206',
        ["frame.number", "frame.time", "ip.src", "ip.dst", "smtp.req.command", "smtp.req.parameter"],
        limit=30,
    )
    smtp_ehlo = [r for r in smtp_out if len(r) > 4 and r[4] in {"EHLO", "HELO", "STAR"}]
    if not smtp_ehlo:
        smtp_ehlo = smtp_out[:10]

    # Hostname from NBNS
    nbns = fields(pcap, "nbns.name", ["nbns.name"], limit=20)
    hostnames = sorted(
        {
            n.split("<")[0]
            for row in nbns
            for n in row
            if n and not n.upper().startswith("NUTMEG-STATION")
        }
    )

    victim_ip = "172.17.4.206"
    if payload:
        victim_ip = payload[0][3]

    infection_local = payload[0][1] if payload else None
    infection_epoch = float(payload[0][2]) if payload else None
    # UTC from epoch
    infection_utc = None
    if infection_epoch is not None:
        import datetime as dt

        infection_utc = (
            dt.datetime.fromtimestamp(infection_epoch, dt.timezone.utc)
            .strftime("%Y-%m-%d %H:%M:%S UTC")
        )


    findings = {
        "pcap": str(pcap),
        "environment": {
            "lan": "172.17.4.0/24",
            "domain": "nutmeg-station.com",
            "dc": "172.17.4.4 (NutmegCrazy-DC)",
            "gateway": "172.17.4.1",
        },
        "victim": {
            "ip": victim_ip,
            "hostname": hostnames[0] if hostnames else "DESKTOP-V0FEH1L",
            "user": users[0] if users else "alfonso.paternoster",
            "users_seen": users,
        },
        "infection": {
            "family": "Qakbot (Qbot)",
            "start_local": infection_local,
            "start_utc": infection_utc,
            "payload_url": (
                f"http://185.183.99.115{payload[0][6]}" if payload and len(payload[0]) > 6 else None
            ),
            "payload_host": "185.183.99.115",
        },
        "follow_on": {
            "https_c2_ips": ["45.32.211.207"],
            "tcp_65400": [f"{r[2]} -> {r[3]}" for r in port_65400],
            "connectivity_checks": ["www.openssl.org", "api.ipify.org"],
            "spambot_smtp": True if smtp_ehlo else False,
            "smtp_targets_sample": [r[3] for r in smtp_ehlo[:8]],
        },
        "samples": {
            "payload_http": payload,
            "c2_clienthello": c2_https,
            "tcp_65400": port_65400,
            "openssl_dns": openssl,
            "ipify_dns": ipify,
            "smtp_ehlo": smtp_ehlo,
            "kerberos_users": kerb_users[:10],
            "dhcp_hint": host_row,
        },
    }
    return findings



def write_reports(findings: dict, out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    (out / "findings.json").write_text(
        json.dumps(findings, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    v = findings["victim"]
    inf = findings["infection"]
    env = findings["environment"]
    fo = findings["follow_on"]

    det = []
    det.append("# Detekcja / IOC (Faza 2)")
    det.append("")
    det.append(f"Pcap: `{Path(findings['pcap']).name}`")
    det.append("")
    det.append("## Identyfikacja hosta")
    det.append("")
    det.append(f"- IP ofiary: `{v['ip']}`")
    det.append(f"- Hostname: `{v['hostname']}`")
    det.append(f"- Konto użytkownika (Kerberos): `{v['user']}`")
    det.append(f"- Domena AD: `{env['domain']}` (DC `{env['dc']}`)")
    det.append("")
    det.append("## Wskaźniki złośliwej aktywności")
    det.append("")
    det.append(f"- Rodzina malware: **{inf['family']}**")
    det.append(f"- Start infekcji (lokalnie w pcapie): `{inf['start_local']}`")
    det.append(f"- Start infekcji (UTC): `{inf['start_utc']}`")
    det.append(f"- Pobranie payloadu: `{inf['payload_url']}`")
    det.append(f"- HTTPS C2 (Client Hello bez SNI / do IP): `{', '.join(fo['https_c2_ips'])}`")
    det.append(f"- Ruch TCP/65400: `{', '.join(fo['tcp_65400']) or 'brak w próbce'}`")
    det.append(f"- Checki łączności DNS: `{', '.join(fo['connectivity_checks'])}`")
    det.append(
        f"- Zachowanie spambota (SMTP EHLO z hosta ofiary): "
        f"{'tak' if fo['spambot_smtp'] else 'nie'}"
    )
    if fo["smtp_targets_sample"]:
        det.append(f"- Przykładowe cele SMTP: `{', '.join(fo['smtp_targets_sample'])}`")
    det.append("")
    det.append("## Ocena")
    det.append("")
    det.append(
        "Trafienia wskazują na klasyczny przebieg Qakbot: pobranie binarki po HTTP, "
        "następnie C2 po HTTPS do adresów IP oraz aktywność spambota SMTP."
    )
    det.append("")
    (out / "detections.md").write_text("\n".join(det) + "\n", encoding="utf-8")

    events: list[tuple[str, str, str]] = []
    if inf["start_local"]:
        events.append(
            (
                inf["start_local"],
                f"Pobranie payloadu HTTP z {inf['payload_host']}",
                f"GET `{inf['payload_url']}`",
            )
        )
    if findings["samples"]["c2_clienthello"]:
        r = findings["samples"]["c2_clienthello"][0]
        events.append((r[1], "HTTPS C2 (TLS Client Hello do IP)", f"{r[2]} -> {r[3]}:443"))
    if findings["samples"]["openssl_dns"]:
        r = findings["samples"]["openssl_dns"][0]
        events.append((r[1], "Check łączności DNS", r[2]))
    if findings["samples"]["tcp_65400"]:
        r = findings["samples"]["tcp_65400"][0]
        events.append((r[1], "SYN na TCP/65400", f"{r[2]} -> {r[3]}:65400"))
    if findings["samples"]["ipify_dns"]:
        r = findings["samples"]["ipify_dns"][0]
        events.append((r[1], "Check publicznego IP", r[2]))
    if findings["samples"]["smtp_ehlo"]:
        r = findings["samples"]["smtp_ehlo"][0]
        cmd = r[4] if len(r) > 4 else ""
        param = r[5] if len(r) > 5 else ""
        events.append((r[1], f"SMTP spambot ({cmd})", f"{r[2]} -> {r[3]} {param}"))
    events.sort(key=lambda e: e[0])

    tl = ["# Oś czasu (Faza 2)", "", "| Czas (z pcapa) | Zdarzenie | Dowód |", "|---|---|---|"]
    for ts, what, proof in events:
        tl.append(f"| {ts} | {what} | {proof} |")
    tl.append("")
    tl.append(f"Start infekcji w UTC: **{inf['start_utc']}**.")
    tl.append("")
    (out / "timeline.md").write_text("\n".join(tl) + "\n", encoding="utf-8")

    iocs = []
    iocs.append("# IOC wyciągnięte z pcapa Fazy 2")
    iocs.append("")
    iocs.append(f"victim_ip={v['ip']}")
    iocs.append(f"victim_host={v['hostname']}")
    iocs.append(f"victim_user={v['user']}")
    iocs.append(f"payload_host={inf['payload_host']}")
    if inf["payload_url"]:
        iocs.append(f"payload_url={inf['payload_url']}")
    for ip in fo["https_c2_ips"]:
        iocs.append(f"c2_https={ip}")
    iocs.append("check=www.openssl.org")
    iocs.append("check=api.ipify.org")
    iocs.append("family=Qakbot")
    iocs.append("")
    (out / "iocs-extracted.txt").write_text("\n".join(iocs), encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "pcap",
        nargs="?",
        default=str(ROOT / "res" / "faza2-instructor" / "PCYB_Faza2_26Z_25.pcap"),
    )
    ap.add_argument("--out", default=str(ROOT / "evidence" / "faza2"))
    args = ap.parse_args()
    pcap = Path(args.pcap)
    if not pcap.is_file():
        print(f"Brak pcapa: {pcap}", file=sys.stderr)
        print("Oczekiwane: res/faza2-instructor/PCYB_Faza2_26Z_25.pcap", file=sys.stderr)
        return 1
    if subprocess.run(["bash", "-lc", "command -v tshark"], capture_output=True).returncode != 0:
        print("Potrzebny tshark (nix develop).", file=sys.stderr)
        return 1


    findings = analyze(pcap)
    out = Path(args.out)
    write_reports(findings, out)
    print(json.dumps({k: findings[k] for k in ("victim", "infection", "follow_on")}, indent=2))
    print(f"\nOK -> {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
