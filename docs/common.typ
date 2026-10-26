#import "zespol.typ": *

#let meta-header(faza: none) = {
  set text(size: 10pt)
  grid(
    columns: (1fr, 1fr),
    gutter: 8pt,
    [*Przedmiot:* #przedmiot],
    [*Semestr:* #semestr],
    [*Zespół:* #nazwa-zespolu],
    [*Kierunek:* #kierunek],
    [*Faza:* #faza],
    [*Data:* #data-dokumentu],
  )
  v(0.6em)
  [*Członkowie zespołu*]
  enum(
    ..czlonkowie.map(c => [#c.imie #c.nazwisko — #c.indeks]),
  )
  v(0.8em)
}

#let podzial-section() = {
  heading(level: 2)[Podział odpowiedzialności]
  table(
    columns: (1.2fr, 2fr),
    stroke: 0.5pt,
    inset: 8pt,
    [*Osoba*], [*Zakres prac*],
    ..podzial.map(p => (p.osoba, p.zakres)).flatten(),
  )
}
