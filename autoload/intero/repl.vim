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
    call timer_start(100, function('s:paste_type'), { 'repeat': 1 })
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

function s:paste_type(timer)
    let l:signature = intero#repl#get_last_response()
    call append(line(".")-1, l:signature)
endfunction

function! s:get_last_response()
    let l:prompt = s:get_last_line()

    call s:switch_to_repl()

    " Find the last two instances of the prompt.
    call cursor(line('$'), 0)
    let l:last_prompt_line = search(l:prompt, 'b')
    let l:prev_prompt_line = search(l:prompt, 'b')
    call cursor(line('$'), 0)

    " For a reason that escapes me, it's possible for these values to be the
    " wrong way around (possible race condition?)
    if l:last_prompt_line < l:prev_prompt_line
        let l:tmp = l:last_prompt_line
        let l:last_prompt_line = l:prev_prompt_line
        let l:prev_prompt_line = l:tmp
    endif


    if l:last_prompt_line == 0 || l:prev_prompt_line == 0
        " The last line is unique, which means there's no response yet
        let l:ret = []
        echoerr 'Could not find prompt: ' l:prompt
    else
        let l:ret = getbufline(g:intero_buffer_id, l:prev_prompt_line + 1, l:last_prompt_line - 1)
    endif

    if len(l:ret) == 0
        echoerr 'Failed to find info'
        echo [l:prompt, l:prev_prompt_line, l:last_prompt_line, l:ret]
    endif

    call s:return_from_repl()

    return l:ret
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

function! s:get_last_line()
    " Retrieves the last non-blank line from the Intero repl, which should be
    " a prompt.
    python import vim
    return pyeval('filter(lambda s: len(s) != 0, vim.buffers[int(vim.eval("g:intero_buffer_id"))])[-1]')
endfunction
