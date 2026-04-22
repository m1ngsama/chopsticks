" env.vim — environment detection (must load first)

set nocompatible

let g:is_tty       = empty($TERM) || $TERM ==# 'dumb' || $TERM =~# 'linux'
                 \ || $TERM =~# 'screen' || &term =~# 'builtin'
let g:has_true_color = ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')

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
