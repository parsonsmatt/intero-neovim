""""""""""
" Repl:
"
" This file contains code for sending commands to the Intero REPL.
""""""""""

" Location information for the identifier to insert a type signature for. It's
" inserted in a callback, hence this state variable.
let s:insert_type_identifier = 0

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

function! s:supports_type_at() abort
    let [l:major, l:minor, l:patch] = g:intero_ghci_version
    " >= 8.0.1 supports :type-at
    return l:major >= 8 && ((l:minor == 0 && l:patch >= 1) || l:minor > 0)
endfunction

" This function only gets the type of what's under the cursor.
" For a visual selection, you MUST use the key mapping, not the command.
function! intero#repl#type(generic) abort
    " " '.' gets the cursor pos (or the end of the selection if selection)
    let [l:l, l:c] = getpos('.')[1:2]

    call intero#repl#type_at(a:generic, l:l, l:c, l:l, l:c)
endfunction

function! intero#repl#type_at(generic, l1, c1, l2, c2) abort
    let l:module = intero#loc#detect_module()

    if a:generic
        if !(a:l1 == a:l2 && a:c1 == a:c2)
            let l:identifier = intero#util#get_selection(a:l1, a:c1, a:l2, a:c2)
        else
            let l:identifier = intero#util#get_haskell_identifier()
        endif
    else
        let l:identifier = 'it'
    endif

    " Fixup tabs for Stack
    let l:col1 = intero#util#getcol(a:l1, a:c1)
    let l:col2 = intero#util#getcol(a:l2, a:c2)

    call intero#repl#eval(
        \ join([':type-at', l:module, a:l1, l:col1, a:l2, l:col2, l:identifier], ' '))
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
        echo s:insert_type_identifier

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
    else
        let l:info = intero#loc#get_identifier_information()
        call intero#repl#send(intero#util#make_command(':uses'))
        exec 'normal! /' . l:info.identifier . "\<CR>N"
        set hlsearch
        let @/ = l:info.identifier
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
    " First, check that the message contains a type signature. Join everything
    " as one line to avoid multiline search problems.
    if (join(a:type_lines) =~# ' :: ')
        let l:col_idx = s:insert_type_identifier.beg_col - 1
        let l:line = s:insert_type_identifier.line

        " The indent as a string.
        let l:indent = repeat(' ', l:col_idx)

        let l:first = a:type_lines[0]
        " We indent all but the first line of the type signature.
        let l:indented = []
        for l:type_line in a:type_lines[1:]
            call add(l:indented, l:indent . l:type_line)
        endfor

        " The contents of the line where we're going to insert the type signature.
        let l:old = getline(l:line)

        " Calculate what to put _before_ and _after_ the inserted type signature.
        if l:col_idx > 0
            " When not on the top-level, everything on the same line, up until the
            " definition, need to be reinserted before the type signature.
            let l:prefix = l:old[0:(l:col_idx - 1)]
            " Everything from the definition and to the end of that line needs to
            " be added after the type signature and indent.
            let l:suffix = l:old[(l:col_idx):]
        else
            " When on the top level, we don't need anything before the type
            " signature.
            let l:prefix = ''
            " And everything on that line should go below the type signature.
            let l:suffix = l:old
        endif

        " We replace the definition line with the prefix (the original indent,
        " if any) and the unindented first line of the type signature.
        call setline(l:line, l:prefix . l:first)
        " And then we append the indented type signature lines, together with
        " the suffix (the original definition line) indented to match the type
        " signatured.
        call append(l:line, l:indented + [l:indent . l:suffix])
    else
        echomsg join(a:type_lines, '\n')
    end
endfunction

