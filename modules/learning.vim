" learning.vim — Learning Surface model and readiness

function! s:PrimaryCommand(commands, fallback) abort
    return ':' . get(a:commands, 0, a:fallback)
endfunction

function! s:FallbackLearningEntrypointSpec() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return {
            \ 'kind': 'map',
            \ 'mode': 'n',
            \ 'lhs': '<Space>?',
            \ 'text': 'ChopsticksCheatSheet',
            \ 'key': 'SPC ?',
            \ 'display_key': 'SPC ?',
            \ }
    endif
    return {
        \ 'kind': 'map',
        \ 'mode': 'n',
        \ 'lhs': ',?',
        \ 'text': 'ChopsticksCheatSheet',
        \ 'key': ',?',
        \ 'display_key': ',?',
        \ }
endfunction

function! s:ContractKey(group, fallback) abort
    return get(ChopsticksKeymapContractKeysOr(a:group, [a:fallback]), 0,
        \ a:fallback)
endfunction

function! s:SpaceLayout() abort
    return get(g:, 'chopsticks_space_keymaps', 1)
endfunction

function! s:LspLearningEnabled() abort
    return ChopsticksLspLearningEnabledOr(
        \ get(g:, 'chopsticks_enable_lsp', 1))
endfunction

function! s:LearningLspLoopInfo() abort
    let l:space = s:SpaceLayout()
    let l:definition_references = ChopsticksKeymapContractKeysOr(
        \ 'lsp_definition_references',
        \ l:space ? ['gd', 'gr'] : [',dd', ',dr'])
    let l:definition = get(l:definition_references, 0,
        \ l:space ? 'gd' : ',dd')
    let l:references = get(l:definition_references, 1,
        \ l:space ? 'gr' : ',dr')
    let l:hover = s:ContractKey('lsp_hover', l:space ? 'K' : ',dk')
    let l:implementation = s:ContractKey('lsp_implementation',
        \ l:space ? 'gI' : ',di')
    let l:type_definition = s:ContractKey('lsp_type_definition',
        \ l:space ? 'gy' : ',dt')
    let l:previous_diagnostic = s:ContractKey('lsp_previous_diagnostic',
        \ l:space ? '[d' : ',dp')
    let l:next_diagnostic = s:ContractKey('lsp_next_diagnostic',
        \ l:space ? ']d' : ',dn')
    let l:code_action = s:ContractKey('lsp_code_action',
        \ l:space ? 'SPC ca' : ',ca')
    let l:rename = s:ContractKey('lsp_rename',
        \ l:space ? 'SPC cr' : ',rn')
    let l:format = s:ContractKey('lsp_format_normal',
        \ l:space ? 'SPC cf' : ',f')
    let l:status = s:ContractKey('lsp_status', l:space ? 'SPC ci' : '')
    let l:outline = s:ContractKey('lsp_outline',
        \ l:space ? 'SPC co' : ',o')
    let l:workspace_symbols = s:ContractKey('lsp_workspace_symbols',
        \ l:space ? 'SPC cS' : ',ws')
    let l:keys = {
        \ 'definition': l:definition,
        \ 'references': l:references,
        \ 'definition_references': join([l:definition, l:references],
        \   ' / '),
        \ 'hover': l:hover,
        \ 'definition_references_docs': join([
        \   l:definition, l:references, l:hover], ' / '),
        \ 'implementation': l:implementation,
        \ 'type_definition': l:type_definition,
        \ 'implementation_type': join([
        \   l:implementation, l:type_definition], ' / '),
        \ 'previous_diagnostic': l:previous_diagnostic,
        \ 'next_diagnostic': l:next_diagnostic,
        \ 'diagnostics': join([
        \   l:previous_diagnostic, l:next_diagnostic], ' '),
        \ 'code_action': l:code_action,
        \ 'rename': l:rename,
        \ 'format': l:format,
        \ 'status': l:status,
        \ 'outline': l:outline,
        \ 'workspace_symbols': l:workspace_symbols,
        \ 'actions_rename_format': join([
        \   l:code_action, l:rename, l:format], '/'),
        \ 'actions_rename': join([l:code_action, l:rename], ' / '),
        \ }
    let l:tutor_rows = l:space ? [
        \ {'key': l:keys.definition_references_docs,
        \  'label': 'definition / refs / docs', 'gap': '  '},
        \ {'key': l:keys.implementation_type,
        \  'label': 'implementation / type', 'gap': '      '},
        \ {'key': l:keys.diagnostics,
        \  'label': 'LSP diagnostics', 'gap': '        '},
        \ {'key': l:keys.actions_rename_format,
        \  'label': 'action / rename / format', 'gap': ' '},
        \ ] : [
        \ {'key': l:keys.definition_references,
        \  'label': 'definition / refs', 'gap': '  '},
        \ {'key': l:keys.hover, 'label': 'hover docs', 'gap': '        '},
        \ {'key': l:keys.actions_rename,
        \  'label': 'action / rename', 'gap': '  '},
        \ {'key': l:keys.format, 'label': 'format', 'gap': '         '},
        \ ]
    let l:cheat_rows = l:space ? [
        \ {'key': l:keys.definition, 'label': 'definition'},
        \ {'key': l:keys.references, 'label': 'references'},
        \ {'key': l:keys.implementation, 'label': 'implementation'},
        \ {'key': l:keys.type_definition, 'label': 'type definition'},
        \ {'key': l:keys.hover, 'label': 'hover docs'},
        \ {'key': l:keys.diagnostics, 'label': 'LSP diagnostics'},
        \ {'key': l:keys.code_action, 'label': 'code action'},
        \ {'key': l:keys.rename, 'label': 'rename'},
        \ {'key': l:keys.format, 'label': 'format'},
        \ {'key': l:keys.status, 'label': 'LSP status'},
        \ {'key': l:keys.outline, 'label': 'outline'},
        \ {'key': l:keys.workspace_symbols, 'label': 'workspace symbols'},
        \ ] : [
        \ {'key': l:keys.definition, 'label': 'definition'},
        \ {'key': l:keys.type_definition, 'label': 'type definition'},
        \ {'key': l:keys.implementation, 'label': 'implementation'},
        \ {'key': l:keys.references, 'label': 'references'},
        \ {'key': l:keys.hover, 'label': 'hover docs'},
        \ {'key': l:keys.rename, 'label': 'rename'},
        \ {'key': l:keys.code_action, 'label': 'code action'},
        \ {'key': l:keys.format, 'label': 'format'},
        \ {'key': l:keys.outline, 'label': 'outline'},
        \ {'key': l:keys.diagnostics, 'label': 'LSP diagnostics'},
        \ ]
    return {
        \ 'enabled': s:LspLearningEnabled(),
        \ 'keys': l:keys,
        \ 'cheat_rows': l:cheat_rows,
        \ 'cheat_command_lines': l:space ? [
        \   '  :LspInstallServer  setup LSP',
        \   '  :ChopsticksStatus   check LSP setup',
        \   '  :ChopsticksDoctor   health issues',
        \ ] : [
        \   '  :LspInstallServer  setup LSP',
        \   '  :ChopsticksStatus   check LSP setup',
        \ ],
        \ 'tutor_rows': l:tutor_rows,
        \ 'beta_rows': [
        \   {'key': l:keys.definition_references,
        \    'label': 'definition / references'},
        \   {'key': l:keys.hover, 'label': 'hover docs'},
        \   {'key': l:keys.format, 'label': 'format'},
        \ ],
        \ }
endfunction

function! ChopsticksLearningLspLoopInfo() abort
    return s:LearningLspLoopInfo()
endfunction

function! s:LearningDailyLoopInfo() abort
    let l:space = s:SpaceLayout()
    let l:lsp_loop = s:LearningLspLoopInfo()
    let l:lsp = get(l:lsp_loop, 'enabled', 0)
    let l:lsp_keys = get(l:lsp_loop, 'keys', {})
    let l:visible_jump = ChopsticksKeymapContractKeysOr('visible_jump_summary',
        \ l:space ? ['s', 'SPC S'] : [',S'])
    let l:keys = {
        \ 'project_files': s:ContractKey('project_files',
        \   l:space ? 'SPC SPC' : ',ff'),
        \ 'visible_jump_primary': get(l:visible_jump, 0,
        \   l:space ? 's' : ',S'),
        \ 'visible_jump_summary': join(l:visible_jump, ' / '),
        \ 'lsp_definition': get(l:lsp_keys, 'definition',
        \   l:space ? 'gd' : ',dd'),
        \ 'lsp_hover': get(l:lsp_keys, 'hover', l:space ? 'K' : ',dk'),
        \ 'project_run': s:ContractKey('project_run',
        \   l:space ? 'SPC rr' : ',cr'),
        \ 'project_grep': s:ContractKey('project_grep',
        \   l:space ? 'SPC /' : ',rg'),
        \ 'git_status': s:ContractKey('git_status',
        \   l:space ? 'SPC gs' : ',gs'),
        \ }
    let l:summary_head = l:space
        \ ? 'files → ' . l:keys.visible_jump_primary . ' jump → '
        \ : 'files → jump → '
    let l:summary_tail = l:lsp
        \ ? (l:space
        \   ? l:keys.lsp_definition . '/' . l:keys.lsp_hover
        \   : 'inspect')
        \ : 'edit'
    let l:drill_steps = [
        \ l:keys.project_files,
        \ l:keys.visible_jump_primary,
        \ ]
    if l:lsp
        call add(l:drill_steps, l:keys.lsp_definition . '/'
            \ . l:keys.lsp_hover)
    endif
    call extend(l:drill_steps, [
        \ 'edit',
        \ l:keys.project_run,
        \ l:keys.project_grep,
        \ l:keys.git_status,
        \ ])
    let l:tasks = ['project navigation', 'code', 'grep', 'git']
    if l:lsp
        call add(l:tasks, 'LSP')
    endif
    call extend(l:tasks, ['Markdown', 'SSH'])
    let l:visible_jump_info = {
        \ 'keys': l:visible_jump,
        \ 'primary_key': l:keys.visible_jump_primary,
        \ 'summary_key': l:keys.visible_jump_summary,
        \ 'cheat_rows': l:space ? [
        \   {'key': get(l:visible_jump, 0, 's') . '+2ch',
        \    'label': 'easymotion jump'},
        \   {'key': get(l:visible_jump, 1, 'SPC S') . '+2ch',
        \    'label': 'jump fallback'},
        \ ] : [
        \   {'key': get(l:visible_jump, 0, ',S') . '+2ch',
        \    'label': 'easymotion jump'},
        \ ],
        \ 'tutor_training_line': '     ' . l:keys.visible_jump_primary
        \     . ' + 2 chars jump to visible text',
        \ 'tutor_lines': l:space ? [
        \   '     ' . get(l:visible_jump, 0, 's')
        \       . ' + 2 chars  visible jump',
        \   ChopsticksDisplayKeyLine('     ', 12,
        \       get(l:visible_jump, 1, 'SPC S'), 'same jump fallback'),
        \ ] : [
        \   '     ' . get(l:visible_jump, 0, ',S')
        \       . ' + 2 chars  EasyMotion jump',
        \ ],
        \ }
    let l:tutor_rows = [
        \ {'key': l:keys.project_files, 'label': 'open a project file'},
        \ {'key': l:keys.visible_jump_primary . ' + 2 chars',
        \  'label': 'jump to visible text'},
        \ ]
    if l:lsp
        call add(l:tutor_rows, {
            \ 'key': get(l:lsp_keys, 'definition_references_docs',
            \   l:keys.lsp_definition . ' / ' . l:keys.lsp_hover),
            \ 'label': 'inspect definition / refs / docs',
            \ })
    endif
    call extend(l:tutor_rows, [
        \ {'key': l:keys.project_run, 'label': 'run current file'},
        \ {'key': l:keys.project_grep, 'label': 'grep project'},
        \ {'key': l:keys.git_status, 'label': 'check git status'},
        \ ])
    let l:beta_rows = [
        \ {'key': l:keys.project_files, 'label': 'find file'},
        \ {'key': l:keys.visible_jump_summary, 'label': 'jump on screen'},
        \ ]
    if l:lsp
        call extend(l:beta_rows, get(l:lsp_loop, 'beta_rows', [])[0:1])
    endif
    call extend(l:beta_rows, [
        \ {'key': l:keys.project_grep, 'label': 'grep project'},
        \ {'key': l:keys.project_run, 'label': 'run current file'},
        \ {'key': l:keys.git_status, 'label': 'git status'},
        \ ])
    if l:lsp
        let l:lsp_beta_rows = get(l:lsp_loop, 'beta_rows', [])
        if len(l:lsp_beta_rows) > 2
            call add(l:beta_rows, l:lsp_beta_rows[2])
        endif
    endif
    return {
        \ 'lsp_enabled': l:lsp,
        \ 'keys': l:keys,
        \ 'summary_lines': [
        \   l:summary_head . l:summary_tail,
        \   'run → grep → git',
        \ ],
        \ 'drill_steps': l:drill_steps,
        \ 'tasks': l:tasks,
        \ 'visible_jump': l:visible_jump_info,
        \ 'tutor_rows': l:tutor_rows,
        \ 'beta_rows': l:beta_rows,
        \ }
endfunction

function! ChopsticksLearningDailyLoopInfo() abort
    return s:LearningDailyLoopInfo()
endfunction

function! s:LearningEntrypointSpec() abort
    let l:fallback = s:FallbackLearningEntrypointSpec()
    return ChopsticksKeymapContractFirstSpecOr('learning_entrypoint',
        \ l:fallback)
endfunction

function! s:LearningEntrypointKey() abort
    let l:fallback = s:FallbackLearningEntrypointSpec()
    let l:fallback_key = get(l:fallback, 'display_key',
        \ get(l:fallback, 'lhs', ''))
    return get(ChopsticksKeymapContractKeysOr('learning_entrypoint',
        \ [l:fallback_key]), 0, l:fallback_key)
endfunction

function! s:LearningEntrypointLine(indent, key_width) abort
    return ChopsticksDisplayKeyLine(a:indent, a:key_width,
        \ s:LearningEntrypointKey(), 'active cheat sheet')
endfunction

function! s:LearningEntrypointLines(indent, key_width) abort
    return ChopsticksKeymapContractLinesOr('learning_entrypoint', a:indent,
        \ a:key_width, [
        \ s:LearningEntrypointLine(a:indent, a:key_width),
        \ ])
endfunction

function! s:LearningEntrypointInfo() abort
    let l:spec = s:LearningEntrypointSpec()
    let l:key = s:LearningEntrypointKey()
    let l:lhs = get(l:spec, 'lhs', get(l:spec, 'key', l:key))
    return {
        \ 'key': l:key,
        \ 'lhs': l:lhs,
        \ 'open_lhs': l:lhs,
        \ 'close_lhs': l:lhs,
        \ 'cheat_title': '  chopsticks         ' . l:key . ' close',
        \ 'guide_lines': s:LearningEntrypointLines('     ', 9),
        \ 'tutor_lines': s:LearningEntrypointLines('     ', 10),
        \ 'feedback_line': '     whether ' . l:key
        \   . ', :ChopsticksTutor, or :ChopsticksStatus answered it',
        \ 'consistency_line': '     README, QUICKSTART, ' . l:key
        \   . ', and tutor teach the same layout',
        \ 'session_prompt': '- Did ' . l:key
        \   . ', :ChopsticksTutor, or :ChopsticksStatus answer it:',
        \ }
endfunction

function! ChopsticksLearningEntrypointInfo() abort
    return s:LearningEntrypointInfo()
endfunction

function! s:HelpKey() abort
    return s:LearningEntrypointKey()
endfunction

function! s:HelpDocPath() abort
    let l:help = ChopsticksInfoOr('ChopsticksHelpInfo', {})
    if has_key(l:help, 'doc_path')
        return l:help.doc_path
    endif
    return get(g:, 'chopsticks_dir', expand('~/.vim')) . '/doc/chopsticks.txt'
endfunction

function! s:ActiveCheatSheetItem() abort
    let l:missing = ChopsticksMissingCommands(['ChopsticksCheatSheet'])
    let l:spec = s:LearningEntrypointSpec()
    let l:map_ready = ChopsticksKeymapSpecReady(l:spec)
    if empty(l:missing) && l:map_ready
        return ChopsticksInfoItem('active cheat sheet', 'ready', s:HelpKey(),
            \ {'diagnostic': 0})
    endif

    let l:parts = copy(l:missing)
    if !l:map_ready
        call add(l:parts, get(l:spec, 'key', s:HelpKey()))
    endif
    return ChopsticksInfoDiagnosticItem('active cheat sheet', 'missing',
        \ 'missing: ' . join(l:parts, ', '), 'active cheat sheet',
        \ ':ChopsticksKeymapAudit', {
        \   'detail': 'missing active cheat sheet entry: '
        \       . join(l:parts, ', '),
        \ })
endfunction

function! s:GuidedTutorItem() abort
    let l:commands = ChopsticksCommandNamesOr('tutor', ['ChopsticksTutor'])
    let l:missing = ChopsticksMissingCommands(l:commands)
    if empty(l:missing)
        return ChopsticksInfoItem('guided tutor', 'ready',
            \ s:PrimaryCommand(l:commands, 'ChopsticksTutor'),
            \ {'diagnostic': 0})
    endif

    return ChopsticksInfoDiagnosticItem('guided tutor', 'missing',
        \ 'missing: ' . join(l:missing, ', '), 'guided tutor',
        \ 'check module load and command definition', {
        \   'detail': 'missing guided tutor command: ' . join(l:missing, ', '),
        \ })
endfunction

function! s:NativeHelpItem() abort
    let l:help = ChopsticksInfoOr('ChopsticksHelpInfo', {})
    if !empty(l:help)
        if get(l:help, 'ok', 0)
            return ChopsticksInfoItem('native help', 'ready',
                \ ':help chopsticks', {'diagnostic': 0})
        endif

        let l:parts = []
        for l:item in get(l:help, 'items', [])
            if get(l:item, 'diagnostic', 0)
                call add(l:parts, get(l:item, 'issue_label',
                    \ get(l:item, 'label', 'help')))
            endif
        endfor
        return ChopsticksInfoDiagnosticItem('native help', 'missing',
            \ 'missing: ' . join(l:parts, ', '), 'native help',
            \ ':ChopsticksStatus', {
            \   'detail': 'missing native help entry: ' . join(l:parts, ', '),
            \ })
    endif

    let l:doc = s:HelpDocPath()
    if ChopsticksCommandAvailable('ChopsticksHelp') && filereadable(l:doc)
        return ChopsticksInfoItem('native help', 'ready', ':help chopsticks',
            \ {'diagnostic': 0})
    endif

    let l:parts = []
    if !ChopsticksCommandAvailable('ChopsticksHelp')
        call add(l:parts, ':ChopsticksHelp')
    endif
    if !filereadable(l:doc)
        call add(l:parts, 'doc/chopsticks.txt')
    endif
    return ChopsticksInfoDiagnosticItem('native help', 'missing',
        \ 'missing: ' . join(l:parts, ', '), 'native help',
        \ ':helptags ' . fnameescape(fnamemodify(l:doc, ':h')), {
        \   'detail': 'missing native help entry: ' . join(l:parts, ', '),
        \ })
endfunction

function! s:ReleaseGuideItem() abort
    let l:beta = ChopsticksInfoOr('ChopsticksBetaInfo', {})
    if !empty(l:beta)
        if !get(l:beta, 'enabled', 0)
            return ChopsticksInfoItem('release guide', 'off',
                \ 'no release guide', {'diagnostic': 0})
        endif
    endif

    let l:commands = ChopsticksCommandNamesOr('beta', [
        \ 'ChopsticksBeta',
        \ 'ChopsticksBetaLog',
        \ 'ChopsticksBetaSession',
        \ ])
    let l:missing = ChopsticksMissingCommands(l:commands)
    if empty(l:missing)
        return ChopsticksInfoItem('release guide', 'ready',
            \ s:PrimaryCommand(l:commands, 'ChopsticksBeta'),
            \ {'diagnostic': 0})
    endif

    return ChopsticksInfoDiagnosticItem('release guide', 'missing',
        \ 'missing: ' . join(l:missing, ', '), 'release guide',
        \ 'check beta module load and command definitions', {
        \   'detail': 'missing release guide commands: ' . join(l:missing, ', '),
        \ })
endfunction

function! ChopsticksLearningInfo() abort
    return ChopsticksInfoSection('learning', {
        \ 'details': [
        \   ChopsticksInfoDetail('layout',
        \       get(g:, 'chopsticks_space_keymaps', 1)
        \       ? 'space' : 'classic'),
        \   ChopsticksInfoDetail('cheat', s:HelpKey()),
        \   ChopsticksInfoDetail('help', ':ChopsticksHelp'),
        \ ],
        \ 'items': [
        \   s:ActiveCheatSheetItem(),
        \   s:GuidedTutorItem(),
        \   s:NativeHelpItem(),
        \   s:ReleaseGuideItem(),
        \ ],
        \ })
endfunction
