""""""""""
" Util:
"
" This file contains functions that are useful for multiple modules, but that
" don't fit specifically in any one.
"""""""""

function! intero#util#stack_opts()
    return '--stack-yaml ' . g:intero_stack_yaml
endfunction

function! intero#util#get_intero_window()
    " Returns the window ID that the Intero process is on, or -1 if it isn't
    " found.
    return bufwinnr('stack ' .  intero#util#stack_opts() . ' ghci --with-ghc intero')
endfunction

function! intero#util#make_command(cmd)
    let info = intero#loc#get_identifier_information()
    return join([a:cmd, info.module, info.line, info.beg_col, info.line, info.end_col, info.identifier], ' ')
endfunction

""""""""""
" The following functions were copied from ghcmod-vim.
""""""""""
"
" Return the current haskell identifier
function! intero#util#get_haskell_identifier()
    let c = col ('.')-1
    let l = line('.')
    let ll = getline(l)
    let ll1 = strpart(ll,0,c)
    let ll1 = matchstr(ll1,"[a-zA-Z0-9_'.]*$")
    let ll2 = strpart(ll,c,strlen(ll)-c+1)
    let ll2 = matchstr(ll2,"^[a-zA-Z0-9_'.]*")
    return ll1.ll2
endfunction "}}}

function! intero#util#print_warning(msg) "{{{
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction "}}}

function! intero#util#print_error(msg) "{{{
    echohl ErrorMsg
    echomsg a:msg
    echohl None
endfunction "}}}

function! intero#util#getcol() "{{{
    let l:line = line('.')
    let l:col = col('.')
    let l:str = getline(l:line)[:(l:col - 1)]
    let l:tabcnt = len(substitute(l:str, '[^\t]', '', 'g'))
    return l:col + 7 * l:tabcnt
endfunction "}}}

function! intero#util#tocol(line, col) "{{{
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

" vim: set ts=4 sw=4 et fdm=marker:
