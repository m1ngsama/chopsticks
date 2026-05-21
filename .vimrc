set nocompatible

let g:chopsticks_dir = fnamemodify(resolve(expand('<sfile>')), ':h')
let s:xdg_config_home = !empty($XDG_CONFIG_HOME) && $XDG_CONFIG_HOME =~# '^/'
    \ ? $XDG_CONFIG_HOME
    \ : '~/.config'
let s:local_config = expand(get(g:, 'chopsticks_local_config',
    \ s:xdg_config_home . '/chopsticks.vim'))
if filereadable(s:local_config)
    execute 'source ' . fnameescape(s:local_config)
endif

if exists('g:chopsticks_loaded') | finish | endif
let g:chopsticks_loaded = 1

let g:surround_no_insert_mappings = get(g:, 'surround_no_insert_mappings', 1)

function! s:load(mod) abort
    execute 'source ' . fnameescape(g:chopsticks_dir . '/modules/' . a:mod . '.vim')
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
call s:load('languages')
call s:load('buffers')
call s:load('utilities')
call s:load('files')
call s:load('runner')
call s:load('quickfix')
call s:load('status')
call s:load('cheatsheet')
call s:load('tutor')
call s:load('tools')
