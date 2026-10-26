#import "common.typ": *

#set document(
  title: "PCYB Faza 2 — blue/purple Log4Shell",
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
  #text(size: 16pt, weight: "bold")[Raport — Faza 2]
  #v(0.3em)
  #text(size: 13pt)[Analiza defensywna i purple teaming — Log4Shell]
  #v(0.3em)
  #text(size: 11pt)[#przedmiot · semestr #semestr]
]

#meta-header(faza: "Faza 2")

= Treść zadania

Ścieżka indywidualna: po Fazie 1 (PoC Log4Shell) zespół realizuje część
defensywną / purple na własnych artefaktach labu — detekcja wskaźników,
oś czasu incydentu, playbook IR oraz weryfikacja mitygacji.

= Założenia

- Materiał wejściowy: katalog `evidence/` z przebiegu Fazy 1 (logi, znacznik RCE,
  ewentualny pcap).
- Cel: pokazać, że ten sam atak da się *wykryć* i *opanować* bez odtwarzania
  destrukcji poza labem.
- Narzędzia: skrypty Python w repozytorium, reguły Suricata, playbook IR.

= Przebieg analizy

== Zebranie materiału

```bash
nix develop
./scripts/run-full-lab.sh          # Faza 1 → evidence/
./scripts/run-faza2.sh             # detekcja + timeline → evidence/faza2/
```

== Detekcja

`scripts/detect-log4shell.py` skanuje logi i artefakty pod kątem wzorców z
`faza2/detections/iocs.txt` (m.in. `${jndi:ldap://`, pobranie `.class`, marker RCE).
Opcjonalnie analizuje pcap przez `tshark`. Wynik: `evidence/faza2/detections.md`.

Reguły sieciowe: `faza2/detections/suricata-log4shell.rules`.

== Oś czasu

`scripts/build-timeline.py` układa zdarzenia ze znacznikami czasu z logów
(`evidence/faza2/timeline.md`) — kolejność: lookup JNDI → LDAP → skutek (marker).

== Reagowanie

Playbook: `faza2/playbooks/ir-log4shell.md`
(kroki: identyfikacja → containment → eradication → recovery).

Mitygacja zweryfikowana już w Fazie 1:

```bash
./scripts/run-mitigated.sh flag
./scripts/run-mitigated.sh patched
```

= Wyniki

Po uruchomieniu `./scripts/run-faza2.sh` w `evidence/faza2/` pojawiają się m.in.:

- `detections.json` / `detections.md` — lista trafień IOC,
- `timeline.md` — chronologia,
- `ir-log4shell.md` — kopia playbooka,
- `INDEX.md` — spis artefaktów Fazy 2.

Oczekiwana ocena detekcji przy kompletnym evidence Fazy 1: *high* / *critical*
(obecność JNDI w logach i/lub pliku `pwned-attack.txt`).

// Zrzuty: docs/figures/faza2-detections.png itd.
// #figure(image("figures/faza2-detections.png", width: 90%), caption: [Wynik detekcji])

= Wnioski

Ten sam przebieg Log4Shell, który w Fazie 1 służył jako PoC ofensywny, dostarcza
czytelnych IOC po stronie blue: ciąg JNDI w logach aplikacji, ruch na port LDAP
oraz artefakt wykonania. Purple teaming polega tu na domknięciu pętli —
atak, obserwacja, detekcja, playbook i potwierdzenie, że patch / flaga Log4j
przerywa łańcuch.

= Podział odpowiedzialności (Faza 2)

#table(
  columns: (1.2fr, 2fr),
  stroke: 0.5pt,
  inset: 8pt,
  [*Osoba*], [*Zakres*],
  [Piotr Świtaj], [Utrzymanie środowiska labu, powtarzalność przebiegu F1→F2 na VM zespołu.],
  [Michał Kopyciński], [Dostarczenie / odtworzenie artefaktów ataku pod analizę, weryfikacja mitygacji.],
  [Szymon Boniuk], [Detekcja, timeline, playbook IR, raport Fazy 2.],
)

= Załączniki

#table(
  columns: (1.2fr, 2fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Ścieżka*], [*Opis*],
  [`faza2/detections/`], [IOC + reguły Suricata],
  [`faza2/playbooks/`], [Playbook IR],
  [`scripts/detect-log4shell.py`], [Skaner evidence/pcap],
  [`scripts/build-timeline.py`], [Oś czasu],
  [`scripts/run-faza2.sh`], [Orkiestracja Fazy 2],
  [`evidence/faza2/`], [Wyniki lokalne (po uruchomieniu)],
)
