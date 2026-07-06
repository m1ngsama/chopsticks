" tutor.vim — guided practice for chopsticks keymaps

function! s:OpenTutor(lines) abort
    let l:surface = ChopsticksOpenScratchBuffer('__ChopsticksTutor__',
        \ a:lines, {'height': 38})
    return get(l:surface, 'opened', 0)
endfunction

function! s:SupportCommandLines() abort
    return ChopsticksCommandLinesOr('survival', '     ', [
        \ '     :ChopsticksHelp        full help',
        \ '     :ChopsticksConfig      local config',
        \ '     :ChopsticksReload      reload config',
        \ '     :ChopsticksTutor       practice',
        \ '     :ChopsticksStatus      health',
        \ '     :ChopsticksDoctor      issues',
        \ '     :ChopsticksKeymapAudit key audit',
        \ '     :ChopsticksBeta        release checklist',
        \ '     :ChopsticksBetaLog     release notes',
        \ '     :ChopsticksBetaSession new release note',
        \ ]
        \ )
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

function! s:TutorKeyLine(key, label) abort
    return ChopsticksDisplayKeyLine('     ', 10, a:key, a:label)
endfunction

function! s:VisibleJumpKeys() abort
    return ChopsticksKeymapContractKeysOr('visible_jump_summary',
        \ s:SpaceLayout() ? ['s', 'SPC S'] : [',S'])
endfunction

function! s:VisibleJumpInfo() abort
    return get(s:LearningDailyLoopInfo(), 'visible_jump', {})
endfunction

function! s:VisibleJumpPrimaryKey() abort
    let l:visible_jump = s:VisibleJumpInfo()
    if has_key(l:visible_jump, 'primary_key')
        return get(l:visible_jump, 'primary_key', '')
    endif
    return get(s:VisibleJumpKeys(), 0, s:SpaceLayout() ? 's' : ',S')
endfunction

function! s:VisibleJumpTrainingLine() abort
    let l:visible_jump = s:VisibleJumpInfo()
    let l:line = get(l:visible_jump, 'tutor_training_line', '')
    if !empty(l:line)
        return l:line
    endif
    return '     ' . s:VisibleJumpPrimaryKey()
        \ . ' + 2 chars jump to visible text'
endfunction

function! s:VisibleJumpTutorLines() abort
    let l:visible_jump = s:VisibleJumpInfo()
    let l:lines = get(l:visible_jump, 'tutor_lines', [])
    if !empty(l:lines)
        return copy(l:lines)
    endif
    let l:keys = s:VisibleJumpKeys()
    if s:SpaceLayout()
        return [
            \ '     ' . get(l:keys, 0, 's')
            \   . ' + 2 chars  visible jump',
            \ ChopsticksDisplayKeyLine('     ', 12,
            \   get(l:keys, 1, 'SPC S'), 'same jump fallback'),
            \ ]
    endif
    return [
        \ '     ' . get(l:keys, 0, ',S')
        \   . ' + 2 chars  EasyMotion jump',
        \ ]
endfunction

function! s:UndoTreeTutorLine() abort
    if !get(g:, 'chopsticks_enable_ui_extras', 1)
        return ''
    endif
    if !ChopsticksPluginDeclared('undotree')
        return ''
    endif
    let l:key = s:ContractKey('undo_tree',
        \ s:SpaceLayout() ? 'SPC U' : ',u')
    let l:width = s:SpaceLayout() ? 13 : 14
    return ChopsticksDisplayKeyLine('     ', l:width - 1, l:key,
        \ 'undo tree')
endfunction

function! s:ProjectFilesKey() abort
    return s:ContractKey('project_files',
        \ s:SpaceLayout() ? 'SPC SPC' : ',ff')
endfunction

function! s:ProjectBuffersKey() abort
    return s:ContractKey('project_buffers',
        \ s:SpaceLayout() ? 'SPC ,' : ',b')
endfunction

function! s:ProjectGrepKey() abort
    return s:ContractKey('project_grep',
        \ s:SpaceLayout() ? 'SPC /' : ',rg')
endfunction

function! s:ProjectRunKey() abort
    return s:ContractKey('project_run',
        \ s:SpaceLayout() ? 'SPC rr' : ',cr')
endfunction

function! s:BufferAlternateKey() abort
    return s:ContractKey('buffer_alternate',
        \ s:SpaceLayout() ? 'SPC Tab' : ',,')
endfunction

function! s:SidebarKeys() abort
    return ChopsticksKeymapContractKeysOr('file_sidebar',
        \ s:SpaceLayout() ? ['SPC e', 'SPC E'] : [',e', ',E'])
endfunction

function! s:SidebarPair() abort
    let l:keys = s:SidebarKeys()
    if s:SpaceLayout()
        return get(l:keys, 0, 'SPC e') . '/'
            \ . substitute(get(l:keys, 1, 'SPC E'), '^SPC ', '', '')
    endif
    return join(l:keys, '/')
endfunction

function! s:WindowLayoutKey() abort
    return s:ContractKey('window_layout',
        \ s:SpaceLayout() ? 'SPC z' : ',z')
endfunction

function! s:WindowNavigationLabel() abort
    let l:keys = ChopsticksKeymapContractKeysOr('window_navigation',
        \ ['<C-h>', '<C-j>', '<C-k>', '<C-l>'])
    if join(l:keys, '/') ==# '<C-h>/<C-j>/<C-k>/<C-l>'
        return 'Ctrl-h/j/k/l'
    endif
    return join(l:keys, '/')
endfunction

function! s:WindowHorizontalNavigationLabel() abort
    let l:keys = ChopsticksKeymapContractKeysOr('window_navigation',
        \ ['<C-h>', '<C-j>', '<C-k>', '<C-l>'])
    if get(l:keys, 0, '') ==# '<C-h>' && get(l:keys, 3, '') ==# '<C-l>'
        return 'Ctrl-h/l'
    endif
    return get(l:keys, 0, '<C-h>') . '/'
        \ . get(l:keys, 3, '<C-l>')
endfunction

function! s:GitStatusKey() abort
    return s:ContractKey('git_status',
        \ s:SpaceLayout() ? 'SPC gs' : ',gs')
endfunction

function! s:GitLogKey() abort
    return s:ContractKey('git_log',
        \ s:SpaceLayout() ? 'SPC gl' : ',gL')
endfunction

function! s:GitStatusDiffBlame() abort
    let l:keys = [
        \ s:GitStatusKey(),
        \ s:ContractKey('git_diff', s:SpaceLayout() ? 'SPC gd' : ',gd'),
        \ s:ContractKey('git_blame', s:SpaceLayout() ? 'SPC gb' : ',gb'),
        \ ]
    if s:SpaceLayout()
        return l:keys[0] . '/'
            \ . substitute(l:keys[1], '^SPC ', '', '')
            \ . '/'
            \ . substitute(l:keys[2], '^SPC ', '', '')
    endif
    return join(l:keys, '/')
endfunction

function! s:QuickfixLoclistKeys() abort
    let l:qf = ChopsticksKeymapContractKeysOr('quickfix_navigation',
        \ ['[q', ']q'])
    let l:loc = ChopsticksKeymapContractKeysOr('loclist_navigation',
        \ ['[l', ']l'])
    return join(l:qf, '/') . ' ' . join(l:loc, '/')
endfunction

function! s:LearningDailyLoopInfo() abort
    return ChopsticksInfoOr('ChopsticksLearningDailyLoopInfo', {})
endfunction

function! s:LearningLspLoopInfo() abort
    return ChopsticksInfoOr('ChopsticksLearningLspLoopInfo', {})
endfunction

function! s:LearningEntrypointInfo() abort
    return ChopsticksInfoOr('ChopsticksLearningEntrypointInfo', {})
endfunction

function! s:LearningEntrypointLines(fallback) abort
    let l:info = s:LearningEntrypointInfo()
    let l:lines = get(l:info, 'tutor_lines', [])
    if !empty(l:lines)
        return copy(l:lines)
    endif
    return ChopsticksKeymapContractLinesOr('learning_entrypoint', '     ', 10, a:fallback)
endfunction

