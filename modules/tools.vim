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

" ── Status Diagnostic (:ChopsticksStatus) ───────────────────────────────────

function! s:Check(name, cmd) abort
    return executable(a:cmd) ? '  OK  ' . a:name : '  --  ' . a:name . '  (missing: ' . a:cmd . ')'
endfunction

function! s:LspCheck(ft, server) abort
    if !exists('*lsp#get_server_names')
        return '  --  ' . a:ft . '  (vim-lsp not loaded)'
    endif
    let l:dir = expand('~/.local/share/vim-lsp-settings/servers/' . a:server)
    if isdirectory(l:dir)
        return '  OK  ' . a:ft . '  (' . a:server . ')'
    endif
    return '  --  ' . a:ft . '  (:LspInstallServer in a ' . a:ft . ' file)'
endfunction

function! s:ChopsticksStatus() abort
    let l:lines = []
    call add(l:lines, 'chopsticks status')
    call add(l:lines, repeat('─', 50))
    call add(l:lines, '')

    call add(l:lines, '── system tools ──')
    call add(l:lines, s:Check('fzf', 'fzf'))
    call add(l:lines, s:Check('ripgrep', 'rg'))
    call add(l:lines, s:Check('git', 'git'))
    call add(l:lines, s:Check('curl', 'curl'))
    call add(l:lines, s:Check('node', 'node'))
    call add(l:lines, s:Check('python3', 'python3'))
    call add(l:lines, s:Check('go', 'go'))
    call add(l:lines, '')

    call add(l:lines, '── lsp servers ──  (:LspInstallServer to install)')
    call add(l:lines, s:LspCheck('python', 'pylsp'))
    call add(l:lines, s:LspCheck('go', 'gopls'))
    call add(l:lines, s:LspCheck('rust', 'rust-analyzer'))
    call add(l:lines, s:LspCheck('typescript', 'typescript-language-server'))
    call add(l:lines, s:LspCheck('c/c++', 'clangd'))
    call add(l:lines, s:LspCheck('bash', 'bash-language-server'))
    call add(l:lines, s:LspCheck('html', 'vscode-html-language-server'))
    call add(l:lines, s:LspCheck('json', 'vscode-json-language-server'))
    call add(l:lines, s:LspCheck('yaml', 'yaml-language-server'))
    call add(l:lines, s:LspCheck('markdown', 'marksman'))
    call add(l:lines, s:LspCheck('sql', 'sqls'))
    call add(l:lines, '')

    call add(l:lines, '── linters ──')
    call add(l:lines, s:Check('flake8 (python)', 'flake8'))
    call add(l:lines, s:Check('pylint (python)', 'pylint'))
    call add(l:lines, s:Check('eslint (js/ts)', 'eslint'))
    call add(l:lines, s:Check('staticcheck (go)', 'staticcheck'))
    call add(l:lines, s:Check('shellcheck (sh)', 'shellcheck'))
    call add(l:lines, s:Check('yamllint (yaml)', 'yamllint'))
    call add(l:lines, s:Check('hadolint (docker)', 'hadolint'))
    call add(l:lines, s:Check('markdownlint (md)', 'markdownlint'))
    call add(l:lines, '')

    call add(l:lines, '── formatters ──  (format-on-save is ON)')
    call add(l:lines, s:Check('black (python)', 'black'))
    call add(l:lines, s:Check('isort (python)', 'isort'))
    call add(l:lines, s:Check('prettier (js/ts/json/md)', 'prettier'))
    call add(l:lines, s:Check('goimports (go)', 'goimports'))
    call add(l:lines, s:Check('rustfmt (rust)', 'rustfmt'))
    call add(l:lines, s:Check('clang-format (c)', 'clang-format'))
    call add(l:lines, '')

    let l:ok = len(filter(copy(l:lines), 'v:val =~# "  OK  "'))
    let l:miss = len(filter(copy(l:lines), 'v:val =~# "  --  "'))
    call add(l:lines, repeat('─', 50))
    call add(l:lines, '  ' . l:ok . ' ready, ' . l:miss . ' missing')
    call add(l:lines, '')
    call add(l:lines, '  Install missing tools with ./install.sh')
    call add(l:lines, '  Install LSP servers with :LspInstallServer')

    let l:name = '__ChopsticksStatus__'
    if bufwinnr(l:name) > 0
        execute bufwinnr(l:name) . 'wincmd w | bd'
    endif
    execute 'botright new ' . l:name
    resize 45
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nowrap nonumber norelativenumber signcolumn=no
    call setline(1, l:lines)
    setlocal nomodifiable readonly
    nnoremap <buffer> <silent> q :bd<CR>
endfunction
command! ChopsticksStatus call s:ChopsticksStatus()

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
        \ '  :ChopsticksStatus  health',
        \ ])
    setlocal nomodifiable readonly
    nnoremap <buffer> <silent> q :bd<CR>
    nnoremap <buffer> <silent> <leader>? :bd<CR>
endfunction
nnoremap <silent> <leader>? :call <SID>CheatSheet()<CR>
