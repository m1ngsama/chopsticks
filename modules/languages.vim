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

function! s:MarkdownKeymaps() abort
    if ChopsticksPluginDeclared('vim-markdown')
        nnoremap <buffer> <localleader>mt :Toc<CR>
    endif
    if ChopsticksPluginDeclared('previm')
        nnoremap <buffer> <localleader>mp :PrevimOpen<CR>
    endif
endfunction

if ChopsticksPluginDeclared('vim-markdown') && !g:chopsticks_space_keymaps
    nnoremap <leader>mt :Toc<CR>
endif

if ChopsticksRuntimeFeatureAvailable('mac')
    let g:previm_open_cmd = '/usr/bin/open'
elseif ChopsticksToolAvailable('xdg-open')
    let g:previm_open_cmd = 'xdg-open'
endif
let g:previm_enable_realtime = get(g:, 'previm_enable_realtime', 0)
if ChopsticksPluginDeclared('previm') && !g:chopsticks_space_keymaps
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
    autocmd FileType markdown if g:chopsticks_space_keymaps | call s:MarkdownKeymaps() | endif
    autocmd FileType sh
        \ setlocal expandtab shiftwidth=2 tabstop=2 textwidth=80
    autocmd FileType make
        \ setlocal noexpandtab shiftwidth=8 tabstop=8
    autocmd FileType json
        \ setlocal expandtab shiftwidth=2 tabstop=2
    autocmd FileType dockerfile
        \ setlocal expandtab shiftwidth=2 tabstop=2
augroup END

function! s:MarkdownWritingMode() abort
    let l:parts = []
    if get(g:, 'chopsticks_markdown_spell', 0)
        call add(l:parts, 'spell')
    endif
    if get(g:, 'chopsticks_markdown_conceal', 0)
        call add(l:parts, 'conceal')
    endif
    return empty(l:parts) ? 'quiet defaults' : join(l:parts, '+')
endfunction

function! s:MarkdownSyntaxItem() abort
    if !ChopsticksPluginDeclared('vim-markdown')
        return ChopsticksInfoDiagnosticItem('markdown syntax', 'missing',
            \ 'vim-markdown not declared', 'markdown syntax',
            \ 'check plugin profile', {
            \ 'severity': 'setup',
            \ 'detail': 'vim-markdown is not declared by the active profile',
            \ })
    endif
    if !ChopsticksPluginInstalled('vim-markdown')
        return ChopsticksInfoDiagnosticItem('markdown syntax', 'missing',
            \ 'vim-markdown not installed', 'markdown syntax',
            \ ':PlugInstall', {
            \ 'severity': 'setup',
            \ 'detail': 'vim-markdown is declared but not installed',
            \ })
    endif
    return ChopsticksInfoItem('markdown syntax', 'ready', 'vim-markdown',
        \ {'diagnostic': 0})
endfunction

function! s:MarkdownWritingItem() abort
    let l:mode = s:MarkdownWritingMode()
    if &filetype ==# 'markdown'
        let l:ready = &l:wrap && &l:linebreak && &l:textwidth == 0
            \ && &l:colorcolumn ==# '0' && &l:signcolumn ==# 'no'
        let l:ready = l:ready
            \ && (&l:conceallevel == (get(g:, 'chopsticks_markdown_conceal', 0) ? 2 : 0))
        if !l:ready
            return ChopsticksInfoDiagnosticItem('markdown writing mode',
                \ 'missing', 'buffer defaults changed',
                \ 'markdown writing mode',
                \ 'reload chopsticks or review local markdown overrides', {
                \ 'detail': 'markdown buffer defaults are not active',
                \ })
        endif
    endif
    return ChopsticksInfoItem('markdown writing mode', 'ready', l:mode,
        \ {'diagnostic': 0})
endfunction

function! s:FallbackMarkdownMapSpecs() abort
    let l:expected = []
    if ChopsticksPluginDeclared('vim-markdown')
        call add(l:expected, {
            \ 'lhs': ',mt',
            \ 'text': 'Toc',
            \ 'label': 'Toc',
            \ 'key': ',mt',
            \ 'display_label': 'Toc',
            \ })
    endif
    if ChopsticksPluginDeclared('previm')
        call add(l:expected, {
            \ 'lhs': ',mp',
            \ 'text': 'PrevimOpen',
            \ 'label': 'PrevimOpen',
            \ 'key': ',mp',
            \ 'display_label': 'PrevimOpen',
            \ })
    endif
    return l:expected
endfunction

function! s:MarkdownMapSpecs() abort
    return ChopsticksKeymapContractSpecsOr('markdown_maps',
        \ s:FallbackMarkdownMapSpecs())
endfunction

function! s:MarkdownMapLabel(spec) abort
    return get(a:spec, 'display_label', get(a:spec, 'label',
        \ get(a:spec, 'key', get(a:spec, 'lhs', 'map'))))
endfunction

function! s:MarkdownMapsItem() abort
    let l:expected = s:MarkdownMapSpecs()
    if empty(l:expected)
        return ChopsticksInfoItem('markdown maps', 'off',
            \ 'markdown plugins disabled', {'diagnostic': 0})
    endif
    if &filetype !=# 'markdown'
        return ChopsticksInfoItem('markdown maps', 'ready',
            \ 'buffer-local on markdown', {'diagnostic': 0})
    endif

    let l:missing = []
    let l:labels = []
    for l:map in l:expected
        let l:label = s:MarkdownMapLabel(l:map)
        call add(l:labels, l:label)
        if stridx(maparg(get(l:map, 'lhs', ''),
            \ get(l:map, 'mode', 'n')), get(l:map, 'text', '')) < 0
            call add(l:missing, l:label)
        endif
    endfor
    if empty(l:missing)
        return ChopsticksInfoItem('markdown maps', 'ready',
            \ join(l:labels, '/'), {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('markdown maps', 'missing',
        \ 'missing: ' . join(l:missing, ', '), 'markdown maps',
        \ ':ChopsticksKeymapAudit', {
        \ 'detail': 'missing markdown maps: ' . join(l:missing, ', '),
        \ })
endfunction

function! s:MarkdownPreviewItem() abort
    if !get(g:, 'chopsticks_enable_markdown_preview', 1)
        return ChopsticksInfoItem('markdown preview', 'off',
            \ 'disabled by profile', {'diagnostic': 0})
    endif
    if !ChopsticksPluginDeclared('previm')
        return ChopsticksInfoDiagnosticItem('markdown preview', 'missing',
            \ 'previm not declared', 'markdown preview',
            \ 'check g:chopsticks_enable_markdown_preview and plugin profile', {
            \ 'severity': 'setup',
            \ 'detail': 'Markdown preview is enabled but previm is not declared',
            \ })
    endif
    if !ChopsticksPluginInstalled('previm')
        return ChopsticksInfoDiagnosticItem('markdown preview', 'missing',
            \ 'previm not installed', 'markdown preview', ':PlugInstall', {
            \ 'severity': 'setup',
            \ 'detail': 'previm is declared but not installed',
            \ })
    endif
    if empty(get(g:, 'previm_open_cmd', ''))
        return ChopsticksInfoDiagnosticItem('markdown preview', 'optional',
            \ 'open command not configured', 'markdown preview',
            \ 'install open or xdg-open', {
            \ 'severity': 'optional',
            \ 'detail': 'previm_open_cmd is not configured',
            \ })
    endif
    return ChopsticksInfoItem('markdown preview', 'ready', 'PrevimOpen',
        \ {'diagnostic': 0})
endfunction

function! s:GoSyntaxItem() abort
    if !get(g:, 'chopsticks_enable_extra_languages', 1)
        return ChopsticksInfoItem('go syntax', 'off', 'disabled by profile',
            \ {'diagnostic': 0})
    endif
    if !ChopsticksPluginDeclared('vim-go')
        return ChopsticksInfoDiagnosticItem('go syntax', 'missing',
            \ 'vim-go not declared', 'go syntax',
            \ 'check g:chopsticks_enable_extra_languages and plugin profile', {
            \ 'severity': 'setup',
            \ 'detail': 'extra language syntax is enabled but vim-go is not declared',
            \ })
    endif
    if !ChopsticksPluginInstalled('vim-go')
        return ChopsticksInfoDiagnosticItem('go syntax', 'missing',
            \ 'vim-go not installed', 'go syntax', ':PlugInstall', {
            \ 'severity': 'setup',
            \ 'detail': 'vim-go is declared but not installed',
            \ })
    endif
    if get(g:, 'go_gopls_enabled', 1)
        \ || get(g:, 'go_code_completion_enabled', 1)
        \ || get(g:, 'go_fmt_autosave', 1)
        \ || get(g:, 'go_imports_autosave', 1)
        return ChopsticksInfoDiagnosticItem('go syntax', 'missing',
            \ 'vim-go intelligence enabled', 'go syntax',
            \ 'reload chopsticks or review vim-go overrides', {
            \ 'detail': 'vim-go must stay syntax-only; vim-lsp/ALE own intelligence',
            \ })
    endif
    return ChopsticksInfoItem('go syntax', 'ready',
        \ 'syntax only; LSP owns intelligence', {'diagnostic': 0})
endfunction

function! s:FiletypeDefaultsItem() abort
    let l:missing = []
    for l:pattern in ['python', 'markdown', 'go', 'json', 'dockerfile']
        if !exists('#ChopstickFiletype#FileType#' . l:pattern)
            call add(l:missing, l:pattern)
        endif
    endfor
    if empty(l:missing)
        return ChopsticksInfoItem('filetype defaults', 'ready',
            \ 'indent + markdown defaults', {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('filetype defaults', 'missing',
        \ 'missing: ' . join(l:missing, ', '), 'filetype defaults',
        \ 'reload chopsticks', {
        \ 'detail': 'missing filetype autocmds: ' . join(l:missing, ', '),
        \ })
endfunction

function! ChopsticksLanguageInfo() abort
    return ChopsticksInfoSection('languages', {
        \ 'details': [
        \   ChopsticksInfoDetail('markdown', s:MarkdownWritingMode()),
        \   ChopsticksInfoDetail('preview',
        \       get(g:, 'chopsticks_enable_markdown_preview', 1)
        \           ? 'PrevimOpen'
        \           : 'disabled'),
        \   ChopsticksInfoDetail('current',
        \       empty(&filetype) ? 'none' : &filetype),
        \ ],
        \ 'items': [
        \   s:MarkdownSyntaxItem(),
        \   s:MarkdownWritingItem(),
        \   s:MarkdownMapsItem(),
        \   s:MarkdownPreviewItem(),
        \   s:GoSyntaxItem(),
        \   s:FiletypeDefaultsItem(),
        \ ],
        \ })
endfunction
