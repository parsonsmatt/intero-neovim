# `intero-neovim` : v1.0.0
[![Build Status](https://travis-ci.org/parsonsmatt/intero-neovim.svg?branch=master)](https://travis-ci.org/parsonsmatt/intero-neovim)

Get the lightning fast type information and go-to-definition that Intero
provides without going to the dark side of emacs!

## Installing

This plugin is compatible with `pathogen`, `vim-plug`, etc.

Intero will be automatically compiled via Stack the first time you open a project.

![Demo of Installation](demo-install-lo.gif)

## Usage

This plugin provides an integration with [Intero][] via Neovim's terminal and
asynchronous job control. You might like the following shortcuts:

```
" Process management:
nnoremap <Leader>hio :InteroOpen<CR>
nnoremap <Leader>hik :InteroKill<CR>
nnoremap <Leader>hic :InteroHide<CR>
nnoremap <Leader>hil :InteroLoadCurrentModule<CR>
nnoremap <Leader>hif :InteroLoadCurrentFile<CR>

" REPL commands
nnoremap <Leader>hie :InteroEval<CR>
nnoremap <Leader>hit :InteroGenericType<CR>
nnoremap <Leader>hiT :InteroType<CR>
nnoremap <Leader>hii :InteroInfo<CR>
nnoremap <Leader>hiI :InteroTypeInsert<CR>

" Go to definition:
nnoremap <Leader>hid :InteroGoToDef<CR>

" Highlight uses of identifier:
nnoremap <Leader>hiu :InteroUses<CR>

" Reload the file in Intero after saving
autocmd! BufWritePost *.hs InteroReload
```

![REPL demo](demo-repl-lo.gif)

## Configuration

### `g:intero_start_immediately`

Default: 1.

Intero needs to start a long-running GHCi process to work. By default, we start
this whenever a Haskell buffer is opened. Setting this option to `0` defers
starting GHCi until you run `:InteroStart` or `:InteroOpen`.

### `g:intero_use_neomake`

Default: 1.

Neomake can detect and use Neomake to asynchronously show errors and warnings in
the sign column. To disable using Neomake completely, set this option to `0`.
For example, you might want this if you plan on using `intero` in conjunction
with a plugin like [ALE](https://github.com/w0rp/ale) or
[Syntastic](https://github.com/vim-syntastic/syntastic).

Note: if you don't have Neomake, we detect that appropriately and continue
gracefully.

## Commands

The following commands are available:

### `InteroEval`

This prompts the user to input a string, which gets sent to the REPL and
evaluated by Intero.

### `InteroResponse`

This retrieves the last thing that was evaluated by `intero`.

### `InteroGenericType`

This gets the type at the current point.

### `InteroTypeInsert`

Inserts the type of the current identifier in the above line at the top level.

### `InteroType`

This gets the type at the current point without generalizing the term.

### `InteroUses`

Highlights all uses of the current identifier and sets it to be the search
term. Also runs the command `:uses` in the Intero REPL.

### `InteroGoToDef`

Jumps to the definition of the current item if it is defined in the same
package. Otherwise, echoes where it is defined.

### `InteroReload`

Issues a `:r` to the REPL, causing it to reload the current module set.

### `InteroLoadCurrentModule`

This loads the current module.

### `InteroLoadCurrentFile`

This loads the current file. Useful for working with stack's global project.

### `InteroOpen`

Opens the Intero terminal buffer.

### `InteroHide`

Hides the Intero buffer without killing the process.

### `InteroStart`

This starts an Intero process connected to a `terminal` buffer. It's hidden at
first.

### `InteroKill`

Kills the Intero process and buffer.

## Configuration

If you need to use a specific `stack.yaml` file, you can set either of `STACK_YAML`
or `g:intero_stack_yaml` before invoking a command.

If you use a custom prompt in GHCi, then you may need to modify the regex for it. The default is

    let g:Intero_prompt_regex = '[^-]> '

## Neomake Integration
This plugin uses [Neomake](https://github.com/neomake/neomake) for compilation error reporting. Note that running `:Neomake!` directly will *not* work, due to a limitation of Neomake - you need to run `:InteroReload` instead. (See [#18](https://github.com/parsonsmatt/intero-neovim/issues/18) for details.)

## Completion
Completion is not handled by this plugin. Check out [neco-ghc][] for fast
autocompletion using `deoplete` or `omnicomplete`. If you have good reason for
wanting Intero-provided completion, please [post in the related
issue](https://github.com/parsonsmatt/intero-neovim/issues/5).

## Known Issues
* some commands may have unexpected side-effects if you have a autocmd that automatically switches to insert mode when entering a terminal buffer

## License

[BSD3 License](http://www.opensource.org/licenses/BSD-3-Clause), the same license as ghcmod-vim.

[intero]: https://github.com/commercialhaskell/intero
[neco-ghc]: https://github.com/eagletmt/neco-ghc
