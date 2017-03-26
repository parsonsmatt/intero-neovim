if exists('b:did_ftplugin_intero') && b:did_ftplugin_intero
    finish
endif
let b:did_ftplugin_intero = 1

if !has('patch-7.4.1578')
    " Don't need to display the error message a second time, since it was
    " already displayed in plugin/intero.vim
    finish
endif

call intero#process#ensure_installed()

if exists('b:undo_ftplugin')
    let b:undo_ftplugin .= ' | '
else
    let b:undo_ftplugin = ''
endif

let b:undo_ftplugin .= 'unlet b:did_ftplugin_intero'

" vim: set ts=4 sw=4 et fdm=marker:
