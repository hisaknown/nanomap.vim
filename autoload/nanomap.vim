scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('s:is_loaded')
    finish
endif


let s:is_loaded = 1
let s:script_dir = expand('<sfile>:p:h')

let s:maps_dict = {}
autocmd NanoMap BufEnter * call s:resize_maps()
autocmd NanoMap VimLeave * call s:post_close_proc('')
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

function! s:nanomap_exists() abort
    if exists('w:nanomap_name') && exists('w:nanomap_winid')
                \ && win_id2win(w:nanomap_winid) != 0
                \ && bufname(winbufnr(w:nanomap_winid))[:6] ==# 'nanomap'
        return 1
    else
        return 0
    endif
endfunction

function! nanomap#show_nanomap() abort
    call nanomap#define_palette()
    let w:nanomap_name = 'nanomap:' . expand('%:p') . win_getid()
    if !s:nanomap_exists()
        let l:current_winid = win_getid()
        let l:nanomap_name = w:nanomap_name
        execute('silent! vertical rightbelow ' . g:nanomap_width . 'split ' . l:nanomap_name)
        let l:nanomap_winid = win_getid()
        let w:nanomap_source_winid = l:current_winid
        setlocal nonumber
        setlocal nowrap
        setlocal winwidth=1
        setlocal buftype=nofile
        setlocal filetype=nanomap
        autocmd! NanoMap * <buffer>
        autocmd NanoMap BufUnload <buffer> call s:post_close_proc(expand('<afile>'))
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

        let w:nanomap_tmpfile = tempname()
        let w:nanomap_tmpmap = tempname()
    else
        echo '[nanomap.vim] NanoMap is already there!'
    endif

    if exists('w:nanomap_timer')
        call timer_stop(w:nanomap_timer)
    endif
    let w:nanomap_timer = timer_start(g:nanomap_delay, funcref('s:update_nanomap'), {'repeat': -1})
    let w:nanomap_prev_changedtick = -1
    call setwinvar(win_id2win(w:nanomap_winid), 'nanomap_timer', w:nanomap_timer)

    let s:maps_dict[w:nanomap_name] = {
                \ 'tmpfile': w:nanomap_tmpfile,
                \ 'tmpmap':  w:nanomap_tmpmap,
                \ 'timer':   w:nanomap_timer,
                \ }
endfunction

function! s:update_nanomap(ch) abort
    try
        if s:nanomap_exists()
            if w:nanomap_prev_changedtick != b:changedtick
                call writefile(getbufline(bufnr('%'), 1, '$'), w:nanomap_tmpfile)
                let l:cmd = 'python ' . s:script_dir . '/nanomap/text_density.py'
                let l:cmd .= ' --color_bins ' . s:len_nanomap_palette
                let l:cmd .= ' --n_target_lines ' . winheight(w:nanomap_winid)
                let l:job = job_start(l:cmd,
                            \ {'in_io': 'file',
                            \  'in_name': w:nanomap_tmpfile,
                            \  'out_io': 'file',
                            \  'out_name': w:nanomap_tmpmap,
                            \  'out_modifiable': 1,
                            \  'out_msg': '',
                            \  'exit_cb': funcref('s:apply_nanomap')
                            \ })
                let w:nanomap_prev_changedtick = b:changedtick
            else
                call s:apply_nanomap(-1, 0)
            endif
        endif
    catch
        call timer_stop(a:ch)
    endtry
endfunction

function! s:apply_nanomap(job, exit_status) abort
    if s:nanomap_exists()
        if winheight(w:nanomap_winid) != w:nanomap_height
            let l:current_winid = win_getid()
            call win_gotoid(w:nanomap_winid)
            %delete _
            call win_gotoid(l:current_winid)
            let w:nanomap_height = winheight(w:nanomap_winid)
            let w:nanomap_prev_changedtick = -1
        endif
        let l:line_ratio = w:nanomap_height * 1.0 / line('$')
        let l:line_upper = line('w0') * l:line_ratio
        let l:line_lower = line('w$') * l:line_ratio

        if type(a:job) == v:t_job
            let w:nanomap_content = readfile(w:nanomap_tmpmap)
        endif
        let l:nanomap_content = copy(w:nanomap_content)
        for l:i in range(float2nr(floor(l:line_upper)),
                    \ min([float2nr(ceil(l:line_lower)), w:nanomap_height - 1]))
            let l:nanomap_content[l:i] .= 'hi'
        endfor
        call setbufline(winbufnr(w:nanomap_winid), 1, l:nanomap_content)
    endif
endfunction

function! s:close_nanomap() abort
    if s:nanomap_exists()
        execute(win_id2win(w:nanomap_winid) . 'close')
    else
        echo '[nanomap.vim] This buffer does not have NanoMap!'
    endif
endfunction

function! nanomap#goto_line(source_winid) abort
    if win_id2win(a:source_winid) != 0
        let l:pos_frac = (line('.') + 0.0) / line('$')
        call win_gotoid(a:source_winid)
        let l:line = str2nr(printf('%.f', round(l:pos_frac * line('$'))))
        call cursor(l:line, 0)
    else
        echo '[nanomap.vim] Corresponding window is not found!'
    endif
endfunction

function! s:post_close_proc(map_name) abort
    if len(a:map_name) == 0 " VimLeave
        for l:map_name in keys(s:maps_dict)
            call timer_stop(s:maps_dict[l:map_name]['timer'])
            call delete(s:maps_dict[l:map_name]['tmpfile'])
            call delete(s:maps_dict[l:map_name]['tmpmap'])
        endfor
    else
        call timer_stop(s:maps_dict[a:map_name]['timer'])
        let l:tmpfile = s:maps_dict[a:map_name]['tmpfile']
        let l:tmpmap = s:maps_dict[a:map_name]['tmpmap']
        call timer_start(g:nanomap_delay, {ch -> [delete(l:tmpfile), delete(l:tmpmap), remove(s:maps_dict, a:map_name)]})
    endif
endfunction

function! s:resize_maps() abort
    for l:map_name in keys(s:maps_dict)
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
                call s:close_nanomap()
                call nanomap#show_nanomap()
                call s:apply_nanomap(-1, 0)
            endif
        endfor
        call win_gotoid(l:current_winid)
    endif
    autocmd NanoMap WinNew * call s:realign_maps()
endfunction

command! NanoMapClose call s:close_nanomap()

let &cpoptions = s:save_cpo
unlet s:save_cpo
