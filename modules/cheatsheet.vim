" cheatsheet.vim — active keymap reference

function! s:SurvivalCommandLines() abort
    return ChopsticksCommandLinesOr('survival', '  ', [
        \ '  :ChopsticksHelp        full help',
        \ '  :ChopsticksConfig      local config',
        \ '  :ChopsticksReload      reload config',
        \ '  :ChopsticksTutor       practice',
        \ '  :ChopsticksStatus      health',
        \ '  :ChopsticksDoctor      issues',
        \ '  :ChopsticksKeymapAudit key audit',
        \ '  :ChopsticksBeta        release checklist',
        \ '  :ChopsticksBetaLog     release notes',
        \ '  :ChopsticksBetaSession new release note',
        \ ])
endfunction

function! s:ContractKey(group, fallback) abort
    return get(ChopsticksKeymapContractKeysOr(a:group, [a:fallback]), 0,
        \ a:fallback)
endfunction

function! s:SpaceLayout() abort
    return get(g:, 'chopsticks_space_keymaps', 1)
endfunction

function! s:ContractKeyAt(group, fallback, index) abort
    return get(ChopsticksKeymapContractKeysOr(a:group, a:fallback), a:index,
        \ get(a:fallback, a:index, ''))
endfunction

function! s:CheatKeyLine(key, label) abort
    return ChopsticksDisplayKeyLine('  ', 9, a:key, a:label)
endfunction

function! s:CheatContractLine(group, fallback, label) abort
    return s:CheatKeyLine(s:ContractKey(a:group, a:fallback), a:label)
endfunction

function! s:CheatContractLineAt(group, fallback, index, label) abort
    return s:CheatKeyLine(s:ContractKeyAt(a:group, a:fallback, a:index),
        \ a:label)
endfunction

function! s:CompactKeyPair(keys) abort
    if len(a:keys) < 2
        return get(a:keys, 0, '')
    endif
    let l:first = a:keys[0]
    let l:second = a:keys[1]
    if l:first =~# '^SPC ' && l:second =~# '^SPC '
        return 'SPC ' . strpart(l:first, 4) . '/' . strpart(l:second, 4)
    endif
    if l:first =~# '^Alt+' && l:second =~# '^Alt+'
        return 'Alt+' . strpart(l:first, 4) . '/'
            \ . strpart(l:second, 4)
    endif
    return join(a:keys[0:1], ' ')
endfunction

function! s:ContractPair(group, fallback, reverse) abort
    let l:keys = ChopsticksKeymapContractKeysOr(a:group, a:fallback)
    if a:reverse
        call reverse(l:keys)
    endif
    return s:CompactKeyPair(l:keys)
endfunction

function! s:CheatContractPairLine(group, fallback, reverse, label) abort
    return s:CheatKeyLine(s:ContractPair(a:group, a:fallback, a:reverse),
        \ a:label)
endfunction

function! s:WindowNavigationCompact() abort
    let l:keys = ChopsticksKeymapContractKeysOr('window_navigation',
        \ ['<C-h>', '<C-j>', '<C-k>', '<C-l>'])
    if join(l:keys, '/') ==# '<C-h>/<C-j>/<C-k>/<C-l>'
        return 'Ctrl-hjkl'
    endif
    return join(l:keys, '/')
endfunction

function! s:WindowResizeSummary() abort
    let l:keys = ChopsticksKeymapContractKeysOr('window_layout', [',z', ',=', ',-'])
    if len(l:keys) >= 3
        return l:keys[1] . ' ' . l:keys[2]
    endif
    return ',= ,-'
endfunction

function! s:GitCheatLines() abort
    let l:space = s:SpaceLayout()
    return [
        \ s:CheatContractLine('git_status', l:space ? 'SPC gs' : ',gs',
        \   'status'),
        \ s:CheatContractLine('git_diff', l:space ? 'SPC gd' : ',gd',
        \   'diff'),
        \ s:CheatContractLine('git_blame', l:space ? 'SPC gb' : ',gb',
        \   'blame'),
        \ s:CheatContractLine('git_commit', l:space ? 'SPC gc' : ',gc',
        \   'commit'),
        \ s:CheatContractLine('git_log', l:space ? 'SPC gl' : ',gL',
        \   'log graph'),
        \ ]
