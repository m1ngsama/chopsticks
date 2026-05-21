" runner.vim — run the current file by filetype

function! s:RunFile() abort
    write
    let l:ft   = &filetype
    let l:file = shellescape(expand('%:p'))
    if     l:ft ==# 'python'     | execute '!python3 '  . l:file
    elseif l:ft ==# 'javascript' | execute '!node '     . l:file
    elseif l:ft ==# 'typescript' | execute '!npx ts-node ' . l:file
    elseif l:ft ==# 'go'         | execute '!go run '   . l:file
    elseif l:ft ==# 'rust'       | execute '!cargo run'
    elseif l:ft ==# 'sh'         | execute '!bash '     . l:file
    elseif l:ft ==# 'c'
        let l:out_path = tempname()
        let l:out = shellescape(l:out_path)
        execute '!gcc -o ' . l:out . ' ' . l:file . ' && ' . l:out
        call delete(l:out_path)
    elseif l:ft ==# 'lua'        | execute '!lua '      . l:file
    elseif l:ft ==# 'ruby'       | execute '!ruby '     . l:file
    elseif l:ft ==# 'perl'       | execute '!perl '     . l:file
    else | echo 'No runner for filetype: ' . l:ft
    endif
endfunction
if g:chopsticks_space_keymaps
    nnoremap <leader>rr :call <SID>RunFile()<CR>
else
    nnoremap <leader>cr :call <SID>RunFile()<CR>
endif
