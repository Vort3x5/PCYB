#import "zespol.typ": *

#let meta-header(faza: none) = {
  set text(size: 10pt)
  grid(
    columns: (1fr, 1fr),
    gutter: 8pt,
    [*Przedmiot:* #przedmiot],
    [*Semestr:* #semestr],
    [*Zespół:* #nazwa-zespolu],
    [*Kierunek:* #if kierunek == "" { text(style: "italic")[(uzupełnić w docs/zespol.typ)] } else { kierunek }],
    [*Faza:* #faza],
    [*Data:* #if data-dokumentu == "" { text(style: "italic")[(uzupełnić w docs/zespol.typ)] } else { data-dokumentu }],
  )
  v(0.6em)
  [*Członkowie zespołu*]
  enum(
    ..czlonkowie.map(c => {
      let name = [#c.imie #c.nazwisko]
      if c.imie == "" and c.nazwisko == "" {
        text(style: "italic")[(uzupełnić w docs/zespol.typ)]
      } else {
        [#name — indeks: #c.indeks]
      }
    }),
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
    ..podzial.map(p => (
      if p.osoba == "" { text(style: "italic")[(docs/zespol.typ)] } else { p.osoba },
      if p.zakres == "" { text(style: "italic")[(docs/zespol.typ)] } else { p.zakres },
    )).flatten(),
  )
}
