" writing.vim — vim-markdown, previm, goyo + limelight zen mode

" ── vim-markdown ────────────────────────────────────────────────────────────

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

" ── previm (Markdown browser preview) ───────────────────────────────────────

if has('macunix')
    let g:previm_open_cmd = '/usr/bin/open'
elseif executable('xdg-open')
    let g:previm_open_cmd = 'xdg-open'
endif
if exists('g:plugs["previm"]')
    nnoremap <leader>mp :PrevimOpen<CR>
endif
let g:previm_enable_realtime = 1

" ── Goyo + Limelight (zen mode) ────────────────────────────────────────────

if exists('g:plugs["goyo.vim"]')
    let g:goyo_width  = 80
    let g:goyo_height = '85%'
    nnoremap <leader>zen :Goyo<CR>

    function! s:goyo_enter()
        if exists('g:plugs["limelight.vim"]') | Limelight | endif
        set wrap linebreak scrolloff=999
    endfunction
    function! s:goyo_leave()
        if exists('g:plugs["limelight.vim"]') | Limelight! | endif
        set nowrap nolinebreak scrolloff=10
    endfunction

    augroup ChopstickGoyo
        autocmd!
        autocmd User GoyoEnter nested call s:goyo_enter()
        autocmd User GoyoLeave nested call s:goyo_leave()
    augroup END
endif

let g:limelight_conceal_ctermfg = 240
let g:limelight_conceal_guifg   = '#586e75'
