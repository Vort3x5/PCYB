#import "common.typ": *

#set document(
  title: "PCYB Pit stop",
  author: "antena izotropowa 40dBi",
)
#set page(margin: 2cm, numbering: "1")
#set text(lang: "pl", size: 11pt)
#set heading(numbering: "1.")

#align(center)[
  #text(size: 16pt, weight: "bold")[Pit stop — zgłoszenie tematyki i planu]
  #v(0.4em)
  #text(size: 12pt)[#przedmiot · semestr #semestr]
]

#meta-header(faza: "Pit stop (przed Fazą 1)")

= Nazwa wybranej techniki

*Log4Shell (CVE-2021-44228)* na przykładzie serwera *Minecraft* (1.16.5)
oraz dema Log4j 2.14.1 w izolowanym środowisku Nix.

= Krótki opis merytoryczny + MITRE ATT&CK

Log4Shell to krytyczna podatność w Apache Log4j 2 (lookup JNDI w treści logów).
Atakujący dostarcza ciąg `${jndi:ldap://…}` (np. czat lub nick w Minecraft).
JVM ofiary wykonuje lookup, łączy się z kontrolowanym LDAP i może załadować
zdalną klasę, co w warunkach CVE-2021-44228 prowadziło do RCE (CVSS 10.0).

W naszym labie payload jest ograniczony: zapis znacznika w `evidence/pwned.txt`
oraz baner na listenerze; środowisko lokalne, bez ataków na zasoby zewnętrzne.

#table(
  columns: (1.1fr, 1.4fr, 1.6fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Tactic*], [*Technique*], [*Mapowanie w labie*],
  [Initial Access], [T1190 Exploit Public-Facing Application], [Logowana treść (czat MC / logger)],
  [Execution], [T1059 / załadowanie klasy Java], [Klasa `Exploit`],
  [Command and Control], [T1071 Application Layer Protocol], [LDAP + HTTP codebase],
  [Discovery (lab)], [—], [Znacznik pliku i baner na listenerze],
)

= Plan realizacji zadania

#table(
  columns: (0.7fr, 1.6fr, 1.4fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Etap*], [*Zakres*], [*Termin orientacyjny*],
  [2], [Nix flake (JDK11, Log4j, narzędzia), topologia], [do ~27.10],
  [3], [Minecraft 1.16.5 + potwierdzenie lookupu JNDI], [tydzień 2],
  [4], [marshalsec LDAP, HTTP payload, listener], [do ~3.11],
  [5], [tcpdump/wireshark, strace/auditd, logi log4j2], [równolegle z 4],
  [6], [Pełny przebieg + mitygacja + dowody], [do ~10.11],
  [7], [Raport Fazy 1], [do 17.11.2026],
)

Repozytorium: `flake.nix`, `scripts/run-full-lab.sh`, `docs/SCENARIO.md`.

#podzial-section()

= Status

Środowisko Nix i automatyczny PoC Log4Shell są uruchamiane lokalnie.
Serwer Minecraft 1.16.5 startuje skryptem `scripts/start-mc-server.sh`;
trigger z klienta GUI zostanie pokazany na zrzutach w raporcie Fazy 1.
