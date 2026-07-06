" runner.vim — run the current file by filetype

function! s:RunnerSpecs() abort
    return [
        \ {'ft': 'python', 'cmd': 'python3', 'run': 'python3 %s'},
        \ {'ft': 'javascript', 'cmd': 'node', 'run': 'node %s'},
        \ {'ft': 'typescript', 'cmd': 'npx', 'run': 'npx ts-node %s'},
        \ {'ft': 'go', 'cmd': 'go', 'run': 'go run %s'},
        \ {'ft': 'rust', 'cmd': 'cargo', 'run': 'cargo run'},
        \ {'ft': 'sh', 'cmd': 'bash', 'run': 'bash %s'},
        \ {'ft': 'c', 'cmd': 'gcc', 'run': 'gcc temporary binary'},
        \ {'ft': 'lua', 'cmd': 'lua', 'run': 'lua %s'},
        \ {'ft': 'ruby', 'cmd': 'ruby', 'run': 'ruby %s'},
        \ {'ft': 'perl', 'cmd': 'perl', 'run': 'perl %s'},
        \ ]
endfunction

function! s:RunnerForFiletype(filetype) abort
    for l:runner in s:RunnerSpecs()
        if get(l:runner, 'ft', '') ==# a:filetype
            return copy(l:runner)
        endif
    endfor
    return {}
endfunction

function! s:SupportedFiletypes() abort
    let l:filetypes = []
    for l:runner in s:RunnerSpecs()
        call add(l:filetypes, get(l:runner, 'ft', ''))
    endfor
    return join(l:filetypes, ', ')
endfunction

function! s:FallbackRunMapSpecs() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return [{'lhs': '<Space>rr', 'key': 'SPC rr', 'text': 'RunFile'}]
    endif
    return [{'lhs': ',cr', 'key': ',cr', 'text': 'RunFile'}]
endfunction

function! s:FallbackRunKeys() abort
    return get(g:, 'chopsticks_space_keymaps', 1) ? ['SPC rr'] : [',cr']
endfunction

function! s:RunMapSpecs() abort
    return ChopsticksKeymapContractSpecsOr('project_run',
        \ s:FallbackRunMapSpecs())
endfunction

function! s:RunKey() abort
    let l:fallback = get(g:, 'chopsticks_space_keymaps', 1) ? 'SPC rr' : ',cr'
    return get(ChopsticksKeymapContractKeysOr('project_run',
        \ s:FallbackRunKeys()), 0, l:fallback)
endfunction

function! s:MissingRunMaps() abort
    return ChopsticksKeymapMissingKeys(s:RunMapSpecs())
endfunction

function! s:CurrentRunnerItem(filetype, runner, missing_maps) abort
    if !empty(a:missing_maps)
        return ChopsticksInfoDiagnosticItem('run file', 'missing',
            \ 'missing: ' . join(a:missing_maps, ', '), 'run keymap',
            \ ':ChopsticksKeymapAudit', {
            \ 'detail': 'missing run file map: ' . join(a:missing_maps, ', '),
            \ })
    endif
    if empty(a:filetype)
        return ChopsticksInfoItem('run file', 'off', 'no filetype', {
            \ 'diagnostic': 0,
            \ })
    endif
    if empty(a:runner)
        return ChopsticksInfoItem('run file', 'off',
            \ 'unsupported filetype: ' . a:filetype, {
            \ 'value': a:filetype,
            \ 'diagnostic': 0,
            \ })
    endif

    let l:cmd = get(a:runner, 'cmd', '')
    if ChopsticksToolAvailable(l:cmd)
        return ChopsticksInfoItem('run file', 'ready', l:cmd, {
            \ 'value': a:filetype,
            \ 'diagnostic': 0,
            \ })
    endif

    return ChopsticksInfoDiagnosticItem('run file', 'missing',
        \ 'missing: ' . l:cmd, a:filetype . ' runner',
        \ 'install: ' . l:cmd, {
        \ 'value': a:filetype,
        \ 'severity': 'setup',
        \ 'detail': 'missing runner command: ' . l:cmd,
        \ })
endfunction

function! s:RunWithSpec(runner, file) abort
    if get(a:runner, 'ft', '') ==# 'c'
        let l:out_path = tempname()
        let l:out = shellescape(l:out_path)
        execute '!gcc -o ' . l:out . ' ' . a:file . ' && ' . l:out
        call delete(l:out_path)
        return
    endif

    let l:run = get(a:runner, 'run', '')
    if stridx(l:run, '%s') >= 0
        execute '!' . printf(l:run, a:file)
    else
        execute '!' . l:run
    endif
endfunction

function! s:RunFile() abort
    write
    let l:ft = &filetype
    let l:file = shellescape(expand('%:p'))
    let l:runner = s:RunnerForFiletype(l:ft)
    if empty(l:runner)
        echo 'No runner for filetype: ' . l:ft
        return
    endif
    call s:RunWithSpec(l:runner, l:file)
endfunction

function! ChopsticksRunnerInfo() abort
    let l:filetype = &filetype
    let l:runner = s:RunnerForFiletype(l:filetype)
    let l:missing_maps = s:MissingRunMaps()
    let l:run_key = s:RunKey()
    return ChopsticksInfoSection('run file', {
        \ 'filetype': l:filetype,
        \ 'keymap': l:run_key,
        \ 'supported': s:SupportedFiletypes(),
        \ 'runner': l:runner,
        \ 'missing_maps': l:missing_maps,
        \ 'details': [
        \   ChopsticksInfoDetail('keymap', l:run_key),
        \   ChopsticksInfoDetail('current',
        \       empty(l:filetype) ? 'none' : l:filetype),
        \   ChopsticksInfoDetail('supported',
        \       len(s:RunnerSpecs()) . ' filetypes'),
        \ ],
        \ 'items': [s:CurrentRunnerItem(l:filetype, l:runner, l:missing_maps)],
        \ })
endfunction

if g:chopsticks_space_keymaps
    nnoremap <leader>rr :call <SID>RunFile()<CR>
else
    nnoremap <leader>cr :call <SID>RunFile()<CR>
endif
