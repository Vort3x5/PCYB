# Log4Shell (CVE-2021-44228) — Minecraft / PCYB

Zespół: **antena izotropowa 40dBi** · ścieżka indywidualna (red + blue/purple)

## Faza 1 — atak

```bash
nix develop
./scripts/fetch-vendor.sh
./scripts/setup-capture.sh   # raz: lokalny tcpdump + CAP_NET_RAW (sudo)
./scripts/run-full-lab.sh
```

Minecraft (czat + live feed etapów): `scripts/trigger-mc-chat.md`.

## Faza 2 — detekcja / IR

```bash
./scripts/run-faza2.sh
# wyniki: evidence/faza2/
```

Dokumenty: `docs/zespol.typ` → `./scripts/build-docs.sh` → `docs/out/*.pdf`.

## Podział

| Osoba | Faza 1 | Faza 2 |
|-------|--------|--------|
| Piotr Świtaj | środowisko, topologia | powtarzalność labu na VM |
| Michał Kopyciński | atak Log4Shell, mitygacja | artefakty pod analizę |
| Szymon Boniuk | monitoring, dokumentacja | detekcja, timeline, raport F2 |

Szczegóły: [`docs/SCENARIO.md`](docs/SCENARIO.md).

```bash
./scripts/stop-lab.sh
```
