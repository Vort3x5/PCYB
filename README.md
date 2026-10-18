# Log4Shell (CVE-2021-44228) — Minecraft / PCYB

Zespół: **antena izotropowa 40dBi**

Izolowany lab Nix: demonstracja Log4Shell, monitoring i mitygacja.

## Start

```bash
nix develop
./scripts/fetch-vendor.sh   # jary (nie są w gicie)
./scripts/run-full-lab.sh
```

Dokumenty: uzupełnij `docs/zespol.typ`, potem `./scripts/build-docs.sh` → `docs/out/*.pdf`.

Scenariusz: [`docs/SCENARIO.md`](docs/SCENARIO.md).

Na GitHubie nie ma `vendor/`, `evidence/`, `run/`, worldów MC ani wygenerowanych PDF — to powstaje lokalnie.


## Etapy

| Etap | Zakres | Komendy |
|------|--------|---------|
| 2 | Środowisko | `nix develop`, `./scripts/verify-env.sh`, `./scripts/lab-topology.sh localhost` |
| 3 | Cel | `./scripts/start-mc-server.sh`, `./scripts/build-all.sh` |
| 4 | Atak | `./scripts/start-http-payload.sh`, `start-ldap.sh`, `start-listener.sh` |
| 5 | Monitoring | `./scripts/start-monitor.sh` |
| 6 | PoC + mitygacja | `./scripts/run-vulnerable.sh`, `./scripts/run-mitigated.sh flag\|patched` |

## Topologia

| Rola | netns | localhost |
|------|-------|-----------|
| mc-server | 10.42.0.10 | :25565 |
| mc-client | 10.42.0.20 | klient 1.16.5 |
| attacker | 10.42.0.30 | LDAP :1389, HTTP :8888, listen :4444 |

Minecraft (GUI): [`scripts/trigger-mc-chat.md`](scripts/trigger-mc-chat.md).

```bash
./scripts/stop-lab.sh
```
