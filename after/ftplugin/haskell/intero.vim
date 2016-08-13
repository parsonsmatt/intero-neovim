if exists('b:did_ftplugin_intero') && b:did_ftplugin_intero
    finish
endif
let b:did_ftplugin_intero = 1

if !has('patch-7.4.1578')
    echom "This version of intero-neovim requires the `timer_start` feature, which your neovim version lacks."
    finish
endif
call intero#process#ensure_installed()

if exists('b:undo_ftplugin')
    let b:undo_ftplugin .= ' | '
else
    let b:undo_ftplugin = ''
endif

" Starts the Intero process in the background.
command! -buffer -nargs=0 -bang InteroStart call intero#process#start()
" Kills the Intero process.
command! -buffer -nargs=0 -bang InteroKill call intero#process#kill()
" Opens the Intero buffer.
command! -buffer -nargs=0 -bang InteroOpen call intero#process#open()
" Hides the Intero buffer.
command! -buffer -nargs=0 -bang InteroHide call intero#process#hide()
" Loads the current module in Intero.
command! -buffer -nargs=0 -bang InteroLoadCurrentModule call intero#repl#load_current_module()
" Prompts user for a string to eval
command! -buffer -nargs=0 -bang InteroEval call intero#repl#eval()
" Gets the specific type at the current point
command! -buffer -nargs=0 -bang InteroType call intero#repl#type(0)
" Gets the type at the current point
command! -buffer -nargs=0 -bang InteroGenericType call intero#repl#type(1)
" Gets info for the identifier at the current point
command! -buffer -nargs=0 -bang InteroInfo call intero#repl#info()
" Go to definition of item under cursor
command! -buffer -nargs=0 -bang InteroGoToDef call intero#loc#go_to_def()
" Insert type of thing below cursor
command! -buffer -nargs=0 -bang InteroTypeInsert call intero#repl#insert_type()
" Reload
command! -buffer -nargs=0 -bang InteroReload call intero#repl#reload()
" Highlight uses of the identifier under cursor
command! -buffer -nargs=0 -bang InteroUses call intero#repl#uses() | set hlsearch

let b:undo_ftplugin .= join(map([
            \ 'InteroType',
            \ 'InteroGenericType',
            \ 'InteroOpen',
            \ 'InteroKill',
            \ 'InteroHide',
            \ 'InteroLoadCurrentModule',
            \ 'InteroEval',
            \ 'InteroGoToDef',
            \ ], '"delcommand " . v:val'), ' | ')
let b:undo_ftplugin .= ' | unlet b:did_ftplugin_intero'

call intero#process#start()

" vim: set ts=4 sw=4 et fdm=marker:
