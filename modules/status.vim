" status.vim — health diagnostics

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

function! s:BetaLogPath() abort
    let l:configured = get(g:, 'chopsticks_beta_log', '')
    if !empty(l:configured)
        return expand(l:configured)
    endif

    let l:xdg = !empty($XDG_CONFIG_HOME) && $XDG_CONFIG_HOME =~# '^/'
        \ ? $XDG_CONFIG_HOME
        \ : '~/.config'
    return expand(l:xdg . '/chopsticks-beta.md')
endfunction

function! s:ChopsticksStatus() abort
    let l:lines = []
    call add(l:lines, 'chopsticks status')
    call add(l:lines, repeat('─', 50))
    call add(l:lines, '')

    if !empty(get(g:, 'chopsticks_beta_label', ''))
        call add(l:lines, '── beta ──')
        call add(l:lines, '  candidate  ' . g:chopsticks_beta_label)
        call add(l:lines, '  keymap     ' . (get(g:, 'chopsticks_space_keymaps', 0) ? 'space' : 'classic'))
        call add(l:lines, '  log        ' . s:BetaLogPath())
        call add(l:lines, '  commands   :ChopsticksBeta  :ChopsticksBetaLog')
        call add(l:lines, '             :ChopsticksBetaSession')
        call add(l:lines, '')
    endif

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
