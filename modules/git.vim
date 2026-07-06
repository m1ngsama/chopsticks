" git.vim — Fugitive mappings, GitGutter config, conflict navigation

" ── GitGutter ───────────────────────────────────────────────────────────────

let g:gitgutter_map_keys              = 0
let g:gitgutter_sign_added            = '+'
let g:gitgutter_sign_modified         = '~'
let g:gitgutter_sign_removed          = '-'
let g:gitgutter_sign_removed_first_line = '^'
let g:gitgutter_sign_modified_removed = '~'

function! s:FallbackMapSpecs() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return [
            \ {'lhs': '<Space>gs', 'key': 'SPC gs', 'text': 'Git status'},
            \ {'lhs': '<Space>gc', 'key': 'SPC gc', 'text': 'Git commit'},
            \ {'lhs': '<Space>gd', 'key': 'SPC gd', 'text': 'Gdiffsplit'},
            \ {'lhs': '<Space>gb', 'key': 'SPC gb', 'text': 'Git blame'},
            \ {'lhs': '<Space>gl', 'key': 'SPC gl', 'text': 'Git log'},
            \ ]
    endif
    return [
        \ {'lhs': ',gs', 'key': ',gs', 'text': 'Git status'},
        \ {'lhs': ',gc', 'key': ',gc', 'text': 'Git commit'},
        \ {'lhs': ',gd', 'key': ',gd', 'text': 'Gdiffsplit'},
        \ {'lhs': ',gb', 'key': ',gb', 'text': 'Git blame'},
        \ {'lhs': ',gL', 'key': ',gL', 'text': 'Git log'},
        \ ]
endfunction

function! s:FallbackStatusKeys() abort
    return get(g:, 'chopsticks_space_keymaps', 1) ? ['SPC gs'] : [',gs']
endfunction

function! s:FallbackLogKeys() abort
    return get(g:, 'chopsticks_space_keymaps', 1) ? ['SPC gl'] : [',gL']
endfunction

function! s:FallbackConflictSpecs() abort
    return [
        \ {'lhs': '[x', 'key': '[x', 'text': '<<<<<<<'},
        \ {'lhs': ']x', 'key': ']x', 'text': '<<<<<<<'},
        \ ]
endfunction

function! s:FallbackConflictKeys() abort
    return ['[x', ']x']
endfunction

function! s:MapSpecs() abort
    return ChopsticksKeymapContractSpecsOr('git_keymaps',
        \ s:FallbackMapSpecs())
endfunction

function! s:ConflictSpecs() abort
    return ChopsticksKeymapContractSpecsOr('git_conflict_navigation',
        \ s:FallbackConflictSpecs())
endfunction

function! s:GitStatusKey() abort
    return get(ChopsticksKeymapContractKeysOr('git_status',
        \ s:FallbackStatusKeys()), 0, get(g:, 'chopsticks_space_keymaps', 1)
        \ ? 'SPC gs' : ',gs')
endfunction

function! s:GitLogKey() abort
    return get(ChopsticksKeymapContractKeysOr('git_log',
        \ s:FallbackLogKeys()), 0, get(g:, 'chopsticks_space_keymaps', 1)
        \ ? 'SPC gl' : ',gL')
endfunction

function! s:ConflictKey() abort
    return join(ChopsticksKeymapContractKeysOr('git_conflict_navigation',
        \ s:FallbackConflictKeys()), ' ')
endfunction

function! s:RepoDetail() abort
    let l:git_dir = finddir('.git', '.;')
    return empty(l:git_dir) ? 'none' : fnamemodify(l:git_dir, ':p:h:h')
endfunction

" ── Fugitive ────────────────────────────────────────────────────────────────

if ChopsticksPluginDeclared('vim-fugitive')
    nnoremap <leader>gs :Git status<CR>
    nnoremap <leader>gc :Git commit<CR>
    nnoremap <leader>gd :Gdiffsplit<CR>
    nnoremap <leader>gb :Git blame<CR>
    if g:chopsticks_space_keymaps
        nnoremap <leader>gl :Git log --oneline --graph -20<CR>
    else
        nnoremap <leader>gL :Git log --oneline --graph -20<CR>
    endif
endif

" ── Conflict Navigation ────────────────────────────────────────────────────

nnoremap <silent> ]x /^\(<<<<<<<\\|=======\\|>>>>>>>\)<CR>
nnoremap <silent> [x ?^\(<<<<<<<\\|=======\\|>>>>>>>\)<CR>

function! ChopsticksGitInfo() abort
    let l:fugitive_declared = ChopsticksPluginDeclared('vim-fugitive')
    let l:gitgutter_declared = ChopsticksPluginDeclared('vim-gitgutter')
    let l:git_command = ChopsticksToolAvailable('git')
    let l:fugitive_loaded = ChopsticksCommandAvailable('Git')
    let l:gitgutter_loaded = ChopsticksCommandAvailable('GitGutter') || exists('g:loaded_gitgutter')
    let l:map_specs = s:MapSpecs()
    let l:missing_maps = ChopsticksKeymapMissingKeys(l:map_specs)
    let l:missing_conflict = ChopsticksKeymapMissingKeys(s:ConflictSpecs())
    let l:conflict_ready = empty(l:missing_conflict)
    let l:items = []
    if l:git_command
        call add(l:items, ChopsticksInfoItem('git command', 'ready', 'git',
            \ {'diagnostic': 0}))
    else
        call add(l:items, ChopsticksInfoDiagnosticItem('git command',
            \ 'missing', 'missing: git', 'git command', 'install: git', {
            \ 'severity': 'setup',
            \ 'detail': 'missing git command',
            \ }))
    endif

    let l:fugitive_ready = l:fugitive_declared && l:fugitive_loaded
    let l:fugitive_reason = !l:fugitive_declared
        \ ? 'plugin not declared'
        \ : (l:fugitive_loaded ? ':Git' : 'command not loaded')
    if l:fugitive_ready
        call add(l:items, ChopsticksInfoItem('fugitive', 'ready',
            \ l:fugitive_reason, {'diagnostic': 0}))
    else
        call add(l:items, ChopsticksInfoDiagnosticItem('fugitive',
            \ 'missing', l:fugitive_reason, 'fugitive',
            \ ':PlugInstall and restart Vim', {
            \ 'severity': 'setup',
            \ 'detail': !l:fugitive_declared
            \     ? 'vim-fugitive plugin is not declared'
            \     : 'vim-fugitive command is not loaded',
            \ }))
    endif

    let l:gitgutter_ready = l:gitgutter_declared && l:gitgutter_loaded
    let l:gitgutter_reason = !l:gitgutter_declared
        \ ? 'plugin not declared'
        \ : (l:gitgutter_loaded ? ':GitGutter' : 'command not loaded')
    if l:gitgutter_ready
        call add(l:items, ChopsticksInfoItem('gitgutter', 'ready',
            \ l:gitgutter_reason, {'diagnostic': 0}))
    else
        call add(l:items, ChopsticksInfoDiagnosticItem('gitgutter',
            \ 'missing', l:gitgutter_reason, 'gitgutter',
            \ ':PlugInstall and restart Vim', {
            \ 'severity': 'setup',
            \ 'detail': !l:gitgutter_declared
            \     ? 'vim-gitgutter plugin is not declared'
            \     : 'vim-gitgutter command is not loaded',
            \ }))
    endif

    if empty(l:missing_maps)
        call add(l:items, ChopsticksInfoItem('git keymaps', 'ready',
            \ s:GitStatusKey(), {'diagnostic': 0}))
    else
        call add(l:items, ChopsticksInfoDiagnosticItem('git keymaps',
            \ 'missing', 'missing: ' . join(l:missing_maps, ', '),
            \ 'git keymaps', ':ChopsticksKeymapAudit', {
            \ 'detail': 'missing git maps: ' . join(l:missing_maps, ', '),
            \ }))
    endif

    if l:conflict_ready
        call add(l:items, ChopsticksInfoItem('conflict navigation', 'ready',
            \ s:ConflictKey(), {'diagnostic': 0}))
    else
        call add(l:items, ChopsticksInfoDiagnosticItem('conflict navigation',
            \ 'missing', 'missing: ' . join(l:missing_conflict, ', '),
            \ 'conflict navigation', ':ChopsticksKeymapAudit', {
            \ 'detail': 'missing conflict marker navigation maps: '
            \     . join(l:missing_conflict, ', '),
            \ }))
    endif

    return ChopsticksInfoSection('git', {
        \ 'details': [
        \   ChopsticksInfoDetail('status', s:GitStatusKey()),
        \   ChopsticksInfoDetail('log', s:GitLogKey()),
        \   ChopsticksInfoDetail('repo', s:RepoDetail()),
        \ ],
        \ 'items': l:items,
        \ 'fugitive_declared': l:fugitive_declared,
        \ 'fugitive_loaded': l:fugitive_loaded,
        \ 'gitgutter_declared': l:gitgutter_declared,
        \ 'gitgutter_loaded': l:gitgutter_loaded,
        \ 'missing_maps': l:missing_maps,
        \ 'missing_conflict_maps': l:missing_conflict,
        \ 'conflict_navigation': l:conflict_ready,
        \ })
endfunction
