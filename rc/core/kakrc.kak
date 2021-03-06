# http://kakoune.org
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate (.*/)?(kakrc|.*.kak) %{
    set buffer filetype kak
}

# Highlighters & Completion
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter -group / regions -default code kakrc \
    comment (^|\h)\K\# $ '' \
    double_string %{(^|\h)"} %{(?<!\\)(\\\\)*"} '' \
    single_string %{(^|\h)'} %{(?<!\\)(\\\\)*'} '' \
    shell '%sh\{' '\}' '\{' \
    shell '%sh\(' '\)' '\(' \
    shell '%sh\[' '\]' '\[' \
    shell '%sh\<' '\>' '\<' \
    shell '-shell-(completion|candidates)\h+%\{' '\}' '\{' \
    shell '-shell-(completion|candidates)\h+%\(' '\)' '\(' \
    shell '-shell-(completion|candidates)\h+%\[' '\]' '\[' \
    shell '-shell-(completion|candidates)\h+%\<' '\>' '\<'

%sh{
    # Grammar
    keywords="hook|remove-hooks|rmhooks|add-highlighter|addhl|remove-highlighter|rmhl|exec|eval|source|runtime|define-command|def|alias"
    keywords="${keywords}|unalias|declare-option|decl|echo|edit|set-option|set|unset-option|unset|map|unmap|set-face|face|prompt|menu|info"
    keywords="${keywords}|try|catch|rename-client|rename-buffer|rename-session|change-directory|colorscheme"
    attributes="global|buffer|window|current"
    attributes="${attributes}|normal|insert|menu|prompt|goto|view|user|object"
    attributes="${attributes}|number_lines|show_matching|show_whitespaces|fill|regex|dynregex|group|flag_lines|ranges|line|column|wrap|ref|regions"
    types="int|bool|str|regex|int-list|str-list|line-flags|completions|range-faces"
    values="default|black|red|green|yellow|blue|magenta|cyan|white|"

    # Add the language's grammar to the static completion list
    printf %s\\n "hook global WinSetOption filetype=kak %{
        set window static_words '${keywords}:${attributes}:${types}:${values}'
        set -- window completion_extra_word_char '-'
    }" | sed 's,|,:,g'

    # Highlight keywords. Teach \b that - does not create a word boundary
    printf %s "
        add-highlighter -group /kakrc/code regex \b(?<!-)(${keywords})(?!-)\b 0:keyword
        add-highlighter -group /kakrc/code regex \b(?<!-)(${attributes})(?!-)\b 0:attribute
        add-highlighter -group /kakrc/code regex \b(?<!-)(${types})(?!-)\b 0:type
        add-highlighter -group /kakrc/code regex \b(?<!-)(${values})(?!-)\b 0:value
    "
}

add-highlighter -group /kakrc/code regex \brgb:[0-9a-fA-F]{6}\b 0:value

add-highlighter -group /kakrc/double_string fill string
add-highlighter -group /kakrc/single_string fill string
add-highlighter -group /kakrc/comment fill comment
add-highlighter -group /kakrc/shell ref sh

# Commands
# ‾‾‾‾‾‾‾‾

def -hidden kak-indent-on-new-line %{
    eval -draft -itersel %{
        # copy '#' comment prefix and following white spaces
        try %{ exec -draft k <a-x> s ^\h*#\h* <ret> y jgh P }
        # preserve previous line indent
        try %{ exec -draft \; K <a-&> }
        # cleanup trailing whitespaces from previous line
        try %{ exec -draft k <a-x> s \h+$ <ret> d }
        # indent after line ending with %[[:punct:]]
        try %{ exec -draft k <a-x> <a-k> \%[[:punct:]]$ <ret> j <a-gt> }
    }
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook -group kak-highlight global WinSetOption filetype=kak %{ add-highlighter ref kakrc }

hook global WinSetOption filetype=kak %{
    hook window InsertChar \n -group kak-indent kak-indent-on-new-line
    # cleanup trailing whitespaces on current line insert end
    hook window InsertEnd .* -group kak-indent %{ try %{ exec -draft \; <a-x> s ^\h+$ <ret> d } }
}

hook -group kak-highlight global WinSetOption filetype=(?!kak).* %{ remove-highlighter kakrc }
hook global WinSetOption filetype=(?!kak).* %{ remove-hooks window kak-indent }
