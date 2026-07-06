" lint.vim — ALE async linting and format-on-save

function! s:FallbackLintMapSpecs() abort
    let l:specs = [
        \ {'mode': 'n', 'lhs': '[e', 'key': '[e', 'text': 'ALEPrevious'},
        \ {'mode': 'n', 'lhs': ']e', 'key': ']e', 'text': 'ALENext'},
        \ ]
    if get(g:, 'chopsticks_space_keymaps', 1)
        call add(l:specs, {
            \ 'mode': 'n', 'lhs': '<Space>xd',
            \ 'key': 'SPC xd', 'text': 'ALEDetail'})
        call add(l:specs, {
            \ 'mode': 'n', 'lhs': '<Space>uf',
            \ 'key': 'SPC uf', 'text': 'ale_fix_on_save'})
    else
        call add(l:specs, {
            \ 'mode': 'n', 'lhs': ',aD',
            \ 'key': ',aD', 'text': 'ALEDetail'})
        call add(l:specs, {
            \ 'mode': 'n', 'lhs': ',af',
            \ 'key': ',af', 'text': 'ale_fix_on_save'})
    endif
    return l:specs
endfunction

function! s:FallbackLintKeys() abort
    return get(g:, 'chopsticks_space_keymaps', 1)
        \ ? ['SPC xd', 'SPC uf', '[e', ']e']
        \ : [',aD', ',af', '[e', ']e']
endfunction

function! s:LintMapSpecs() abort
    return ChopsticksKeymapContractSpecsOr('lint_keymaps',
        \ s:FallbackLintMapSpecs())
endfunction

function! s:FormatLintKeys(keys) abort
    if len(a:keys) <= 2
        return join(a:keys, '/')
    endif
    return join(a:keys[0:1], '/') . '/' . join(a:keys[2:], ' ')
endfunction

function! s:LintKey() abort
    return s:FormatLintKeys(
        \ ChopsticksKeymapContractKeysOr('lint_keymaps',
        \ s:FallbackLintKeys()))
endfunction

function! s:MarkdownMode() abort
    let l:parts = []
    if get(g:, 'chopsticks_markdown_lint', 0)
        call add(l:parts, 'lint')
    endif
    if get(g:, 'chopsticks_markdown_format_on_save', 0)
        call add(l:parts, 'format')
    endif
    return empty(l:parts) ? 'quiet defaults' : join(l:parts, '+')
endfunction

