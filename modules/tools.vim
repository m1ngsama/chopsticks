" tools.vim — run file, sudo save, quickfix, helpers

" ── Buffer Close ───────────────────────────────────────────────────────────

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

" ── Utilities ──────────────────────────────────────────────────────────────

nnoremap <leader>F gg=G``
nnoremap <leader>wa :wa<CR>

nnoremap <silent> <Leader>= :exe "resize "          . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize "          . (winheight(0) * 2/3)<CR>

nnoremap <leader><leader> <c-^>

nnoremap <leader>W :%s/\s\+$//<CR>:let @/=''<CR>

nnoremap <leader>ev :edit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>:echo "vimrc reloaded"<CR>

nnoremap <leader>* :%s/\<<C-r><C-w>\>//g<Left><Left>

if has('clipboard')
    nnoremap <leader>cp :let @+ = expand("%:p")<CR>:echo "Copied: " . expand("%:p")<CR>
    nnoremap <leader>cf :let @+ = expand("%:t")<CR>:echo "Copied: " . expand("%:t")<CR>
endif

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

" ── QuickFix ────────────────────────────────────────────────────────────────

augroup ChopstickQF
    autocmd!
    autocmd QuickFixCmdPost [^l]* cwindow
    autocmd QuickFixCmdPost l*    lwindow
augroup END

nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [q :cprev<CR>
