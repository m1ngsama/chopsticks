" languages.vim — vim-go, vim-markdown, per-filetype autocmds

" ── vim-markdown ───────────────────────────────────────────────────────────

let g:vim_markdown_conceal             = 1
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_folding_disabled    = 0
let g:vim_markdown_folding_level       = 2
let g:vim_markdown_frontmatter        = 1
let g:vim_markdown_toml_frontmatter   = 1
let g:vim_markdown_json_frontmatter   = 1
let g:vim_markdown_follow_anchor      = 1
let g:vim_markdown_new_list_item_indent = 2
let g:vim_markdown_strikethrough      = 1

if exists('g:plugs["vim-markdown"]')
    nnoremap <leader>mt :Toc<CR>
endif

if has('macunix')
    let g:previm_open_cmd = '/usr/bin/open'
elseif executable('xdg-open')
    let g:previm_open_cmd = 'xdg-open'
endif
let g:previm_enable_realtime = 1
if exists('g:plugs["previm"]')
    nnoremap <leader>mp :PrevimOpen<CR>
endif

" ── vim-go (syntax only — vim-lsp handles intelligence) ─────────────────────

let g:go_gopls_enabled            = 0
let g:go_code_completion_enabled  = 0
let g:go_fmt_autosave             = 0
let g:go_imports_autosave         = 0
let g:go_highlight_types          = 1
let g:go_highlight_fields         = 1
let g:go_highlight_functions      = 1
let g:go_highlight_function_calls = 1

" ── Filetype Detection ──────────────────────────────────────────────────────

augroup ChopstickFiletype
    autocmd!

    autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

    autocmd FileType python
        \ setlocal expandtab shiftwidth=4 tabstop=4 textwidth=88
    autocmd FileType javascript,typescript
        \ setlocal expandtab shiftwidth=2 tabstop=2 textwidth=100
    autocmd FileType go
        \ setlocal noexpandtab shiftwidth=4 tabstop=4 textwidth=120
    autocmd FileType rust
        \ setlocal expandtab shiftwidth=4 tabstop=4 textwidth=100
    autocmd FileType c,cpp
        \ setlocal expandtab shiftwidth=4 tabstop=4 textwidth=80
    autocmd FileType html,css
        \ setlocal expandtab shiftwidth=2 tabstop=2
    autocmd FileType yaml
        \ setlocal expandtab shiftwidth=2 tabstop=2
    autocmd FileType markdown
        \ setlocal wrap linebreak spell textwidth=0 conceallevel=2
    autocmd FileType sh
        \ setlocal expandtab shiftwidth=2 tabstop=2 textwidth=80
    autocmd FileType make
        \ setlocal noexpandtab shiftwidth=8 tabstop=8
    autocmd FileType json
        \ setlocal expandtab shiftwidth=2 tabstop=2
    autocmd FileType dockerfile
        \ setlocal expandtab shiftwidth=2 tabstop=2
augroup END
