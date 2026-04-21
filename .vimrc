if exists('g:chopsticks_loaded') | finish | endif
let g:chopsticks_loaded = 1

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
