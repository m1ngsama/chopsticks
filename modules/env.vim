" env.vim — environment detection (must load first)

set nocompatible

let g:is_tty       = empty($TERM) || $TERM ==# 'dumb' || $TERM =~# 'linux'
                 \ || $TERM =~# 'screen' || &term =~# 'builtin'
let g:has_true_color = ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')

let g:chopsticks_profile = get(g:, 'chopsticks_profile', 'engineer')
if index(['minimal', 'engineer', 'full'], g:chopsticks_profile) < 0
    let g:chopsticks_profile = 'engineer'
endif

let s:profile_full = g:chopsticks_profile ==# 'full'
let s:profile_minimal = g:chopsticks_profile ==# 'minimal'

let g:chopsticks_enable_lsp = get(g:, 'chopsticks_enable_lsp',
    \ !s:profile_minimal)
let g:chopsticks_enable_lint = get(g:, 'chopsticks_enable_lint',
    \ !s:profile_minimal)
let g:chopsticks_enable_extra_languages = get(g:,
    \ 'chopsticks_enable_extra_languages', !s:profile_minimal)
let g:chopsticks_enable_ui_extras = get(g:, 'chopsticks_enable_ui_extras',
    \ !s:profile_minimal)
let g:chopsticks_enable_markdown_preview = get(g:,
    \ 'chopsticks_enable_markdown_preview', !s:profile_minimal)

let g:chopsticks_markdown_lint = get(g:, 'chopsticks_markdown_lint',
    \ s:profile_full)
let g:chopsticks_markdown_format_on_save = get(g:,
    \ 'chopsticks_markdown_format_on_save', s:profile_full)
let g:chopsticks_markdown_lsp = get(g:, 'chopsticks_markdown_lsp',
    \ s:profile_full)
let g:chopsticks_markdown_spell = get(g:, 'chopsticks_markdown_spell',
    \ s:profile_full)
let g:chopsticks_markdown_conceal = get(g:, 'chopsticks_markdown_conceal',
    \ s:profile_full)
let g:chopsticks_lsp_virtual_text = get(g:, 'chopsticks_lsp_virtual_text',
    \ s:profile_full && !g:is_tty)

" Skip built-in plugins we never use
let g:loaded_2html_plugin      = 1
let g:loaded_getscriptPlugin   = 1
let g:loaded_gzip              = 1
let g:loaded_logiPat           = 1
let g:loaded_rrhelper          = 1
let g:loaded_tarPlugin         = 1
let g:loaded_vimballPlugin     = 1
let g:loaded_zipPlugin         = 1
let g:loaded_tutor_mode_plugin = 1
let g:loaded_spellfile_plugin  = 1
let g:loaded_openPlugin        = 1
let g:loaded_manpager_plugin   = 1
