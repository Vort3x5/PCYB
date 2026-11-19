# Scenariusz PCYB

## Faza 1 (red) — Log4Shell

Łańcuch: input -> Log4j lookup -> LDAP -> HTTP `.class` -> kod w JVM, oraz mitygacja.

```bash
nix develop
./scripts/setup-capture.sh
./scripts/run-full-lab.sh
```

## Faza 2 (blue) — pcap od prowadzącej

Wejście: `PCYB_Faza2_26Z_25.pcap` (infekcja Qakbot w AD `nutmeg-station.com`).

```bash
nix develop
./scripts/run-faza2.sh
# -> evidence/faza2/
```

Ustalane m.in.: IP/hostname/user ofiary, czas startu UTC, rodzina malware, IOC C2/SMTP.
