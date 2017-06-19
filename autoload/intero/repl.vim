""""""""""
" Repl:
"
" This file contains code for sending commands to the Intero REPL.
""""""""""

function! intero#repl#eval(...)
    " Given no arguments, this requests an expression from the user and
    " evaluates it in the Intero REPL.
    if a:0 == 0
        call inputsave()
        let l:eval = input("Command: ")
        call inputrestore()
    elseif a:0 == 1
        let l:eval = a:1
    else
        echomsg "Call with nothing for eval or with command string."
        return
    endif

    let g:intero_echo_next = 1
    call intero#repl#send(l:eval)
endfunction

function! intero#repl#load_current_module()
    " Loads the current module, inferred from the given filename.
    call intero#repl#eval(':l ' . intero#detect_module())
endfunction

function! intero#repl#type(generic)
    " Gets the type at the current point.
    let l:line = line('.')
    let l:col = intero#util#getcol()
    let l:module = intero#detect_module()
    if a:generic
        let l:identifier = intero#util#get_haskell_identifier()
    else
        let l:identifier = "it"
    endif

    call intero#repl#eval(
        \ join([':type-at', l:module, l:line, l:col, l:line, l:col, l:identifier], ' '))
endfunction

function! intero#repl#info()
    let l:ident = intero#util#get_haskell_identifier()
    call intero#repl#eval(':info ' . l:ident)
endfunction

function! intero#repl#send(str)
    " Sends a:str to the Intero REPL.
    if !exists('g:intero_buffer_id')
        echomsg "Intero not running."
        return
    endif
    call jobsend(g:intero_job_id, add([a:str], ''))
endfunction

function! intero#repl#insert_type()
    call intero#process#add_handler(function('s:paste_type'))
    call intero#repl#send(intero#util#make_command(':type-at'))
endfunction

function! intero#repl#reload()
    call intero#repl#send(':r')
endfunction

function! intero#repl#uses()
    let info = intero#loc#get_identifier_information()
    call intero#repl#send(intero#util#make_command(':uses'))
    exec "normal! /" . info.identifier . "\<CR>N"
    set hlsearch
    let @/ = info.identifier
endfunction

""""""""""
" Private:
""""""""""

function s:paste_type(response)
    call append(line(".")-1, a:response)
endfunction

