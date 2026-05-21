" languages.vim — vim-go, vim-markdown, per-filetype autocmds

" ── vim-markdown ───────────────────────────────────────────────────────────

let g:vim_markdown_conceal             = get(g:, 'vim_markdown_conceal',
    \ g:chopsticks_markdown_conceal)
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_folding_disabled    = get(g:, 'vim_markdown_folding_disabled', 1)
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
let g:previm_enable_realtime = get(g:, 'previm_enable_realtime', 0)
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

function! s:MarkdownDefaults() abort
    setlocal wrap linebreak textwidth=0 colorcolumn=0 signcolumn=no
    let &l:conceallevel = get(g:, 'chopsticks_markdown_conceal', 0) ? 2 : 0

    if get(g:, 'chopsticks_markdown_spell', 0)
        setlocal spell
    else
        setlocal nospell
    endif

    if !get(g:, 'chopsticks_markdown_lint', 0)
        \ && !get(g:, 'chopsticks_markdown_format_on_save', 0)
        let b:ale_enabled = 0
    endif
endfunction

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
    autocmd FileType markdown call s:MarkdownDefaults()
    autocmd FileType sh
        \ setlocal expandtab shiftwidth=2 tabstop=2 textwidth=80
    autocmd FileType make
        \ setlocal noexpandtab shiftwidth=8 tabstop=8
    autocmd FileType json
        \ setlocal expandtab shiftwidth=2 tabstop=2
    autocmd FileType dockerfile
        \ setlocal expandtab shiftwidth=2 tabstop=2
augroup END
