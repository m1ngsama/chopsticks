" help.vim — native Vim help entrypoint

function! s:OpenHelp() abort
    let l:doc = g:chopsticks_dir . '/doc'
    if isdirectory(l:doc)
        silent! execute 'helptags ' . fnameescape(l:doc)
    endif

    try
        help chopsticks
    catch /^Vim\%((\a\+)\)\=:E149/
        echohl WarningMsg
        echom 'chopsticks help tags are missing; run :helptags ' . l:doc
        echohl None
    endtry
endfunction

command! ChopsticksHelp call s:OpenHelp()
