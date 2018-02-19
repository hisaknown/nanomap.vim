scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if exists('s:is_loaded')
    finish
endif


let s:is_loaded = 1
let s:script_dir = expand('<sfile>:p:h')

let s:tmpfiles = []
let s:timers = []

autocmd NanoMap VimLeave * call s:delete_tmpfiles()

function! s:delete_tmpfiles() abort
    for l in s:timers
        call timer_stop(l)
    endfor
    for l in s:tmpfiles
        call delete(l)
    endfor
endfunction

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

    for i in range(s:len_nanomap_palette)
        for j in range(s:len_nanomap_palette)
            execute('highlight nanomap' . printf('%02d%02d', i, j)
                        \ . ' ' . s:backend . 'fg=' . s:nanomap_palette[i]
                        \ . ' ' . s:backend . 'bg=' . s:nanomap_palette[j])
            execute('highlight nanomap' . printf('%02d%02dhi', i, j)
                        \ . ' ' . s:backend . 'fg=' . s:nanomap_palette_hi[i]
                        \ . ' ' . s:backend . 'bg=' . s:nanomap_palette_hi[j])
        endfor
    endfor
endfunction

function! s:nanomap_exists() abort
    if exists('b:nanomap_name') && exists('b:nanomap_winid')
                \ && win_id2win(b:nanomap_winid) != 0
                \ && bufname(winbufnr(b:nanomap_winid))[:6] ==# 'nanomap'
        return 1
    else
        return 0
    endif
endfunction

function! nanomap#show_nanomap() abort
    call nanomap#define_palette()
    let b:nanomap_name = 'nanomap:' . expand('%')
    if !s:nanomap_exists()
        let l:current_winid = win_getid()
        execute('silent! vertical rightbelow ' . g:nanomap_width . 'split nanomap:' . expand('%'))
        let l:nanomap_winid = win_getid()
        let b:nanomap_source_winid = l:current_winid
        setl nonumber
        setl nowrap
        setl winwidth=1
        setl buftype=nofile
        setl filetype=nanomap
        for i in range(s:len_nanomap_palette)
            for j in range(s:len_nanomap_palette)
                execute('syntax match nanomap' . printf('%02d%02d', i, j)
                            \ . ' /.nanomap' . printf('%02d%02d/', i, j))
                execute('syntax match nanomap' . printf('%02d%02dhi', i, j)
                            \ . ' /.nanomap' . printf('%02d%02dhi/', i, j))
            endfor
        endfor
        nnoremap <buffer> <CR> :<C-u>silent! call nanomap#goto_line(b:nanomap_source_winid)<CR>
        call win_gotoid(l:current_winid)
        let b:nanomap_winid = l:nanomap_winid
        let b:nanomap_height = winheight(b:nanomap_winid)

        let b:nanomap_tmpfile = tempname()
        let s:tempfiles = add(s:tmpfiles, b:nanomap_tmpfile)
        let b:nanomap_tmpmap = tempname()
        let s:tempfiles = add(s:tmpfiles, b:nanomap_tmpmap)
    else
        echomsg '[nanomap.vim] NanoMap is already there!'
    endif

    if exists('b:nanomap_timer')
        call timer_stop(b:nanomap_timer)
    endif
    let b:nanomap_timer = timer_start(g:nanomap_delay, funcref('s:update_nanomap'), {'repeat': -1})
    let s:timers = add(s:timers, b:nanomap_timer)
endfunction

function! s:update_nanomap(ch) abort
    try
        if s:nanomap_exists()
            call writefile(getbufline(bufnr('%'), 1, '$'), b:nanomap_tmpfile)
            let l:cmd = 'python3 ' . s:script_dir . '/nanomap/text_density.py'
            let l:cmd .= ' --color_bins ' . s:len_nanomap_palette
            let l:cmd .= ' --n_target_lines ' . winheight(b:nanomap_winid)
            let l:cmd .= ' --highlight_lines ' . line('w0') . ' ' . line('w$')
            let l:job = job_start(l:cmd,
                        \ {'in_io': 'file',
                        \  'in_name': b:nanomap_tmpfile,
                        \  'out_io': 'file',
                        \  'out_name': b:nanomap_tmpmap,
                        \  'out_modifiable': 1,
                        \  'out_msg': '',
                        \  'exit_cb': funcref('s:apply_nanomap')
                        \ })
        else
            call timer_stop(a:ch)
        endif
    catch
        call timer_stop(a:ch)
    endtry
endfunction

function! s:apply_nanomap(job, exit_status) abort
    if s:nanomap_exists()
        if winheight(b:nanomap_winid) != b:nanomap_height
            let l:current_winid = win_getid()
            call win_gotoid(b:nanomap_winid)
            %delete _
            call win_gotoid(l:current_winid)
        endif
        let l:line_count = 0
        for l in readfile(b:nanomap_tmpmap)
            call setbufline(winbufnr(b:nanomap_winid), l:line_count, l)
            let l:line_count += 1
        endfor
    endif
endfunction

function! s:close_nanomap() abort
    if s:nanomap_exists()
        execute(win_id2win(b:nanomap_winid) . 'close')
    else
        echo '[nanomap.vim] This buffer does not have NanoMap!'
    endif
endfunction

function! nanomap#goto_line(source_winid) abort
    if win_id2win(a:source_winid) != 0
        let l:pos_frac = (line('.') + 0.0) / line('$')
        call win_gotoid(a:source_winid)
        let l:line = str2nr(printf('%.f', round(l:pos_frac * line('$'))))
        call cursor(l:line, 10)
    else
        echo '[nanomap.vim] Corresponding window is not found!'
    endif
endfunction

command! NanoMapClose call s:close_nanomap()

let &cpo = s:save_cpo
unlet s:save_cpo
