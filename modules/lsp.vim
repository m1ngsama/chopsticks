" lsp.vim — vim-lsp settings, asyncomplete, LSP buffer keymaps

if !g:chopsticks_enable_lsp
    finish
endif

let g:lsp_settings_lazyload = 1

let g:lsp_settings_filetype_python     = ['pylsp']
let g:lsp_settings_filetype_go         = ['gopls']
let g:lsp_settings_filetype_rust       = ['rust-analyzer']
let g:lsp_settings_filetype_typescript = ['typescript-language-server']
let g:lsp_settings_filetype_javascript = ['typescript-language-server']
let g:lsp_settings_filetype_c          = ['clangd']
let g:lsp_settings_filetype_sh         = ['bash-language-server']
let g:lsp_settings_filetype_html       = ['vscode-html-language-server']
let g:lsp_settings_filetype_css        = ['vscode-css-language-server']
let g:lsp_settings_filetype_scss       = ['vscode-css-language-server']
let g:lsp_settings_filetype_json       = ['vscode-json-language-server']
let g:lsp_settings_filetype_yaml       = ['yaml-language-server']
let g:lsp_settings_filetype_sql        = ['sqls']

if g:chopsticks_markdown_lsp
    let g:lsp_settings_filetype_markdown = ['marksman']
endif

let g:lsp_diagnostics_virtual_text_enabled = g:chopsticks_lsp_virtual_text
let g:lsp_diagnostics_virtual_text_delay   = 200
let g:lsp_diagnostics_highlights_enabled   = !g:is_tty
let g:lsp_document_highlight_enabled       = !g:is_tty
let g:lsp_document_highlight_delay         = 200
let g:lsp_signs_enabled                    = 1
let g:lsp_diagnostics_echo_cursor          = 1
let g:lsp_diagnostics_echo_delay           = 100
let g:lsp_completion_documentation_enabled = 1

let g:lsp_signs_error       = {'text': 'X'}
let g:lsp_signs_warning     = {'text': '!'}
let g:lsp_signs_information = {'text': 'i'}
let g:lsp_signs_hint        = {'text': '>'}

" ── Completion ──────────────────────────────────────────────────────────────

if has('patch-8.1.1517')
    set completeopt=menuone,noinsert,noselect,popup
else
    set completeopt=menuone,noinsert,noselect
endif
set pumheight=15
let g:asyncomplete_auto_popup       = 1
let g:asyncomplete_auto_completeopt = 0
let g:asyncomplete_popup_delay      = 50

inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>    pumvisible() ? asyncomplete#close_popup() : "\<CR>"

" ── Buffer Keymaps ──────────────────────────────────────────────────────────

function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    if !g:is_tty && &filetype !=# 'markdown'
        setlocal signcolumn=yes
    endif

    nmap <buffer> <leader>dd  <plug>(lsp-definition)
    nmap <buffer> <leader>dt  <plug>(lsp-type-definition)
    nmap <buffer> <leader>di  <plug>(lsp-implementation)
    nmap <buffer> <leader>dr  <plug>(lsp-references)
    nmap <buffer> <leader>dp  <plug>(lsp-previous-diagnostic)
    nmap <buffer> <leader>dn  <plug>(lsp-next-diagnostic)

    nmap <buffer> <leader>dk  <plug>(lsp-hover)

    nmap <buffer> <leader>rn  <plug>(lsp-rename)
    nmap <buffer> <leader>ca  <plug>(lsp-code-action)
    nmap <buffer> <leader>f   <plug>(lsp-document-format)
    xmap <buffer> <leader>f   <plug>(lsp-document-range-format)

    nmap <buffer> <leader>o   <plug>(lsp-document-symbol-search)
    nmap <buffer> <leader>ws  <plug>(lsp-workspace-symbol-search)
    nmap <buffer> <leader>cD  <plug>(lsp-document-diagnostics)
endfunction

augroup lsp_install
    autocmd!
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END
