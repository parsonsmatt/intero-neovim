"""""""""""
" Process:
"
" This file contains functions for working with the Intero process. This
" includes ensuring that Intero is installed, starting/killing the
" process, and hiding/showing the REPL.
"""""""""""
" Lines of output consistuting of a command and the response to it
let s:current_response = []

" The current (incomplete) line
let s:current_line = ''

" Whether Intero has finished starting yet
let g:intero_started = 0

" If true, echo the next response. Reset after each response.
let g:intero_echo_next = 0

" Queue of functions to run when a response is received. For a given response,
" only the first will be run, after which it will be dropped from the queue.
let s:response_handlers = []

function! intero#process#initialize() abort
    " This is the entry point. It ensures that Intero is installed, sets any
    " global state we need, and starts it.

    if(!exists('g:intero_built'))
        " If `stack` exits with a non-0 exit code, that means it failed to find the executable.
        if (!executable('stack'))
            echom 'Stack is required for Intero.'
            return
        endif

        " We haven't set the stack-root yet, so we shouldn't be able to find this yet.
        if (executable('intero'))
            echom 'Intero is installed in your PATH, which may cause problems when using different resolvers.'
            echom 'This usually happens if you run `stack install intero` instead of `stack build intero`.'
            return
        endif

        " Load Python code
        py import sys
        call pyeval('sys.path.append("' . g:intero_plugin_root . '")')
        py import intero

        " Find stack.yaml
        if (!exists('g:intero_stack_yaml'))
            " Change dir temporarily and see if stack can find a config
            silent! lcd %:p:h
            let g:intero_stack_yaml = systemlist('stack path --config-location')[-1]
            silent! lcd -
        endif

        " Either start Intero, or start compiling it.
        " TODO: Verify that we have a version of intero that the plugin can work with.
        let l:version = system('stack ' . intero#util#stack_opts() . ' exec --verbosity silent -- intero --version')
        if v:shell_error
            let g:intero_built = 0
            echom 'Intero not installed.'
            let l:opts = { 'on_exit': function('s:build_complete') }
            call s:start_compile(10, l:opts)
        else
            let g:intero_built = 1
            call intero#process#start()
        endif
    endif
endfunction

function! intero#process#start() abort
    " Starts an intero terminal buffer, initially only occupying a small area.
    " Returns the intero buffer id.
    if(!exists('g:intero_built') || g:intero_built == 0)
        echom 'Intero is still compiling'
        return
    endif

    if !exists('g:intero_buffer_id')
        let g:intero_buffer_id = s:start_buffer(10)
    endif
    augroup close_intero
        autocmd!
        autocmd VimLeave * call intero#repl#eval(":quit")
        autocmd VimLeavePre * InteroKill
        autocmd VimLeave * InteroKill
        autocmd VimLeavePre * call jobstop(g:intero_job_id)
        autocmd VimLeave * call jobstop(g:intero_job_id)
    augroup END
    return g:intero_buffer_id
endfunction

function! intero#process#kill() abort
    " Kills the intero buffer, if it exists.
    if exists('g:intero_buffer_id')
        exe 'bd! ' . g:intero_buffer_id
        unlet g:intero_buffer_id
    else
        echo 'No Intero process loaded.'
    endif
endfunction

function! intero#process#hide() abort
    " Hides the current buffer without killing the process.
    silent! call s:hide_buffer()
endfunction

function! intero#process#open() abort
    " Opens the Intero REPL. If the REPL isn't currently running, then this
    " creates it. If the REPL is already running, this is a noop. Returns the
    " window ID.
    let l:intero_win = intero#util#get_intero_window()
    if l:intero_win != -1
        return l:intero_win
    elseif exists('g:intero_buffer_id')
        let l:current_window = winnr()
        silent! call s:open_window(10)
        exe 'silent! buffer ' . g:intero_buffer_id
        normal! G
        exe 'silent! ' . l:current_window . 'wincmd w'
    else
        call intero#process#start()
        return intero#process#open()
    endif
endfunction

function! intero#process#add_handler(func) abort
    " Adds an event handler to the queue
    let s:response_handlers = s:response_handlers + [a:func]
endfunction

""""""""""
" Private:
""""""""""

function! s:start_compile(height, opts) abort
    " Starts an Intero compiling in a split below the current buffer.
    " Returns the ID of the buffer.
    exe 'below ' . a:height . ' split'

    enew!
    call termopen('stack ' . intero#util#stack_opts() . ' build intero', a:opts)

    set bufhidden=hide
    set noswapfile
    set hidden
    let l:buffer_id = bufnr('%')
    let g:intero_job_id = b:terminal_job_id
    call feedkeys("\<ESC>")
    wincmd w
    return l:buffer_id
endfunction

function! s:start_buffer(height) abort
    " Starts an Intero REPL in a split below the current buffer. Returns the
    " ID of the buffer.
    exe 'below ' . a:height . ' split'

    enew
    call termopen('stack ' . intero#util#stack_opts() . ' ghci --with-ghc intero', {
                \ 'on_stdout': function('s:on_stdout'),
                \ 'cwd': pyeval('intero.stack_dirname()')
                \ })

    set bufhidden=hide
    set noswapfile
    set hidden
    let l:buffer_id = bufnr('%')
    let g:intero_job_id = b:terminal_job_id
    quit
    call feedkeys("\<ESC>")
    return l:buffer_id
endfunction

function! s:on_stdout(jobid, lines, event) abort
    if !exists('g:intero_prompt_regex')
        let g:intero_prompt_regex = '[^-]> $'
    endif

    for l:line_seg in a:lines
        let s:current_line = s:current_line . l:line_seg

        " If we've found a newline, flush the line buffer
        if s:current_line =~# '\r$'
            " Remove trailing newline, control chars
            let s:current_line = substitute(s:current_line, '\r$', '', '')
            let s:current_line = pyeval('intero.strip_control_chars()')

            " Flush line buffer
            let s:current_response = s:current_response + [s:current_line]
            let s:current_line = ''
        endif

        " If the current line is a prompt, we just completed a response
        if s:current_line =~ g:intero_prompt_regex
            if len(s:current_response) > 0
                " The first line is the input command, so we discard it
                call s:new_response(s:current_response[1:])
            endif

            let s:current_response = []
        endif

    endfor
endfunction

function! s:new_response(response) abort
    " This means that Intero is now available to run commands
    " TODO: ignore commands until this is set
    if !g:intero_started
        echom 'Intero ready'
        let g:intero_started = 1
    endif

    " For debugging
    let g:intero_response = a:response

    if g:intero_echo_next
        echo join(a:response, "\n")
        let g:intero_echo_next = 0
    endif

    " If a handler has been registered, pop it and run it
    if len(s:response_handlers) > 0
        call s:response_handlers[0](a:response)
        let s:response_handlers = s:response_handlers[1:]
    endif
endfunction

function! s:open_window(height) abort
    " Opens a window of a:height and moves it to the very bottom.
    exe 'below ' . a:height . ' split'
    normal! <C-w>J
endfunction

function! s:hide_buffer() abort
    " This closes the Intero REPL buffer without killing the process.
    let l:window_number = intero#util#get_intero_window()
    if l:window_number > 0
        exec 'silent! ' . l:window_number . 'wincmd c'
    endif
endfunction

function! s:build_complete(job_id, data, event) abort
    if(a:event ==# 'exit')
        if(a:data == 0)
            let g:intero_built = 1
            call intero#process#start()
        else
            echom 'Intero failed to compile.'
        endif
    endif
endfunction

