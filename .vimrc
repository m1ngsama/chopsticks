set nocompatible

if has('nvim')
    echoerr 'chopsticks is intentionally Vim-only; use Vim 8.2 or Vim 9.x.'
    finish
endif

if v:version < 802
    echoerr 'chopsticks requires Vim 8.2 or Vim 9.x.'
    finish
endif

let g:chopsticks_dir = fnamemodify(resolve(expand('<sfile>')), ':h')
if index(split(&runtimepath, ','), g:chopsticks_dir) < 0
    let &runtimepath = g:chopsticks_dir . ',' . &runtimepath
endif
let s:xdg_config_home = !empty($XDG_CONFIG_HOME) && $XDG_CONFIG_HOME =~# '^/'
    \ ? $XDG_CONFIG_HOME
    \ : '~/.config'
let s:local_config = expand(get(g:, 'chopsticks_local_config',
    \ s:xdg_config_home . '/chopsticks.vim'))
let g:chopsticks_resolved_local_config = s:local_config
let g:chopsticks_local_config_source = exists('g:chopsticks_local_config')
    \ ? 'override'
    \ : 'xdg'
let g:chopsticks_local_config_exists = filereadable(s:local_config)
let g:chopsticks_local_config_loaded = 0
let g:chopsticks_local_config_error = ''
let g:chopsticks_local_config_throwpoint = ''
if filereadable(s:local_config)
    try
        execute 'source ' . fnameescape(s:local_config)
        let g:chopsticks_local_config_loaded = 1
    catch
        let g:chopsticks_local_config_error = v:exception
        let g:chopsticks_local_config_throwpoint = v:throwpoint
    endtry
endif

if exists('g:chopsticks_loaded') | finish | endif
let g:chopsticks_loaded = 1

let g:surround_no_insert_mappings = get(g:, 'surround_no_insert_mappings', 1)

let g:chopsticks_module_manifest = [
    \ 'env',
    \ 'info',
    \ 'input_method',
    \ 'plugins',
    \ 'core',
    \ 'ui',
    \ 'editing',
    \ 'navigation',
    \ 'lsp',
    \ 'lint',
    \ 'git',
    \ 'languages',
    \ 'buffers',
    \ 'utilities',
    \ 'files',
    \ 'runner',
    \ 'quickfix',
    \ 'keymap',
    \ 'tools',
    \ 'health',
    \ 'status',
    \ 'learning',
    \ 'cheatsheet',
    \ 'tutor',
    \ 'beta',
    \ 'help',
    \ ]
let g:chopsticks_module_loads = []

function! s:load(mod) abort
    let l:path = g:chopsticks_dir . '/modules/' . a:mod . '.vim'
    try
        execute 'source ' . fnameescape(l:path)
        call add(g:chopsticks_module_loads, {
            \ 'name': a:mod,
            \ 'path': l:path,
            \ 'loaded': 1,
            \ 'error': '',
            \ 'throwpoint': '',
            \ })
    catch
        call add(g:chopsticks_module_loads, {
            \ 'name': a:mod,
            \ 'path': l:path,
            \ 'loaded': 0,
            \ 'error': v:exception,
            \ 'throwpoint': v:throwpoint,
            \ })
    endtry
endfunction

for s:module in g:chopsticks_module_manifest
    call s:load(s:module)
endfor
unlet s:module
