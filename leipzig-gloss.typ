#let gloss_count = counter("gloss_count")

#let build_gloss(
    interword_spacing,
    gloss_line_spacing,
    formatters,
    gloss_line_lists,
    nlevel,
    item_styles,
    item_alignment,
    gloss_padding
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
        box(stack(dir: ttb, spacing: gloss_line_spacing, ..args))
    }

    let prev_space_after = false
    for item_idx in range(0, line_len) {
        let args = ()

        let current_item_dict = if nlevel and type(gloss_line_lists.at(item_idx)) == "dictionary" {true} else {false}
        let item_in_style_list = if str(item_idx) in item_styles {true} else {false}

        for (line_idx, formatter) in formatters.enumerate() {
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
            item_styles.at(str(item_idx)).style
            } else if item_alignment != none {
            align.with(item_alignment)
        }

        let spacing_before = if current_item_dict {
            gloss_line_lists.at(item_idx).spacing_before
        } else if item_in_style_list {
            item_styles.at(str(item_idx)).spacing_before
        } else {true}

        let spacing_after = if current_item_dict {
            gloss_line_lists.at(item_idx).spacing_after
        } else if item_in_style_list {
            item_styles.at(str(item_idx)).spacing_after
        } else {true}

        args = if item_formatting != none {
            args.map(x => item_formatting(x))
        } else {args}
        if item_idx == 0 and gloss_padding != none {
                h(gloss_padding)
        } else if spacing_before and prev_space_after {
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
    item_alignment: left, // default alignment to apply to items when not overridden for an individual item
    item_styles: (:), // a dictionary from strings of ints (representing the index of the relevant item) to a dictionary containing formatting and spacing values to apply to the item at that index
    translation: none,
    translation_style: none,
    pre_translation_space: .5em,
    interword_spacing: 1em,
    gloss_line_spacing: .5em,
    total_padding: 2.5em,
    number_padding: .5em,
    gloss_padding: none,
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
            if post_header_space != none {
                v(post_header_space)
            } else {
                linebreak()
            }
        }

        let formatters = ()
        let gloss_lists = ()

        if source_text != none {
            assert(nlevel==false, message: "source_text parameter may not be used with nlevel glossing")
            formatters.push(source_text_style)
            gloss_lists.push(source_text)
        }
        if transliteration != none {
            assert(nlevel==false, message: "transliteration parameter may not be used with nlevel glossing")
            formatters.push(transliteration_style)
            gloss_lists.push(transliteration)
        }
        if morphemes != none {
            assert(nlevel==false, message: "morphemes parameter may not be used with nlevel glossing")
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
            assert(type(gloss_group)=="array", message: "gloss_lines must consist of nested lists")
            gloss_lists.push(gloss_group)
        }

        for item in item_styles.keys() {
            let val = item_styles.at(item)
            let val_type = type(val)
            assert(
                val_type in ("function","dictionary") or(val_type == "string" and val in ("prefix","suffix","no_space_before","no_space_after")),message: "Invalid item style value -- must be function, dictionary, or one of a set of pre-defined strings."
                )
            let result_style = if val_type == "function" {
                (
                    "style": val,
                    "spacing_before": true,
                    "spacing_after": true,
                )
            } else if val_type == "string" {
                if val == "prefix" {
                    (
                        "style": x => align(right,x),
                        "spacing_before": true,
                        "spacing_after": false,
                    )
                } else if val == "suffix" {
                    (
                        "style": x => align(left, x),
                        "spacing_before": false,
                        "spacing_after": true,
                    )
                } else if val == "no_space_before" {
                    (
                        "style": none,
                        "spacing_before": false,
                        "spacing_after": true,
                    )
                } else if val == "no_space_after" {
                    (
                        "style": none,
                        "spacing_before": true,
                        "spacing_after": false,
                    )
                }
            } else if val_type == "dictionary" {
                if "spacing_before" not in val {
                    val.insert("spacing_before", true)
                }
                if "spacing_after" not in val {
                    val.insert("spacing_after", true)
                }
                val
            }
            item_styles.insert(item, result_style)
        }

        build_gloss(interword_spacing,gloss_line_spacing,formatters,gloss_lists,nlevel, item_styles, item_alignment, gloss_padding)

        if translation != none {
            if pre_translation_space != none {
                v(pre_translation_space)
            } else {
                linebreak()
            }
            if translation_style != none{
                translation_style(translation)
            }
            else {
                translation
            }
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
            number_padding,
            [#gloss_number],
            total_padding - number_padding - measure([#gloss_number],styles).width,
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
    connector: "\u{2011}",
    ..args,
) = {
    let connector = if connector == "-" {"\u{2011}"}
    return formatted_item(..args.pos().map(x => x + connector), style:align.with(right), no_space_after: true)
}

#let suffix(
    connector: "\u{2011}",
    ..args,
) = {
    let connector = if connector == "-" {"\u{2011}"}
    return formatted_item(..args.pos().map(x => connector + x), style: align.with(left), no_space_before: true)
}
