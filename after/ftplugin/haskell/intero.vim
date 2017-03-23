if exists('g:did_ftplugin_intero') && g:did_ftplugin_intero
    finish
endif
let g:did_ftplugin_intero = 1

call intero#process#ensure_installed()

if exists('b:undo_ftplugin')
    let b:undo_ftplugin .= ' | '
else
    let b:undo_ftplugin = ''
endif

let b:undo_ftplugin .= 'unlet g:did_ftplugin_intero'

" vim: set ts=4 sw=4 et fdm=marker:
