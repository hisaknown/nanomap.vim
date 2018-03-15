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
- `g:nanomap_highlight_delay`: Update interval for the highlight of the map in milliseconds. Defaults to `500`.
- `g:nanomap_update_delay`: Update interval for the content of the map in milliseconds. Defaults to `5000`. Small value will cause laggy editting.
- `g:nanomap_width`: Width of the buffer for the map. Defaults to `2`.
- `g:nanomap_auto_realign`: If `1`, the map (somewhat agressively) follows when the window is split. Defaults to `0`.
- `g:nanomap_relative_color`: If `1`, color of the map is based on relative density of the buffer. Otherwise, it is based on absolute density. Defaults to `0`.

### Advanced setting example
This setting allows your vim to open NanoMap automatically.
```vim
" More scrollbar-ish behavior
let g:nanomap_auto_realign = 1
let g:nanomap_highlight_delay = 100

" Automatically open NanoMap on opening files.
autocmd vimrc BufRead * NanoMapShow
" Automatically close NanoMap
"   Note that this causes E855 when you attempt to :close the last buffer.
autocmd vimrc BufWinLeave * NanoMapClose
"   Using :quit instead of :close works without error.
autocmd vimrc QuitPre * NanoMapClose
```
