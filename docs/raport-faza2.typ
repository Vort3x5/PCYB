#import "common.typ": *

#set document(
  title: "PCYB Faza 2: analiza pcapa / antena izotropowa 40dBi",
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
#show figure: set block(breakable: true)

#align(center)[
  #text(size: 16pt, weight: "bold")[Raport Faza 2]
  #v(0.3em)
  #text(size: 13pt)[Analiza powłamaniowa ruchu sieciowego (pcap od prowadzącej)]
  #v(0.3em)
  #text(size: 11pt)[#przedmiot · semestr #semestr]
]

#meta-header(faza: "Faza 2")

= Treść zadania

Zadanie Fazy 2
to analiza capture: identyfikacja hosta i użytkownika, wskaźniki kompromitacji,
chronologia, playbook IR oraz wnioski w raporcie.

= Opis merytoryczny i klasyfikacja MITRE ATT&CK

== Charakter ruchu

Pcap obejmuje stację Windows w domenie Active Directory `nutmeg-station.com`
(LAN `172.17.4.0/24`, DC `172.17.4.4`). Obok typowej aktywności domenowej
(Kerberos, LDAP, SMB) widać sekwencję wskazującą na infekcję Qakbot (Qbot):
pobranie payloadu po HTTP, C2 po HTTPS do adresów IP, checki łączności oraz
wychodzący SMTP (spambot).

== Mapowanie ATT&CK

#table(
  columns: (1fr, 1.3fr, 1.8fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Tactic*], [*Technique*], [*Obserwacja w pcapie*],
  [Initial Access], [T1566], [Kontekst wektora (złośliwy mail); w pcapie skutek na hoście],
  [Command and Control], [T1071.001], [HTTPS do IP (`45.32.211.207:443`), bez typowego SNI],
  [Command and Control], [T1571], [Ruch TCP/65400 do `54.36.108.120`],
  [Discovery], [T1016], [DNS/HTTPS do `api.ipify.org`],
  [Impact], [T1496], [Wychodzący SMTP (EHLO) ze stacji końcowej],
)

= Środowisko analizy

Analizę robiliśmy lokalnie (ten sam sprzęt co w Fazie 1), w `nix develop`,
głównie przez `tshark` oraz skrypt `scripts/analyze-faza2-pcap.py`.

#table(
  columns: (1.2fr, 2fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Element*], [*Wartość*],
  [Materiał], [`PCYB_Faza2_26Z_25.pcap` (~18 MB, 27504 pakiety)],
  [Czas capture], [2021-05-05 ~00:16 - 01:47 (czas lokalny pcapa)],
  [Narzędzia], [tshark, `scripts/analyze-faza2-pcap.py`, `scripts/run-faza2.sh`],
  [System], [#sprzet.os / #sprzet.kernel],
  [*CPU*], [#sprzet.cpu],
  [*RAM*], [#sprzet.ram],
)

= Przebieg analizy

== Uruchomienie pipeline

```bash
nix develop
unzip -o PCYB_Faza2_26Z_25.zip -d res/faza2-instructor
./scripts/run-faza2.sh
# wyniki: evidence/faza2/
```

Najpierw tożsamość hosta w AD (DHCP/NBNS/Kerberos), potem pierwszy podejrzany
egress HTTP, a na tej podstawie chronologia C2 i SMTP.

== Identyfikacja ofiary

Z DHCP wynika przydział `172.17.4.206` dla `DESKTOP-V0FEH1L.nutmeg-station.com`
(serwer `172.17.4.4`, router `172.17.4.1`). NBNS potwierdza nazwę hosta i domenę
`NUTMEG-STATION`.

#figure(
  image("figures/f2_env.png", width: 92%),
  caption: [DHCP i NBNS: IP ofiary, FQDN hosta, DC i nazwa domeny.],
)

Kerberos pokazuje konto użytkownika `alfonso.paternoster` oraz konto maszyny
`DESKTOP-V0FEH1L$` w realmie `NUTMEG-STATION.COM`.

#figure(
  image("figures/f2_user.png", width: 85%),
  caption: [Kerberos: użytkownik `alfonso.paternoster` oraz konto maszyny hosta.],
)

== Początek infekcji

Szukamy pierwszego nietypowego pobrania z Internetu. Trafienie: HTTP GET do
`185.183.99.115` po `/44313,6048108796.dat`, odpowiedź `200` /
`application/octet-stream` (~974 KB). Czas lokalny pcapa: `2021-05-05 00:16:52`,
czyli `2021-05-04 22:16:52 UTC`.

