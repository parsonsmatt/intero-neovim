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

    let g:intero_should_echo = 1
    call intero#repl#send(l:eval)
endfunction

function! intero#repl#load_current_module()
    " Loads the current module, inferred from the given filename.
    call intero#repl#eval(':l ' . intero#util#path_to_module(expand('%')))
endfunction

function! intero#repl#type(generic)
    " Gets the type at the current point.
    let l:line = line('.')
    let l:col = intero#util#getcol()
    let l:module = intero#util#path_to_module(expand('%'))
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

function! intero#repl#get_last_response()
    return s:get_last_response()
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
    let g:intero_should_echo = 0
    call intero#repl#send(intero#util#make_command(':type-at'))
    call timer_start(100, 's:paste_type', { 'repeat': 1 })
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

function s:paste_type()
    let l:signature = join(intero#repl#get_last_response(), "\n")
    call append(line(".")-1, l:signature)
endfunction

function! s:get_last_response()
    " Returns the previous response.
    let l:last_line = s:get_last_line()
    let l:lines = s:get_prev_matching(l:last_line[0:-1])
    return l:lines[0:-2]
endfunction

function! s:get_prev_matching(str)
    call s:switch_to_repl()

    let l:end = line('$')
    call cursor(l:end - 1, 0)
    let l:go_up = search(a:str, 'bn')
    let l:ret = getline(l:go_up + 1, l:end)

    call s:return_from_repl()

    return l:ret
endfunction

function! s:get_last_line()
    return join(s:get_line_repl(0))
endfunction

function! s:repl_hidden()
    " Returns whether or not the Intero repl is hidden.
    return -1 == intero#util#get_intero_window()
endfunction

function! s:switch_to_repl()
    " Switches to the REPL. Use with return_from_repl.
    let s:current_window = winnr()
    let l:i_win = intero#util#get_intero_window()

    if l:i_win == -1
        " Intero window not found. Open and close it.
        call intero#process#open()
        let l:i_win = intero#util#get_intero_window()
        exe 'silent! ' . l:i_win . ' wincmd w'
    else
        " Intero window available. Don't close it.
        exe 'silent! ' . l:i_win . ' wincmd w'
        let b:dont_close_intero_window = 1
    endif
endfunction

function! s:return_from_repl()
    " Returns to the current window from the REPL.
    if ! exists('s:current_window')
        echom "No current window."
        return
    endif

    if exists('b:dont_close_intero_window')
        unlet b:dont_close_intero_window
    else
        call intero#process#hide()
    endif

    exe s:current_window . 'wincmd w'
endfunction

function! s:get_line_repl(n)
    " Retrieves the second to last line from the Intero repl. The most recent
    " line will always be a prompt.
    python import vim
    let l:last_line = pyeval('len(vim.buffers[' . g:intero_buffer_id . '])')
    return getbufline(g:intero_buffer_id, l:last_line - a:n, l:last_line)
endfunction
