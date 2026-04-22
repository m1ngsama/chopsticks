" navigation.vim — FZF, netrw, buffer/window management, terminal

" ── netrw (built-in file browser) ───────────────────────────────────────────

let g:netrw_liststyle    = 3
let g:netrw_banner       = 0
let g:netrw_browse_split = 4
let g:netrw_winsize      = 25
let g:netrw_altv         = 1
let g:netrw_list_hide    = '\(^\|\s\s\)\zs\.\S\+'
let g:netrw_list_hide   .= ',\.pyc$,node_modules,\.git,__pycache__,\.DS_Store'

function! s:ToggleSidebar(...) abort
    let l:dir = a:0 ? a:1 : getcwd()
    if exists('t:netrw_sidebar_buf')
        let l:win = bufwinnr(t:netrw_sidebar_buf)
        if l:win != -1
            let l:cur = winnr()
            execute l:win . 'wincmd w'
            close
            if l:cur > l:win
                execute (l:cur - 1) . 'wincmd w'
            endif
            unlet t:netrw_sidebar_buf
            return
        endif
        unlet t:netrw_sidebar_buf
    endif
    execute '1wincmd w'
    execute 'Vexplore ' . fnameescape(l:dir)
    vertical resize 30
    let t:netrw_sidebar_buf = bufnr('%')
    wincmd l
endfunction

nnoremap <silent> <leader>e :call <SID>ToggleSidebar()<CR>
nnoremap <silent> <leader>E :call <SID>ToggleSidebar(expand('%:p:h'))<CR>

augroup ChopstickNetrw
    autocmd!
    autocmd FileType netrw setlocal bufhidden=wipe
augroup END

" ── FZF ─────────────────────────────────────────────────────────────────────

function! s:SmartFiles() abort
    if isdirectory('.git') || finddir('.git', '.;') !=# ''
        GFiles
    else
        Files
    endif
endfunction

if exists('g:plugs["fzf.vim"]')
    nnoremap <C-p>      :call <SID>SmartFiles()<CR>
    nnoremap <leader>b  :Buffers<CR>
    nnoremap <leader>rg :Rg<CR>
    nnoremap <leader>rG :RgWord<CR>
    nnoremap <leader>rt :Tags<CR>
    nnoremap <leader>gF :GFiles<CR>
    nnoremap <leader>fh :History<CR>
    nnoremap <leader>fc :Commands<CR>
    nnoremap <leader>fm :Marks<CR>
    nnoremap <leader>fl :BLines<CR>
    nnoremap <leader>fL :Lines<CR>
    nnoremap <leader>f/ :History/<CR>
    nnoremap <leader>f: :History:<CR>
endif

let g:fzf_layout = { 'down': '40%' }

if g:is_tty
    let g:fzf_preview_window = []
else
    let g:fzf_preview_window = ['right:50%', 'ctrl-/']
endif

if g:is_tty
    command! -bang -nargs=* Rg
        \ call fzf#vim#grep(
        \   'rg --column --line-number --no-heading --color=always --smart-case -- '
        \   .shellescape(<q-args>), 1, <bang>0)
    command! -bang GFiles call fzf#vim#gitfiles('', <bang>0)
else
    command! -bang -nargs=* Rg
        \ call fzf#vim#grep(
        \   'rg --column --line-number --no-heading --color=always --smart-case -- '
        \   .shellescape(<q-args>), 1, fzf#vim#with_preview(), <bang>0)
    command! -bang GFiles call fzf#vim#gitfiles('', fzf#vim#with_preview(), <bang>0)
endif

if g:is_tty
    command! -bang -nargs=* RgWord
        \ call fzf#vim#grep(
        \   'rg --column --line-number --no-heading --color=always --smart-case -F -- '
        \   .shellescape(expand('<cword>')), 1, <bang>0)
else
    command! -bang -nargs=* RgWord
        \ call fzf#vim#grep(
        \   'rg --column --line-number --no-heading --color=always --smart-case -F -- '
        \   .shellescape(expand('<cword>')), 1, fzf#vim#with_preview(), <bang>0)
endif

" ── Window Maximize Toggle ──────────────────────────────────────────────────

function! s:ToggleMaximize() abort
    if exists('t:maximize_session')
        execute t:maximize_session
        unlet t:maximize_session
        echo 'Window: restored'
    else
        let t:maximize_session = winrestcmd()
        resize | vertical resize
        echo 'Window: MAXIMIZED'
    endif
endfunction
nnoremap <silent> <leader>z :call <SID>ToggleMaximize()<CR>

" ── Terminal ────────────────────────────────────────────────────────────────

if has('terminal')
    nnoremap <leader>tv :terminal<CR>
    nnoremap <leader>th :terminal ++rows=10<CR>
    tnoremap <Esc><Esc> <C-\><C-n>
    tnoremap <C-h> <C-\><C-n><C-w>h
    tnoremap <C-j> <C-\><C-n><C-w>j
    tnoremap <C-k> <C-\><C-n><C-w>k
    tnoremap <C-l> <C-\><C-n><C-w>l
endif
