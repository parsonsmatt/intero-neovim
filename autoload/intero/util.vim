""""""""""
" Util:
"
" This file contains functions that are useful for multiple modules, but that
" don't fit specifically in any one.
"""""""""

function! intero#util#stack_opts() abort
    return '--stack-yaml ' . g:intero_stack_yaml
endfunction

function! intero#util#stack_build_opts() abort
    return intero#util#load_targets_as_string()
endfunction

function! intero#util#get_intero_window() abort
    " Returns the window ID that the Intero process is on, or -1 if it isn't
    " found.
    return bufwinnr('stack ' .  intero#util#stack_opts() . ' ghci --with-ghc intero')
endfunction

function! intero#util#make_command(cmd) abort
    let l:info = intero#loc#get_identifier_information()
    return join([a:cmd, l:info.module, l:info.line, l:info.beg_col, l:info.line, l:info.end_col, l:info.identifier], ' ')
endfunction

""""""""""
" The following functions were copied from ghcmod-vim.
""""""""""
"
" Return the current haskell identifier
function! intero#util#get_haskell_identifier() abort
    let l:c = col ('.') - 1
    let l:l = line('.')
    let l:ll = getline(l:l)
    let l:ll1 = strpart(l:ll, 0, l:c)
    let l:ll1 = matchstr(l:ll1, "[a-zA-Z0-9_'.]*$")
    let l:ll2 = strpart(l:ll, l:c, strlen(l:ll) - l:c + 1)
    let l:ll2 = matchstr(l:ll2, "^[a-zA-Z0-9_'.]*")
    return l:ll1 . l:ll2
endfunction "}}}

function! intero#util#print_warning(msg) abort "{{{
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction "}}}

function! intero#util#print_error(msg) abort "{{{
    echohl ErrorMsg
    echomsg a:msg
    echohl None
endfunction "}}}

function! intero#util#getcol() abort "{{{
    let l:line = line('.')
    let l:col = col('.')
    let l:str = getline(l:line)[:(l:col - 1)]
    let l:tabcnt = len(substitute(l:str, '[^\t]', '', 'g'))
    return l:col + 7 * l:tabcnt
endfunction "}}}

function! intero#util#tocol(line, col) abort "{{{
    let l:str = getline(a:line)
    let l:len = len(l:str)
    let l:col = 0
    for l:i in range(1, l:len)
        let l:col += (l:str[l:i - 1] ==# "\t" ? 8 : 1)
        if l:col >= a:col
            return l:i
        endif
    endfor
    return l:len + 1
endfunction "}}}

function! s:load_targets_from_stack() abort
    return systemlist('stack ide targets')
endfunction

if (!exists('g:intero_load_targets'))
    " A list of load targets.
    let g:intero_load_targets = []
endif

" Attempt to set the load targets. When passed an empty array, this uses the
" targets as given by `stack ide targets`.
function! intero#util#set_load_targets(targets) abort
    if len(a:targets) == 0
        let g:intero_load_targets = s:load_targets_from_stack()
        return g:intero_load_targets
    endif

    " if stack targets are empty, then we are not in a stack project.
    " attempting to set the targets will cause the build command to fail.
    let l:stack_targets = s:load_targets_from_stack()
    if empty(l:stack_targets)
        let g:intero_load_targets = []
        return g:intero_load_targets
    endif

    let l:valid_targets = []
    " we are in a stack project, and there are desired targets. validate that
    " they are contained inside the stack load targets
    for l:target in a:targets
        if index(l:stack_targets, l:target) == -1
            call intero#util#print_warning("Target " . l:target . " not present in available Stack targets: " . join(l:stack_targets, ' '))
        else 
            call add(l:valid_targets, l:target)
        endif
    endfor

    let g:intero_load_targets = l:valid_targets
    return g:intero_load_targets
endfunction

function! intero#util#get_load_targets() abort
    return g:intero_load_targets
endfunction

function! intero#util#load_targets_as_string() abort
    return join(intero#util#get_load_targets(), ' ')
endfunction
" vim: set ts=4 sw=4 et fdm=marker:
