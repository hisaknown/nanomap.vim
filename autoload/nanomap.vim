scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('s:is_loaded')
    finish
endif


let s:is_loaded = 1
let s:script_dir = expand('<sfile>:p:h')

let g:maps_dict = {}
autocmd NanoMap BufEnter * call s:resize_maps()
autocmd NanoMap WinNew * call s:realign_maps()

function! nanomap#define_palette() abort
    if has('gui_running') || (has('termguicolors') && &termguicolors)
        let s:len_nanomap_palette = len(g:nanomap_cgui)
        let s:nanomap_palette = g:nanomap_cgui
        let s:nanomap_palette_hi = g:nanomap_cgui_highlight
        let s:backend = 'gui'
    else
        let s:len_nanomap_palette = len(g:nanomap_cterm)
        let s:nanomap_palette = g:nanomap_cterm
        let s:nanomap_palette_hi = g:nanomap_cterm_highlight
        let s:backend = 'cterm'
    endif

    for l:i in range(s:len_nanomap_palette)
        for l:j in range(s:len_nanomap_palette)
            execute('highlight nanomap' . printf('%02d%02d', l:i, l:j)
                        \ . ' ' . s:backend . 'fg=' . s:nanomap_palette[l:i]
                        \ . ' ' . s:backend . 'bg=' . s:nanomap_palette[l:j])
            execute('highlight nanomap' . printf('%02d%02dhi', l:i, l:j)
                        \ . ' ' . s:backend . 'fg=' . s:nanomap_palette_hi[l:i]
                        \ . ' ' . s:backend . 'bg=' . s:nanomap_palette_hi[l:j])
        endfor
    endfor
endfunction

function! nanomap#nanomap_exists() abort
    if exists('w:nanomap_name')
                \ && exists('w:nanomap_winid')
                \ && win_id2win(w:nanomap_winid) != 0
                \ && bufname(winbufnr(w:nanomap_winid))[-8:] ==# ':nanomap'
        return 1
    endif
    return 0
endfunction

function! nanomap#show_nanomap() abort
    if bufname('%')[-8:] == ':nanomap'
        return
    endif
    call nanomap#define_palette()
    let w:nanomap_name = expand('%:p') . ':' . win_getid() . ':nanomap'
    if !nanomap#nanomap_exists()
        autocmd! NanoMap WinNew *
        let l:current_winid = win_getid()
        let l:nanomap_name = w:nanomap_name
        execute('silent! noswapfile vertical rightbelow ' . g:nanomap_width . 'split ' . l:nanomap_name)
        let l:nanomap_winid = win_getid()
        let w:nanomap_source_winid = l:current_winid
        setlocal nonumber
        setlocal nowrap
        setlocal winwidth=1
        setlocal buftype=nofile
        setlocal modifiable
        setlocal filetype=nanomap
        setlocal winfixwidth
        for l:i in range(s:len_nanomap_palette)
            for l:j in range(s:len_nanomap_palette)
                call matchadd('nanomap' . printf('%02d%02d', l:i, l:j), printf('▀%02d%02d', l:i, l:j))
                call matchadd('nanomap' . printf('%02d%02dhi', l:i, l:j), printf('▀%02d%02dhi', l:i, l:j))
            endfor
        endfor
        nnoremap <buffer><silent> <CR> :<C-u>silent! call nanomap#goto_line(w:nanomap_source_winid)<CR>
        nnoremap <buffer><silent> <LeftRelease> <Esc>:<C-u>silent! call nanomap#goto_line(w:nanomap_source_winid)<CR>
        call win_gotoid(l:current_winid)
        let w:nanomap_winid = l:nanomap_winid
        let w:nanomap_height = winheight(w:nanomap_winid)

        autocmd NanoMap WinNew * call s:realign_maps()
    else
        if g:nanomap_verbose
            echo '[nanomap.vim] NanoMap is already there!'
        endif
    endif

    if !exists('s:nanomap_timer')
        let s:nanomap_timer = timer_start(g:nanomap_highlight_delay, funcref('s:update_nanomap'), {'repeat': -1})
    endif
    let w:nanomap_prev_changedtick = -1
    let w:nanomap_prev_update_time = 0
endfunction

