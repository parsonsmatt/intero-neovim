function! intero#detect_module() abort "{{{
    let l:regex = '^\C>\=\s*module\s\+\zs[A-Za-z0-9.]\+'
    for l:lineno in range(1, line('$'))
        let l:line = getline(l:lineno)
        let l:pos = match(l:line, l:regex)
        if l:pos != -1
            let l:synname = synIDattr(synID(l:lineno, l:pos+1, 0), 'name')
            if l:synname !~# 'Comment'
                return matchstr(l:line, l:regex)
            endif
        endif
        let l:lineno += 1
    endfor
    return 'Main'
endfunction "}}}

" vim: set ts=4 sw=4 et fdm=marker:
