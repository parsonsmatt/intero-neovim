""""""""""
" Repl:
"
" This file contains code for sending commands to the Intero REPL.
""""""""""

" Location information for the identifier to insert a type signature for. It's
" inserted in a callback, hence this state variable.
let s:insert_type_identifier = 0

" Keep track of the current word under the cursor. It's used to avoid rerunning
" type info on hover when it's the same identifier.
let s:word_under_cursor = ''

function! intero#repl#eval(...) abort
    if !g:intero_started
        echoerr 'Intero is still starting up'
    else
        " Given no arguments, this requests an expression from the user and
        " evaluates it in the Intero REPL.
        if a:0 == 0
            call inputsave()
            let l:eval = input('Command: ')
            call inputrestore()
        elseif a:0 == 1
            let l:eval = a:1
        else
            echomsg 'Call with nothing for eval or with command string.'
            return
        endif

        let g:intero_echo_next = 1
        call intero#repl#send(l:eval)
    endif
endfunction

function! intero#repl#load_current_module() abort
    if !g:intero_started
        echoerr 'Intero is still starting up'
    else
        " Loads the current module, inferred from the given filename.
        call intero#repl#send(':l ' . intero#loc#detect_module())
    endif
endfunction

function! intero#repl#load_current_file() abort
    if !g:intero_started
        echoerr 'Intero is still starting up'
    else
        " Load the current file (useful for using the stack global project)
        call intero#repl#send(':l ' . expand('%:p'))
    endif
endfunction

" This function only gets the type of what's under the cursor.
" For a visual selection, you MUST use the key mapping, not the command.
function! intero#repl#type(generic) abort
    " " '.' gets the cursor pos (or the end of the selection if selection)
    let [l:l, l:c] = getpos('.')[1:2]

    call intero#repl#type_at(a:generic, l:l, l:c, l:l, l:c)
endfunction

" Gets the type at the given location, specified by:
"
" * `l1`: start line
" * `c1`: start column
" * `l2`: end line
" * `c2`: end column
"
" The `generic` argument specifies if this should return the
" generic or specialized type.
function! intero#repl#type_at(generic, l1, c1, l2, c2) abort
    let l:info = intero#loc#get_identifier_information()

    if !(a:l1 == a:l2 && a:c1 == a:c2)
        let l:identifier = intero#util#get_selection(a:l1, a:c1, a:l2, a:c2)
        let l:col1 = a:c1
        let l:col2 = a:c2
    else
        " Use the detected identifier information if we don't have a selection.
        let l:identifier = l:info.identifier
        let l:col1 = l:info.beg_col
        let l:col2 = l:info.end_col
    endif

    if !a:generic
        let l:identifier = 'it'
    endif

    if s:ghci_supports_type_at_and_uses()
        if g:intero_backend_info.backend ==# 'intero'
            let l:module = intero#loc#detect_module()

            " Fixup tabs for Stack
            let l:col1 = intero#util#getcol(a:l1, a:c1)
            let l:col2 = intero#util#getcol(a:l2, a:c2)
        else
            " Relative path to current file, quoted.
            let l:module = '"' . @% . '"'

            " Weird difference where regular GHCi needs the end column to be
            " beyond the last character of the selection, as opposed to how
            " Intero wants it:
            let l:col2 += 1
        endif

        call intero#repl#eval(
            \ join([':type-at', l:module, a:l1, l:col1, a:l2, l:col2, l:identifier], ' '))
    else
        " Fallback to :type for older versions of GHCi.
        call intero#repl#eval(join([':type', l:identifier], ' '))
    endif
endfunction

" This function gets the type of what's under the cursor OR under a selection.
" It MUST be run from a key mapping (commands exit you out of visual mode).
function! intero#repl#pos_for_type(generic) abort
    " 'v' gets the start of the selection (or cursor pos if no selection)
    let [l:l1, l:c1] = getpos('v')[1:2]
    " " '.' gets the cursor pos (or the end of the selection if selection)
    let [l:l2, l:c2] = getpos('.')[1:2]

    " Meant to be used from an expr map (:help :map-<expr>).
    " That means we have to return the next command as a string.
    if a:generic
      return ':InteroGenericTypeAt '.l:l1.' '.l:c1.' '.l:l2.' '.l:c2."\<CR>"
    else
      return ':InteroTypeAt '.l:l1.' '.l:c1.' '.l:l2.' '.l:c2."\<CR>"
    endif
endfunction

function! intero#repl#info() abort
    if !g:intero_started
        echoerr 'Intero is still starting up'
    else
        let l:ident = intero#util#get_haskell_identifier()
        call intero#repl#eval(':info ' . l:ident)
    endif
endfunction

function! intero#repl#send(str) abort
    " Sends a:str to the Intero REPL.
    if !exists('g:intero_buffer_id')
        echomsg 'Intero not running.'
        return
    endif
    call jobsend(g:intero_job_id, add([a:str], ''))
endfunction

function! intero#repl#insert_type() abort
    if !g:intero_started
        echoerr 'Intero is still starting up'
    else
        " for callback to add correct indent:
        let s:insert_type_identifier = intero#loc#get_identifier_information()

        call intero#process#add_handler(function('s:paste_type'))
        call intero#repl#send(intero#util#make_command(':type-at'))
    endif