function! s:DailyLoopTutorLines() abort
    let l:loop = s:LearningDailyLoopInfo()

    let l:lines = [
        \ s:TutorKeyLine(s:ProjectFilesKey(), 'open a project file'),
        \ s:VisibleJumpTrainingLine(),
        \ ]
    let l:lsp_training_line = s:LspTrainingLine()
    if !empty(l:lsp_training_line)
        call add(l:lines, l:lsp_training_line)
    endif
    call extend(l:lines, [
        \ s:TutorKeyLine(s:ProjectRunKey(), 'run current file'),
        \ s:TutorKeyLine(s:ProjectGrepKey(), 'grep project'),
        \ s:TutorKeyLine(s:GitStatusKey(), 'check git status'),
        \ ])
    return ChopsticksLearningInfoRowLinesOr(l:loop, 'tutor_rows', {
        \ 'indent': '     ',
        \ 'key_width': 10,
        \ }, l:lines)
endfunction

function! s:DailyDrill() abort
    let l:loop = s:LearningDailyLoopInfo()
    let l:steps = [
        \ s:ProjectFilesKey(),
        \ s:VisibleJumpPrimaryKey(),
        \ ]
    if s:LspTutorAvailable()
        call add(l:steps, s:LspDefinitionHoverDrill())
    endif
    call extend(l:steps, [
        \ 'edit',
        \ s:ProjectRunKey(),
        \ s:ProjectGrepKey(),
        \ s:GitStatusKey(),
        \ ])
    return ChopsticksLearningDrillLine(l:loop, l:steps)
endfunction

function! s:LspTutorAvailable() abort
    let l:lsp_loop = s:LearningLspLoopInfo()
    let l:loop = s:LearningDailyLoopInfo()
    return ChopsticksLearningLoopEnabled(l:loop, l:lsp_loop,
        \ get(g:, 'chopsticks_enable_lsp', 1))
endfunction

function! s:LspDefinitionReferencesDocs() abort
    let l:lsp_loop = s:LearningLspLoopInfo()
    let l:space = s:SpaceLayout()
    let l:fallback = join([
        \ s:ContractKey('lsp_definition', l:space ? 'gd' : ',dd'),
        \ s:ContractKey('lsp_references', l:space ? 'gr' : ',dr'),
        \ s:ContractKey('lsp_hover', l:space ? 'K' : ',dk'),
        \ ], ' / ')
    return ChopsticksLearningKey(l:lsp_loop, 'definition_references_docs',
        \ l:fallback)
endfunction

function! s:LspImplementationType() abort
    let l:lsp_loop = s:LearningLspLoopInfo()
    let l:space = s:SpaceLayout()
    let l:fallback = join([
        \ s:ContractKey('lsp_implementation', l:space ? 'gI' : ',di'),
        \ s:ContractKey('lsp_type_definition', l:space ? 'gy' : ',dt'),
        \ ], ' / ')
    return ChopsticksLearningKey(l:lsp_loop, 'implementation_type',
        \ l:fallback)
endfunction

function! s:LspDiagnostics() abort
    let l:lsp_loop = s:LearningLspLoopInfo()
    let l:space = s:SpaceLayout()
    let l:fallback = join([
        \ s:ContractKey('lsp_previous_diagnostic',
        \   l:space ? '[d' : ',dp'),
        \ s:ContractKey('lsp_next_diagnostic',
        \   l:space ? ']d' : ',dn'),
        \ ], ' ')
    return ChopsticksLearningKey(l:lsp_loop, 'diagnostics', l:fallback)
endfunction

function! s:LspActionsRenameFormat() abort
    let l:lsp_loop = s:LearningLspLoopInfo()
    let l:space = s:SpaceLayout()
    let l:fallback = join([
        \ s:ContractKey('lsp_code_action', l:space ? 'SPC ca' : ',ca'),
        \ s:ContractKey('lsp_rename', l:space ? 'SPC cr' : ',rn'),
        \ s:ContractKey('lsp_format_normal', l:space ? 'SPC cf' : ',f'),
        \ ], '/')
    return ChopsticksLearningKey(l:lsp_loop, 'actions_rename_format',
        \ l:fallback)
endfunction

