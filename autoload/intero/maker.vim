""""""""""
" Maker:
"
" This file contains code for integrating with Neomake.
""""""""""

" This is where we store the build log for consumption by Neomake.
" We can't assume .stack-work exists, because of Stack scripts, and we need
" this to be different for each running instance.
let s:log_file = tempname()

function! intero#maker#get_log_file() abort
    " Getter for log file path

    return s:log_file
endfunction

function! intero#maker#write_update(lines) abort
    " Writes the specified lines to the log file, then notifies Neomake

    call writefile(a:lines, s:log_file)

    if g:intero_use_neomake && exists(':NeomakeProject')
        NeomakeProject intero
    endif
endfunction

function! intero#maker#cleanup() abort
    call delete(s:log_file)
endfunction

