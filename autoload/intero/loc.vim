""""""""""
" Location:
"
" This file contains code for parsing locations and jumping to them.
""""""""""

function! intero#loc#go_to_def()
    call intero#repl#send(intero#util#make_command(':loc-at'))
    call intero#process#add_handler(function('s:handle_loc'))
endfunction

function! intero#loc#get_identifier_information()
    " Returns information about the identifier under the point. Return type is
    " a dictionary with the keys 'module', 'line', 'beg_col', 'end_col', and
    " 'identifier'.
    let l:module = intero#util#path_to_module(expand('%'))
    let l:line = line('.')
    let l:identifier = intero#util#get_haskell_identifier()
    let l:winview = winsaveview()
    normal! |
    call search('\<' . l:identifier . '\>', '', l:line)
    let l:beg_col = intero#util#getcol()
    let l:end_col = l:beg_col + len(l:identifier)
    let l:cmd = join([':loc-at', l:module, l:line, l:beg_col, l:line, l:end_col, l:identifier], ' ')
    call winrestview(l:winview)
    return { 'module': l:module, 'line': l:line, 'beg_col': l:beg_col, 'end_col': l:end_col, 'identifier': l:identifier }
endfunction

""""""""""
" Private:
""""""""""

function! s:handle_loc(resp)
    let l:response = join(a:resp, "\n")
    let l:split = split(l:response, ':')
    if len(l:split) != 2
        echom l:response
        return
    endif
    let l:pack_or_path = l:split[0]
    let l:module_or_loc = l:split[1]

    if l:module_or_loc =~ '[\h\+\.\?]\+'
        echom l:response
    else
        let l:loc_split = split(l:module_or_loc, '-')
        let l:start = substitute(l:loc_split[0], '[\(\)]', '', 'g')
        let l:end = substitute(l:loc_split[1], '[\(\)]', '', 'g')
        let l:start_split = split(l:start, ',')
        let l:start_row = l:start_split[0]
        let l:start_col = l:start_split[1]
        let l:cwd = getcwd()
        if l:pack_or_path != l:cwd . '/' . expand('%')
            exec 'edit +' . l:start_row . ' ' . l:pack_or_path
        endif
        call cursor(l:start_row, l:start_col)
        exec 'cd ' . l:cwd
    endif
endfunction
