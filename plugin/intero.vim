if exists('b:did_plugin_intero') && b:did_plugin_intero
    finish
endif
let b:did_plugin_intero = 1

if !has('patch-7.4.1578')
    echom "This version of intero-neovim requires the `timer_start` feature, which your neovim version lacks."
    finish
endif

" Starts the Intero process in the background.
command! -nargs=0 -bang InteroStart call intero#process#start()
" Kills the Intero process.
command! -nargs=0 -bang InteroKill call intero#process#kill()
" Opens the Intero buffer.
command! -nargs=0 -bang InteroOpen call intero#process#open()
" Hides the Intero buffer.
command! -nargs=0 -bang InteroHide call intero#process#hide()
" Loads the current module in Intero.
command! -nargs=0 -bang InteroLoadCurrentModule call intero#repl#load_current_module()
" Prompts user for a string to eval
command! -nargs=0 -bang InteroEval call intero#repl#eval()
" Gets the specific type at the current point
command! -nargs=0 -bang InteroType call intero#repl#type(0)
" Gets the type at the current point
command! -nargs=0 -bang InteroGenericType call intero#repl#type(1)
" Gets info for the identifier at the current point
command! -nargs=0 -bang InteroInfo call intero#repl#info()
" Go to definition of item under cursor
command! -nargs=0 -bang InteroGoToDef call intero#loc#go_to_def()
" Insert type of thing below cursor
command! -nargs=0 -bang InteroTypeInsert call intero#repl#insert_type()
" Reload
command! -nargs=0 -bang InteroReload call intero#repl#reload()
" Highlight uses of the identifier under cursor
command! -nargs=0 -bang InteroUses call intero#repl#uses() | set hlsearch


" vim: set ts=4 sw=4 et fdm=marker:
