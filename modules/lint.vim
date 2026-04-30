" lint.vim — ALE async linting and format-on-save

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

let g:ale_fix_on_save          = 1
let g:ale_python_isort_options = '--profile black'
let g:ale_sign_error           = 'X'
let g:ale_sign_warning         = '!'
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_enter        = 1
let g:ale_lint_delay           = 200
let g:ale_echo_delay           = 100
let g:ale_virtualtext_cursor   = get(g:, 'ale_virtualtext_cursor', 'disabled')

if exists('g:plugs["ale"]')
    nnoremap <silent> [e :ALEPrevious<cr>
    nnoremap <silent> ]e :ALENext<cr>
    nnoremap <silent> <leader>aD :ALEDetail<cr>
    nnoremap <silent> <leader>af :let g:ale_fix_on_save = !g:ale_fix_on_save
        \ <bar> echo 'Format on save: ' . (g:ale_fix_on_save ? 'ON' : 'OFF')<cr>
endif
