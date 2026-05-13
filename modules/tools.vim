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
vnoremap <leader>F =
nnoremap <leader>wa :wa<CR>

nnoremap <silent> <Leader>= :exe "resize "          . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize "          . (winheight(0) * 2/3)<CR>

nnoremap <leader><leader> <c-^>

nnoremap <leader>W :%s/\s\+$//<CR>:let @/=''<CR>
vnoremap <leader>W :s/\s\+$//<CR>:let @/=''<CR>gv

nnoremap <leader>ev :edit $MYVIMRC<CR>
nnoremap <leader>sv :unlet! g:chopsticks_loaded<CR>:execute 'source ' . fnameescape($MYVIMRC)<CR>:echo "vimrc reloaded"<CR>

nnoremap <leader>* :%s/\<<C-r><C-w>\>//g<Left><Left>
vnoremap <leader>* :s///g<Left><Left><Left>

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

let g:LargeFile = get(g:, 'LargeFile', 1024 * 1024 * 10)
let s:tty_large  = g:is_tty ? 512000 : g:LargeFile

function! s:ApplyLargeFileSettings() abort
    if get(b:, 'chopsticks_large_file', 0)
        setlocal bufhidden=unload undolevels=-1 noswapfile
        let b:ale_enabled = 0
        if &l:syntax !=# ''
            setlocal syntax=
        endif
    elseif get(b:, 'chopsticks_tty_large_file', 0)
        if &l:syntax !=# ''
            setlocal syntax=
        endif
    endif
endfunction

function! s:MarkLargeFile(file) abort
    if empty(a:file)
        return
    endif

    let l:fsize = getfsize(a:file)
    if l:fsize > g:LargeFile || l:fsize == -2
        let b:chopsticks_large_file = 1
    elseif g:is_tty && l:fsize > s:tty_large
        let b:chopsticks_tty_large_file = 1
    endif
    call s:ApplyLargeFileSettings()
endfunction

augroup ChopstickLargeFile
    autocmd!
    autocmd BufReadPre * call s:MarkLargeFile(expand('<afile>'))
    autocmd BufReadPost,FileType,Syntax * call s:ApplyLargeFileSettings()
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
    elseif l:ft ==# 'c'
        let l:out_path = tempname()
        let l:out = shellescape(l:out_path)
        execute '!gcc -o ' . l:out . ' ' . l:file . ' && ' . l:out
        call delete(l:out_path)
    elseif l:ft ==# 'lua'        | execute '!lua '      . l:file
    elseif l:ft ==# 'ruby'       | execute '!ruby '     . l:file
    elseif l:ft ==# 'perl'       | execute '!perl '     . l:file
    else | echo 'No runner for filetype: ' . l:ft
    endif
endfunction
nnoremap <leader>cr :call <SID>RunFile()<CR>

" ── Sudo Save ───────────────────────────────────────────────────────────────

if get(g:, 'chopsticks_enable_sudo_save_bang', 0)
    cnoremap w!! w !sudo tee > /dev/null %
endif

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

function! s:Off(name, reason) abort
    return '  off ' . a:name . '  (' . a:reason . ')'
endfunction

function! s:PlugDir(name) abort
    if !exists('g:plugs') || !has_key(g:plugs, a:name)
        return ''
    endif
    return fnamemodify(get(g:plugs[a:name], 'dir', ''), ':p')
endfunction

function! s:PlugInstalled(name) abort
    let l:dir = s:PlugDir(a:name)
    return !empty(l:dir) && isdirectory(l:dir)
endfunction

function! s:LspStackIssue() abort
    if !get(g:, 'chopsticks_enable_lsp', 1)
        return 'LSP disabled by profile'
    endif
    if empty(s:PlugDir('vim-lsp'))
        return 'vim-lsp not declared by this profile'
    endif
    if !s:PlugInstalled('vim-lsp')
        return 'vim-lsp not installed; run :PlugInstall'
    endif
    if empty(s:PlugDir('vim-lsp-settings'))
        return 'vim-lsp-settings not declared by this profile'
    endif
    if !s:PlugInstalled('vim-lsp-settings')
        return 'vim-lsp-settings not installed; run :PlugInstall'
    endif
    return ''
endfunction

function! s:LspStackCheck() abort
    let l:issue = s:LspStackIssue()
    if l:issue ==# 'LSP disabled by profile'
        return s:Off('vim-lsp stack', l:issue)
    endif
    if !empty(l:issue)
        return '  --  vim-lsp stack  (' . l:issue . ')'
    endif
    if exists(':LspStatus') == 2 || exists(':LspInstallServer') == 2
        return '  OK  vim-lsp stack  (installed)'
    endif
    return '  OK  vim-lsp stack  (installed; not loaded yet)'
endfunction

