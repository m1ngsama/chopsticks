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
    if getbufvar(winbufnr(1), '&filetype') ==# 'netrw' && getwinvar(1, '&winfixwidth')
        let l:cur = winnr()
        1wincmd w
        close
        if l:cur > 1
            execute (l:cur - 1) . 'wincmd w'
        endif
        return
    endif
    execute 'topleft vertical 30new'
    execute 'Explore ' . fnameescape(l:dir)
    setlocal winfixwidth
    setlocal bufhidden=wipe
    wincmd p
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
    nnoremap <leader>gC :Commits<CR>
    nnoremap <leader>gB :BCommits<CR>
endif

let g:fzf_layout = { 'down': '40%' }

if g:is_tty
    let g:fzf_preview_window = []
else
    let g:fzf_preview_window = ['right:50%', 'ctrl-/']
endif

function! s:Preview() abort
    return g:is_tty ? {} : fzf#vim#with_preview()
endfunction

command! -bang -nargs=* Rg
    \ call fzf#vim#grep(
    \   'rg --column --line-number --no-heading --color=always --smart-case -- '
    \   .shellescape(<q-args>), 1, s:Preview(), <bang>0)
command! -bang -nargs=* RgWord
    \ call fzf#vim#grep(
    \   'rg --column --line-number --no-heading --color=always --smart-case -F -- '
    \   .shellescape(expand('<cword>')), 1, s:Preview(), <bang>0)
command! -bang -nargs=? GFiles call fzf#vim#gitfiles(<q-args>, s:Preview(), <bang>0)

" ── Window Navigation ───────────────────────────────────────────────────────

if empty($TMUX)
    nnoremap <C-h> <C-w>h
    nnoremap <C-j> <C-w>j
    nnoremap <C-k> <C-w>k
    nnoremap <C-l> <C-w>l
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
