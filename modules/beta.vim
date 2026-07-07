" beta.vim — in-editor release checklist

let g:chopsticks_release_label = get(g:, 'chopsticks_release_label',
    \ get(g:, 'chopsticks_beta_label', '2.3.0'))
let g:chopsticks_beta_label = get(g:, 'chopsticks_beta_label',
    \ g:chopsticks_release_label)

function! s:BetaLabel() abort
    return get(g:, 'chopsticks_release_label',
        \ get(g:, 'chopsticks_beta_label', '2.3.0'))
endfunction

function! s:BetaCommandLines() abort
    return ChopsticksCommandLinesOr('beta', '     ', [
        \ '     :ChopsticksBeta        release checklist',
        \ '     :ChopsticksBetaLog     release notes',
        \ '     :ChopsticksBetaSession new release note',
        \ ]
        \ )
endfunction

function! s:BetaCommand(name_index, fallback) abort
    return ':' . get(s:BetaCommandNames(), a:name_index, a:fallback)
endfunction

function! s:GuideKeyLine(key, label) abort
    return ChopsticksDisplayKeyLine('     ', 9, a:key, a:label)
endfunction

function! s:ContractKey(group, fallback) abort
    return get(ChopsticksKeymapContractKeysOr(a:group, [a:fallback]), 0,
        \ a:fallback)
endfunction

function! s:FallbackLearningEntrypointKey() abort
    return get(g:, 'chopsticks_space_keymaps', 1) ? 'SPC ?' : ',?'
endfunction

function! s:FallbackLearningEntrypointInfo() abort
    let l:key = s:ContractKey('learning_entrypoint',
        \ s:FallbackLearningEntrypointKey())
    return {
        \ 'key': l:key,
        \ 'guide_lines': [
        \   s:GuideKeyLine(l:key, 'active cheat sheet'),
        \ ],
        \ 'feedback_line': '     whether ' . l:key
        \   . ', :ChopsticksTutor, or :ChopsticksStatus answered it',
        \ 'consistency_line': '     README, QUICKSTART, ' . l:key
        \   . ', and tutor teach the same layout',
        \ 'session_prompt': '- Did ' . l:key
        \   . ', :ChopsticksTutor, or :ChopsticksStatus answer it:',
        \ }
endfunction

function! s:LearningEntrypointInfo() abort
    return ChopsticksInfoOr('ChopsticksLearningEntrypointInfo',
        \ s:FallbackLearningEntrypointInfo())
endfunction

function! s:LearningEntrypointKey() abort
    return get(s:LearningEntrypointInfo(), 'key',
        \ s:FallbackLearningEntrypointKey())
endfunction

function! s:LearningEntrypointLines() abort
    let l:info = s:LearningEntrypointInfo()
    let l:lines = get(l:info, 'guide_lines', [])
    return empty(l:lines)
        \ ? get(s:FallbackLearningEntrypointInfo(), 'guide_lines', [])
        \ : copy(l:lines)
endfunction

function! s:LearningFeedbackLine() abort
    return get(s:LearningEntrypointInfo(), 'feedback_line',
        \ get(s:FallbackLearningEntrypointInfo(), 'feedback_line', ''))
endfunction

function! s:LearningConsistencyLine() abort
    return get(s:LearningEntrypointInfo(), 'consistency_line',
        \ get(s:FallbackLearningEntrypointInfo(), 'consistency_line', ''))
endfunction

function! s:LearningSessionPrompt() abort
    return get(s:LearningEntrypointInfo(), 'session_prompt',
        \ get(s:FallbackLearningEntrypointInfo(), 'session_prompt', ''))
endfunction

function! s:LearningDailyLoopInfo() abort
    return ChopsticksInfoOr('ChopsticksLearningDailyLoopInfo', {})
endfunction

function! s:LearningLspLoopInfo() abort
    return ChopsticksInfoOr('ChopsticksLearningLspLoopInfo', {})
endfunction

function! s:LspDailyLoopAvailable() abort
    let l:lsp_loop = s:LearningLspLoopInfo()
    let l:loop = s:LearningDailyLoopInfo()
    return ChopsticksLearningLoopEnabled(l:loop, l:lsp_loop,
        \ get(g:, 'chopsticks_enable_lsp', 1))
endfunction

