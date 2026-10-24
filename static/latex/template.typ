// Editorial palette and type from the Fullbleed report and invoice samples.
#let ink = rgb("#17382e")
#let rust = rgb("#b44123")
#let muted = rgb("#5b6c64")
#let rule = rgb("#9eafa4")

#let contact(text: "", link: none, type: "") = {
  (text: text, link: link, type: type)
}

#let subSection(title: "", titleEnd: none, subTitle: none, subTitleEnd: none, content: []) = {
  (title: title, titleEnd: titleEnd, subTitle: subTitle, subTitleEnd: subTitleEnd, content: content)
}

#let section(title: "", content: subSection()) = {
  (title: title, content: content)
}

#let project(
  theme: rust,
  name: "",
  surname: "",
  title: none,
  contact: (),
  skills: (languages: ()),
  main: (),
  sidebar: (),
  body,
) = {
  set text(font: "Inter", size: 9.6pt, fill: ink)
  set par(leading: 4pt)
  set list(indent: 10pt, body-indent: 3pt, spacing: 4pt)

  let icon(name) = box(height: 11pt, baseline: 1pt, image(name + ".svg", alt: name))

  let section-title(label) = [
    #v(4pt)
    #grid(
      columns: (3pt, 1fr),
      column-gutter: 7pt,
      align: horizon,
      rect(width: 3pt, height: 14pt, fill: theme, stroke: none),
      text(font: "Bebas Neue", size: 17pt, fill: ink, tracking: .4pt)[#label],
    )
    #v(4pt)
  ]

  let entry(item) = [
    #if item.title != "" or item.titleEnd != none { [
      #text(weight: "bold", size: 9pt)[#item.title]
      #if item.titleEnd != none { [#h(4pt)#text(fill: muted, size: 8pt)[#item.titleEnd]] }
      #v(1pt)
    ] }
    #if item.subTitle != none or item.subTitleEnd != none { [
      #text(fill: theme, size: 7.7pt)[
        #if item.subTitle != none { item.subTitle }
        #if item.subTitleEnd != none { [#if item.subTitle != none { [ · ] }#item.subTitleEnd] }
      ]
      #v(2pt)
    ] }
    #item.content
  ]

  let render-sections(sections, entry-gap: 2pt) = {
    for s in sections {
      if s.title == "" {
        s.content
        v(5pt)
      } else {
        section-title(s.title)
        for item in s.content {
          entry(item)
          v(entry-gap)
        }
      }
    }
  }

  // A compact masthead keeps the report's display/serif pairing without
  // sacrificing space for the resume's work history.
  grid(
    columns: (2fr, 1fr),
    column-gutter: 17pt,
    align: (top, left + bottom),
    [
      #stack(
        dir: ttb,
        spacing: 9pt,
        text(font: "DM Serif Display", size: 31pt)[#name #surname],
        text(font: "Bebas Neue", size: 15pt, fill: theme, tracking: .5pt)[#title],
        block(width: 100%)[#main.first().content],
      )
    ],
    [
      #set text(size: 10pt)
      #for c in contact {
        [#icon(c.type) #if c.link == none { c.text } else { link(c.link, c.text) }]
        if c != contact.last() { linebreak() }
      }
    ],
  )

  grid(
    columns: (2fr, 1fr),
    column-gutter: 17pt,
    [#render-sections(main.slice(1))],
    [#set text(size: 9pt)
     #render-sections(sidebar, entry-gap: 0pt)],
  )
}
