# Change Log

## `v1.0.0`

Initial release! 

## 2016-07-23

- Added `InteroUses` to highlight uses of the identifier under point in the
  buffer.

## 2016-07-22

- Added `InteroInsertType` to insert type of identifier at current location.
- Added `InteroReload`, which can be used to reload the current module after
  saving.

## 2016-07-10

- Improved echoing, fixed a flicker and performance issue.
- Added `InteroGoToDef` for jump-to-definition

## 2016-07-09

- Fixed the REPL echo stuff.

## 2016-07-08

- `InteroType` uses the identifier name instead of `it`, allowing for more
general type information.
- `InteroInfo` added
- Fixes the `buftype` issue described in [this issue](https://github.com/parsonsmatt/intero-neovim/issues/9)
- Removes the `InteroDiagnostic` command reference

## 2016-07-05

- Rudimentary implementation of `InteroType`
- Rudimentary implementation of `InteroResponse`

## 2016-07-03

- Installing `intero` locally
- Starting a terminal buffer process for the `intero` REPL
- Hiding the `intero` window
- Opening the `intero` window
