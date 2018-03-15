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

## Variables
- `g:nanomap_cgui`: List of colors which will be used in GUI.
- `g:nanomap_cterm`: List of colors which will be used in terminal.
- `g:nanomap_cgui_highlight`: Highlighted version of `g:nanomap_cgui`. This will be used to show where the cursor is. Must have the same length as `g:nanomap_cgui`.
- `g:nanomap_cterm_highlight`: Highlighted version of `g:nanomap_cterm`. This will be used to show where the cursor is. Must have the same length as `g:nanomap_cterm`.
- `g:nanomap_delay`: Update interval for the map in milliseconds. Defaults to `500`.
- `g:nanomap_width`: Width of the buffer for the map. Defaults to `2`.
- `g:nanomap_auto_realign`: If `1`, the map follows when the window is split. Defaults to `1`.
- `g:nanomap_relative_color`: If `1`, color of the map is based on relative density of the buffer. Otherwise, it is based on absolute density. Defaults to `1`.

### Setting example
This setting allows your vim to open NanoMap automatically.
```vim
let g:nanomap_relative_color = 0
" Automatically open NanoMap.
autocmd vimrc BufWinEnter * NanoMapShow
" Automatically close NanoMap
" Note that this causes E855 when you attempt to :close the last buffer.
autocmd vimrc BufWinLeave * NanoMapClose
" Using :quit instead of :close works without error.
autocmd vimrc QuitPre * NanoMapClose
```
