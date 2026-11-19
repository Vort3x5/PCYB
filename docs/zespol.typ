#let przedmiot = "Podstawy cyberbezpieczeństwa [PCYB]"
#let semestr = "26Z"
#let nazwa-zespolu = "antena izotropowa 40dBi"
#let kierunek = "Telekomunikacja"
#let data-dokumentu = "19.11.2026"

#let czlonkowie = (
  (imie: "Szymon", nazwisko: "Boniuk", indeks: "337314"),
  (imie: "Michał", nazwisko: "Kopyciński", indeks: "337343"),
  (imie: "Piotr", nazwisko: "Świtaj", indeks: "337400"),
)

#let podzial = (
  (
    osoba: "Piotr Świtaj",
    zakres: "Konfiguracja środowiska labowego, topologia, uruchomienie u zespołu.",
  ),
  (
    osoba: "Michał Kopyciński",
    zakres: "Realizacja ataku Log4Shell oraz demonstracja mitygacji.",

  ),
  (
    osoba: "Szymon Boniuk",
    zakres: "Monitoring, zbieranie dowodów, dokumentacja i raport Fazy 1.",
  ),
)


#let sprzet = (
  cpu: "AMD Ryzen 7 7800X3D (8 rdzeni)",
  ram: "32 GB",
  gpu: "NVIDIA GeForce RTX 4070 SUPER",
  dysk: "NVMe 2 TB (KINGSTON SKC3000D2048G), lab lokalny (localhost)",
  os: "NixOS 26.05 (Yarara)",
  kernel: "Linux 6.18.56",
)
