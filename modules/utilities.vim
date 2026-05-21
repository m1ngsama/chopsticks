" utilities.vim — small editing and config helpers

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
    nnoremap <leader>fv :edit $MYVIMRC<CR>
    nnoremap <leader>fV :unlet! g:chopsticks_loaded<CR>:execute 'source ' . fnameescape($MYVIMRC)<CR>:echo "vimrc reloaded"<CR>
else
    nnoremap <leader>ev :edit $MYVIMRC<CR>
    nnoremap <leader>sv :unlet! g:chopsticks_loaded<CR>:execute 'source ' . fnameescape($MYVIMRC)<CR>:echo "vimrc reloaded"<CR>
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
