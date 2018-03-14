# nanomap.vim
Tiny overview of the code.
Inspired by minimap in Sublime Text.

## Screencast
Watch the right side!
![Demo of nanomap.vim](https://raw.githubusercontent.com/wiki/hisaknown/nanomap.vim/screencast.gif)

## Requirements
- Vim with `has('job')`, `setbufline()`.
- Python

## Usage
`:NanoMapShow` to show the map of the current buffer.
To disable, `:NanoMapClose` or just close the window of the map.

## Customization
- `g:nanomap_cgui`: List of colors which will be used in GUI.
- `g:nanomap_cterm`: List of colors which will be used in terminal.
- `g:nanomap_cgui_highlight`: Highlighted version of `g:nanomap_cgui`. This will be used to show where the cursor is. Must have the same length as `g:nanomap_cgui`.
- `g:nanomap_cterm_highlight`: Highlighted version of `g:nanomap_cterm`. This will be used to show where the cursor is. Must have the same length as `g:nanomap_cterm`.
- `g:nanomap_delay`: Update interval for the map in milliseconds. Defaults to `500`.
- `g:nanomap_width`: Width of the buffer for the map. Defaults to `2`.
- `g:nanomap_auto_realign`: If `1`, the map follows when the window is split. Defaults to `1`.
- `g:nanomap_relative_color`: If `1`, color of the map is based on relative density of the buffer. Otherwise, it is based on absolute density. Defaults to `1`.

### Setting example (Default values)
```vim
let g:nanomap_cterm = [
            \ 16,
            \ 232,
            \ 233,
            \ 234,
            \ 235,
            \ 236,
            \ 237,
            \ 238,
            \ 239,
            \ 240,
            \ 241,
            \ 242,
            \ 243,
            \ ]
let g:nanomap_cterm_highlight = [
            \ 244,
            \ 245,
            \ 246,
            \ 247,
            \ 248,
            \ 249,
            \ 250,
            \ 251,
            \ 252,
            \ 253,
            \ 254,
            \ 255,
            \ 231,
            \ ]
let g:nanomap_cgui = [
            \ '#000000',
            \ '#080808',
            \ '#121212',
            \ '#1c1c1c',
            \ '#262626',
            \ '#303030',
            \ '#3a3a3a',
            \ '#444444',
            \ '#4e4e4e',
            \ '#585858',
            \ '#626262',
            \ '#6c6c6c',
            \ '#767676',
            \ ]
let g:nanomap_cgui_highlight = [
            \ '#0a283c',
            \ '#123044',
            \ '#1c3a4e',
            \ '#264458',
            \ '#304e62',
            \ '#3a586c',
            \ '#446276',
            \ '#4e6c80',
            \ '#58768a',
            \ '#628094',
            \ '#6c8a9e',
            \ '#7694a8',
            \ '#809eb2',
            \ ]
let g:nanomap_delay = 500
let g:nanomap_width = 2
```
