# Playbook IR — Log4Shell (CVE-2021-44228)

## 1. Identyfikacja

- Alert / znalezisko: ciąg `${jndi:…}` w logach aplikacji, nietypowy ruch LDAP
  (np. port 1389), pobranie `.class` po HTTP, marker RCE na dysku.
- Potwierdzenie: `./scripts/detect-log4shell.py evidence/` oraz timeline
  (`./scripts/build-timeline.py`).

## 2. Zabezpieczenie (containment)

- Odciąć egress JVM ofiary do LDAP/HTTP atakującego (firewall / izolacja VM).
- Zatrzymać podatną usługę albo przełączyć na tryb tylko do odczytu logów.
- Zachować kopię `evidence/`, pcap, logów aplikacji — nie nadpisywać.

## 3. Eliminacja

- Upgrade Log4j do ≥ 2.17.1 **albo** `-Dlog4j2.formatMsgNoLookups=true`
  (weryfikacja: `./scripts/run-mitigated.sh flag|patched`).
- Usunąć zbędne `trustURLCodebase=true` z JVM produkcyjnych.
- Przeskanować host pod kątem markerów / reverse shelli / cronów.

## 4. Odzyskanie

- Restart usługi na załatanym stacku.
- Ponowny test payloadem JNDI — oczekiwany brak RCE.
- Przywrócenie ruchu sieciowego po weryfikacji.

## 5. Lekcje

- Pin wersji Log4j w buildzie (u nas: flake).
- Monitoring egress LDAP/RMI z procesów Java.
- Logi aplikacji + pcap jako stały zestaw dowodów przy alercie RCE.