function! s:LspCheck(ft, server) abort
    let l:issue = s:LspStackIssue()
    if l:issue ==# 'LSP disabled by profile'
        return s:Off(a:ft, l:issue)
    endif
    if !empty(l:issue)
        return '  --  ' . a:ft . '  (' . l:issue . ')'
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
    call add(l:lines, s:LspStackCheck())
    if get(g:, 'chopsticks_enable_lsp', 1)
        call add(l:lines, '  LSP actions are buffer-local and start after a server attaches.')
        call add(l:lines, '  Missing one? Open that filetype and run :LspInstallServer once.')
    endif
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
    if get(g:, 'chopsticks_enable_lint', 1)
        call add(l:lines, s:Check('flake8 (python)', 'flake8'))
        call add(l:lines, s:Check('pylint (python)', 'pylint'))
        call add(l:lines, s:Check('eslint (js/ts)', 'eslint'))
        call add(l:lines, s:Check('staticcheck (go)', 'staticcheck'))
        call add(l:lines, s:Check('shellcheck (sh)', 'shellcheck'))
        call add(l:lines, s:Check('yamllint (yaml)', 'yamllint'))
        call add(l:lines, s:Check('hadolint (docker)', 'hadolint'))
        if get(g:, 'chopsticks_markdown_lint', 0)
            call add(l:lines, s:Check('markdownlint (md)', 'markdownlint'))
        else
            call add(l:lines, s:Off('markdownlint (md)', 'disabled by default'))
        endif
    else
        call add(l:lines, s:Off('ALE linters', 'lint disabled by profile'))
    endif
    call add(l:lines, '')

    call add(l:lines, '── formatters ──  (format-on-save is ' . (get(g:, 'ale_fix_on_save', 0) ? 'ON' : 'OFF') . ')')
    if get(g:, 'chopsticks_enable_lint', 1)
        call add(l:lines, s:Check('black (python)', 'black'))
        call add(l:lines, s:Check('isort (python)', 'isort'))
        call add(l:lines, s:Check('prettier (js/ts/json)', 'prettier'))
        if get(g:, 'chopsticks_markdown_format_on_save', 0)
            call add(l:lines, s:Check('prettier (md)', 'prettier'))
        else
            call add(l:lines, s:Off('prettier (md)', 'disabled by default'))
        endif
        call add(l:lines, s:Check('goimports (go)', 'goimports'))
        call add(l:lines, s:Check('rustfmt (rust)', 'rustfmt'))
        call add(l:lines, s:Check('clang-format (c)', 'clang-format'))
    else
        call add(l:lines, s:Off('ALE formatters', 'lint disabled by profile'))
    endif
    call add(l:lines, '')

    let l:ok = len(filter(copy(l:lines), 'v:val =~# "  OK  "'))
    let l:miss = len(filter(copy(l:lines), 'v:val =~# "  --  "'))
    call add(l:lines, repeat('─', 50))
    call add(l:lines, '  ' . l:ok . ' ready, ' . l:miss . ' missing')
    call add(l:lines, '')
    call add(l:lines, '  Install missing tools with ./install.sh')
    if get(g:, 'chopsticks_enable_lsp', 1)
        call add(l:lines, '  Install LSP servers with :LspInstallServer')
    endif

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

    let l:has_lsp = get(g:, 'chopsticks_enable_lsp', 1)
    let l:has_lint = get(g:, 'chopsticks_enable_lint', 1)
    let l:has_undotree = exists('g:plugs["undotree"]')
    let l:has_previm = exists('g:plugs["previm"]')

    let l:lines = [
        \ '  chopsticks         ,? close',
        \ '  ─────────────────────────────',
        \ '',
        \ '  ── files ──────────────────',
        \ '  ,ff       files',
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
        \ ]

    if l:has_lsp
        call extend(l:lines, [
            \ '  ,dd       definition',
            \ '  ,dt       type definition',
            \ '  ,di       implementation',
            \ '  ,dr       references',
            \ '  ,dk       hover docs',
            \ '  ,rn       rename',
            \ '  ,ca       code action',
            \ '  ,f        format',
            \ '  ,o        outline',
            \ '  ,dp ,dn   LSP diagnostics',
            \ '  :LspInstallServer  setup LSP',
            \ '  :ChopsticksStatus   check LSP setup',
            \ ])
    endif

    call add(l:lines, '  ,cr       run file')
    if l:has_previm
        call add(l:lines, '  ,mp       markdown preview')
    endif
    call add(l:lines, '  ,mt       table of contents')

    if l:has_lint
        call extend(l:lines, [
            \ '  [e ]e     ALE errors',
            \ '  ,af       format on save',
            \ ])
    endif

    call extend(l:lines, [
        \ '',
        \ '  ── edit ──────────────────',
        \ '  gc        comment',
        \ '  ,S+2ch    easymotion jump',
        \ '  cs"''      surround',
        \ ])

    if l:has_undotree
        call add(l:lines, '  ,u        undo tree')
    endif

    call extend(l:lines, [
        \ '  ,y ,p     clipboard y/p  (v)',
        \ '  Alt+j/k   move line      (v)',
        \ '  ,*        replace word    (v)',
        \ '  ,F        re-indent       (v)',
        \ '  ,W        strip trailing  (v)',
        \ '',
        \ '  ── git ───────────────────',
        \ '  ,gs       status',
        \ '  ,gd       diff',
        \ '  ,gb       blame',
        \ '  ,gc       commit',
        \ '  ,gp       push',
        \ '  ,gl       pull',
        \ '  ,gL       log graph',
        \ '  ,gC       FZF commits',
        \ '  [x ]x     conflict markers',
        \ '',
        \ '  ── windows ───────────────',
        \ '  <C-w>hjkl navigate splits',
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
        \ '  Esc       exit insert',
        \ '  ,ev       edit vimrc',
        \ '  ,sv       reload vimrc',
        \ '  :ChopsticksStatus  health',
        \ ])

    execute 'vertical botright new ' . l:name
    vertical resize 42
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nowrap nonumber norelativenumber signcolumn=no
    setlocal winfixwidth
    call setline(1, l:lines)
    setlocal nomodifiable readonly
    nnoremap <buffer> <silent> q :bd<CR>
    nnoremap <buffer> <silent> <leader>? :bd<CR>
endfunction
nnoremap <silent> <leader>? :call <SID>CheatSheet()<CR>
