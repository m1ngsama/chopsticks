let g:chopsticks_dir = fnamemodify(resolve(expand('<sfile>')), ':h')
let s:local_config = expand(get(g:, 'chopsticks_local_config',
    \ '~/.config/chopsticks.vim'))
if filereadable(s:local_config)
    execute 'source ' . fnameescape(s:local_config)
endif

if exists('g:chopsticks_loaded') | finish | endif
let g:chopsticks_loaded = 1

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
call s:load('tools')