function! s:update_nanomap(ch) abort
    try
        if nanomap#nanomap_exists()
            if w:nanomap_prev_changedtick != b:changedtick &&
                        \ (reltimefloat(reltime()) - w:nanomap_prev_update_time) * 1000 >= g:nanomap_update_delay
                let l:cmd = 'python ' . s:script_dir . '/nanomap/text_density.py'
                let l:cmd .= ' --color_bins ' . s:len_nanomap_palette
                let l:cmd .= ' --n_target_lines ' . winheight(w:nanomap_winid)
                if g:nanomap_relative_color
                    let l:cmd .= ' --relative_color'
                endif
                let l:job = job_start(l:cmd,
                            \ {'in_io': 'buffer',
                            \  'in_buf': bufnr('%'),
                            \  'out_msg': '',
                            \  'close_cb': funcref('s:apply_nanomap')
                            \ })
                let w:nanomap_prev_changedtick = b:changedtick
                let w:nanomap_prev_update_time = reltimefloat(reltime())
            else
                call s:apply_nanomap(-1)
            endif
        endif
    catch
        echomsg '[nanomap.vim] Something went wrong. Stopping update of nanomap...'
        echomsg '[nanomap.vim] Problem details: ' . v:exception
        call timer_stop(a:ch)
        unlet s:nanomap_timer
    endtry
endfunction

function! s:apply_nanomap(channel) abort
    if nanomap#nanomap_exists()
        if winheight(w:nanomap_winid) != w:nanomap_height
            let l:current_winid = win_getid()
            call win_gotoid(w:nanomap_winid)
            %delete _
            call win_gotoid(l:current_winid)
            let w:nanomap_height = winheight(w:nanomap_winid)
            let w:nanomap_prev_changedtick = -1
        endif

        if type(a:channel) == v:t_channel
            let w:nanomap_content = []
            while ch_status(a:channel, {'part': 'out'}) == 'buffered'
                call add(w:nanomap_content, ch_read(a:channel))
            endwhile
            while len(w:nanomap_content) < w:nanomap_height
                call add(w:nanomap_content, '')
            endwhile
        elseif !exists('w:nanomap_content') || w:nanomap_prev_changedtick < 0
            " Should update the map immediately
            let w:nanomap_prev_update_time = 0
            call s:update_nanomap(-1)
        endif
        let l:nanomap_content = copy(w:nanomap_content)

        let l:line_ratio = (w:nanomap_height - count(w:nanomap_content, '')) * 1.0 / line('$')
        let l:line_upper = (line('w0') - 1) * l:line_ratio
        let l:line_lower = (line('w$') - 1) * l:line_ratio
        try
            for l:i in range(float2nr(floor(l:line_upper)),
                        \ min([float2nr(ceil(l:line_lower)), w:nanomap_height]))
                if l:nanomap_content[l:i] != ''
                    let l:nanomap_content[l:i] .= 'hi'
                endif
            endfor
        catch /^Vim\%((\a\+)\)\=:E684/
            " Catch out of range
        endtry
        try
            call setbufline(winbufnr(w:nanomap_winid), 1, l:nanomap_content)
        catch /^Vim\%((\a\+)\)\=:E21/
            " Catch nomodifible
        endtry
    endif
endfunction

function! nanomap#close() abort
    if nanomap#nanomap_exists()
        execute(win_id2win(w:nanomap_winid) . 'quit')
    else
        if g:nanomap_verbose
            echo '[nanomap.vim] This buffer does not have NanoMap!'
        endif
    endif
endfunction

function! nanomap#goto_line(source_winid) abort
    if win_id2win(a:source_winid) != 0
        let l:pos_frac = (line('.') + 0.0) / (line('$') - count(getline(1, '$'), ''))
        call win_gotoid(a:source_winid)
        let l:line = str2nr(printf('%.f', round(l:pos_frac * line('$'))))
        call cursor(l:line, 0)
    else
        if g:nanomap_verbose
            echo '[nanomap.vim] Corresponding window is not found!'
        endif
    endif
endfunction

function! s:resize_maps() abort
    for l:map_name in keys(g:maps_dict)
        for l:winid in win_findbuf(bufnr(l:map_name))
            if winwidth(l:winid) != g:nanomap_width
                let l:current_winid = win_getid()
                call win_gotoid(l:winid)
                call execute('vertical resize ' . g:nanomap_width)
                call cursor(0, 1)
                call win_gotoid(l:current_winid)
            endif
        endfor
    endfor
endfunction

function! s:realign_maps() abort
    autocmd! NanoMap WinNew *
    if g:nanomap_auto_realign
        let l:current_winid = win_getid()
        for l:win in getwininfo()
            call win_gotoid(l:win['winid'])
            let l:nanomap_winid = getwinvar(l:win['winnr'], 'nanomap_winid')
            if !empty(l:nanomap_winid) && win_id2win(l:nanomap_winid) != 0
                call nanomap#close()
                call nanomap#show_nanomap()
                call s:apply_nanomap(-1)
            endif
        endfor
        call win_gotoid(l:current_winid)
    endif
    autocmd NanoMap WinNew * call s:realign_maps()
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
