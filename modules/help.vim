" help.vim — native Vim help entrypoint

function! s:HelpDocDir() abort
    return get(g:, 'chopsticks_dir', expand('~/.vim')) . '/doc'
endfunction

function! s:HelpDocPath() abort
    return s:HelpDocDir() . '/chopsticks.txt'
endfunction

function! s:HelpTagsPath() abort
    return s:HelpDocDir() . '/tags'
endfunction

function! s:DisplayPath(path) abort
    return fnamemodify(a:path, ':~:.')
endfunction

function! s:DocReady() abort
    return filereadable(s:HelpDocPath())
endfunction

function! s:TagsReady() abort
    let l:tags = s:HelpTagsPath()
    if !filereadable(l:tags)
        return 0
    endif
    try
        return !empty(filter(readfile(l:tags), "v:val =~# '^chopsticks\\>'"))
    catch
        return 0
    endtry
endfunction

function! s:EnsureHelpTags() abort
    let l:doc = s:HelpDocDir()
    if isdirectory(l:doc)
        silent! execute 'helptags ' . fnameescape(l:doc)
    endif
endfunction

function! s:HelpCommandItem() abort
    if ChopsticksCommandAvailable('ChopsticksHelp')
        return ChopsticksInfoItem('help command', 'ready', ':ChopsticksHelp',
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('help command', 'missing',
        \ 'missing: :ChopsticksHelp', 'help command',
        \ 'check help module load and command definition', {
        \ 'detail': 'missing help command: :ChopsticksHelp',
        \ })
endfunction

function! s:HelpDocumentItem() abort
    if s:DocReady()
        return ChopsticksInfoItem('help document', 'ready',
            \ s:DisplayPath(s:HelpDocPath()), {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('help document', 'missing',
        \ 'missing: doc/chopsticks.txt', 'help document',
        \ 'restore doc/chopsticks.txt', {
        \ 'detail': 'missing native help document: doc/chopsticks.txt',
        \ })
endfunction

function! s:HelpTagsItem() abort
    if s:TagsReady()
        return ChopsticksInfoItem('help tags', 'ready',
            \ s:DisplayPath(s:HelpTagsPath()), {'diagnostic': 0})
    endif
    if s:DocReady() && isdirectory(s:HelpDocDir())
        return ChopsticksInfoItem('help tags', 'ready',
            \ 'generated on open', {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('help tags', 'missing',
        \ 'missing: doc/tags', 'help tags',
        \ ':helptags ' . fnameescape(s:HelpDocDir()), {
        \ 'detail': 'help tags cannot be generated without doc/chopsticks.txt',
        \ })
endfunction

function! s:OpenHelp() abort
    let l:doc = s:HelpDocDir()
    call s:EnsureHelpTags()

    try
        help chopsticks
    catch /^Vim\%((\a\+)\)\=:E149/
        echohl WarningMsg
        echom 'chopsticks help tags are missing; run :helptags ' . l:doc
        echohl None
    endtry
endfunction

command! ChopsticksHelp call s:OpenHelp()

function! ChopsticksHelpInfo() abort
    let l:tags = s:TagsReady() ? s:DisplayPath(s:HelpTagsPath()) : 'generated on open'
    return ChopsticksInfoSection('help surface', {
        \ 'ok': ChopsticksCommandAvailable('ChopsticksHelp') && s:DocReady(),
        \ 'direct_help_ready': s:TagsReady(),
        \ 'doc_path': s:HelpDocPath(),
        \ 'tags_path': s:HelpTagsPath(),
        \ 'details': [
        \   ChopsticksInfoDetail('command', ':ChopsticksHelp'),
        \   ChopsticksInfoDetail('doc', s:DisplayPath(s:HelpDocPath())),
        \   ChopsticksInfoDetail('tags', l:tags),
        \ ],
        \ 'items': [
        \   s:HelpCommandItem(),
        \   s:HelpDocumentItem(),
        \   s:HelpTagsItem(),
        \ ],
        \ })
endfunction
