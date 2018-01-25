if exists('g:did_plugin_intero') && g:did_plugin_intero
    finish
endif
let g:did_plugin_intero = 1

if !exists('g:intero_use_neomake')
    let g:intero_use_neomake = 1
endif

if !exists('g:intero_type_on_hover')
    let g:intero_type_on_hover = 0
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
" Loads the current file in Intero.
command! -nargs=0 -bang InteroLoadCurrentFile call intero#repl#load_current_file()
" Prompts user for a string to eval
command! -nargs=? -bang InteroEval call intero#repl#eval(<f-args>)
" Sends a string to the Intero buffer (doesn't prompt to "press any key")
command! -nargs=? -bang InteroSend call intero#repl#send(<f-args>)
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
" Kill and restart the Intero process
command! -nargs=0 -bang InteroRestart call intero#process#restart()
" Set the load targets for Intero.
command! -nargs=* -bang InteroSetTargets call intero#process#restart_with_targets(<f-args>)
" Set Intero to use all targets given by stack ide targets
command! -nargs=0 -bang InteroUseAllTargets call intero#targets#enable_all_targets()
" Clear the cached targets (useful if you've moved into a new stack project)
command! -nargs=0 -bang InteroClearTargetCache call intero#targets#clear_target_cache()
" Toggle type information on hover.
command! -nargs=0 -bang InteroToggleTypeOnHover call intero#repl#toggle_type_on_hover()
" Enable type information on hover.
command! -nargs=0 -bang InteroEnableTypeOnHover call intero#repl#enable_type_on_hover()
" Disable type information on hover.
command! -nargs=0 -bang InteroDisableTypeOnHover call intero#repl#disable_type_on_hover()

" Same as the :InteroType commands, but as maps (so they work with selections)
noremap <expr> <Plug>InteroType intero#repl#pos_for_type(0)
noremap <expr> <Plug>InteroGenericType intero#repl#pos_for_type(1)

" Two helper commands needed by the above mappings
" You should never need to call these manually.
command! -nargs=* -bang -range InteroTypeAt call intero#repl#type_at(0, <f-args>)
command! -nargs=* -bang -range InteroGenericTypeAt call intero#repl#type_at(1, <f-args>)

if g:intero_use_neomake
    " Try GHC 8 errors and warnings, then GHC 7 errors and warnings, and regard
    " lines starting with two spaces as continuations on an error message. All
    " other lines are disregarded. This gives a clean one-line-per-entry in the
    " QuickFix list.
    "
    " Code credit to @owickstrom from his neovim-ghci fork :)
    let s:efm = '%E%f:%l:%c:\ error:%#,' .
                \ '%W%f:%l:%c:\ warning:%#,' .
                \ '%W%f:%l:%c:\ warning:\ [-W%.%#]%#,' .
                \ '%f:%l:%c:\ %trror: %m,' .
                \ '%f:%l:%c:\ %tarning: %m,' .
                \ '%E%f:%l:%c:%#,' .
                \ '%E%f:%l:%c:%m,' .
                \ '%W%f:%l:%c:\ Warning:%#,' .
                \ '%C\ \ %m%#,' .
                \ '%-G%.%#'

    let g:neomake_intero_maker = {
            \ 'exe': 'cat',
            \ 'args': [intero#maker#get_log_file()],
            \ 'errorformat': s:efm
        \ }
endif

if g:intero_type_on_hover
    InteroEnableTypeOnHover
endif
" Get type information when you hold the cursor still for some time.
augroup interoTypeOnHover
    au!
    au CursorHold *.hs call intero#repl#type_on_hover()
augroup END

" vim: set ts=4 sw=4 et fdm=marker:
