" tools.vim — cheat sheet, run file, sudo save, quickfix, helpers

" ── Helper Functions ────────────────────────────────────────────────────────

function! HasPaste()
    if &paste | return 'PASTE MODE  ' | endif
    return ''
endfunction

command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
    let l:currentBufNum   = bufnr("%")
    let l:alternateBufNum = bufnr("#")
    if buflisted(l:alternateBufNum)
        buffer #
    else
        bnext
    endif
    if bufnr("%") == l:currentBufNum
        new
    endif
    if buflisted(l:currentBufNum)
        execute("bdelete! " . l:currentBufNum)
    endif
endfunction

fun! CleanExtraSpaces()
    let save_cursor = getpos(".")
    let old_query   = getreg('/')
    silent! %s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfun

function! ToggleNumber()
    if(&relativenumber == 1)
        set norelativenumber
        set number
    else
        set relativenumber
    endif
endfunc

" ── Additional Utilities ────────────────────────────────────────────────────

nnoremap <leader>F gg=G``
nnoremap <leader>wa :wa<CR>

nnoremap <silent> <Leader>= :exe "resize "          . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize "          . (winheight(0) * 2/3)<CR>
nnoremap <silent> <Leader>+ :exe "vertical resize " . (winwidth(0)  * 3/2)<CR>
nnoremap <silent> <Leader>_ :exe "vertical resize " . (winwidth(0)  * 2/3)<CR>

nnoremap <leader><leader> <c-^>

nnoremap <leader>W :%s/\s\+$//<CR>:let @/=''<CR>

nnoremap <leader>so :if &filetype ==# 'vim' <Bar> source % <Bar> echo "Sourced " . expand('%') <Bar> else <Bar> echo "Not a vim file" <Bar> endif<CR>
nnoremap <leader>ev :edit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>:echo "vimrc reloaded"<CR>

nnoremap <leader>* :%s/\<<C-r><C-w>\>//g<Left><Left>

if has('clipboard')
    nnoremap <leader>cp :let @+ = expand("%:p")<CR>:echo "Copied: " . expand("%:p")<CR>
    nnoremap <leader>cf :let @+ = expand("%:t")<CR>:echo "Copied: " . expand("%:t")<CR>
endif

nnoremap <leader>ms :e ~/buffer.md<cr>

" ── Auto-Create Directories ─────────────────────────────────────────────────

function! s:MkNonExDir(file, buf)
    if empty(getbufvar(a:buf, '&buftype')) && a:file !~# '\v^\w+\:\/'
        let dir = fnamemodify(a:file, ':h')
        if !isdirectory(dir)
            call mkdir(dir, 'p')
        endif
    endif
endfunction
augroup BWCCreateDir
    autocmd!
    autocmd BufWritePre *
        \ if !empty(expand('<afile>')) |
        \     call s:MkNonExDir(expand('<afile>'), +expand('<abuf>')) |
        \ endif
augroup END

" ── Large File Handling ──────────────────────────────────────────────────────

let g:LargeFile = 1024 * 1024 * 10
let s:tty_large  = g:is_tty ? 512000 : g:LargeFile

augroup ChopstickLargeFile
    autocmd!
    autocmd BufReadPre *
        \ if !empty(expand('<afile>')) |
        \     let s:fsize = getfsize(expand('<afile>')) |
        \     if s:fsize > g:LargeFile || s:fsize == -2 |
        \         setlocal bufhidden=unload undolevels=-1 noswapfile syntax= |
        \         let b:ale_enabled = 0 |
        \     elseif g:is_tty && s:fsize > s:tty_large |
        \         setlocal syntax= |
        \     endif |
        \ endif
augroup END

if g:is_tty && !exists("g:tty_message_shown")
    augroup TTYMessage
        autocmd!
        autocmd VimEnter * echom "TTY mode — visual features disabled"
    augroup END
    let g:tty_message_shown = 1
endif

" ── Run Current File (,cr) ──────────────────────────────────────────────────

function! s:RunFile() abort
    write
    let l:ft   = &filetype
    let l:file = shellescape(expand('%:p'))
    if     l:ft ==# 'python'     | execute '!python3 '  . l:file
    elseif l:ft ==# 'javascript' | execute '!node '     . l:file
    elseif l:ft ==# 'typescript' | execute '!npx ts-node ' . l:file
    elseif l:ft ==# 'go'         | execute '!go run '   . l:file
    elseif l:ft ==# 'rust'       | execute '!cargo run'
    elseif l:ft ==# 'sh'         | execute '!bash '     . l:file
    elseif l:ft ==# 'c'          | execute '!gcc -o /tmp/a.out ' . l:file . ' && /tmp/a.out'
    elseif l:ft ==# 'lua'        | execute '!lua '      . l:file
    elseif l:ft ==# 'ruby'       | execute '!ruby '     . l:file
    elseif l:ft ==# 'perl'       | execute '!perl '     . l:file
    else | echo 'No runner for filetype: ' . l:ft
    endif
endfunction
nnoremap <leader>cr :call <SID>RunFile()<CR>

" ── Sudo Save ───────────────────────────────────────────────────────────────

cnoremap w!! w !sudo tee > /dev/null %

" ── QuickFix Improvements ───────────────────────────────────────────────────

