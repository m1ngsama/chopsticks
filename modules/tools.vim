" tools.vim — external toolchain diagnostics

function! s:DisplayTool(tool) abort
    let l:label = get(a:tool, 'label', get(a:tool, 'cmd', 'tool'))
    let l:cmd = get(a:tool, 'cmd', l:label)
    let l:state = get(a:tool, 'state', '')
    let l:action = empty(l:cmd) ? '' : 'install: ' . l:cmd
    let l:opts = {
        \ 'cmd': l:cmd,
        \ 'optional': get(a:tool, 'optional', 0),
        \ 'available': get(a:tool, 'available', 0),
        \ 'enabled': get(a:tool, 'enabled', 1),
        \ 'detail': get(a:tool, 'reason', ''),
        \ 'action': l:action,
        \ }
    if l:state ==# 'off' || !get(a:tool, 'enabled', 1)
        let l:opts.diagnostic = 0
        return ChopsticksInfoItem(l:label, 'off',
            \ get(a:tool, 'reason', 'disabled'), l:opts)
    endif
    if l:state ==# 'ready' || get(a:tool, 'available', 0)
        let l:opts.diagnostic = 0
        return ChopsticksInfoItem(l:label, 'ready', '', l:opts)
    endif
    if l:state ==# 'optional' || get(a:tool, 'optional', 0)
        let l:opts.severity = 'optional'
        let l:opts.detail = get(a:tool, 'reason', 'missing optional tool')
        return ChopsticksInfoDiagnosticItem(l:label, 'optional',
            \ l:action, l:label, l:action, l:opts)
    endif
    let l:opts.severity = 'setup'
    let l:opts.detail = get(a:tool, 'reason', 'missing tool')
    return ChopsticksInfoDiagnosticItem(l:label, 'missing',
        \ 'missing: ' . l:cmd, l:label, l:action, l:opts)
endfunction

function! s:ToolItems(tools) abort
    let l:items = []
    for l:tool in a:tools
        call add(l:items, s:DisplayTool(l:tool))
    endfor
    return l:items
endfunction

function! s:Section(title, items, suffix, severity) abort
    return ChopsticksInfoSection(a:title, {
        \ 'suffix': a:suffix,
        \ 'severity': a:severity,
        \ 'items': s:ToolItems(a:items),
        \ })
endfunction

function! ChopsticksToolchainInfo() abort
    let l:lint_enabled = get(g:, 'chopsticks_enable_lint', 1)
    let l:markdown_lint = get(g:, 'chopsticks_markdown_lint', 0)
    let l:markdown_format = get(g:, 'chopsticks_markdown_format_on_save', 0)
    let l:format_on_save = get(g:, 'ale_fix_on_save', 0)

    let l:linters = []
    let l:formatters = []
    if l:lint_enabled
        let l:linters = [
            \ ChopsticksToolState('flake8 (python)', 'flake8', 1, 'optional Python lint'),
            \ ChopsticksToolState('pylint (python)', 'pylint', 1, 'optional Python lint'),
            \ ChopsticksToolState('eslint (js/ts)', 'eslint', 1, 'optional JS/TS lint'),
            \ ChopsticksToolState('staticcheck (go)', 'staticcheck', 1, 'optional Go lint'),
            \ ChopsticksToolState('shellcheck (sh)', 'shellcheck', 1, 'optional shell lint'),
            \ ChopsticksToolState('yamllint (yaml)', 'yamllint', 1, 'optional YAML lint'),
            \ ChopsticksToolState('hadolint (docker)', 'hadolint', 1, 'optional Docker lint'),
            \ ]
        if l:markdown_lint
            call add(l:linters,
                \ ChopsticksToolState('markdownlint (md)', 'markdownlint', 1,
                \ 'optional Markdown lint'))
        else
            call add(l:linters,
                \ ChopsticksToolOffState('markdownlint (md)', 'disabled by default'))
        endif

        let l:formatters = [
            \ ChopsticksToolState('black (python)', 'black', 1, 'optional Python format'),
            \ ChopsticksToolState('isort (python)', 'isort', 1, 'optional Python format'),
            \ ChopsticksToolState('prettier (js/ts/json)', 'prettier', 1, 'optional JS/TS format'),
            \ ChopsticksToolState('goimports (go)', 'goimports', 1, 'optional Go format'),
            \ ChopsticksToolState('rustfmt (rust)', 'rustfmt', 1, 'optional Rust format'),
            \ ChopsticksToolState('clang-format (c)', 'clang-format', 1, 'optional C format'),
            \ ]
        if l:markdown_format
            call add(l:formatters,
                \ ChopsticksToolState('prettier (md)', 'prettier', 1,
                \ 'optional Markdown format'))
        else
            call add(l:formatters,
                \ ChopsticksToolOffState('prettier (md)', 'disabled by default'))
        endif
    else
        let l:linters = [ChopsticksToolOffState('ALE linters', 'lint disabled by profile')]
        let l:formatters = [ChopsticksToolOffState('ALE formatters', 'lint disabled by profile')]
    endif
    let l:project = [
        \ ChopsticksToolState('fzf', 'fzf', 0, 'fuzzy file/buffer picker'),
        \ ChopsticksToolState('ripgrep', 'rg', 0, 'project grep'),
        \ ChopsticksToolState('git', 'git', 0, 'git integration'),
        \ ChopsticksToolState('curl', 'curl', 0, 'vim-plug bootstrap'),
        \ ]
    let l:language = [
        \ ChopsticksToolState('node', 'node', 1, 'optional JS/TS tools'),
        \ ChopsticksToolState('python3', 'python3', 1, 'optional Python tools'),
        \ ChopsticksToolState('go', 'go', 1, 'optional Go tools'),
        \ ]

    return ChopsticksInfoSection('toolchain', {
        \ 'project': l:project,
        \ 'language': l:language,
        \ 'linters': l:linters,
        \ 'formatters': l:formatters,
        \ 'lint_enabled': l:lint_enabled,
        \ 'markdown_lint': l:markdown_lint,
        \ 'markdown_format': l:markdown_format,
        \ 'format_on_save': l:format_on_save,
        \ 'footers': [
        \   'Install optional tools with ./install.sh --install-tools',
        \ ],
        \ 'sections': [
        \   s:Section('project loop tools', l:project, '', 'setup'),
        \   s:Section('optional language runtimes', l:language, '', 'optional'),
        \   s:Section('linters', l:linters, '', 'optional'),
        \   s:Section('formatters', l:formatters,
        \       'format-on-save is ' . (l:format_on_save ? 'ON' : 'OFF'),
        \       'optional'),
        \ ],
        \ })
endfunction