function! s:LspDailyLoopLines() abort
    if !s:LspDailyLoopAvailable()
        return []
    endif
    let l:lsp_loop = s:LearningLspLoopInfo()
    let l:space = get(g:, 'chopsticks_space_keymaps', 1)
    let l:definition_references = join(ChopsticksKeymapContractKeysOr(
        \ 'lsp_definition_references',
        \ l:space ? ['gd', 'gr'] : [',dd', ',dr']), ' / ')
    let l:fallback = [
        \ s:GuideKeyLine(l:definition_references,
        \   'definition / references'),
        \ s:GuideKeyLine(s:ContractKey('lsp_hover',
        \   l:space ? 'K' : ',dk'), 'hover docs'),
        \ s:GuideKeyLine(s:ContractKey('lsp_format',
        \   l:space ? 'SPC cf' : ',f'), 'format'),
        \ ]
    return ChopsticksLearningInfoRowLinesOr(l:lsp_loop, 'beta_rows', {
        \ 'indent': '     ',
        \ 'key_width': 9,
        \ }, l:fallback)
endfunction

function! s:DailyLoopLines() abort
    let l:loop = s:LearningDailyLoopInfo()
    let l:space = get(g:, 'chopsticks_space_keymaps', 1)
    let l:visible_jump = join(ChopsticksKeymapContractKeysOr(
        \ 'visible_jump_summary', l:space ? ['s', 'SPC S'] : [',S']),
        \ ' / ')
    let l:lines = [
        \ s:GuideKeyLine(s:ContractKey('project_files',
        \       l:space ? 'SPC SPC' : ',ff'), 'find file'),
        \ s:GuideKeyLine(l:visible_jump, 'jump on screen'),
        \ ]
    let l:lsp_lines = s:LspDailyLoopLines()
    if !empty(l:lsp_lines)
        call extend(l:lines, l:lsp_lines[0:1])
    endif
    call extend(l:lines, [
        \ s:GuideKeyLine(s:ContractKey('project_grep',
        \       l:space ? 'SPC /' : ',rg'), 'grep project'),
        \ s:GuideKeyLine(s:ContractKey('project_run',
        \       l:space ? 'SPC rr' : ',cr'), 'run current context'),
        \ s:GuideKeyLine(s:ContractKey('project_task_picker',
        \       l:space ? 'SPC rt' : ',ct'), 'pick project task'),
        \ s:GuideKeyLine(s:ContractKey('git_status',
        \       l:space ? 'SPC gs' : ',gs'), 'git status'),
        \ ])
    if len(l:lsp_lines) > 2
        call add(l:lines, l:lsp_lines[2])
    endif
    return ChopsticksLearningInfoRowLinesOr(l:loop, 'beta_rows', {
        \ 'indent': '     ',
        \ 'key_width': 9,
        \ }, l:lines)
endfunction

function! s:RecordTaskLine() abort
    let l:loop = s:LearningDailyLoopInfo()
    let l:tasks = ['project navigation', 'code', 'run tasks', 'grep', 'git']
    if s:LspDailyLoopAvailable()
        call add(l:tasks, 'LSP')
    endif
    call extend(l:tasks, ['Markdown', 'SSH'])
    return ChopsticksLearningTaskLine(l:loop, '     ', l:tasks)
endfunction

function! s:OpenBetaGuide() abort
    let l:lines = [
        \ '  chopsticks release ' . s:BetaLabel() . '      q close',
        \ '  ─────────────────────────────',
        \ '',
        \ '  goal',
        \ '     Validate the long-term project loop before tagging.',
        \ '     Record real editing friction before release.',
        \ '',
        \ '  daily loop',
        \ ]
    call extend(l:lines, s:DailyLoopLines())
    call extend(l:lines, s:LearningEntrypointLines())
    call extend(l:lines, [
        \ '     ' . s:BetaCommand(2, 'ChopsticksBetaSession') . '  new note block',
        \ '',
        \ '  record',
        \ s:RecordTaskLine(),
        \ '     first key tried when stuck',
        \ s:LearningFeedbackLine(),
        \ '     any key that felt slow, awkward, surprising, or easy to mistype',
        \ '',
        \ '  exit criteria',
        \ '     s as jump still feels worth the native override',
        \ '     no high-frequency action needs an undocumented key',
        \ '     window/sidebar navigation beats native <C-w> only',
        \ s:LearningConsistencyLine(),
        \ '     no GitHub/private wiki is needed to remember the daily loop',
        \ '     quick/vim tests pass locally and over SSH',
        \ '',
        \ '  commands',
        \ ])
    call extend(l:lines, s:BetaCommandLines())
    call extend(l:lines, [
        \ '',
        \ '  references',
        \ '     BETA.md        release checklist and rollback',
        \ '     QUICKSTART.md  five-minute path',
        \ '     README.md      complete reference',
        \ ])

    call ChopsticksOpenScratchBuffer('__ChopsticksBeta__', l:lines, {
        \ 'height': 34,
        \ 'mappings': [
        \   {'lhs': '?', 'rhs': ':ChopsticksCheatSheet<CR>'},
        \ ],
        \ })
