if exists('b:did_ftplugin_intero') && b:did_ftplugin_intero
    finish
endif
let b:did_ftplugin_intero = 1

if !exists('g:intero_start_immediately')
    let g:intero_start_immediately = 1
endif

if g:intero_start_immediately
    call intero#process#start()
endif

if exists('b:undo_ftplugin')
    let b:undo_ftplugin .= ' | '
else
    let b:undo_ftplugin = ''
endif

let b:undo_ftplugin .= 'unlet b:did_ftplugin_intero'

" vim: set ts=4 sw=4 et fdm=marker:
