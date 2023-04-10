#let gloss_count = counter("gloss_count")

#let build_gloss(
    interword_spacing,
    formatters,
    gloss_line_lists,
    nlevel,
    item_styles
) = {
    assert(gloss_line_lists.len() > 0, message: "Gloss line lists cannot be empty")

    let line_len = if nlevel == true {
        gloss_line_lists.len()
    } else {
        gloss_line_lists.at(0).len()
    }
    
    let n_lines = if nlevel == true {
        if type(gloss_line_lists.at(0)) == "array" {
                gloss_line_lists.at(0).len()
            } else {
                gloss_line_lists.at(0).items.len()
            }
    } else {
        gloss_line_lists.len()
    }

    assert(formatters.len() == n_lines, message: "The number of formatters and the number of gloss lines should be equal")

    let make_item_box(..args) = {
        box(stack(dir: ttb, spacing: 0.5em, ..args))
    }

    let prev_space_after = true
    for item_idx in range(0, line_len) {
        let args = ()

        let current_item_dict = if nlevel and type(gloss_line_lists.at(item_idx)) == "dictionary" {true} else {false}
        let item_in_style_list = if str(item_idx) in item_styles {true} else {false}

        for line_idx, formatter in formatters {
            let formatter_fn = if formatter == none {
                (x) => x
            } else {
                formatter
            }

            let first_idx = if nlevel {
                item_idx
            } else {
                line_idx
            }
            let second_idx =  if nlevel {
                line_idx
            } else {
                item_idx
            }
            
            let item_group = gloss_line_lists.at(first_idx)

            let item = if current_item_dict {
                    item_group.items.at(second_idx)
                } else {
                    item_group.at(second_idx)
                }
            assert(type(item)=="content", message: repr(item_group))
            args.push(formatter_fn(item))
        }

        let item_formatting = if current_item_dict {
            gloss_line_lists.at(item_idx).style
        } else if item_in_style_list {
            item_styles.item_idx.style
        }

        let spacing_before = if current_item_dict {
            gloss_line_lists.at(item_idx).spacing_before
        } else if item_in_style_list {
            if "spacing_before" in item_styles.item_idx {
                item_styles.item_idx.spacing_before
            }
        } else {true}

        let spacing_after = if current_item_dict {
            gloss_line_lists.at(item_idx).spacing_after
        } else if item_in_style_list {
            if "spacing_after" in item_styles.item_idx {
                item_styles.item_idx.spacing_after
            }
        } else {true}

        args = if item_formatting != none {
            args.map(x => item_formatting(x))
        } else {args}
        if spacing_before and prev_space_after {
                h(interword_spacing)
            }
        make_item_box(..args)

        prev_space_after = spacing_after
    }
}


#let gloss(
    header_text: none,
    header_text_style: none,
    post_header_space: .5em,
    source_text: none,
    source_text_style: emph,
    transliteration: none,
    transliteration_style: none,
    morphemes: none,
    morphemes_style: none,
    gloss_lines: (), // List of lists of content,
    line_styles: (), // list of formatting functions to apply per line (in order) to lines in gloss_lines
    item_styles: (:), // a dictionary from strings of ints (representing the index of the relevant item) to a dictionary containing formatting and spacing values to apply to the item at that index
    translation: none,
    translation_style: none,
    pre_translation_space: .5em,
    interword_spacing: 1em,
    left_padding: .5em,
    gloss_padding: 2em,
    numbering: false,
    nlevel: false,
    breakable: false,
) = {
    if source_text != none {
        assert(type(source_text)=="array", message: "source_text needs to be an array; perhaps you forgot to type `(` and `)`, or a trailing comma?")
    }
    if morphemes != none {
        assert(type(morphemes)=="array", message: "morphemes needs to be an array; perhaps you forgot to type `(` and `)`, or a trailing comma?")
    }
    if transliteration != none {
        assert(type(transliteration)=="array", message: "transliteration needs to be an array; perhaps you forgot to type `(` and `)`, or a trailing comma?")
    }

    let gloss_items = {

        if header_text != none {
            if header_text_style != none{
                header_text_style(header_text)
            }
            else {
                header_text
            }
            v(post_header_space)
        }

        let formatters = ()
        let gloss_lists = ()

        if source_text != none {
            formatters.push(source_text_style)
            gloss_lists.push(source_text)
        }
        if transliteration != none {
            formatters.push(transliteration_style)
            gloss_lists.push(transliteration)
        }
        if morphemes != none {
            formatters.push(morphemes_style)
            gloss_lists.push(morphemes)
        }

        let n_lines = if nlevel {
            if type(gloss_lines.at(0)) == "array" {
                gloss_lines.at(0).len()
            } else {
                gloss_lines.at(0).items.len()
            }
        } else {
            gloss_lines.len()
        }
        let n_styles = line_styles.len()
        for idx in range(0,n_lines) {
            if idx < n_styles {
                formatters.push(line_styles.at(idx))
            } else {
                formatters.push(none)
            }
        }
        
        for gloss_group in gloss_lines {
            gloss_lists.push(gloss_group)
        }

        build_gloss(interword_spacing,formatters,gloss_lists,nlevel,item_styles)

        if translation != none {
            v(pre_translation_space)
            ["#translation"]
        }
    }


    if numbering {
        gloss_count.step()
    }

    let gloss_number = if numbering {
        [(#gloss_count.display())]
    } else {
        none
    }

    style(styles => {
        block(breakable: breakable)[
            #stack(
            dir:ltr,
            left_padding,
            [#gloss_number],
            gloss_padding - left_padding - measure([#gloss_number],styles).width,
            [#gloss_items]
            )
        ]
    }
    )
}

#let numbered_gloss = gloss.with(numbering:true)

#let nogloss = " "

#let formatted_item(
    style: none,
    no_space_before: false,
    no_space_after: false,
    ..list
) = {
    return (items: list.pos(), style: style, spacing_before: not no_space_before, spacing_after: not no_space_after)
}

#let prefix(
    connector: "-",
    ..args,
) = {
    return formatted_item(..args.pos().map(x => x + connector), style:align.with(right), no_space_after: true)
}

#let suffix(
    connector: "-",
    ..args,
) = {
    return formatted_item(..args.pos().map(x => connector + x), style: align.with(left), no_space_before: true)
}