function! s:LspDefinitionHoverDrill() abort
    let l:lsp_loop = s:LearningLspLoopInfo()
    let l:space = s:SpaceLayout()
    let l:definition = ChopsticksLearningKey(l:lsp_loop, 'definition',
        \ s:ContractKey('lsp_definition', l:space ? 'gd' : ',dd'))
    let l:hover = ChopsticksLearningKey(l:lsp_loop, 'hover',
        \ s:ContractKey('lsp_hover', l:space ? 'K' : ',dk'))
    return l:definition . '/' . l:hover
endfunction

function! s:LspTrainingLine() abort
    if !s:LspTutorAvailable()
        return ''
    endif
    return '     ' . s:LspDefinitionReferencesDocs()
        \ . ' inspect definition / refs / docs'
endfunction

function! s:LspTutorLines() abort
    if !s:LspTutorAvailable()
        return []
    endif
    let l:lsp_loop = s:LearningLspLoopInfo()
    if s:SpaceLayout()
        let l:fallback = [
            \ '     ' . s:LspDefinitionReferencesDocs()
            \   . '  definition / refs / docs',
            \ '     ' . s:LspImplementationType()
            \   . '      implementation / type',
            \ '     ' . s:LspDiagnostics()
            \   . '        LSP diagnostics',
            \ '     ' . s:LspActionsRenameFormat()
            \   . ' action / rename / format',
            \ ]
    else
        let l:fallback = [
            \ '     ' . join(ChopsticksKeymapContractKeysOr('lsp_definition_references',
            \   [',dd', ',dr']), ' / ') . '  definition / refs',
            \ '     ' . s:ContractKey('lsp_hover', ',dk') . '        hover docs',
            \ '     ' . join([
            \       s:ContractKey('lsp_code_action', ',ca'),
            \       s:ContractKey('lsp_rename', ',rn'),
            \   ], ' / ') . '  action / rename',
            \ '     ' . s:ContractKey('lsp_format_normal', ',f') . '         format',
            \ ]
    endif
    return ChopsticksLearningInfoRowLinesOr(l:lsp_loop, 'tutor_rows', {
        \ 'indent': '     ',
        \ 'key_width': 10,
        \ }, l:fallback)
endfunction