endfunction

function! intero#repl#reload() abort
    if !g:intero_started
        echoerr 'Intero is still starting up'
    else
        " Truncate file, so that we don't show stale results while recompiling
        call intero#maker#write_update([])

        call intero#repl#send(':reload')
    endif
endfunction

function! intero#repl#uses() abort
    if !g:intero_started
        echoerr 'Intero is still starting up'
    elseif s:ghci_supports_type_at_and_uses()
        let l:info = intero#loc#get_identifier_information()
        call intero#repl#send(intero#util#make_command(':uses'))
        exec 'normal! /' . l:info.identifier . "\<CR>N"
        set hlsearch
        let @/ = l:info.identifier
    else
        echoerr 'Your GHCi version does not seem to support `:uses`'
    endif
endfunction

function! g:intero#repl#is_type_signature(type_lines) abort
    " Join everything as one line to avoid multiline search problems.
    return (join(a:type_lines) =~# ' :: ')
endfunction

function! g:intero#repl#get_type_signature_line_replacement(existing_line, type_lines, col) abort
    let l:col_idx = a:col - 1
    " The indent as a string.
    let l:indent = repeat(' ', l:col_idx)

    let l:first = a:type_lines[0]
    " We indent all but the first line of the type signature.
    let l:indented = []
    for l:type_line in a:type_lines[1:]
        call add(l:indented, l:indent . l:type_line)
    endfor

    " Calculate what to put _before_ and _after_ the inserted type signature.
    if l:col_idx > 0
        " When not on the top-level, everything on the same line, up until the
        " definition, need to be reinserted before the type signature.
        let l:prefix = a:existing_line[0:(l:col_idx - 1)]
        " Everything from the definition and to the end of that line needs to
        " be added after the type signature and indent.
        let l:suffix = a:existing_line[(l:col_idx):]
    else
        " When on the top level, we don't need anything before the type
        " signature.
        let l:prefix = ''
        " And everything on that line should go below the type signature.
        let l:suffix = a:existing_line
    endif

    " The replacement lines consists of:
    "
    " * The definition line with the prefix (the original indent, if any) and
    "   the unindented first line of the type signature.
    " * The indented type signature lines, together with
    "   the suffix (the original definition line) indented to match the type
    "   signature.
    return
                \ [l:prefix . l:first]
                \ + l:indented + [l:indent . l:suffix]
endfunction

function! intero#repl#toggle_type_on_hover() abort
    if g:intero_type_on_hover
        call intero#repl#disable_type_on_hover()
    else
        call intero#repl#enable_type_on_hover()
    endif
endfunction

function! intero#repl#enable_type_on_hover() abort
    let g:intero_type_on_hover = 1
endfunction

function! intero#repl#disable_type_on_hover() abort
    let g:intero_type_on_hover = 0
endfunction

function! intero#repl#type_on_hover() abort
    if g:intero_type_on_hover && g:intero_started
        let l:new_word_under_cursor = expand('<cword>')
        if s:word_under_cursor !=# l:new_word_under_cursor
            let l:ident = intero#util#get_haskell_identifier()
            if !empty(l:ident)
                call intero#process#add_handler(function('intero#repl#type_on_hover_handler'))
                call intero#repl#send(':type ' . l:ident)
            endif
            let s:word_under_cursor = l:new_word_under_cursor
        endif
    endif
endfunction

function! intero#repl#type_on_hover_handler(lines) abort
    if len(a:lines) > 0
        let l:message = a:lines[0]
        " NOTE: Whenever this is merged https://github.com/neovim/neovim/pull/6619, we could
        " use that to display the type information instead of echo.
        echo l:message
    endif
endfunction

""""""""""
" Private:
""""""""""

" Callback that inserts a type signature for a requested definition. Inserts
" the type signature at the definition's location, and indents the definition
" (that gets pushed down) the correct number of spaces, to match the type
" signature.
function! s:paste_type(type_lines) abort
    " First, check that the message contains a type signature.
    if (join(a:type_lines) =~# ' :: ')
        " The contents of the line where we're going to insert the type signature.
        let l:existing_line = getline(s:insert_type_identifier.line)
        " Calculate the replacement lines:
        let l:replacement = g:intero#repl#get_type_signature_line_replacement(
                    \ l:existing_line,
                    \ a:type_lines,
                    \ s:insert_type_identifier.beg_col)
        " Perform side-effects, setting the first line, and adding the rest of
        " them afterwards.
        call setline(s:insert_type_identifier.line, l:replacement[0])
        call append(s:insert_type_identifier.line, l:replacement[1:])
    else
        echomsg join(a:type_lines, '\n')
    end
endfunction

function! s:ghci_supports_type_at_and_uses() abort
    let l:ghci_has_type_at = intero#process#backend_info#version_gte(
                \ g:intero_backend_info.version, [8, 0, 1])
    return g:intero_backend_info.backend ==# 'intero' || l:ghci_has_type_at
endfunction
