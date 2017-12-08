"""""""""""
" Version:
"
" This file contains functions for parsing and checking backend information,
" e.g. the GHCi or Intero version.
"""""""""""

" A backend info contains the backend identifier, which is 'ghci' or 'intero',
" and a version. A version is a list of three numbers, for the MAJOR, MINOR, and
" PATCH versions.
function! intero#process#backend_info#backend_info(backend, major, minor, patch) abort
    let l:version = [a:major + 0, a:minor + 0, a:patch + 0]
    return {'backend': a:backend, 'version': l:version}
endfunction

let s:backend_regexps = [
            \ ['ghci',  'GHC\%(i\|\sInteractive\), version \(\d*\)\.\(\d*\).\(\d*\)[:,]'],
            \ ['intero', 'Intero .* (GHC \(\d*\)\.\(\d*\).\(\d*\))']
            \ ]

" Tries to parse the backend info from a list of lines. Returns a dict with
" backend info if successful, otherwise an empty dict.
function! intero#process#backend_info#parse_lines(output) abort
    for l:l in a:output
        " Try parsing the line with each backend/regexp pair available.
        for [l:backend, l:regexp] in s:backend_regexps
            let l:matches = matchlist(l:l, l:regexp)
            if !empty(l:matches)
                return intero#process#backend_info#backend_info(
                            \ l:backend,
                            \ l:matches[1],
                            \ l:matches[2],
                            \ l:matches[3])
            endif
        endfor
    endfor

    return {}
endfunction

function! intero#process#backend_info#version_gte(version, other) abort
    let l:major_gt = a:version[0] > a:other[0]
    let l:minor_gt = a:version[0] == a:other[0] && a:version[1] > a:other[1]
    let l:patch_gte = a:version[0] == a:other[0] && a:version[1] == a:other[1] && a:version[1] >= a:other[1]
    return l:major_gt || l:minor_gt || l:patch_gte
endfunction
