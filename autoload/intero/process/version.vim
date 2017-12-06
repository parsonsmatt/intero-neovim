"""""""""""
" Version:
"
" This file contains functions for parsing and checking GHCi versions.
"""""""""""

" A parsed version is a list of 4 elements, containing one string (either
" 'intero' or 'ghci'), and three numbers, for the MAJOR, MINOR, and PATCH
" versions.

" An empty version value that can be used as a default, or to signal that
" parsing failed.
let g:intero#process#version#no_version = ['', 0, 0, 0]

" Tries to parse the GHCi or Intero version from a list of lines.
function! intero#process#version#parse_lines(output) abort
    for l:l in a:output
        " Try parsing regular GHCi version.
        let l:matches = matchlist(l:l, 'GHC\%(i\|\sInteractive\), version \(\d*\)\.\(\d*\).\(\d*\)[:,]')
        if !empty(l:matches)
            return ['ghci', l:matches[1] + 0, l:matches[2] + 0, l:matches[3] + 0]
        else
            " Fallback to parsing Intero-style version.
            let l:matches = matchlist(l:l, 'Intero .* (GHC \(\d*\)\.\(\d*\).\(\d*\))')
            if !empty(l:matches)
                return ['intero', l:matches[1] + 0, l:matches[2] + 0, l:matches[3] + 0]
            endif
        endif
    endfor

    return g:intero#process#version#no_version
endfunction

function! intero#process#version#is_intero(version) abort
    return a:version[0] ==# 'intero'
endfunction

function! intero#process#version#is_ghci(version) abort
    return a:version[0] ==# 'ghci'
endfunction
