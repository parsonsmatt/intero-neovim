# [Intero][] for Neovim

[![Build Status](https://travis-ci.org/parsonsmatt/intero-neovim.svg?branch=master)](https://travis-ci.org/parsonsmatt/intero-neovim)

> A complete interactive development program for Haskell

[Intero][] makes working with Haskell painless by harnessing the power of
the GHCi REPL. Intero was originally built alongside an Emacs package. This
plugin ports much of the Emacs plugin functionality into a package for Neovim.

<p align="center">
  <a href="https://asciinema.org/a/128416">
    <img
      width="700px"
      alt="Intero for Neovim asciicast"
      src="https://asciinema.org/a/128416.png">
  </a>
</p>

- - -

Some key features:

- **Designed for Stack**

  Intero requires Stack. If your project works with Stack, it almost definitely
  works with Intero.

- **Automatic Setup**

  `intero-neovim` takes care of installing Intero into your Stack environment.
  The installation is local (not global!). This means that Intero is always
  current for each of your projects. The goal of Intero is to Just Work™.

- **Bring Your Own GHCi**

  You can configure the plugin to use a custom *backend*, e.g. `cabal repl` or
  plain `ghci`, instead of the default Intero backend. Newer features are
  enabled based on the GHCi version.

- **On-the-fly Typechecking**

  Intero reports errors and warnings as you work on your file using the Neomake
  plugin. Errors appear asynchronously, and don't block the UI.

- **Built-in REPL**

  Work with your Haskell code directly in GHCi using Neovim `:terminal` buffers.
  Load your file and play around with top-level functions directly.

- **Type Information**

  You can ask for type information of the identifier under your cursor as well
  as of a selection. Intero makes an effort to remember type information even
  when the module no longer typechecks.

- **Jump to Definition**

  After a module has been loaded by Intero, you can jump to the defintion of any
  identifiers within your package. If the identifier comes from a different
  package, Intero will tell you which package the identifier comes from.

- **Easy Target Switching**

  Intero makes working with multiple stack targets simple. Jump between your app
  and test suite seamlessly.


## Installing

This plugin is compatible with `pathogen`, `vim-plug`, etc. For example:

```viml
Plug 'parsonsmatt/intero-neovim'
```

This plugin requires [Stack][]. Optionally, install [Neomake][] for error
reporting.


## Quickstart

The goal of Intero is to Just Work™. Most of the hard work is done behind the
scenes. Intero will set itself up automatically when you open a Haskell file.

- To open the REPL:
  - `:InteroOpen`
- To load into the REPL:
  - `:InteroLoadCurrentFile`
- To reload whatever's in the REPL:
  - `:InteroReload`
- To get the type of the current identifier or selection:
  - in your vimrc: `map <silent> <leader>t <Plug>InteroGenericType`
  - then: press `<leader>t`
- To jump to a definition:
  - first `:InteroLoadCurrentFile`
  - then `:InteroGoToDef`.
- To switch targets:
  - `:InteroSetTargets`


## Usage

Complete usage and configuration information can be found in here:

```vim
:help intero
```

## Example Configuration

These are some suggested settings. This plugin sets up no keybindings by
default.

```vim
augroup interoMaps
  au!
  " Maps for intero. Restrict to Haskell buffers so the bindings don't collide.

  " Background process and window management
  au FileType haskell nnoremap <silent> <leader>is :InteroStart<CR>
  au FileType haskell nnoremap <silent> <leader>ik :InteroKill<CR>

  " Open intero/GHCi split horizontally
  au FileType haskell nnoremap <silent> <leader>io :InteroOpen<CR>
  " Open intero/GHCi split vertically
  au FileType haskell nnoremap <silent> <leader>iov :InteroOpen<CR><C-W>H
  au FileType haskell nnoremap <silent> <leader>ih :InteroHide<CR>

  " Reloading (pick one)
  " Automatically reload on save
  au BufWritePost *.hs InteroReload
  " Manually save and reload
  au FileType haskell nnoremap <silent> <leader>wr :w \| :InteroReload<CR>

  " Load individual modules
  au FileType haskell nnoremap <silent> <leader>il :InteroLoadCurrentModule<CR>
  au FileType haskell nnoremap <silent> <leader>if :InteroLoadCurrentFile<CR>

  " Type-related information
  " Heads up! These next two differ from the rest.
  au FileType haskell map <silent> <leader>t <Plug>InteroGenericType
  au FileType haskell map <silent> <leader>T <Plug>InteroType
  au FileType haskell nnoremap <silent> <leader>it :InteroTypeInsert<CR>

  " Navigation
  au FileType haskell nnoremap <silent> <leader>jd :InteroGoToDef<CR>

  " Managing targets
  " Prompts you to enter targets (no silent):
  au FileType haskell nnoremap <leader>ist :InteroSetTargets<SPACE>
augroup END

" Intero starts automatically. Set this if you'd like to prevent that.
let g:intero_start_immediately = 0

" Enable type information on hover (when holding cursor at point for ~1 second).
let g:intero_type_on_hover = 1
" OPTIONAL: Make the update time shorter, so the type info will trigger faster.
set updatetime=1000
```

## Using a Custom Backend

The default Intero backend can be overriden, so that you can use this plugin
without Stack and Intero. The following configuration uses `cabal new-repl`,
and specifies a `cwd` for a sub-directory project:

``` vim
let g:intero_backend = {
        \ 'command': 'cabal new-repl',
        \ 'options': '-Wall',
        \ 'cwd': expand('%:p:h')
        | }
```

Such configuration can be set per-project using a [local .nvimrc
file](https://andrew.stwrt.ca/posts/project-specific-vimrc/), or in your init
file for a system-wide effect.

**NOTE:** If `g:intero_backend` is set, `g:intero_ghci_options` and
`g:intero_load_targets` have no effect.

## Caveats

- Running `:Neomake!` directly will not work. You need to run `:InteroReload`
  instead.

- Some commands may have unexpected side-effects if you have an autocommand
  that automatically switches to insert mode when entering a terminal buffer.

- Completion is not handled by this plugin. You might want to checkout out
  [neco-ghc][] if you want completion.


## License

[BSD3 License](http://www.opensource.org/licenses/BSD-3-Clause), the same
license as ghcmod-vim.


[Intero]: https://commercialhaskell.github.io/intero/
[Stack]: https://haskellstack.org/
[Neomake]: https://github.com/neomake/neomake
[neco-ghc]: https://github.com/eagletmt/neco-ghc
