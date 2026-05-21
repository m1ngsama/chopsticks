" files.vim — file safety and large-file handling

function! s:MkNonExDir(file, buf)
    if empty(getbufvar(a:buf, '&buftype')) && a:file !~# '\v^\w+\:\/'
        let dir = fnamemodify(a:file, ':h')
        if !isdirectory(dir)
            call mkdir(dir, 'p')
        endif
    endif
endfunction
augroup BWCCreateDir
    autocmd!
    autocmd BufWritePre *
        \ if !empty(expand('<afile>')) |
        \     call s:MkNonExDir(expand('<afile>'), +expand('<abuf>')) |
        \ endif
augroup END

let g:LargeFile = get(g:, 'LargeFile', 1024 * 1024 * 10)
let s:tty_large  = g:is_tty ? 512000 : g:LargeFile

function! s:ApplyLargeFileSettings() abort
    if get(b:, 'chopsticks_large_file', 0)
        setlocal bufhidden=unload undolevels=-1 noswapfile
        let b:ale_enabled = 0
        if &l:syntax !=# ''
            setlocal syntax=
        endif
    elseif get(b:, 'chopsticks_tty_large_file', 0)
        if &l:syntax !=# ''
            setlocal syntax=
        endif
    endif
endfunction

function! s:MarkLargeFile(file) abort
    if empty(a:file)
        return
    endif

    let l:fsize = getfsize(a:file)
    if l:fsize > g:LargeFile || l:fsize == -2
        let b:chopsticks_large_file = 1
    elseif g:is_tty && l:fsize > s:tty_large
        let b:chopsticks_tty_large_file = 1
    endif
    call s:ApplyLargeFileSettings()
endfunction

augroup ChopstickLargeFile
    autocmd!
    autocmd BufReadPre * call s:MarkLargeFile(expand('<afile>'))
    autocmd BufReadPost,FileType,Syntax * call s:ApplyLargeFileSettings()
augroup END