augroup ChopstickQF
    autocmd!
    autocmd QuickFixCmdPost [^l]* cwindow
    autocmd QuickFixCmdPost l*    lwindow
augroup END

nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [q :cprev<CR>

" ── Debug Helpers ───────────────────────────────────────────────────────────

nnoremap <leader>sh :call <SID>SynStack()<CR>
function! <SID>SynStack()
    if !exists("*synstack") | return | endif
    echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

" ── Cheat Sheet (,?) ────────────────────────────────────────────────────────

function! s:CheatSheet() abort
    let l:name = '__ChopsticksCheatSheet__'
    if bufwinnr(l:name) > 0
        execute bufwinnr(l:name) . 'wincmd w'
        return
    endif
    execute 'botright new ' . l:name
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    call setline(1, [
        \ '=== chopsticks — Quick Reference ===',
        \ '',
        \ 'SURVIVAL',
        \ '  Esc / jk      Exit insert or visual mode',
        \ '  :q! + Enter   Quit without saving',
        \ '  ,x  Save+quit   ,w  Save   Ctrl+s  Save (any mode)',
        \ '  :w!!          Sudo save (when you forgot to open as root)',
        \ '',
        \ 'FILES & SEARCH',
        \ '  Ctrl+p        Fuzzy find file (git-aware)',
        \ '  ,e / ,E       File browser / vertical split',
        \ '  ,b            Search open buffers',
        \ '  ,rg           Search project contents (ripgrep)',
        \ '  ,rG           Ripgrep word under cursor',
        \ '  ,fh           Recent files history',
        \ '  ,fl / ,fL     Search lines in buffer / all buffers',
        \ '  ,fc           Commands  |  ,fm  Marks',
        \ '  ,f/ / ,f:     Search / command history',
        \ '  ,,            Switch to last file (Ctrl+^)',
        \ '',
        \ 'CODE INTELLIGENCE (vim-lsp)',
        \ '  gd  Definition   gy  Type def   gi  Impl   gr  Refs',
        \ '  K               Hover documentation',
        \ '  [g / ]g         Prev / next LSP diagnostic',
        \ '  [e / ]e         Prev / next ALE error',
        \ '  ,ca  Code action   ,rn  Rename   ,f  Format',
        \ '  ,o   File outline   ,ws  Workspace symbols',
        \ '  ,cr             Run current file',
        \ '',
        \ 'MARKDOWN & WRITING',
        \ '  ,mp           Live browser preview (previm)',
        \ '  ,mt           Table of contents',
        \ '  ,zen          Zen mode (Goyo + Limelight)',
        \ '  zr / zm       Unfold / fold all headings',
        \ '',
        \ 'EDITING',
        \ '  gc            Toggle comment (visual mode too)',
        \ '  s + 2 chars   EasyMotion jump anywhere',
        \ '  ,u / F5       Undo tree',
        \ '  ,y / ,Y       Yank to system clipboard',
        \ '  Alt+j / Alt+k Move line down / up',
        \ '  ,F  Re-indent file   ,W  Strip trailing whitespace',
        \ '  ,*            Search and replace word under cursor',
        \ '',
        \ 'GIT',
        \ '  ,gs  Status   ,gd  Diff   ,gb  Blame',
        \ '  ,gc  Commit   ,gp  Push   ,gl  Pull',
        \ '  [x / ]x       Navigate git conflict markers',
        \ '',
        \ 'WINDOWS & PANES',
        \ '  Ctrl+h/j/k/l  Navigate splits and tmux panes',
        \ '  ,h / ,l       Prev / next buffer   ,bd  Close buffer',
        \ '  ,z            Maximize / restore current window',
        \ '  ,tv / ,th     Terminal (vertical / horizontal)',
        \ '  Esc Esc       Exit terminal mode',
        \ '  ,= / ,-       Resize height   ,+ / ,_  Resize width',
        \ '',
        \ 'QUICKFIX',
        \ '  ,qo / ,qc     Open / close quickfix',
        \ '  ]q / [q        Next / prev quickfix entry',
        \ '',
        \ 'UTILITIES',
        \ '  ,ev / ,sv     Edit / reload ~/.vimrc',
        \ '  ,cp / ,cf     Copy file path / filename to clipboard',
        \ '  ,ms  Scratch buffer   ,cd  CD to file dir',
        \ '  ,ss  Toggle spell   ,so  Source current vim file',
        \ '  F2 Paste  F3 Line#  F4 Relative#  F6 Invisible',
        \ '',
        \ '(press q to close)',
        \ ])
    setlocal nomodifiable readonly
    nnoremap <buffer> <silent> q :bd<CR>
endfunction
nnoremap <silent> <leader>? :call <SID>CheatSheet()<CR>

" ── Interactive Tutorial ────────────────────────────────────────────────────

function! s:ChopsticksLearn() abort
    let l:tutor = g:chopsticks_dir . '/tutor/chopsticks.tutor'
    if !filereadable(l:tutor)
        echo "Tutorial not found: " . l:tutor
        return
    endif
    execute 'edit ' . fnameescape(l:tutor)
    setlocal nomodifiable readonly
    setlocal buftype=nofile bufhidden=wipe
    setlocal filetype=text
    setlocal wrap linebreak
endfunction
command! ChopsticksLearn call s:ChopsticksLearn()
