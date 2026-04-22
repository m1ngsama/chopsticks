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

" ── Cheat Sheet (,?) ────────────────────────────────────────────────────────

function! s:CheatSheet() abort
    let l:name = '__ChopsticksCheatSheet__'
    if bufwinnr(l:name) > 0
        execute bufwinnr(l:name) . 'wincmd w | bd'
        return
    endif
    execute 'vertical botright new ' . l:name
    vertical resize 42
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nowrap nonumber norelativenumber signcolumn=no
    setlocal winfixwidth
    call setline(1, [
        \ '  chopsticks         ,? close',
        \ '  ─────────────────────────────',
        \ '',
        \ '  ── files ──────────────────',
        \ '  Ctrl+p    find file',
        \ '  ,b        buffers',
        \ '  ,rg       grep project',
        \ '  ,rG       grep word',
        \ '  ,e        sidebar (cwd)',
        \ '  ,E        sidebar (file dir)',
        \ '  ,,        last file',
        \ '  ,fh       recent files',
        \ '  ,fl       lines in buffer',
        \ '  ,fc       commands',
        \ '  ,fm       marks',
        \ '',
        \ '  ── code ──────────────────',
        \ '  gd        definition',
        \ '  gy        type definition',
        \ '  gi        implementation',
        \ '  gr        references',
        \ '  K         hover docs',
        \ '  ,rn       rename',
        \ '  ,ca       code action',
        \ '  ,f        format',
        \ '  ,o        outline',
        \ '  ,cr       run file',
        \ '  ,mp       markdown preview',
        \ '  ,mt       table of contents',
        \ '  [g ]g     LSP diagnostics',
        \ '  [e ]e     ALE errors',
        \ '  :LspInstallServer  setup LSP',
        \ '',
        \ '  ── edit ──────────────────',
        \ '  gc        comment',
        \ '  s+2ch     easymotion jump',
        \ '  cs"''      surround',
        \ '  ,u        undo tree',
        \ '  ,y        clipboard yank',
        \ '  Alt+j/k   move line',
        \ '  ,*        replace word',
        \ '  ,F        re-indent file',
        \ '  ,W        strip whitespace',
        \ '',
        \ '  ── git ───────────────────',
        \ '  ,gs       status',
        \ '  ,gd       diff',
        \ '  ,gb       blame',
        \ '  ,gc       commit',
        \ '  ,gp       push',
        \ '  ,gl       pull',
        \ '  [x ]x     conflict markers',
        \ '',
        \ '  ── windows ───────────────',
        \ '  Ctrl+hjkl navigate splits',
        \ '  ,h ,l     prev / next buf',
        \ '  ,bd       close buffer',
        \ '  ,z        maximize toggle',
        \ '  ,= ,-     resize height',
        \ '  ,tv ,th   terminal v / h',
        \ '  ]q [q     next / prev qf',
        \ '  ,qo ,qc   open / close qf',
        \ '',
        \ '  ── toggle ────────────────',
        \ '  F2        paste mode',
        \ '  F3        line numbers',
        \ '  F4        relative numbers',
        \ '  F6        invisible chars',
        \ '  ,ss       spell check',
        \ '',
        \ '  ── survival ──────────────',
        \ '  ,w        save',
        \ '  ,q        quit',
        \ '  ,x        save + quit',
        \ '  Ctrl+s    save (any mode)',
        \ '  jk        exit insert',
        \ '  :w!!      sudo save',
        \ '  ,ev       edit vimrc',
        \ '  ,sv       reload vimrc',
        \ ])
    setlocal nomodifiable readonly
    nnoremap <buffer> <silent> q :bd<CR>
    nnoremap <buffer> <silent> <leader>? :bd<CR>
endfunction
nnoremap <silent> <leader>? :call <SID>CheatSheet()<CR>
