" env.vim — environment detection (must load first)

set nocompatible

let g:is_tty       = empty($TERM) || $TERM ==# 'dumb' || $TERM =~# 'linux'
                 \ || $TERM =~# 'screen' || &term =~# 'builtin'
let g:has_true_color = ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')
