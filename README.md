# rangeundo.vim

RangeUndo is a plugin for undoing changes in a visual selection. Inspired by
the "Undo in region" feature in Emacs.

## Usage

Map a key to `<Plug>(rangeundo)` in your vimrc.

E.g.

    xmap u <Plug>(rangeundo)

When `<Plug>(rangeundo)` is executed, the latest change in the selected lines
will be undone. Continue executing `<Plug>(rangeundo)` on the same selection
immediately will undo earlier changes.

Just like `U`, rangeundo itself also counts as a change. So cancel the
selection and press `u` will redo the changes in the selected lines.

## Configuration

Set `g:rangeundo_max_undo` before loading the plugin to limit the maximum undo
levels checked by the plugin, unlimited when not set.

E.g. 

    let g:rangeundo_max_undo=50

The plugin contains both lua and vimscript versions of code, the lua version
will be used if possible. Set `g:rangeundo_use_vimscript` to use the vimscript
version.

## Limitations

The plugin compares undo states line by line, so selecting any characters on a
line will be the same as selecting the whole line.

The plugin cannot undo changes that are partially inside the selected range.

## Installation

Install this plugin with a vim plugin manager like
[vim-plug](https://github.com/junegunn/vim-plug)

## Requirements

- Neovim 0.2.1+ for lua version
- Vim 7.3.590+ for vimscript version