endfunction

function! s:GitPickerCheatLines() abort
    let l:space = s:SpaceLayout()
    return [
        \ s:CheatContractLine('git_commit_picker',
        \   l:space ? 'SPC gC' : ',gC', 'FZF commits'),
        \ s:CheatContractLine('git_buffer_commit_picker',
        \   l:space ? 'SPC gB' : ',gB', 'FZF buffer commits'),
        \ ]
endfunction

function! s:MarkdownCheatLines(has_previm) abort
    let l:keys = ChopsticksKeymapContractKeysOr('markdown_maps', [',mt', ',mp'])
    let l:lines = []
    if a:has_previm
        call add(l:lines, s:CheatKeyLine(get(l:keys, 1, ',mp'),
            \ 'markdown preview'))
    endif
    call add(l:lines, s:CheatKeyLine(get(l:keys, 0, ',mt'),
        \ 'table of contents'))
    return l:lines
endfunction

function! s:LintCheatLines() abort
    let l:fallback = s:SpaceLayout()
        \ ? ['SPC xd', 'SPC uf', '[e', ']e']
        \ : [',aD', ',af', '[e', ']e']
    let l:keys = ChopsticksKeymapContractKeysOr('lint_keymaps', l:fallback)
    return [
        \ s:CheatKeyLine(s:CompactKeyPair(l:keys[2:3]), 'ALE errors'),
        \ s:CheatKeyLine(get(l:keys, 0, l:fallback[0]), 'ALE detail'),
        \ s:CheatKeyLine(get(l:keys, 1, l:fallback[1]), 'format on save'),
        \ ]
endfunction

function! s:VisibleJumpCheatLines() abort
    let l:visible_jump = get(s:LearningDailyLoopInfo(), 'visible_jump', {})
    let l:space = s:SpaceLayout()
    let l:keys = ChopsticksKeymapContractKeysOr('visible_jump_summary',
        \ l:space ? ['s', 'SPC S'] : [',S'])
    if l:space
        let l:fallback = [
            \ s:CheatKeyLine(get(l:keys, 0, 's') . '+2ch',
            \   'easymotion jump'),
            \ s:CheatKeyLine(get(l:keys, 1, 'SPC S') . '+2ch',
            \   'jump fallback'),
            \ ]
    else
        let l:fallback = [
            \ s:CheatKeyLine(get(l:keys, 0, ',S') . '+2ch',
            \   'easymotion jump'),
            \ ]
    endif
    return ChopsticksLearningInfoRowLinesOr(l:visible_jump, 'cheat_rows', {
        \ 'indent': '  ',
        \ 'key_width': 9,
        \ }, l:fallback)
endfunction

function! s:ReindentCheatLine() abort
    let l:label = get(g:, 'chopsticks_enable_reindent_file', 0)
        \ ? 're-indent file'
        \ : 're-indent file (opt-in)'
    return s:CheatContractLine('full_file_reindent',
        \ s:SpaceLayout() ? 'SPC c=' : ',F', l:label)
endfunction

function! s:ClipboardCheatLines() abort
    if !ChopsticksRuntimeFeatureAvailable('clipboard')
        return []
    endif
    return [
        \ s:CheatKeyLine(s:ContractPair('clipboard_summary',
        \   s:SpaceLayout() ? ['SPC y', 'SPC p'] : [',y', ',p'], 0),
        \   'clipboard y/p'),
        \ ]
endfunction

function! s:LineMoveCheatLine() abort
    return s:CheatContractPairLine('line_move_summary',
        \ ['Alt+j', 'Alt+k'], 0, 'move line')
endfunction

