" ============================================================================
" chopsticks — vim configuration
" Philosophy: flowing writing on any machine. No Node.js. Solarized palette.
" ============================================================================
"
" Modular layout — each file in modules/ is self-contained:
"   env.vim        Environment detection (TTY, truecolor)
"   plugins.vim    vim-plug bootstrap + all 30 plugin declarations
"   core.vim       General settings, keymaps, performance, indentation
"   ui.vim         Colorscheme, statusline, startify, indentline
"   editing.vim    EasyMotion, yank highlight, search auto-clear
"   navigation.vim FZF, netrw, window management, terminal
"   lsp.vim        vim-lsp + asyncomplete configuration
"   lint.vim       ALE linting and format-on-save
"   git.vim        Fugitive, GitGutter, conflict navigation
"   writing.vim    Markdown, previm, goyo + limelight zen mode
"   languages.vim  vim-go config, per-filetype settings
"   tools.vim      Cheat sheet, run file, sudo save, helpers

let g:chopsticks_dir = fnamemodify(resolve(expand('<sfile>')), ':h')

function! s:load(mod) abort
    execute 'source ' . g:chopsticks_dir . '/modules/' . a:mod . '.vim'
endfunction

call s:load('env')
call s:load('plugins')
call s:load('core')
call s:load('ui')
call s:load('editing')
call s:load('navigation')
call s:load('lsp')
call s:load('lint')
call s:load('git')
call s:load('writing')
call s:load('languages')
call s:load('tools')