function! s:ChopsticksTutor() abort
    if g:chopsticks_space_keymaps
        let l:lines = [
            \ '  chopsticks tutor        q close',
            \ '  ───────────────────────────────',
            \ '',
            \ '  Goal: train one long-term project loop around Vim.',
            \ '  Keep Vim editing habits; standardize the surrounding work.',
            \ '',
            \ '  1. trained loop',
            \ ]
        call extend(l:lines, s:DailyLoopTutorLines())
        call extend(l:lines, s:LearningEntrypointLines([
            \ '     SPC ?      active cheat sheet',
            \ ]))
        call extend(l:lines, [
            \ '',
            \ '  2. survival',
            \ ])
        call extend(l:lines, ChopsticksKeymapContractLinesOr('survival_core', '     ', 10, [
            \ '     SPC w      save',
            \ '     SPC W      save all',
            \ '     SPC q      quit',
            \ ]))
        call extend(l:lines, [
            \ '     :x / ZZ    save and quit',
            \ '     Esc        Normal mode',
            \ ])
        call extend(l:lines, ChopsticksKeymapContractLinesOr('survival_config', '     ', 10, [
            \ '     SPC fc     edit local config',
            \ '     SPC fv     edit vimrc',
            \ '     SPC fV     reload vimrc',
            \ ]))
        call extend(l:lines, s:SupportCommandLines())
        call extend(l:lines, [
            \ '',
            \ '  3. find and switch',
            \ s:TutorKeyLine(s:ProjectFilesKey(), 'find files'),
            \ s:TutorKeyLine(s:ProjectGrepKey(), 'grep project'),
            \ s:TutorKeyLine(s:ProjectBuffersKey(), 'buffers'),
            \ s:TutorKeyLine(s:BufferAlternateKey(), 'alternate buffer'),
            \ s:TutorKeyLine(s:SidebarPair(), 'sidebar cwd / file dir'),
            \ '',
            \ '  4. jump and edit',
            \ ])
        call extend(l:lines, s:VisibleJumpTutorLines())
        call extend(l:lines, [
            \ '     cl / cc      native s / S substitute',
            \ '     gc           comment',
            \ ])
        let l:undo_line = s:UndoTreeTutorLine()
        if !empty(l:undo_line)
            call add(l:lines, l:undo_line)
        endif
        call extend(l:lines, [
            \ '',
            \ '  5. code loop',
            \ ])
        call extend(l:lines, s:LspTutorLines())
        call extend(l:lines, [
            \ ChopsticksDisplayKeyLine('     ', 12, s:ProjectRunKey(),
            \   'run current file'),
            \ '',
            \ '  6. git and windows',
            \ ChopsticksDisplayKeyLine('     ', 13,
            \   s:GitStatusDiffBlame(), 'status / diff / blame'),
            \ ChopsticksDisplayKeyLine('     ', 13, s:GitLogKey(),
            \   'log graph'),
            \ '     ' . s:WindowNavigationLabel() . ' split navigation',
            \ '     <C-w>hjkl    native fallback',
            \ '     ' . get(s:SidebarKeys(), 0, 'SPC e') . ', '
            \   . s:WindowHorizontalNavigationLabel()
            \   . '  enter/leave sidebar',
            \ ChopsticksDisplayKeyLine('     ', 13, s:WindowLayoutKey(),
            \   'maximize split'),
            \ ChopsticksDisplayKeyLine('     ', 13,
            \   s:QuickfixLoclistKeys(), 'qf / loclist'),
            \ '',
            \ '  daily drill',
            \ '     ' . s:DailyDrill(),
            \ ])
    else
        let l:lines = [
            \ '  chopsticks tutor        q close',
            \ '  ───────────────────────────────',
            \ '',
            \ '  Goal: train one long-term project loop around Vim.',
            \ '',
            \ '  classic layout',
            \ ]
        call extend(l:lines, s:LearningEntrypointLines([
            \ '     ,?         active cheat sheet',
            \ ]))
        call extend(l:lines, [
            \ '     ,w / ,x    save / save and quit',
            \ s:TutorKeyLine(s:ProjectFilesKey(), 'find files'),
            \ s:TutorKeyLine(s:ProjectGrepKey(), 'grep project'),
            \ s:TutorKeyLine(s:ProjectBuffersKey(), 'buffers'),
            \ s:TutorKeyLine(s:BufferAlternateKey(), 'alternate buffer'),
            \ '',
            \ '  code loop',
            \ ])
        call extend(l:lines, s:LspTutorLines())
        call extend(l:lines, [
            \ s:TutorKeyLine(s:ProjectRunKey(), 'run current file'),
            \ '',
            \ '  edit and git',
            \ ])
        call extend(l:lines, s:VisibleJumpTutorLines())
        call extend(l:lines, [
            \ '     gc            comment',
            \ ])
        let l:undo_line = s:UndoTreeTutorLine()
        if !empty(l:undo_line)
            call add(l:lines, l:undo_line)
        endif
        call extend(l:lines, [
            \ ChopsticksDisplayKeyLine('     ', 13,
            \   s:GitStatusDiffBlame(), 'status / diff / blame'),
            \ '     ' . s:WindowNavigationLabel() . '  split navigation',
            \ '     <C-w>hjkl     native fallback',
            \ ChopsticksDisplayKeyLine('     ', 13,
            \   s:QuickfixLoclistKeys(), 'qf / loclist'),
            \ '',
            \ '  support',
            \ ])
        call extend(l:lines, ChopsticksKeymapContractLinesOr('survival_config', '     ', 9, [
            \ '     ,ec       edit local config',
            \ '     ,ev       edit vimrc',
            \ '     ,sv       reload vimrc',
            \ ]))
        call extend(l:lines, s:SupportCommandLines())
        call extend(l:lines, [
            \ '     README.md          full reference',
            \ '     QUICKSTART.md      5-minute path',
            \ ])
    endif

    if s:OpenTutor(l:lines)
        nnoremap <buffer> <silent> ? :ChopsticksCheatSheet<CR>
    endif
endfunction
command! ChopsticksTutor call s:ChopsticksTutor()
