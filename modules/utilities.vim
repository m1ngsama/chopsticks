" utilities.vim — small editing and config helpers

function! s:LocalConfigPath() abort
    let l:xdg = !empty($XDG_CONFIG_HOME) && $XDG_CONFIG_HOME =~# '^/'
        \ ? $XDG_CONFIG_HOME
        \ : '~/.config'
    return expand(get(g:, 'chopsticks_resolved_local_config',
        \ get(g:, 'chopsticks_local_config', l:xdg . '/chopsticks.vim')))
endfunction

function! s:EditLocalConfig() abort
    let l:path = s:LocalConfigPath()
    let l:new_file = !filereadable(l:path)
    let l:dir = fnamemodify(l:path, ':h')
    if !isdirectory(l:dir)
        call mkdir(l:dir, 'p')
    endif

    execute 'edit ' . fnameescape(l:path)
    setlocal filetype=vim
    if l:new_file && line('$') == 1 && getline(1) ==# ''
        call setline(1, [
            \ '" chopsticks local preferences',
            \ "let g:chopsticks_profile = 'engineer'",
            \ "let g:chopsticks_keymap_style = 'space'",
            \ '',
            \ '" Optional habits:',
            \ '" let g:chopsticks_enable_jk_escape = 1',
            \ '" let g:chopsticks_enable_ctrl_s_save = 1',
            \ '" let g:chopsticks_enable_auto_pairs = 1',
            \ ])
        setlocal nomodified
    endif
endfunction

function! s:ReloadChopsticks() abort
    unlet! g:chopsticks_loaded
    execute 'source ' . fnameescape($MYVIMRC)
    echo 'chopsticks reloaded'
endfunction

command! ChopsticksConfig call s:EditLocalConfig()
command! ChopsticksReload call s:ReloadChopsticks()

if get(g:, 'chopsticks_enable_reindent_file', 0)
    if g:chopsticks_space_keymaps
        nnoremap <leader>c= gg=G``
    else
        nnoremap <leader>F gg=G``
    endif
endif
if g:chopsticks_space_keymaps
    vnoremap <leader>= =
else
    vnoremap <leader>F =
    nnoremap <leader>wa :wa<CR>
endif

if !g:chopsticks_space_keymaps
    nnoremap <silent> <Leader>= :exe "resize "          . (winheight(0) * 3/2)<CR>
    nnoremap <silent> <Leader>- :exe "resize "          . (winheight(0) * 2/3)<CR>
endif

if g:chopsticks_space_keymaps
    nnoremap <leader><Tab> <c-^>
else
    nnoremap <leader><leader> <c-^>
endif

if g:chopsticks_space_keymaps
    nnoremap <leader>cW :%s/\s\+$//<CR>:let @/=''<CR>
    vnoremap <leader>cW :s/\s\+$//<CR>:let @/=''<CR>gv
else
    nnoremap <leader>W :%s/\s\+$//<CR>:let @/=''<CR>
    vnoremap <leader>W :s/\s\+$//<CR>:let @/=''<CR>gv
endif

if g:chopsticks_space_keymaps
    nnoremap <leader>fc :ChopsticksConfig<CR>
    nnoremap <leader>fv :edit $MYVIMRC<CR>
    nnoremap <leader>fV :ChopsticksReload<CR>
else
    nnoremap <leader>ec :ChopsticksConfig<CR>
    nnoremap <leader>ev :edit $MYVIMRC<CR>
    nnoremap <leader>sv :ChopsticksReload<CR>
endif

if g:chopsticks_space_keymaps
    nnoremap <leader>sr :%s/\<<C-r><C-w>\>//g<Left><Left>
    vnoremap <leader>sr :s///g<Left><Left><Left>
else
    nnoremap <leader>* :%s/\<<C-r><C-w>\>//g<Left><Left>
    vnoremap <leader>* :s///g<Left><Left><Left>
endif

if has('clipboard')
    if g:chopsticks_space_keymaps
        nnoremap <leader>fp :let @+ = expand("%:p")<CR>:echo "Copied: " . expand("%:p")<CR>
        nnoremap <leader>fn :let @+ = expand("%:t")<CR>:echo "Copied: " . expand("%:t")<CR>
    else
        nnoremap <leader>cp :let @+ = expand("%:p")<CR>:echo "Copied: " . expand("%:p")<CR>
        nnoremap <leader>cf :let @+ = expand("%:t")<CR>:echo "Copied: " . expand("%:t")<CR>
    endif
endif

if get(g:, 'chopsticks_enable_sudo_save_bang', 0)
    cnoremap w!! w !sudo tee > /dev/null %
endif