#figure(
  image("figures/f2_payload.png", width: 92%),
  caption: [Pobranie payloadu: GET `.dat` oraz odpowiedź HTTP 200 (octet-stream).],
)

== Follow-on: C2 i spambot

Po delivery widać powtarzalne TLS Client Hello z ofiary do `45.32.211.207:443`
bez sensownego SNI (C2 po HTTPS do gołego IP).

#figure(
  image("figures/f2_c2.png", width: 92%),
  caption: [TLS Client Hello do `45.32.211.207` (brak SNI w polu wyjściowym).],
)

Dodatkowo ruch na nietypowym porcie TCP/65400 do `54.36.108.120` (handshake SYN/SYN-ACK
i dalsza wymiana danych).

#figure(
  image("figures/f2_65400.png", width: 92%),
  caption: [Sesja TCP/65400: `172.17.4.206` -> `54.36.108.120`.],
)

Na końcu host zaczyna wychodzący SMTP: `EHLO localhost` i `STARTTLS` do kilku
zewnętrznych serwerów poczty. To wygląda na wykorzystanie stacji jako spambota.

#figure(
  image("figures/f2_smtp.png", width: 92%),
  caption: [SMTP z ofiary: EHLO/STARTTLS do zewnętrznych IP.],
)

= Wyniki automatyczne

`./scripts/run-faza2.sh` składa te same ustalenia w `evidence/faza2/`
(`findings.json`, `detections.md`, `timeline.md`, IOC, playbook, reguły Suricata).

#figure(
  image("figures/f2_timeline.png", width: 92%),
  caption: [Wygenerowana oś czasu: payload -> C2 -> 65400/checki -> SMTP.],
)

= Playbook IR (skrót)

Na podstawie pcapa: izolacja hosta, blokada IP payloadu/C2 oraz SMTP z klientów,
zbieranie artefaktów, czyszczenie/reimage, reset hasła `alfonso.paternoster`,
monitoring sąsiadów w LAN. Szczegóły: `faza2/playbooks/ir-qakbot.md`.

= Podsumowanie

Przeanalizowano oficjalny pcap Fazy 2. Zidentyfikowano stację `DESKTOP-V0FEH1L`
(`172.17.4.206`) użytkowaną przez `alfonso.paternoster`, początek aktywności
złośliwej w `2021-05-04 22:16:52 UTC` oraz rodzinę Qakbot, z dowodami C2
i spambota w tym samym capture.

= Wnioski

Sam pcap wystarcza do ustalenia tożsamości ofiary w AD i chronologii infekcji,
jeśli łączy się DHCP/NBNS/Kerberos z HTTP/TLS/SMTP. Najsilniejsze IOC sieciowe
to pobranie `.dat` z `185.183.99.115`, HTTPS do gołych IP oraz SMTP wychodzący
ze stacji końcowej. W produkcji warto blokować bezpośredni SMTP z endpointów
i alertować na C2 bez SNI oraz nietypowe checki `ipify` / `openssl`.

= Podział odpowiedzialności

#table(
  columns: (1.2fr, 2fr),
  stroke: 0.5pt,
  inset: 8pt,
  [*Osoba*], [*Zakres*],
  [Piotr Świtaj], [Przygotowanie środowiska analizy, odtworzenie przebiegu w tshark.],
  [Michał Kopyciński], [Analiza łańcucha infekcji, IOC, mapowanie ATT&CK.],
  [Szymon Boniuk], [Timeline, playbook IR, automatyzacja `run-faza2.sh`, raport.],
)

= Opis załączników

#table(
  columns: (1.2fr, 2fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Ścieżka*], [*Opis*],
  [`PCYB_Faza2_26Z_25.zip` / pcap], [Materiał od prowadzącej],
  [`scripts/analyze-faza2-pcap.py`], [Ekstrakcja IOC i timeline z pcapa],
  [`scripts/run-faza2.sh`], [Orkiestracja Fazy 2],
  [`faza2/detections/`], [Lista IOC + reguły Suricata],
  [`faza2/playbooks/ir-qakbot.md`], [Playbook IR],
  [`evidence/faza2/`], [Wyniki lokalne po uruchomieniu],
  [`img2/`], [Zrzuty tshark użyte w raporcie],
)
