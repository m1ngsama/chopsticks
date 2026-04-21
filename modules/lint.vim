" lint.vim — ALE async linting and format-on-save

let g:ale_disable_lsp = 1

let g:ale_linters = {
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
\   'markdown':   ['markdownlint'],
\   'sql':        ['sqlfluff'],
\}

let g:ale_fixers = {
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
\   'markdown':   ['prettier'],
\   'sql':        ['sqlfluff'],
\}

let g:ale_fix_on_save          = 1
let g:ale_python_isort_options = '--profile black'
let g:ale_sign_error           = 'X'
let g:ale_sign_warning         = '!'
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_enter        = 1
let g:ale_lint_delay           = 200
let g:ale_echo_delay           = 100

if exists('g:plugs["ale"]')
    nnoremap <silent> [e :ALEPrevious<cr>
    nnoremap <silent> ]e :ALENext<cr>
    nnoremap <silent> <leader>aD :ALEDetail<cr>
endif
