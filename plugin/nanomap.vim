scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if exists('s:is_loaded')
    finish
endif
let s:is_loaded = 1


if !exists('g:nanomap_cterm')
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
endif
if !exists('g:nanomap_cterm_highlight')
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
endif
if !exists('g:nanomap_cgui')
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
endif
if !exists('g:nanomap_cgui_highlight')
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
endif
if !exists('g:nanomap_highlight_delay')
    let g:nanomap_highlight_delay = 500
endif
if !exists('g:nanomap_update_delay')
    let g:nanomap_update_delay = 5000
endif
if !exists('g:nanomap_width')
    let g:nanomap_width = 2
endif
if !exists('g:nanomap_auto_realign')
    let g:nanomap_auto_realign = 0
endif
if !exists('g:nanomap_relative_color')
    let g:nanomap_relative_color = 0
endif
if !exists('g:nanomap_auto_open_close')
    let g:nanomap_auto_open_close = 0
endif
if !exists('g:nanomap_verbose')
    let g:nanomap_verbose = 0
endif

function! s:define_palette_if_exists() abort
    if exists('b:nanomap_name') && exists('b:nanomap_winid') && win_id2win(b:nanomap_winid) != 0
        call nanomap#define_palette()
    endif
endfunction

augroup NanoMap
    autocmd!
    autocmd ColorScheme * call s:define_palette_if_exists()
    autocmd TabLeave * call nanomap#set_leaving_tab(1)
    autocmd TabEnter * call nanomap#set_leaving_tab(0)
    if g:nanomap_auto_open_close
        autocmd WinNew,VimEnter * NanoMapShow
        autocmd WinEnter * if !nanomap#get_leaving_tab() | call nanomap#close_abandoned() | endif
    endif
augroup END

command! NanoMapShow call nanomap#show_nanomap()
command! NanoMapClose call nanomap#close()

let &cpo = s:save_cpo
unlet s:save_cpo