function! s:LspCheatLines() abort
    let l:lsp_loop = s:LearningLspLoopInfo()
    let l:lines = ChopsticksLearningInfoRowLinesOr(l:lsp_loop,
        \ 'cheat_rows', {
        \   'indent': '  ',
        \   'key_width': 9,
        \ }, [])
    call extend(l:lines, get(l:lsp_loop, 'cheat_command_lines', []))
    return l:lines
endfunction

function! s:LearningLspLoopInfo() abort
    return ChopsticksInfoOr('ChopsticksLearningLspLoopInfo', {})
endfunction

function! s:LearningDailyLoopInfo() abort
    return ChopsticksInfoOr('ChopsticksLearningDailyLoopInfo',
        \ {'summary_lines': []})
endfunction

function! s:TrainedLoopLines() abort
    return map(copy(get(s:LearningDailyLoopInfo(), 'summary_lines', [])),
        \ "'  ' . v:val")
endfunction

function! s:LearningEntrypointKey() abort
    let l:info = s:LearningEntrypointInfo()
    let l:key = get(l:info, 'key', '')
    if !empty(l:key)
        return l:key
    endif
    let l:fallback_key = s:SpaceLayout() ? 'SPC ?' : ',?'
    return get(ChopsticksKeymapContractKeysOr('learning_entrypoint',
        \ [l:fallback_key]), 0, l:fallback_key)
endfunction

function! s:LearningEntrypointLhs(field) abort
    let l:info = s:LearningEntrypointInfo()
    let l:lhs = get(l:info, a:field, '')
    if !empty(l:lhs)
        return l:lhs
    endif
    let l:fallback_lhs = s:SpaceLayout() ? '<Space>?' : ',?'
    let l:spec = ChopsticksKeymapContractFirstSpecOr('learning_entrypoint', {
        \ 'kind': 'map',
        \ 'mode': 'n',
        \ 'lhs': l:fallback_lhs,
        \ 'text': 'ChopsticksCheatSheet',
        \ 'key': s:LearningEntrypointKey(),
        \ 'display_key': s:LearningEntrypointKey(),
        \ })
    return get(l:spec, 'lhs', l:fallback_lhs)
endfunction

function! s:LearningEntrypointInfo() abort
    return ChopsticksInfoOr('ChopsticksLearningEntrypointInfo', {})
endfunction

function! s:CheatSheetTitle() abort
    return get(s:LearningEntrypointInfo(), 'cheat_title',
        \ '  chopsticks         ' . s:LearningEntrypointKey() . ' close')
endfunction

function! s:CheatSheetCloseLhs() abort
    return get(s:LearningEntrypointInfo(), 'close_lhs',
        \ s:LearningEntrypointLhs('close_lhs'))
endfunction

function! s:CheatSheetOpenLhs() abort
    return get(s:LearningEntrypointInfo(), 'open_lhs',
        \ s:LearningEntrypointLhs('open_lhs'))
endfunction

function! s:MapCheatSheetEntrypoint() abort
    let l:open_lhs = s:CheatSheetOpenLhs()
    if !empty(l:open_lhs)
        execute 'nnoremap <silent> ' . l:open_lhs . ' :ChopsticksCheatSheet<CR>'
    endif
endfunction

function! s:OpenCheatSheet(lines) abort
    let l:close_lhs = s:CheatSheetCloseLhs()
    let l:mappings = []
    if !empty(l:close_lhs)
        call add(l:mappings, {'lhs': l:close_lhs, 'rhs': ':bd<CR>'})
    endif
    call ChopsticksOpenScratchBuffer('__ChopsticksCheatSheet__', a:lines, {
        \ 'split': 'vertical botright new',
        \ 'width': 42,
        \ 'winfixwidth': 1,
        \ 'mappings': l:mappings,
        \ })
endfunction

