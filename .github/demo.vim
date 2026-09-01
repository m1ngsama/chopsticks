scriptencoding utf-8

" Deterministic rich-profile harness for .github/demo.tape.  It still sources
" the real configuration and installed plugins; only machine-local choices
" and background activity are disabled for a repeatable recording.
let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
let $MYVIMRC = s:root . '/.vimrc'
let g:chopsticks_local_config = ''
let g:chopsticks_ui_density = 'rich'
let g:chopsticks_colorscheme = 'everforest'
let g:chopsticks_transparent_background = 0
let g:chopsticks_dashboard = 1
let g:chopsticks_bufferline = 1
let g:chopsticks_icons = 1
let g:chopsticks_use_fern = 1
let g:chopsticks_markdown_spell = 0
let g:chopsticks_session_dir = tempname()
let g:ale_enabled = 0
let g:everforest_background = 'hard'
let g:everforest_enable_italic = 1
let g:everforest_ui_contrast = 'high'
let g:everforest_current_word = 'high contrast background'

execute 'source ' . fnameescape(s:root . '/.vimrc')
