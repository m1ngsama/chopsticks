" files.vim — file safety and large-file handling

function! s:Bytes(value) abort
    return a:value . ' bytes'
endfunction

function! s:Number(value) abort
    try
        return a:value + 0
    catch
        return 0
    endtry
endfunction

function! s:ThresholdValid() abort
    return s:Number(get(g:, 'LargeFile', 0)) > 0
endfunction

function! s:MkNonExDir(file, buf)
    if empty(getbufvar(a:buf, '&buftype')) && a:file !~# '\v^\w+\:\/'
        call ChopsticksEnsureParentDir(a:file)
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

function! s:CurrentBufferItem() abort
    let l:file = expand('%:p')
    if empty(l:file) || &buftype !=# ''
        return ChopsticksInfoItem('current buffer', 'off', 'no file', {
            \ 'diagnostic': 0,
            \ })
    endif

    let l:size = getfsize(l:file)
    if get(b:, 'chopsticks_large_file', 0)
        return ChopsticksInfoItem('current buffer', 'ready',
            \ 'syntax/undo/swap/ALE reduced', {
            \ 'value': 'large file',
            \ 'diagnostic': 0,
            \ 'size': l:size,
            \ })
    endif
    if get(b:, 'chopsticks_tty_large_file', 0)
        return ChopsticksInfoItem('current buffer', 'ready', 'syntax reduced', {
            \ 'value': 'TTY large file',
            \ 'diagnostic': 0,
            \ 'size': l:size,
            \ })
    endif
    return ChopsticksInfoItem('current buffer', 'ready', 'normal', {
        \ 'value': l:size >= 0 ? s:Bytes(l:size) : 'unknown size',
        \ 'diagnostic': 0,
        \ 'size': l:size,
        \ })
endfunction

function! s:LargeFileGuardItem() abort
    let l:large = s:Number(get(g:, 'LargeFile', 0))
    if s:ThresholdValid()
        return ChopsticksInfoItem('large file guard', 'ready',
            \ 'threshold=' . l:large, {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('large file guard', 'missing',
        \ 'invalid threshold: ' . string(get(g:, 'LargeFile', '')),
        \ 'large file threshold',
        \ 'set g:LargeFile to a positive byte threshold', {
        \ 'detail': 'invalid g:LargeFile: '
        \     . string(get(g:, 'LargeFile', '')),
        \ })
endfunction

function! ChopsticksFileSafetyInfo() abort
    let l:large = s:Number(get(g:, 'LargeFile', 0))
    let l:tty = s:Number(s:tty_large)
    return ChopsticksInfoSection('file safety', {
        \ 'large_threshold': l:large,
        \ 'tty_threshold': l:tty,
        \ 'current_file': expand('%:p'),
        \ 'current_size': empty(expand('%:p')) ? -1 : getfsize(expand('%:p')),
        \ 'large_buffer': get(b:, 'chopsticks_large_file', 0),
        \ 'tty_large_buffer': get(b:, 'chopsticks_tty_large_file', 0),
        \ 'details': [
        \   ChopsticksInfoDetail('write', 'auto mkdir'),
        \   ChopsticksInfoDetail('large', s:Bytes(l:large)),
        \   ChopsticksInfoDetail('tty', s:Bytes(l:tty)),
        \ ],
        \ 'items': [
        \   ChopsticksInfoItem('write directory guard', 'ready',
        \       'BufWritePre mkdir -p', {'diagnostic': 0}),
        \   s:LargeFileGuardItem(),
        \   s:CurrentBufferItem(),
        \ ],
        \ })
endfunction