function! s:CheatSheet() abort
    let l:has_lsp = get(g:, 'chopsticks_enable_lsp', 1)
    let l:has_lint = get(g:, 'chopsticks_enable_lint', 1)
    let l:has_undotree = ChopsticksPluginDeclared('undotree')
    let l:has_previm = ChopsticksPluginDeclared('previm')

    if g:chopsticks_space_keymaps
        let l:lines = [
            \ s:CheatSheetTitle(),
            \ '  ─────────────────────────────────',
            \ '',
            \ '  trained loop:',
            \ ]
        call extend(l:lines, s:TrainedLoopLines())
        call extend(l:lines, [
            \ '',
            \ '  ── fast path ─────────────',
            \ s:CheatContractLine('project_files', 'SPC SPC', 'files'),
            \ s:CheatContractLine('project_buffers', 'SPC ,', 'buffers'),
            \ s:CheatContractLine('project_grep', 'SPC /', 'grep project'),
            \ s:CheatContractLine('buffer_alternate', 'SPC Tab',
            \   'last file'),
            \ s:CheatContractLineAt('file_sidebar',
            \   ['SPC e', 'SPC E'], 0, 'sidebar (cwd)'),
            \ s:CheatContractLineAt('file_sidebar',
            \   ['SPC e', 'SPC E'], 1, 'sidebar (file dir)'),
            \ '',
            \ '  ── files/find ────────────',
            \ s:CheatContractLine('project_files_picker',
            \   'SPC ff', 'files'),
            \ s:CheatContractLine('project_buffers_picker',
            \   'SPC fb', 'buffers'),
            \ s:CheatContractLine('project_git_files',
            \   'SPC fg', 'git files'),
            \ s:CheatContractLine('project_recent_files',
            \   'SPC fr', 'recent files'),
            \ s:CheatContractLine('project_buffer_lines',
            \   'SPC fl', 'lines in buffer'),
            \ s:CheatContractLine('project_commands',
            \   'SPC sc', 'commands'),
            \ s:CheatContractLine('project_marks', 'SPC sm', 'marks'),
            \ s:CheatContractLine('project_search_history',
            \   'SPC s/', 'search history'),
            \ s:CheatContractLine('project_command_history',
            \   'SPC s:', 'command history'),
            \ s:CheatContractLine('project_grep_picker',
            \   'SPC sg', 'grep project'),
            \ s:CheatContractLine('project_grep_word',
            \   'SPC sw', 'grep word'),
            \ s:CheatContractLine('project_tags', 'SPC st', 'tags'),
            \ '',
            \ '  ── code ──────────────────',
            \ ])

        if l:has_lsp
            call extend(l:lines, s:LspCheatLines())
        endif

        call extend(l:lines, [
            \ s:CheatContractLine('project_run', 'SPC rr', 'run file'),
            \ s:ReindentCheatLine(),
            \ ])
        call extend(l:lines, s:MarkdownCheatLines(l:has_previm))

        if l:has_lint
            call extend(l:lines, s:LintCheatLines())
        endif

        call extend(l:lines, [
            \ '',
            \ '  ── edit ──────────────────',
            \ '  gc        comment',
            \ '  cl / cc   native s / S substitute',
            \ '  cs"''      surround',
            \ ])
        call extend(l:lines, s:VisibleJumpCheatLines())
        call extend(l:lines, ChopsticksKeymapContractLinesOr('edit_cleanup_summary',
            \ '  ', 9, [
            \ '  SPC cW    strip trailing whitespace',
            \ '  SPC sr    replace word',
            \ '  SPC =     indent selection',
            \ ]))

        if l:has_undotree
            call add(l:lines, s:CheatContractLine('undo_tree',
                \ 'SPC U', 'undo tree'))
        endif

        call extend(l:lines, s:ClipboardCheatLines())
        call add(l:lines, s:LineMoveCheatLine())
        call extend(l:lines, [
            \ '',
            \ '  ── git ───────────────────',
            \ ])
        call extend(l:lines, s:GitCheatLines())
        call extend(l:lines, s:GitPickerCheatLines())
        call extend(l:lines, [
            \ s:CheatContractPairLine('git_conflict_navigation',
            \   ['[x', ']x'], 0, 'conflict markers'),
            \ '',
            \ '  ── windows ───────────────',
            \ s:CheatKeyLine(s:WindowNavigationCompact(), 'windows'),
            \ '  <C-w>hjkl native fallback',
            \ s:CheatContractPairLine('buffer_navigation',
            \   ['SPC bn', 'SPC bp'], 1, 'prev / next buf'),
            \ s:CheatContractLine('buffer_close', 'SPC bd',
            \   'close buffer'),
            \ s:CheatContractLine('buffer_close_others', 'SPC bo',
            \   'close other buffers'),
            \ s:CheatContractLine('window_layout', 'SPC z',
            \   'maximize toggle'),
            \ s:CheatContractPairLine('terminal_entry',
            \   ['SPC tt', 'SPC th'], 0, 'terminal / split'),
            \ s:CheatContractPairLine('quickfix_navigation',
            \   ['[q', ']q'], 1, 'next / prev qf'),
            \ s:CheatContractPairLine('loclist_navigation',
            \   ['[l', ']l'], 1, 'next / prev loc'),
            \ s:CheatContractPairLine('quickfix_window',
            \   ['SPC xq', 'SPC xQ'], 0, 'open / close qf'),
            \ s:CheatContractPairLine('loclist_window',
            \   ['SPC xl', 'SPC xL'], 0, 'open / close loclist'),
            \ '',
            \ '  ── toggle ────────────────',
            \ ])
        call extend(l:lines, ChopsticksKeymapContractLinesOr('core_toggles', '  ', 9, [
            \ '  F2        paste mode',
            \ '  F3        line numbers',
            \ '  F4        relative numbers',
            \ '  F6        invisible chars',
            \ '  SPC us    spell check',
            \ ]))
        call extend(l:lines, [
            \ '',
            \ '  ── survival ──────────────',
            \ ])
        call extend(l:lines, ChopsticksKeymapContractLinesOr('survival_core', '  ', 9, [
            \ '  SPC w     save',
            \ '  SPC W     save all',
            \ '  SPC q     quit',
            \ ]))
        call extend(l:lines, [
            \ '  :x / ZZ   save + quit',
            \ '  Esc       exit insert',
            \ ])
        call extend(l:lines, ChopsticksKeymapContractLinesOr('survival_config', '  ', 9, [
            \ '  SPC fc    edit local config',
            \ '  SPC fv    edit vimrc',
            \ '  SPC fV    reload vimrc',
            \ ]))
        call extend(l:lines, s:SurvivalCommandLines())

        call s:OpenCheatSheet(l:lines)
        return
    endif

    let l:lines = [
        \ s:CheatSheetTitle(),
        \ '  ─────────────────────────────',
        \ '',
        \ '  trained loop:',
        \ ]
    call extend(l:lines, s:TrainedLoopLines())
    call extend(l:lines, [
        \ '',
        \ '  ── files ──────────────────',
        \ s:CheatContractLine('project_files', ',ff', 'files'),
        \ s:CheatContractLine('project_buffers', ',b', 'buffers'),
        \ s:CheatContractLine('project_grep', ',rg', 'grep project'),
        \ s:CheatContractLine('project_grep_word', ',rG', 'grep word'),
        \ s:CheatContractLineAt('file_sidebar',
        \   [',e', ',E'], 0, 'sidebar (cwd)'),
        \ s:CheatContractLineAt('file_sidebar',
        \   [',e', ',E'], 1, 'sidebar (file dir)'),
        \ s:CheatContractLine('buffer_alternate', ',,', 'last file'),
        \ s:CheatContractLine('project_recent_files',
        \   ',fh', 'recent files'),
        \ s:CheatContractLine('project_buffer_lines',
        \   ',fl', 'lines in buffer'),
        \ s:CheatContractLine('project_commands', ',fc', 'commands'),
        \ s:CheatContractLine('project_marks', ',fm', 'marks'),
        \ '',
        \ '  ── code ──────────────────',
        \ ])

    if l:has_lsp
        call extend(l:lines, s:LspCheatLines())
    endif

    call add(l:lines, s:CheatContractLine('project_run', ',cr',
        \ 'run file'))
    call extend(l:lines, s:MarkdownCheatLines(l:has_previm))

    if l:has_lint
        call extend(l:lines, s:LintCheatLines())
    endif

    call extend(l:lines, [
        \ '',
        \ '  ── edit ──────────────────',
        \ '  gc        comment',
        \ '  cs"''      surround',
        \ ])
    call extend(l:lines, s:VisibleJumpCheatLines())
    call extend(l:lines, ChopsticksKeymapContractLinesOr('edit_cleanup_summary',
        \ '  ', 9, [
        \ '  ,W        strip trailing whitespace',
        \ '  ,*        replace word',
        \ '  ,F        indent selection',
        \ ]))
    if get(g:, 'chopsticks_enable_reindent_file', 0)
        call add(l:lines, s:ReindentCheatLine())
    endif

    if l:has_undotree
        call add(l:lines, s:CheatContractLine('undo_tree',
            \ ',u', 'undo tree'))
    endif

    call extend(l:lines, s:ClipboardCheatLines())
    call add(l:lines, s:LineMoveCheatLine())
    call extend(l:lines, [
        \ '',
        \ '  ── git ───────────────────',
        \ ])
    call extend(l:lines, s:GitCheatLines())
    call extend(l:lines, s:GitPickerCheatLines())
    call extend(l:lines, [
        \ s:CheatContractPairLine('git_conflict_navigation',
        \   ['[x', ']x'], 0, 'conflict markers'),
        \ '',
        \ '  ── windows ───────────────',
        \ s:CheatKeyLine(s:WindowNavigationCompact(), 'windows'),
        \ '  <C-w>hjkl native fallback',
        \ s:CheatContractPairLine('buffer_navigation',
        \   [',l', ',h'], 1, 'prev / next buf'),
        \ s:CheatContractLine('buffer_close', ',bd', 'close buffer'),
        \ s:CheatContractLine('window_layout', ',z', 'maximize toggle'),
        \ s:CheatKeyLine(s:WindowResizeSummary(), 'resize height'),
        \ s:CheatContractPairLine('terminal_entry',
        \   [',tv', ',th'], 0, 'terminal v / h'),
        \ s:CheatContractPairLine('quickfix_navigation',
        \   ['[q', ']q'], 1, 'next / prev qf'),
        \ s:CheatContractPairLine('loclist_navigation',
        \   ['[l', ']l'], 1, 'next / prev loc'),
        \ s:CheatContractPairLine('quickfix_window',
        \   [',qo', ',qc'], 0, 'open / close qf'),
        \ '',
        \ '  ── toggle ────────────────',
        \ ])
    call extend(l:lines, ChopsticksKeymapContractLinesOr('core_toggles', '  ', 9, [
        \ '  F2        paste mode',
        \ '  F3        line numbers',
        \ '  F4        relative numbers',
        \ '  F6        invisible chars',
        \ '  ,ss       spell check',
        \ ]))
    call extend(l:lines, [
        \ '',
        \ '  ── survival ──────────────',
        \ ])
    call extend(l:lines, ChopsticksKeymapContractLinesOr('survival_core', '  ', 9, [
        \ '  ,w        save',
        \ '  ,q        quit',
        \ '  ,x        save + quit',
        \ ]))
    call add(l:lines, '  Esc       exit insert')
    call extend(l:lines, ChopsticksKeymapContractLinesOr('survival_config', '  ', 9, [
        \ '  ,ec       edit local config',
        \ '  ,ev       edit vimrc',
        \ '  ,sv       reload vimrc',
        \ ]))
    call extend(l:lines, s:SurvivalCommandLines())

    call s:OpenCheatSheet(l:lines)
endfunction

command! ChopsticksCheatSheet call s:CheatSheet()
call s:MapCheatSheetEntrypoint()
