"""""""""""
" Syntax:
"
" Custom syntax highlighting for GHCi in the embeded terminal window.
"""""""""""

" Because we have some regex that use non-ASCII characters
scriptencoding utf-8

syntax include @haskell syntax/haskell.vim

" Try to distinguish between GHC output and GHCi prompt lines, so that we can
" enable Haskell highlighting on the GHCi prompts.
exe 'syntax region GhciLine matchgroup=GhciLinePrompt start=/^'.g:intero_prompt_regex.'/ matchgroup=NONE end=/\n/ oneline keepend contains=@haskell,GhciCommand,GhciLoadCommand'
syntax match GhciCommand /:[a-z-]\+/ contained
syntax match GhciLoadCommand /:l.*/ contained contains=GhciCommand

" ----- GHC output ----------------------------------------------------------
" Some rather ad-hoc regexes for GHC output.

" For when the modules are loaded / reloaded by GHCi.
syntax region GhciSteps start=/^\[\s*\d\+ of \s*\d\+\]/ end=/)/
syntax region GhciOk start=/^Ok, modules loaded:/ end=/\.$/

" Experimentally, it seems like GHC outputs "expected/actual" results in one
" of two formats. Ideally, we'd have match group names describing when one
" format isused over another.
syntax region GhciExpectedActual1 start=/\(expected\|actual\) type/ end=/’/ keepend contains=GhciQuotedType
syntax region GhciQuotedType start=/‘/ end=/’/ contained keepend
syntax region GhciExpectedActual2  matchgroup=Constant start=/\(Expected\|Actual\) type: / end=/$/

syntax match GhciCause /^\s*• \(Probable\|Possible\) cause: .*$/
syntax match GhciFix /^\s*\(Probable\|Possible\) fix: .*$/
syntax region GhciPerhapsRegion matchgroup=GhciPerhapsYouMeant start=/^\z(\s*\)Perhaps you meant/ matchgroup=NONE end=/^\z1\S/ contains=GhciPerhapsSuggestion
syntax region GhciPerhapsSuggestion start=/‘/ end=/’/ contained keepend


" ----- Default highlight groups --------------------------------------------
" Used only if the user's colorscheme doesn't provide its own defaults.
" In particular, you can configure these for yourself in your vimrc!

" We ignore the prompt GHCi prompts without ANSI color codes don't pick up
" styles from the underlying Haskell syntax groups.
hi def link GhciLinePrompt Ignore
hi def link GhciCommand PreProc
hi def link GhciLoadCommand Constant

hi def link GhciExpectedActual1 Constant
hi def link GhciQuotedType Type
hi def link GhciExpectedActual2 Type

hi def link GhciSteps Comment
hi def link GhciOk Statement

hi def link GhciCause Underlined
hi def link GhciFix Underlined
hi def link GhciPerhapsYouMeant Underlined
hi def link GhciPerhapsSuggestion Statement

