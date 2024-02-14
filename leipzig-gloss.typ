#import "abbreviations.typ"

#let gloss-count = counter("gloss_count")
#let subex-count = counter("subex")

#let build_gloss(item-spacing, formatters, gloss_line_lists) = {
    assert(gloss_line_lists.len() > 0, message: "Gloss line lists cannot be empty")

    let len = gloss_line_lists.at(0).len()

    for line in gloss_line_lists {
        assert(line.len() == len)
    }

    assert(formatters.len() == gloss_line_lists.len(), message: "The number of formatters and the number of gloss line lists should be equal")

    let make_item_box(..args) = {
        box(stack(dir: ttb, spacing: 0.5em, ..args))
    }

    for item_index in range(0, len) {
        let args = ()
        for (line_idx, formatter) in formatters.enumerate() {
            let formatter_fn = if formatter == none {
                (x) => x
            } else {
                formatter
            }

            let item = gloss_line_lists.at(line_idx).at(item_index)
            args.push(formatter_fn(item))
        }
        make_item_box(..args)
        h(item-spacing)
    }
}


#let gloss-lines(
    header: none,
    header-style: none,
    source: (),
    source-style: none,
    transliteration: none,
    transliteration-style: none,
    morphemes: none,
    morphemes-style: none,
    additional-lines: (), //List of list of content
    translation: none,
    translation-style: none,
    item-spacing: 1em,
) = {

    assert(type(source) == "array", message: "source needs to be an array; perhaps you forgot to type `(` and `)`, or a trailing comma?")

    if morphemes != none {
        assert(type(morphemes) == "array", message: "morphemes needs to be an array; perhaps you forgot to type `(` and `)`, or a trailing comma?")
        assert(source.len() == morphemes.len(), message: "source and morphemes have different lengths")
    }

    if transliteration != none {
        assert(transliteration.len() == source.len(), message: "source and transliteration have different lengths")
    }

    if header != none {
        if header-style != none {
            header-style(header)
        } else {
            header
        }
        linebreak()
    }

    let formatters = (source-style,)
    let gloss_line_lists = (source,)

    if transliteration != none {
        formatters.push(transliteration-style)
        gloss_line_lists.push(transliteration)
    }

    if morphemes != none {
        formatters.push(morphemes-style)
        gloss_line_lists.push(morphemes)
    }

    for additional in additional-lines {
        formatters.push(none) //TODO fix this
        gloss_line_lists.push(additional)
    }


    build_gloss(item-spacing, formatters, gloss_line_lists)

    if translation != none {
        linebreak()

        if translation-style == none {
            translation
        } else {
            translation-style(translation)
        }
    }
}

#let gloss-ex-shell(
    left-padding: 0.5em,
    ex-padding: 2.0em,
    numbering: false,
    number-style: "(1)",
    breakable: false,
    counter: none, // pass the counter for numbering to use
    content
) = {
    if numbering {
        assert(counter != none, message: "gloss-ex-shell needs a counter passed to the function if numbering is true")
        counter.step()
    }

    let ex-number = if numbering {
        counter.display(number-style)
    } else {
        none
    }

    style(styles => {
        block(breakable: breakable)[
            #stack(
                dir:ltr, //TODO this needs to be more flexible
                left-padding,
                [#ex-number],
                ex-padding - left-padding - measure([#ex-number],styles).width,
                [#content]
            )
        ]
    }
    )
}

#let ling-example = gloss-ex-shell.with(counter:gloss-count)

#let numbered-example = gloss-ex-shell.with(numbering:true,counter:gloss-count)

#let multi-example(..args, content) = gloss-ex-shell(numbering: true,counter:gloss-count,..args)[
    #subex-count.update(0)
    #content
]

#let sub-example = gloss-ex-shell.with(numbering:true,counter:subex-count,number-style:"a.")

#let gloss(
    gloss-padding: 2.0em, //TODO document these
    left-padding: 0.5em,
    numbering: false,
    number-style: "(1)",
    breakable: false,
    ..args,
) = {
    let gloss-lines = gloss-lines(..args)
    if numbering {
        numbered-example(
            left-padding: left-padding,
            ex-padding: gloss-padding,
            number-style: number-style,
            breakable: breakable
        )[#gloss-lines]
    } else {
        ling-example(
            left-padding: left-padding,
            ex-padding: gloss-padding,
            breakable: breakable
        )[#gloss-lines]
    }
}

#let numbered-gloss = gloss.with(numbering: true)

#let sub-gloss(
    gloss-padding: 2.0em,
    left-padding: 0.5em,
    breakable: false,
    ..args
) = {
    let gloss-lines = gloss-lines(..args)
    sub-example(
        left-padding: left-padding,
        ex-padding: gloss-padding,
        breakable: breakable
    )[#gloss-lines]
}