function! s:AleStackItem() abort
    if !get(g:, 'chopsticks_enable_lint', 1)
        return ChopsticksInfoItem('ALE stack', 'off', 'lint disabled by profile',
            \ {'diagnostic': 0})
    endif
    if !ChopsticksPluginDeclared('ale')
        return ChopsticksInfoDiagnosticItem('ALE stack', 'missing',
            \ 'not declared by profile', 'ALE stack',
            \ 'check g:chopsticks_enable_lint and plugin profile', {
            \ 'detail': 'ALE is enabled but not declared by the active profile',
            \ })
    endif
    if ChopsticksCommandAvailable('ALEDetail')
        return ChopsticksInfoItem('ALE stack', 'ready', 'installed',
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('ALE stack', 'missing',
        \ 'command not loaded', 'ALE stack', ':PlugInstall and restart Vim', {
        \ 'detail': 'ALE is declared but :ALEDetail is not loaded',
        \ })
endfunction

function! s:LintKeymapsItem() abort
    if !get(g:, 'chopsticks_enable_lint', 1)
        return ChopsticksInfoItem('lint keymaps', 'off',
            \ 'lint disabled by profile',
            \ {'diagnostic': 0})
    endif

    let l:missing = ChopsticksKeymapMissingKeys(s:LintMapSpecs())
    if empty(l:missing)
        return ChopsticksInfoItem('lint keymaps', 'ready', s:LintKey(),
            \ {'diagnostic': 0})
    endif

    return ChopsticksInfoDiagnosticItem('lint keymaps', 'missing',
        \ 'missing: ' . join(l:missing, ', '), 'lint keymaps',
        \ ':ChopsticksKeymapAudit', {
        \ 'detail': 'missing lint maps: ' . join(l:missing, ', '),
        \ })
endfunction

function! s:FormatOnSaveItem() abort
    if !get(g:, 'chopsticks_enable_lint', 1)
        return ChopsticksInfoItem('format on save', 'off',
            \ 'lint disabled by profile', {'diagnostic': 0})
    endif
    if get(g:, 'ale_fix_on_save', 0)
        return ChopsticksInfoItem('format on save', 'ready', 'ON',
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoItem('format on save', 'off', 'disabled by user',
        \ {'diagnostic': 0})
endfunction

function! s:MarkdownLintItem() abort
    if !get(g:, 'chopsticks_enable_lint', 1)
        return ChopsticksInfoItem('markdown lint', 'off',
            \ 'lint disabled by profile', {'diagnostic': 0})
    endif

    let l:mode = s:MarkdownMode()
    if l:mode ==# 'quiet defaults'
        return ChopsticksInfoItem('markdown lint', 'off', l:mode,
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoItem('markdown lint', 'ready', l:mode,
        \ {'diagnostic': 0})
endfunction

function! ChopsticksLintInfo() abort
    return ChopsticksInfoSection('lint', {
        \ 'details': [
        \   ChopsticksInfoDetail('engine', get(g:, 'chopsticks_enable_lint', 1)
        \       ? 'ALE' : 'disabled'),
        \   ChopsticksInfoDetail('format',
        \       get(g:, 'ale_fix_on_save', 0) ? 'ON' : 'OFF'),
        \   ChopsticksInfoDetail('markdown', s:MarkdownMode()),
        \ ],
        \ 'items': [
        \   s:AleStackItem(),
        \   s:LintKeymapsItem(),
        \   s:FormatOnSaveItem(),
        \   s:MarkdownLintItem(),
        \ ],
        \ })
endfunction

if !g:chopsticks_enable_lint
    finish
endif

let g:ale_disable_lsp = 1

let s:ale_linters = {
\   'python':     ['flake8', 'pylint'],
\   'javascript': ['eslint'],
\   'typescript': ['eslint'],
\   'go':         ['staticcheck'],
\   'rust':       ['cargo'],
\   'c':          ['cc'],
\   'sh':         ['shellcheck'],
\   'yaml':       ['yamllint'],
\   'dockerfile': ['hadolint'],
\   'css':        ['stylelint'],
\   'scss':       ['stylelint'],
\   'sql':        ['sqlfluff'],
\}

if g:chopsticks_markdown_lint
    let s:ale_linters.markdown = ['markdownlint']
endif

let g:ale_linters = s:ale_linters

let s:ale_fixers = {
\   '*':          ['remove_trailing_lines', 'trim_whitespace'],
\   'python':     ['black', 'isort'],
\   'javascript': ['prettier', 'eslint'],
\   'typescript': ['prettier', 'eslint'],
\   'go':         ['goimports'],
\   'rust':       ['rustfmt'],
\   'c':          ['clang-format'],
\   'json':       ['prettier'],
\   'yaml':       ['prettier'],
\   'html':       ['prettier'],
\   'css':        ['prettier'],
\   'scss':       ['prettier'],
\   'less':       ['prettier'],
\   'sql':        ['sqlfluff'],
\}

if g:chopsticks_markdown_format_on_save
    let s:ale_fixers.markdown = ['prettier']
endif

let g:ale_fixers = s:ale_fixers

let g:ale_fix_on_save          = get(g:, 'ale_fix_on_save', 1)
let g:ale_python_isort_options = '--profile black'
let g:ale_sign_error           = 'X'
let g:ale_sign_warning         = '!'
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_enter        = 1
let g:ale_lint_delay           = 200
let g:ale_echo_delay           = 100
let g:ale_virtualtext_cursor   = get(g:, 'ale_virtualtext_cursor', 'disabled')

if ChopsticksPluginDeclared('ale')
    nnoremap <silent> [e :ALEPrevious<cr>
    nnoremap <silent> ]e :ALENext<cr>
    if g:chopsticks_space_keymaps
        nnoremap <silent> <leader>xd :ALEDetail<cr>
        nnoremap <silent> <leader>uf :let g:ale_fix_on_save = !g:ale_fix_on_save
            \ <bar> echo 'Format on save: ' . (g:ale_fix_on_save ? 'ON' : 'OFF')<cr>
    else
        nnoremap <silent> <leader>aD :ALEDetail<cr>
        nnoremap <silent> <leader>af :let g:ale_fix_on_save = !g:ale_fix_on_save
            \ <bar> echo 'Format on save: ' . (g:ale_fix_on_save ? 'ON' : 'OFF')<cr>
    endif
endif
