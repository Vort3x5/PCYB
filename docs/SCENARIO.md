# Scenariusz lab — Log4Shell (CVE-2021-44228)

## Faza 1 (red)

Łańcuch: input → Log4j lookup → LDAP → HTTP `.class` → kod w JVM,
oraz mitygacja. PoC: `VulnerableLogger` + Log4j 2.14.1; kontekst: Minecraft 1.16.5.

```bash
nix develop -c ./scripts/run-full-lab.sh
```

## Faza 2 (blue / purple)

Na artefaktach z `evidence/`: detekcja IOC, timeline, playbook IR.

```bash
./scripts/run-faza2.sh
# → evidence/faza2/
```

## Role

| Rola | Adres | Składniki |
|------|-------|-----------|
| victim / mc-server | 10.42.0.10 / localhost | JDK11, Log4j 2.14.1 / MC 1.16.5 |
| mc-client | 10.42.0.20 | klient MC 1.16.5 |
| attacker | 10.42.0.30 / localhost | marshalsec :1389, HTTP :8888, listener :4444 |
