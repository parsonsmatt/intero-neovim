""""""""""
" Repl:
"
" This file contains code for sending commands to the Intero REPL.
""""""""""

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

function! s:paste_type(lines) abort
    let l:message = join(a:lines, '\n')
    if l:message =~# ' :: '
        call append(line('.')-1, a:lines)
    else
        echomsg l:message
    end
endfunction

