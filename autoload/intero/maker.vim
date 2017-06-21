""""""""""
" Maker:
"
" This file contains code for integrating with Neomake.
""""""""""

" This is where we store the build log for consumption by Neomake.
" The path is relative the working directory, which should be the project
" root. This needs to be statically defined, since we set the maker on
" startup.
let s:log_file = '.stack-work/logs/intero-build.log'

function! intero#maker#get_log_file() abort
    " Getter for log file path

    return s:log_file
endfunction

function! intero#maker#write_update(lines) abort
    " Writes the specified lines to the log file, then notifies Neomake

    call writefile(a:lines, '.stack-work/logs/intero-build.log')

    if exists(':NeomakeProject')
        NeomakeProject intero
    endif
endfunction
