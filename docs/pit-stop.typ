#import "common.typ": *

#set document(
  title: "PCYB Pit stop",
  author: nazwa-zespolu,
)
#set page(margin: 2cm, numbering: "1")
#set text(lang: "pl", size: 11pt)
#set heading(numbering: "1.")

#align(center)[
  #text(size: 16pt, weight: "bold")[Pit stop — zgłoszenie tematyki i planu]
  #v(0.4em)
  #text(size: 12pt)[#przedmiot · semestr #semestr]
]

#meta-header(faza: "Pit stop")

= Nazwa wybranej techniki

Log4Shell (CVE-2021-44228) na przykładzie serwera Minecraft.

= Opis merytoryczny i klasyfikacja MITRE ATT&CK

Log4Shell to podatność w bibliotece Apache Log4j 2. Jeśli aplikacja loguje dane
pochodzące od użytkownika (np. wiadomość na czacie lub nick), atakujący może
wstrzyknąć wyrażenie `${jndi:ldap://…}`. JVM wykonuje wtedy lookup JNDI, łączy się
z serwerem LDAP kontrolowanym przez atakującego i — w podatnych konfiguracjach —
może pobrać oraz uruchomić złośliwą klasę (RCE). Luka miała ocenę CVSS 10.0
i w 2021 r. dotyczyła m.in. serwerów Minecraft używających Log4j.

W projekcie pokażemy ten łańcuch w izolowanym labie (VM), zbierzemy dowody
z monitoringu sieci i systemu oraz porównamy zachowanie przed i po mitygacji.

#table(
  columns: (1.2fr, 1.6fr, 1.6fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Tactic*], [*Technique*], [*W naszym scenariuszu*],
  [Initial Access], [T1190], [Treść logowana przez serwer (czat / nick)],
  [Execution], [T1059], [Wykonanie kodu po łańcuchu JNDI],
  [Command and Control], [T1071], [Komunikacja LDAP z maszyną atakującego],
)

= Plan realizacji zadania

1. Przygotowanie środowiska labowego i podział na role (serwer, klient, atakujący).
2. Uruchomienie podatnego serwera Minecraft i potwierdzenie, że Log4j wykonuje lookup JNDI.
3. Postawienie infrastruktury ataku, przeprowadzenie PoC oraz zbieranie logów i ruchu sieciowego.
4. Pokazanie mitygacji i przygotowanie raportu Fazy 1.

#podzial-section()