endfunction

function! s:BetaLogPath() abort
    let l:configured = get(g:, 'chopsticks_beta_log', '')
    if !empty(l:configured)
        return expand(l:configured)
    endif

    let l:xdg = !empty($XDG_CONFIG_HOME) && $XDG_CONFIG_HOME =~# '^/'
        \ ? $XDG_CONFIG_HOME
        \ : '~/.config'
    return expand(l:xdg . '/chopsticks-' . s:BetaLabel() . '.md')
endfunction

function! s:BetaCommandNames() abort
    return ChopsticksCommandNamesOr('beta', [
        \ 'ChopsticksBeta',
        \ 'ChopsticksBetaLog',
        \ 'ChopsticksBetaSession',
        \ ]
        \ )
endfunction

function! s:BetaCommandDetails() abort
    let l:commands = map(copy(s:BetaCommandNames()), "':' . v:val")
    if empty(l:commands)
        return []
    endif

    let l:details = [
        \ ChopsticksInfoDetail('commands', join(l:commands[0:1], '  ')),
        \ ]
    if len(l:commands) > 2
        call add(l:details, ChopsticksInfoDetail('',
            \ join(l:commands[2:], '  ')))
    endif
    return l:details
endfunction

function! ChopsticksBetaInfo() abort
    let l:label = s:BetaLabel()
    if empty(l:label)
        return ChopsticksInfoSection('release guide', {
            \ 'enabled': 0,
            \ 'label': '',
            \ 'log_path': '',
            \ 'details': [],
            \ 'items': [],
            \ })
    endif

    let l:log_path = s:BetaLogPath()
    let l:details = [
        \ ChopsticksInfoDetail('release', l:label),
        \ ChopsticksInfoDetail('keymap', get(g:, 'chopsticks_space_keymaps', 0)
        \   ? 'space' : 'classic'),
        \ ChopsticksInfoDetail('log', l:log_path),
        \ ]
    call extend(l:details, s:BetaCommandDetails())
    return ChopsticksInfoSection('release guide', {
        \ 'enabled': 1,
        \ 'label': l:label,
        \ 'log_path': l:log_path,
        \ 'details': l:details,
        \ 'items': [],
        \ })
endfunction

function! s:SessionBlock() abort
    return [
        \ '',
        \ '## ' . strftime('%Y-%m-%d %H:%M'),
        \ '',
        \ '- Task:',
        \ '- First key tried when stuck:',
        \ s:LearningSessionPrompt(),
        \ '- Friction:',
        \ '- Decision:',
        \ ]
endfunction

function! s:EnsureBetaLog(path) abort
    call ChopsticksEnsureManagedFile(a:path, [
        \ '# chopsticks ' . s:BetaLabel() . ' release log',
        \ '',
        \ 'Use :ChopsticksBeta for the release checklist. Keep one session block per real editing session.',
        \ ] + s:SessionBlock())
endfunction

function! s:OpenBetaLog() abort
    let l:path = s:BetaLogPath()
    call s:EnsureBetaLog(l:path)
    call ChopsticksOpenManagedFile(l:path, {'filetype': 'markdown'})
endfunction

function! s:AppendBetaSession() abort
    let l:path = s:BetaLogPath()
    call s:EnsureBetaLog(l:path)
    call ChopsticksAppendManagedFile(l:path, s:SessionBlock())
    call ChopsticksOpenManagedFile(l:path, {'filetype': 'markdown'})
    normal! G
endfunction

command! ChopsticksBeta call s:OpenBetaGuide()
command! ChopsticksBetaLog call s:OpenBetaLog()
command! ChopsticksBetaSession call s:AppendBetaSession()
