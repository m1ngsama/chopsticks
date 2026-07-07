" keymap.vim — ergonomic keymap contract audit

function! s:AddIssue(issues, message) abort
    call add(a:issues, a:message)
endfunction

function! s:Diagnostic(issue) abort
    return {
        \ 'diagnostic': 1,
        \ 'severity': 'attention',
        \ 'issue_label': 'ergonomic contract',
        \ 'detail': a:issue,
        \ 'action': ':ChopsticksKeymapAudit',
        \ }
endfunction

function! s:LeaderSpec(var, expected, message) abort
    return {
        \ 'kind': 'leader',
        \ 'var': a:var,
        \ 'expected': a:expected,
        \ 'message': a:message,
        \ }
endfunction

function! s:ExpectedMapSpec(mode, lhs, text, label, ...) abort
    let l:spec = {
        \ 'kind': 'map',
        \ 'mode': a:mode,
        \ 'lhs': a:lhs,
        \ 'text': a:text,
        \ 'label': a:label,
        \ }
    if a:0
        call extend(l:spec, a:1)
    endif
    if !has_key(l:spec, 'key')
        let l:spec.key = get(l:spec, 'display_key', a:lhs)
    endif
    return l:spec
endfunction

function! s:ForbiddenMapSpec(mode, lhs, label, ...) abort
    let l:spec = {
        \ 'kind': 'no_map',
        \ 'mode': a:mode,
        \ 'lhs': a:lhs,
        \ 'label': a:label,
        \ }
    if a:0
        call extend(l:spec, a:1)
    endif
    if !has_key(l:spec, 'key')
        let l:spec.key = get(l:spec, 'display_key', a:lhs)
    endif
    return l:spec
endfunction

function! s:AutoPairsMapSpec(lhs, text, label, ...) abort
    let l:spec = {
        \ 'kind': 'auto_pairs_map',
        \ 'lhs': a:lhs,
        \ 'text': a:text,
        \ 'label': a:label,
        \ }
    if a:0
        call extend(l:spec, a:1)
    endif
    if !has_key(l:spec, 'key')
        let l:spec.key = get(l:spec, 'display_key', a:lhs)
    endif
    return l:spec
endfunction

function! s:LspBufferMapSpec(mode, lhs, rhs, label, display_key, display_label, display_groups, ...) abort
    let l:spec = s:ExpectedMapSpec(a:mode, a:lhs, a:rhs, a:label, {
        \ 'display_groups': ['lsp_buffer_keymaps'] + copy(a:display_groups),
        \ 'display_key': a:display_key,
        \ 'display_label': a:display_label,
        \ 'rhs': a:rhs,
        \ 'scope': 'lsp_buffer',
        \ 'audit': 0,
        \ 'buffer_local': 1,
        \ 'map_command': a:mode ==# 'x' ? 'xmap' : 'nmap',
        \ })
    if a:0
        call extend(l:spec, a:1)
    endif
    return l:spec
endfunction

function! s:CheckContractSpec(issues, spec) abort
    if !get(a:spec, 'audit', 1)
        return
    endif
    let l:issue = ChopsticksKeymapSpecIssue(a:spec)
    if !empty(l:issue)
        call s:AddIssue(a:issues, l:issue)
    endif
endfunction

function! s:AuditSpecs(issues, specs) abort
    for l:spec in a:specs
        call s:CheckContractSpec(a:issues, l:spec)
    endfor
endfunction

function! s:SpecInDisplayGroup(spec, group) abort
    return index(get(a:spec, 'display_groups', []), a:group) >= 0
endfunction

function! s:DisplayKey(spec) abort
    return get(a:spec, 'display_key', get(a:spec, 'lhs', ''))
endfunction

function! s:DisplayLabel(spec) abort
    return get(a:spec, 'display_label', get(a:spec, 'label', ''))
endfunction

function! s:KeymapContractLines(group, indent, key_width) abort
    let l:lines = []
    for l:spec in s:KeymapContractGroup(a:group)
        call add(l:lines, ChopsticksDisplayKeyLine(a:indent, a:key_width,
            \ s:DisplayKey(l:spec), s:DisplayLabel(l:spec)))
    endfor
    return l:lines
endfunction

function! s:KeymapContractGroup(group) abort
    let l:matches = []
    for l:spec in ChopsticksKeymapContractSpecs().specs
        if s:SpecInDisplayGroup(l:spec, a:group)
            call add(l:matches, copy(l:spec))
        endif
    endfor
    return l:matches
endfunction

function! s:KeymapContractKeys(group) abort
    let l:keys = []
    for l:spec in s:KeymapContractGroup(a:group)
        call add(l:keys, s:DisplayKey(l:spec))
    endfor
    return l:keys
endfunction

function! s:TmuxNavigatorReady() abort
    return get(g:, 'chopsticks_enable_tmux_navigator', 0)
        \ && !empty($TMUX)
        \ && exists('g:loaded_tmux_navigator')
        \ && ChopsticksCommandAvailable('TmuxNavigateLeft')
endfunction

function! s:CoreToggleSpecs() abort
    let l:spell_lhs = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? '<Space>us'
        \ : ',ss'
    let l:spell_key = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? 'SPC us'
        \ : ',ss'
    return [
        \ s:ExpectedMapSpec('n', '<F2>', 'paste', 'core toggles', {
        \   'display_groups': ['core_toggles'],
        \   'display_key': 'F2',
        \   'display_label': 'paste mode'}),
        \ s:ExpectedMapSpec('n', '<F3>', 'number', 'core toggles', {
        \   'display_groups': ['core_toggles'],
        \   'display_key': 'F3',
        \   'display_label': 'line numbers'}),
        \ s:ExpectedMapSpec('n', '<F4>', 'relativenumber',
        \   'core toggles', {
        \   'display_groups': ['core_toggles'],
        \   'display_key': 'F4',
        \   'display_label': 'relative numbers'}),
        \ s:ExpectedMapSpec('n', '<F6>', 'list', 'core toggles', {
        \   'display_groups': ['core_toggles'],
        \   'display_key': 'F6',
        \   'display_label': 'invisible chars'}),
        \ s:ExpectedMapSpec('n', l:spell_lhs, 'spell', 'core toggles', {
        \   'display_groups': ['core_toggles'],
        \   'display_key': l:spell_key,
        \   'display_label': 'spell check'}),
        \ ]
endfunction

function! s:CoreClipboardSpecs() abort
    let l:yank_lhs = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? '<Space>y'
        \ : ',y'
    let l:yank_key = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? 'SPC y'
        \ : ',y'
    let l:yank_line_lhs = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? '<Space>Y'
        \ : ',Y'
    let l:yank_line_key = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? 'SPC Y'
        \ : ',Y'
    let l:put_lhs = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? '<Space>p'
        \ : ',p'
    let l:put_key = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? 'SPC p'
        \ : ',p'
    let l:put_before_lhs = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? '<Space>P'
        \ : ',P'
    let l:put_before_key = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? 'SPC P'
        \ : ',P'
    if ChopsticksRuntimeFeatureAvailable('clipboard')
        return [
            \ s:ExpectedMapSpec('n', l:yank_lhs, '"+y',
            \   'core clipboard', {
            \   'display_groups': ['clipboard_maps',
            \     'clipboard_summary'],
            \   'display_key': l:yank_key,
            \   'display_label': 'clipboard yank'}),
            \ s:ExpectedMapSpec('v', l:yank_lhs, '"+y',
            \   'core clipboard', {
            \   'display_groups': ['clipboard_maps'],
            \   'display_key': 'v ' . l:yank_key,
            \   'display_label': 'clipboard yank selection'}),
            \ s:ExpectedMapSpec('n', l:yank_line_lhs, '"+Y',
            \   'core clipboard', {
            \   'display_groups': ['clipboard_maps'],
            \   'display_key': l:yank_line_key,
            \   'display_label': 'clipboard yank line'}),
            \ s:ExpectedMapSpec('n', l:put_lhs, '"+p',
            \   'core clipboard', {
            \   'display_groups': ['clipboard_maps',
            \     'clipboard_summary'],
            \   'display_key': l:put_key,
            \   'display_label': 'clipboard put'}),
            \ s:ExpectedMapSpec('v', l:put_lhs, '"+p',
            \   'core clipboard', {
            \   'display_groups': ['clipboard_maps'],
            \   'display_key': 'v ' . l:put_key,
            \   'display_label': 'clipboard put selection'}),
            \ s:ExpectedMapSpec('n', l:put_before_lhs, '"+P',
            \   'core clipboard', {
            \   'display_groups': ['clipboard_maps'],
            \   'display_key': l:put_before_key,
            \   'display_label': 'clipboard put before'}),
            \ s:ExpectedMapSpec('v', l:put_before_lhs, '"+P',
            \   'core clipboard', {
            \   'display_groups': ['clipboard_maps'],
            \   'display_key': 'v ' . l:put_before_key,
            \   'display_label': 'clipboard put before selection'}),
            \ ]
    endif
    return [
        \ s:ForbiddenMapSpec('n', l:yank_lhs,
        \   'core clipboard unavailable'),
        \ s:ForbiddenMapSpec('v', l:yank_lhs,
        \   'core clipboard unavailable'),
        \ s:ForbiddenMapSpec('n', l:yank_line_lhs,
        \   'core clipboard unavailable'),
        \ s:ForbiddenMapSpec('n', l:put_lhs,
        \   'core clipboard unavailable'),
        \ s:ForbiddenMapSpec('v', l:put_lhs,
        \   'core clipboard unavailable'),
        \ s:ForbiddenMapSpec('n', l:put_before_lhs,
        \   'core clipboard unavailable'),
        \ s:ForbiddenMapSpec('v', l:put_before_lhs,
        \   'core clipboard unavailable'),
        \ ]
endfunction

function! s:CoreLineMoveSpecs() abort
    return [
        \ s:ExpectedMapSpec('n', '<M-j>', ':m .+1',
        \   'core line move', {
        \   'display_groups': ['line_move', 'line_move_summary'],
        \   'display_key': 'Alt+j',
        \   'display_label': 'move line down'}),
        \ s:ExpectedMapSpec('n', '<M-k>', ':m .-2',
        \   'core line move', {
        \   'display_groups': ['line_move', 'line_move_summary'],
        \   'display_key': 'Alt+k',
        \   'display_label': 'move line up'}),
        \ s:ExpectedMapSpec('v', '<M-j>', ":m '>+1",
        \   'core line move', {
        \   'display_groups': ['line_move'],
        \   'display_key': 'v Alt+j',
        \   'display_label': 'move selection down'}),
        \ s:ExpectedMapSpec('v', '<M-k>', ":m '<-2",
        \   'core line move', {
        \   'display_groups': ['line_move'],
        \   'display_key': 'v Alt+k',
        \   'display_label': 'move selection up'}),
        \ ]
endfunction

function! s:SpaceLspBufferSpecs() abort
    return [
        \ s:LspBufferMapSpec('n', 'gd', '<plug>(lsp-definition)',
        \   'space LSP definition', 'gd', 'definition',
        \   ['lsp_definition', 'lsp_definition_references',
        \    'lsp_inspection']),
        \ s:LspBufferMapSpec('n', 'gr', '<plug>(lsp-references)',
        \   'space LSP references', 'gr', 'references',
        \   ['lsp_references', 'lsp_definition_references',
        \    'lsp_inspection']),
        \ s:LspBufferMapSpec('n', 'gI', '<plug>(lsp-implementation)',
        \   'space LSP implementation', 'gI', 'implementation',
        \   ['lsp_implementation', 'lsp_inspection']),
        \ s:LspBufferMapSpec('n', 'gy', '<plug>(lsp-type-definition)',
        \   'space LSP type definition', 'gy', 'type definition',
        \   ['lsp_type_definition', 'lsp_inspection']),
        \ s:LspBufferMapSpec('n', 'K', '<plug>(lsp-hover)',
        \   'space LSP hover', 'K', 'hover docs',
        \   ['lsp_hover', 'lsp_inspection']),
        \ s:LspBufferMapSpec('n', '[d', '<plug>(lsp-previous-diagnostic)',
        \   'space LSP diagnostics', '[d', 'previous diagnostic',
        \   ['lsp_previous_diagnostic', 'lsp_diagnostics']),
        \ s:LspBufferMapSpec('n', ']d', '<plug>(lsp-next-diagnostic)',
        \   'space LSP diagnostics', ']d', 'next diagnostic',
        \   ['lsp_next_diagnostic', 'lsp_diagnostics']),
        \ s:LspBufferMapSpec('n', '<Space>ca', '<plug>(lsp-code-action)',
        \   'space LSP code action', 'SPC ca', 'code action',
        \   ['lsp_code_action', 'lsp_actions']),
        \ s:LspBufferMapSpec('n', '<Space>cr', '<plug>(lsp-rename)',
        \   'space LSP rename', 'SPC cr', 'rename',
        \   ['lsp_rename', 'lsp_actions']),
        \ s:LspBufferMapSpec('n', '<Space>cf',
        \   '<plug>(lsp-document-format)', 'space LSP format',
        \   'SPC cf', 'format', ['lsp_format_normal', 'lsp_format']),
        \ s:LspBufferMapSpec('x', '<Space>cf',
        \   '<plug>(lsp-document-range-format)', 'space LSP range format',
        \   'v SPC cf', 'format selection', ['lsp_format_visual',
        \    'lsp_format']),
        \ s:LspBufferMapSpec('n', '<Space>ci', ':LspStatus<CR>',
        \   'space LSP status', 'SPC ci', 'LSP status',
        \   ['lsp_status', 'lsp_actions'], {'map_command': 'nnoremap'}),
        \ s:LspBufferMapSpec('n', '<Space>co',
        \   '<plug>(lsp-document-symbol-search)', 'space LSP outline',
        \   'SPC co', 'outline', ['lsp_outline', 'lsp_symbols']),
        \ s:LspBufferMapSpec('n', '<Space>cS',
        \   '<plug>(lsp-workspace-symbol-search)', 'space LSP workspace symbols',
        \   'SPC cS', 'workspace symbols',
        \   ['lsp_workspace_symbols', 'lsp_symbols']),
        \ ]
endfunction

function! s:ClassicLspBufferSpecs() abort
    return [
        \ s:LspBufferMapSpec('n', ',dd', '<plug>(lsp-definition)',
        \   'classic LSP definition', ',dd', 'definition',
        \   ['lsp_definition', 'lsp_definition_references',
        \    'lsp_inspection']),
        \ s:LspBufferMapSpec('n', ',dt', '<plug>(lsp-type-definition)',
        \   'classic LSP type definition', ',dt', 'type definition',
        \   ['lsp_type_definition', 'lsp_inspection']),
        \ s:LspBufferMapSpec('n', ',di', '<plug>(lsp-implementation)',
        \   'classic LSP implementation', ',di', 'implementation',
        \   ['lsp_implementation', 'lsp_inspection']),
        \ s:LspBufferMapSpec('n', ',dr', '<plug>(lsp-references)',
        \   'classic LSP references', ',dr', 'references',
        \   ['lsp_references', 'lsp_definition_references',
        \    'lsp_inspection']),
        \ s:LspBufferMapSpec('n', ',dp', '<plug>(lsp-previous-diagnostic)',
        \   'classic LSP diagnostics', ',dp', 'previous diagnostic',
        \   ['lsp_previous_diagnostic', 'lsp_diagnostics']),
        \ s:LspBufferMapSpec('n', ',dn', '<plug>(lsp-next-diagnostic)',
        \   'classic LSP diagnostics', ',dn', 'next diagnostic',
        \   ['lsp_next_diagnostic', 'lsp_diagnostics']),
        \ s:LspBufferMapSpec('n', ',dk', '<plug>(lsp-hover)',
        \   'classic LSP hover', ',dk', 'hover docs',
        \   ['lsp_hover', 'lsp_inspection']),
        \ s:LspBufferMapSpec('n', ',rn', '<plug>(lsp-rename)',
        \   'classic LSP rename', ',rn', 'rename',
        \   ['lsp_rename', 'lsp_actions']),
        \ s:LspBufferMapSpec('n', ',ca', '<plug>(lsp-code-action)',
        \   'classic LSP code action', ',ca', 'code action',
        \   ['lsp_code_action', 'lsp_actions']),
        \ s:LspBufferMapSpec('n', ',f', '<plug>(lsp-document-format)',
        \   'classic LSP format', ',f', 'format',
        \   ['lsp_format_normal', 'lsp_format']),
        \ s:LspBufferMapSpec('x', ',f',
        \   '<plug>(lsp-document-range-format)', 'classic LSP range format',
        \   'v ,f', 'format selection', ['lsp_format_visual',
        \    'lsp_format']),
        \ s:LspBufferMapSpec('n', ',o',
        \   '<plug>(lsp-document-symbol-search)', 'classic LSP outline',
        \   ',o', 'outline', ['lsp_outline', 'lsp_symbols']),
        \ s:LspBufferMapSpec('n', ',ws',
        \   '<plug>(lsp-workspace-symbol-search)', 'classic LSP workspace symbols',
        \   ',ws', 'workspace symbols',
        \   ['lsp_workspace_symbols', 'lsp_symbols']),
        \ s:LspBufferMapSpec('n', ',cD',
        \   '<plug>(lsp-document-diagnostics)', 'classic LSP document diagnostics',
        \   ',cD', 'document diagnostics',
        \   ['lsp_document_diagnostics', 'lsp_diagnostics']),
        \ ]
endfunction

function! s:SpaceContractSpecs() abort
    let l:specs = [
        \ s:LeaderSpec('mapleader', "\<Space>",
        \   'space layout: mapleader is not Space'),
        \ s:LeaderSpec('maplocalleader', ',',
        \   'space layout: maplocalleader is not comma'),
        \ s:ExpectedMapSpec('n', '<Space>?',
        \   'ChopsticksCheatSheet', 'space learning entrypoint', {
        \   'display_groups': ['learning_entrypoint'],
        \   'display_key': 'SPC ?',
        \   'display_label': 'active cheat sheet'}),
        \ s:ExpectedMapSpec('n', '<Space><Space>', 'SmartFiles',
        \   'space fast path', {
        \   'display_groups': ['project_search', 'project_files'],
        \   'display_key': 'SPC SPC',
        \   'display_label': 'files'}),
        \ s:ExpectedMapSpec('n', '<Space>,', 'Buffers',
        \   'space fast path buffers', {
        \   'display_groups': ['project_buffers'],
        \   'display_key': 'SPC ,',
        \   'display_label': 'buffers'}),
        \ s:ExpectedMapSpec('n', '<Space>w', ':w', 'space survival', {
        \   'display_groups': ['survival_core', 'core_survival'],
        \   'display_key': 'SPC w',
        \   'display_label': 'save'}),
        \ s:ExpectedMapSpec('n', '<Space>W', ':wa', 'space survival', {
        \   'display_groups': ['survival_core', 'core_survival'],
        \   'display_key': 'SPC W',
        \   'display_label': 'save all'}),
        \ s:ExpectedMapSpec('n', '<Space>q', ':q', 'space survival', {
        \   'display_groups': ['survival_core', 'core_survival'],
        \   'display_key': 'SPC q',
        \   'display_label': 'quit'}),
        \ s:ExpectedMapSpec('n', '<Space>uh', ':noh', 'space survival', {
        \   'display_groups': ['core_survival'],
        \   'display_key': 'SPC uh',
        \   'display_label': 'clear search'}),
        \ s:ExpectedMapSpec('n', '<Space>fd', ':lcd', 'space survival', {
        \   'display_groups': ['core_survival'],
        \   'display_key': 'SPC fd',
        \   'display_label': 'lcd file dir'}),
        \ s:ExpectedMapSpec('n', '<Space>fc', 'ChopsticksConfig',
        \   'space config', {
        \   'display_groups': ['survival_config', 'utility_config'],
        \   'display_key': 'SPC fc',
        \   'display_label': 'edit local config'}),
        \ s:ExpectedMapSpec('n', '<Space>fv', '$MYVIMRC', 'space config', {
        \   'display_groups': ['survival_config', 'utility_config'],
        \   'display_key': 'SPC fv',
        \   'display_label': 'edit vimrc'}),
        \ s:ExpectedMapSpec('n', '<Space>fV', 'ChopsticksReload',
        \   'space config', {
        \   'display_groups': ['survival_config', 'utility_config'],
        \   'display_key': 'SPC fV',
        \   'display_label': 'reload vimrc'}),
        \ ]
    if ChopsticksRuntimeFeatureAvailable('clipboard')
        call add(l:specs, s:ExpectedMapSpec('n', '<Space>fp',
            \ 'expand("%:p")', 'space path copy', {
            \ 'display_groups': ['utility_path_copy'],
            \ 'display_key': 'SPC fp',
            \ 'display_label': 'copy full path'}))
        call add(l:specs, s:ExpectedMapSpec('n', '<Space>fn',
            \ 'expand("%:t")', 'space path copy', {
            \ 'display_groups': ['utility_path_copy'],
            \ 'display_key': 'SPC fn',
            \ 'display_label': 'copy file name'}))
    else
        call add(l:specs, s:ForbiddenMapSpec('n', '<Space>fp',
            \ 'space path copy', {
            \ 'display_groups': ['utility_path_copy'],
            \ 'display_key': 'SPC fp'}))
        call add(l:specs, s:ForbiddenMapSpec('n', '<Space>fn',
            \ 'space path copy', {
            \ 'display_groups': ['utility_path_copy'],
            \ 'display_key': 'SPC fn'}))
    endif
    call extend(l:specs, [
        \ s:ExpectedMapSpec('n', '<Space>e', 'ToggleSidebar',
        \   'space file sidebar', {
        \   'display_groups': ['file_sidebar'],
        \   'display_key': 'SPC e',
        \   'display_label': 'sidebar'}),
        \ s:ExpectedMapSpec('n', '<Space>E', 'ToggleSidebar',
        \   'space file sidebar', {
        \   'display_groups': ['file_sidebar'],
        \   'display_key': 'SPC E',
        \   'display_label': 'sidebar here'}),
        \ s:ExpectedMapSpec('n', '<Space>/', 'Rg', 'space project search', {
        \   'display_groups': ['project_search', 'project_grep'],
        \   'display_key': 'SPC /',
        \   'display_label': 'grep'}),
        \ s:ExpectedMapSpec('n', '<Space>ff', 'SmartFiles',
        \   'space file picker', {
        \   'display_groups': ['project_files_picker'],
        \   'display_key': 'SPC ff',
        \   'display_label': 'files'}),
        \ s:ExpectedMapSpec('n', '<Space>fb', 'Buffers',
        \   'space buffer picker', {
        \   'display_groups': ['project_buffers_picker'],
        \   'display_key': 'SPC fb',
        \   'display_label': 'buffers'}),
        \ s:ExpectedMapSpec('n', '<Space>fg', 'GFiles',
        \   'space git file picker', {
        \   'display_groups': ['project_git_files'],
        \   'display_key': 'SPC fg',
        \   'display_label': 'git files'}),
        \ s:ExpectedMapSpec('n', '<Space>fr', 'History',
        \   'space recent file picker', {
        \   'display_groups': ['project_recent_files'],
        \   'display_key': 'SPC fr',
        \   'display_label': 'recent files'}),
        \ s:ExpectedMapSpec('n', '<Space>fl', 'BLines',
        \   'space buffer line picker', {
        \   'display_groups': ['project_buffer_lines'],
        \   'display_key': 'SPC fl',
        \   'display_label': 'lines in buffer'}),
        \ s:ExpectedMapSpec('n', '<Space>sc', 'Commands',
        \   'space command picker', {
        \   'display_groups': ['project_commands'],
        \   'display_key': 'SPC sc',
        \   'display_label': 'commands'}),
        \ s:ExpectedMapSpec('n', '<Space>sm', 'Marks',
        \   'space mark picker', {
        \   'display_groups': ['project_marks'],
        \   'display_key': 'SPC sm',
        \   'display_label': 'marks'}),
        \ s:ExpectedMapSpec('n', '<Space>s/', 'History/',
        \   'space search history', {
        \   'display_groups': ['project_search_history'],
        \   'display_key': 'SPC s/',
        \   'display_label': 'search history'}),
        \ s:ExpectedMapSpec('n', '<Space>s:', 'History:',
        \   'space command history', {
        \   'display_groups': ['project_command_history'],
        \   'display_key': 'SPC s:',
        \   'display_label': 'command history'}),
        \ s:ExpectedMapSpec('n', '<Space>sg', 'Rg',
        \   'space grep picker', {
        \   'display_groups': ['project_grep_picker'],
        \   'display_key': 'SPC sg',
        \   'display_label': 'grep project'}),
        \ s:ExpectedMapSpec('n', '<Space>sw', 'RgWord',
        \   'space project search', {
        \   'display_groups': ['project_search', 'project_grep_word'],
        \   'display_key': 'SPC sw',
        \   'display_label': 'grep word'}),
        \ s:ExpectedMapSpec('n', '<Space>st', 'Tags',
        \   'space project search', {
        \   'display_groups': ['project_search', 'project_tags'],
        \   'display_key': 'SPC st',
        \   'display_label': 'tags'}),
        \ s:ExpectedMapSpec('n', '<Space>rr', 'ChopsticksRun', 'space run loop', {
        \   'display_groups': ['project_run'],
        \   'display_key': 'SPC rr',
        \   'display_label': 'run context'}),
        \ s:ExpectedMapSpec('n', '<Space>rt', 'ChopsticksRunTask',
        \   'space task picker', {
        \   'display_groups': ['project_task_picker'],
        \   'display_key': 'SPC rt',
        \   'display_label': 'pick task'}),
        \ s:ExpectedMapSpec('n', '<Space>rl', 'ChopsticksRunLast',
        \   'space last run', {
        \   'display_groups': ['project_run_last'],
        \   'display_key': 'SPC rl',
        \   'display_label': 'last run'}),
        \ s:ExpectedMapSpec('n', '<Space>gs', 'Git status', 'space git', {
        \   'display_groups': ['git_keymaps', 'git_status'],
        \   'display_key': 'SPC gs',
        \   'display_label': 'git status'}),
        \ s:ExpectedMapSpec('n', '<Space>gc', 'Git commit', 'space git', {
        \   'display_groups': ['git_keymaps', 'git_commit'],
        \   'display_key': 'SPC gc',
        \   'display_label': 'git commit'}),
        \ s:ExpectedMapSpec('n', '<Space>gd', 'Gdiffsplit', 'space git', {
        \   'display_groups': ['git_keymaps', 'git_diff'],
        \   'display_key': 'SPC gd',
        \   'display_label': 'git diff'}),
        \ s:ExpectedMapSpec('n', '<Space>gb', 'Git blame', 'space git', {
        \   'display_groups': ['git_keymaps', 'git_blame'],
        \   'display_key': 'SPC gb',
        \   'display_label': 'git blame'}),
        \ s:ExpectedMapSpec('n', '<Space>gl', 'Git log', 'space git', {
        \   'display_groups': ['git_keymaps', 'git_log'],
        \   'display_key': 'SPC gl',
        \   'display_label': 'git log'}),
        \ s:ExpectedMapSpec('n', '<Space>gC', 'Commits',
        \   'space commit picker', {
        \   'display_groups': ['git_commit_picker'],
        \   'display_key': 'SPC gC',
        \   'display_label': 'FZF commits'}),
        \ s:ExpectedMapSpec('n', '<Space>gB', 'BCommits',
        \   'space buffer commit picker', {
        \   'display_groups': ['git_buffer_commit_picker'],
        \   'display_key': 'SPC gB',
        \   'display_label': 'FZF buffer commits'}),
        \ s:ExpectedMapSpec('n', '<Space>bd', 'Bclose',
        \   'space buffer lifecycle', {
        \   'display_groups': ['buffer_close', 'buffer_lifecycle'],
        \   'display_key': 'SPC bd',
        \   'display_label': 'close buffer'}),
        \ s:ExpectedMapSpec('n', '<Space>ba', 'BcloseAll',
        \   'space close all buffers', {
        \   'display_groups': ['buffer_close_all', 'buffer_lifecycle'],
        \   'display_key': 'SPC ba',
        \   'display_label': 'close all buffers'}),
        \ s:ExpectedMapSpec('n', '<Space>bo', 'BcloseOthers',
        \   'space close other buffers', {
        \   'display_groups': ['buffer_close_others', 'buffer_lifecycle'],
        \   'display_key': 'SPC bo',
        \   'display_label': 'close other buffers'}),
        \ s:ExpectedMapSpec('n', '<Space>bn', 'bnext',
        \   'space buffer lifecycle', {
        \   'display_groups': ['buffer_navigation', 'buffer_lifecycle'],
        \   'display_key': 'SPC bn',
        \   'display_label': 'next buffer'}),
        \ s:ExpectedMapSpec('n', '<Space>bp', 'bprevious',
        \   'space buffer lifecycle', {
        \   'display_groups': ['buffer_navigation', 'buffer_lifecycle'],
        \   'display_key': 'SPC bp',
        \   'display_label': 'previous buffer'}),
        \ s:ExpectedMapSpec('n', '<Space><Tab>', 'Balternate',
        \   'space buffer lifecycle', {
        \   'display_groups': ['buffer_alternate', 'buffer_lifecycle'],
        \   'display_key': 'SPC Tab',
        \   'display_label': 'alternate buffer'}),
        \ s:ExpectedMapSpec('n', '<Space>xq', 'copen',
        \   'space quickfix window', {
        \   'display_groups': ['quickfix_window'],
        \   'display_key': 'SPC xq',
        \   'display_label': 'open quickfix'}),
        \ s:ExpectedMapSpec('n', '<Space>xQ', 'cclose',
        \   'space quickfix window', {
        \   'display_groups': ['quickfix_window'],
        \   'display_key': 'SPC xQ',
        \   'display_label': 'close quickfix'}),
        \ s:ExpectedMapSpec('n', '<Space>xl', 'lopen',
        \   'space location-list window', {
        \   'display_groups': ['loclist_window'],
        \   'display_key': 'SPC xl',
        \   'display_label': 'open loclist'}),
        \ s:ExpectedMapSpec('n', '<Space>xL', 'lclose',
        \   'space location-list window', {
        \   'display_groups': ['loclist_window'],
        \   'display_key': 'SPC xL',
        \   'display_label': 'close loclist'}),
        \ s:ExpectedMapSpec('n', '<Space>z', 'ToggleMaximize',
        \   'space window layout', {
        \   'display_groups': ['window_layout'],
        \   'display_key': 'SPC z',
        \   'display_label': 'maximize'}),
        \ s:ExpectedMapSpec('n', '<Space>cW', 's/\s\+$',
        \   'space edit cleanup', {
        \   'display_groups': ['edit_cleanup', 'edit_cleanup_summary'],
        \   'display_key': 'SPC cW',
        \   'display_label': 'strip trailing whitespace'}),
        \ s:ExpectedMapSpec('v', '<Space>cW', 's/\s\+$',
        \   'space edit cleanup', {
        \   'display_groups': ['edit_cleanup'],
        \   'display_key': 'v SPC cW',
        \   'display_label': 'strip selection whitespace'}),
        \ s:ExpectedMapSpec('n', '<Space>sr', '%s/\<',
        \   'space edit cleanup', {
        \   'display_groups': ['edit_cleanup', 'edit_cleanup_summary'],
        \   'display_key': 'SPC sr',
        \   'display_label': 'replace word'}),
        \ s:ExpectedMapSpec('v', '<Space>sr', 's///g',
        \   'space edit cleanup', {
        \   'display_groups': ['edit_cleanup'],
        \   'display_key': 'v SPC sr',
        \   'display_label': 'replace selection'}),
        \ s:ExpectedMapSpec('v', '<Space>=', '=', 'space edit cleanup', {
        \   'display_groups': ['edit_cleanup', 'edit_cleanup_summary'],
        \   'display_key': 'SPC =',
        \   'display_label': 'indent selection'}),
        \ ])
    if get(g:, 'chopsticks_enable_lint', 1)
        \ && ChopsticksPluginDeclared('ale')
        call add(l:specs, s:ExpectedMapSpec('n', '<Space>xd',
            \ 'ALEDetail', 'space lint', {
            \ 'display_groups': ['lint_keymaps'],
            \ 'display_key': 'SPC xd',
            \ 'display_label': 'lint detail'}))
        call add(l:specs, s:ExpectedMapSpec('n', '<Space>uf',
            \ 'ale_fix_on_save', 'space lint', {
            \ 'display_groups': ['lint_keymaps'],
            \ 'display_key': 'SPC uf',
            \ 'display_label': 'format toggle'}))
    endif
    if ChopsticksRuntimeFeatureAvailable('terminal')
        call extend(l:specs, [
            \ s:ExpectedMapSpec('n', '<Space>tt', ':terminal',
            \   'space terminal entry', {
            \   'display_groups': ['terminal_entry'],
            \   'display_key': 'SPC tt',
            \   'display_label': 'terminal'}),
            \ s:ExpectedMapSpec('n', '<Space>th', ':terminal',
            \   'space terminal split', {
            \   'display_groups': ['terminal_entry'],
            \   'display_key': 'SPC th',
            \   'display_label': 'terminal split'}),
            \ ])
    endif
    if &filetype ==# 'markdown'
        if ChopsticksPluginDeclared('vim-markdown')
            call add(l:specs, s:ExpectedMapSpec('n', ',mt',
                \ 'Toc', 'markdown maps', {
                \ 'display_groups': ['markdown_maps'],
                \ 'display_key': ',mt',
                \ 'display_label': 'Toc'}))
        endif
        if ChopsticksPluginDeclared('previm')
            call add(l:specs, s:ExpectedMapSpec('n', ',mp',
                \ 'PrevimOpen', 'markdown maps', {
                \ 'display_groups': ['markdown_maps'],
                \ 'display_key': ',mp',
                \ 'display_label': 'PrevimOpen'}))
        endif
    endif
    if get(g:, 'chopsticks_enable_ui_extras', 1)
        call add(l:specs, s:ExpectedMapSpec('n', '<Space>U',
            \ 'UndotreeToggle', 'space undo tree', {
            \ 'display_groups': ['undo_tree'],
            \ 'display_key': 'SPC U',
            \ 'display_label': 'undo history'}))
    else
        call add(l:specs, s:ForbiddenMapSpec('n', '<Space>U',
            \ 'space undo tree', {
            \ 'display_groups': ['undo_tree'],
            \ 'display_key': 'SPC U'}))
    endif
    if get(g:, 'chopsticks_enable_reindent_file', 0)
        call add(l:specs, s:ExpectedMapSpec('n', '<Space>c=',
            \ 'gg=G', 'space full-file reindent', {
            \ 'display_groups': ['full_file_reindent'],
            \ 'display_key': 'SPC c=',
            \ 'display_label': 'reindent file'}))
    else
        call add(l:specs, s:ForbiddenMapSpec('n', '<Space>c=',
            \ 'space full-file reindent', {
            \ 'display_groups': ['full_file_reindent'],
            \ 'display_key': 'SPC c='}))
    endif

    call extend(l:specs, [
        \ s:ExpectedMapSpec('n', 's', 'easymotion-overwin-f2',
        \   'space visible jump', {
        \   'display_groups': ['visible_jump', 'visible_jump_summary'],
        \   'display_key': 's',
        \   'display_label': 'jump'}),
        \ s:ExpectedMapSpec('n', '<Space>S', 'easymotion-overwin-f2',
        \   'space visible jump', {
        \   'display_groups': ['visible_jump', 'visible_jump_summary'],
        \   'display_key': 'SPC S',
        \   'display_label': 'jump fallback'}),
        \ s:ForbiddenMapSpec('n', 'cl', 'native substitute fallback'),
        \ s:ForbiddenMapSpec('n', 'cc', 'native substitute fallback'),
        \ s:ForbiddenMapSpec('n', '<Space>', 'leader prefix'),
        \ s:ForbiddenMapSpec('n', '<Space>f', 'which-key style prefix'),
        \ s:ForbiddenMapSpec('n', '<Space>c', 'which-key style prefix'),
        \ s:ForbiddenMapSpec('n', '<Space>x', 'which-key style prefix'),
        \ s:ForbiddenMapSpec('n', '<Space>wm', 'space window layout'),
        \ s:ForbiddenMapSpec('n', '<Space>w+', 'space window layout'),
        \ s:ForbiddenMapSpec('n', '<Space>w-', 'space window layout'),
        \ s:ForbiddenMapSpec('n', '<Space>gp', 'dangerous git push'),
        \ s:ForbiddenMapSpec('n', '<Space>glp', 'dangerous git pull'),
        \ ])
    return l:specs
endfunction

function! s:ClassicContractSpecs() abort
    let l:specs = [
        \ s:LeaderSpec('mapleader', ',',
        \   'classic layout: mapleader is not comma'),
        \ s:ExpectedMapSpec('n', ',?',
        \   'ChopsticksCheatSheet', 'classic learning entrypoint', {
        \   'display_groups': ['learning_entrypoint'],
        \   'display_key': ',?',
        \   'display_label': 'active cheat sheet'}),
        \ s:ExpectedMapSpec('n', ',ff', 'SmartFiles', 'classic files', {
        \   'display_groups': ['project_search', 'project_files'],
        \   'display_key': ',ff',
        \   'display_label': 'files'}),
        \ s:ExpectedMapSpec('n', ',w', ':w', 'classic survival', {
        \   'display_groups': ['survival_core', 'core_survival'],
        \   'display_key': ',w',
        \   'display_label': 'save'}),
        \ s:ExpectedMapSpec('n', ',wa', ':wa', 'classic survival'),
        \ s:ExpectedMapSpec('n', ',q', ':q', 'classic survival', {
        \   'display_groups': ['survival_core', 'core_survival'],
        \   'display_key': ',q',
        \   'display_label': 'quit'}),
        \ s:ExpectedMapSpec('n', ',x', ':x', 'classic survival', {
        \   'display_groups': ['survival_core', 'core_survival'],
        \   'display_key': ',x',
        \   'display_label': 'save + quit'}),
        \ s:ExpectedMapSpec('n', ',<CR>', ':noh', 'classic survival', {
        \   'display_groups': ['core_survival'],
        \   'display_key': ',<CR>',
        \   'display_label': 'clear search'}),
        \ s:ExpectedMapSpec('n', ',cd', ':lcd', 'classic survival', {
        \   'display_groups': ['core_survival'],
        \   'display_key': ',cd',
        \   'display_label': 'lcd file dir'}),
        \ s:ExpectedMapSpec('n', ',ec', 'ChopsticksConfig',
        \   'classic config', {
        \   'display_groups': ['survival_config', 'utility_config'],
        \   'display_key': ',ec',
        \   'display_label': 'edit local config'}),
        \ s:ExpectedMapSpec('n', ',ev', '$MYVIMRC', 'classic config', {
        \   'display_groups': ['survival_config', 'utility_config'],
        \   'display_key': ',ev',
        \   'display_label': 'edit vimrc'}),
        \ s:ExpectedMapSpec('n', ',sv', 'ChopsticksReload',
        \   'classic config', {
        \   'display_groups': ['survival_config', 'utility_config'],
        \   'display_key': ',sv',
        \   'display_label': 'reload vimrc'}),
        \ ]
    if ChopsticksRuntimeFeatureAvailable('clipboard')
        call add(l:specs, s:ExpectedMapSpec('n', ',cp',
            \ 'expand("%:p")', 'classic path copy', {
            \ 'display_groups': ['utility_path_copy'],
            \ 'display_key': ',cp',
            \ 'display_label': 'copy full path'}))
        call add(l:specs, s:ExpectedMapSpec('n', ',cf',
            \ 'expand("%:t")', 'classic path copy', {
            \ 'display_groups': ['utility_path_copy'],
            \ 'display_key': ',cf',
            \ 'display_label': 'copy file name'}))
    else
        call add(l:specs, s:ForbiddenMapSpec('n', ',cp',
            \ 'classic path copy', {
            \ 'display_groups': ['utility_path_copy'],
            \ 'display_key': ',cp'}))
        call add(l:specs, s:ForbiddenMapSpec('n', ',cf',
            \ 'classic path copy', {
            \ 'display_groups': ['utility_path_copy'],
            \ 'display_key': ',cf'}))
    endif
    call extend(l:specs, [
        \ s:ExpectedMapSpec('n', ',e', 'ToggleSidebar',
        \   'classic file sidebar', {
        \   'display_groups': ['file_sidebar'],
        \   'display_key': ',e',
        \   'display_label': 'sidebar'}),
        \ s:ExpectedMapSpec('n', ',E', 'ToggleSidebar',
        \   'classic file sidebar', {
        \   'display_groups': ['file_sidebar'],
        \   'display_key': ',E',
        \   'display_label': 'sidebar here'}),
        \ s:ExpectedMapSpec('n', ',b', 'Buffers',
        \   'classic project buffers', {
        \   'display_groups': ['project_buffers'],
        \   'display_key': ',b',
        \   'display_label': 'buffers'}),
        \ s:ExpectedMapSpec('n', ',rg', 'Rg', 'classic project search', {
        \   'display_groups': ['project_search', 'project_grep'],
        \   'display_key': ',rg',
        \   'display_label': 'grep'}),
        \ s:ExpectedMapSpec('n', ',rG', 'RgWord',
        \   'classic project search', {
        \   'display_groups': ['project_search', 'project_grep_word'],
        \   'display_key': ',rG',
        \   'display_label': 'grep word'}),
        \ s:ExpectedMapSpec('n', ',rt', 'Tags', 'classic project search', {
        \   'display_groups': ['project_search', 'project_tags'],
        \   'display_key': ',rt',
        \   'display_label': 'tags'}),
        \ s:ExpectedMapSpec('n', ',gF', 'GFiles',
        \   'classic git file picker', {
        \   'display_groups': ['project_git_files'],
        \   'display_key': ',gF',
        \   'display_label': 'git files'}),
        \ s:ExpectedMapSpec('n', ',fh', 'History',
        \   'classic recent file picker', {
        \   'display_groups': ['project_recent_files'],
        \   'display_key': ',fh',
        \   'display_label': 'recent files'}),
        \ s:ExpectedMapSpec('n', ',fl', 'BLines',
        \   'classic buffer line picker', {
        \   'display_groups': ['project_buffer_lines'],
        \   'display_key': ',fl',
        \   'display_label': 'lines in buffer'}),
        \ s:ExpectedMapSpec('n', ',fc', 'Commands',
        \   'classic command picker', {
        \   'display_groups': ['project_commands'],
        \   'display_key': ',fc',
        \   'display_label': 'commands'}),
        \ s:ExpectedMapSpec('n', ',fm', 'Marks',
        \   'classic mark picker', {
        \   'display_groups': ['project_marks'],
        \   'display_key': ',fm',
        \   'display_label': 'marks'}),
        \ s:ExpectedMapSpec('n', ',cr', 'ChopsticksRun', 'classic run loop', {
        \   'display_groups': ['project_run'],
        \   'display_key': ',cr',
        \   'display_label': 'run context'}),
        \ s:ExpectedMapSpec('n', ',ct', 'ChopsticksRunTask',
        \   'classic task picker', {
        \   'display_groups': ['project_task_picker'],
        \   'display_key': ',ct',
        \   'display_label': 'pick task'}),
        \ s:ExpectedMapSpec('n', ',cR', 'ChopsticksRunLast',
        \   'classic last run', {
        \   'display_groups': ['project_run_last'],
        \   'display_key': ',cR',
        \   'display_label': 'last run'}),
        \ s:ExpectedMapSpec('n', ',gs', 'Git status', 'classic git', {
        \   'display_groups': ['git_keymaps', 'git_status'],
        \   'display_key': ',gs',
        \   'display_label': 'git status'}),
        \ s:ExpectedMapSpec('n', ',gc', 'Git commit', 'classic git', {
        \   'display_groups': ['git_keymaps', 'git_commit'],
        \   'display_key': ',gc',
        \   'display_label': 'git commit'}),
        \ s:ExpectedMapSpec('n', ',gd', 'Gdiffsplit', 'classic git', {
        \   'display_groups': ['git_keymaps', 'git_diff'],
        \   'display_key': ',gd',
        \   'display_label': 'git diff'}),
        \ s:ExpectedMapSpec('n', ',gb', 'Git blame', 'classic git', {
        \   'display_groups': ['git_keymaps', 'git_blame'],
        \   'display_key': ',gb',
        \   'display_label': 'git blame'}),
        \ s:ExpectedMapSpec('n', ',gL', 'Git log', 'classic git', {
        \   'display_groups': ['git_keymaps', 'git_log'],
        \   'display_key': ',gL',
        \   'display_label': 'git log'}),
        \ s:ExpectedMapSpec('n', ',gC', 'Commits',
        \   'classic commit picker', {
        \   'display_groups': ['git_commit_picker'],
        \   'display_key': ',gC',
        \   'display_label': 'FZF commits'}),
        \ s:ExpectedMapSpec('n', ',gB', 'BCommits',
        \   'classic buffer commit picker', {
        \   'display_groups': ['git_buffer_commit_picker'],
        \   'display_key': ',gB',
        \   'display_label': 'FZF buffer commits'}),
        \ s:ExpectedMapSpec('n', ',S', 'easymotion-overwin-f2',
        \   'classic visible jump', {
        \   'display_groups': ['visible_jump', 'visible_jump_summary'],
        \   'display_key': ',S',
        \   'display_label': 'jump'}),
        \ s:ExpectedMapSpec('n', ',j', 'easymotion-j',
        \   'classic visible jump', {
        \   'display_groups': ['visible_jump'],
        \   'display_key': ',j',
        \   'display_label': 'jump down'}),
        \ s:ExpectedMapSpec('n', ',k', 'easymotion-k',
        \   'classic visible jump', {
        \   'display_groups': ['visible_jump'],
        \   'display_key': ',k',
        \   'display_label': 'jump up'}),
        \ s:ExpectedMapSpec('n', ',bd', 'Bclose',
        \   'classic buffer lifecycle', {
        \   'display_groups': ['buffer_close', 'buffer_lifecycle'],
        \   'display_key': ',bd',
        \   'display_label': 'close buffer'}),
        \ s:ExpectedMapSpec('n', ',ba', 'BcloseAll',
        \   'classic close all buffers', {
        \   'display_groups': ['buffer_close_all', 'buffer_lifecycle'],
        \   'display_key': ',ba',
        \   'display_label': 'close all buffers'}),
        \ s:ExpectedMapSpec('n', ',bo', 'BcloseOthers',
        \   'classic close other buffers', {
        \   'display_groups': ['buffer_close_others', 'buffer_lifecycle'],
        \   'display_key': ',bo',
        \   'display_label': 'close other buffers'}),
        \ s:ExpectedMapSpec('n', ',l', 'bnext',
        \   'classic buffer lifecycle', {
        \   'display_groups': ['buffer_navigation', 'buffer_lifecycle'],
        \   'display_key': ',l',
        \   'display_label': 'next buffer'}),
        \ s:ExpectedMapSpec('n', ',h', 'bprevious',
        \   'classic buffer lifecycle', {
        \   'display_groups': ['buffer_navigation', 'buffer_lifecycle'],
        \   'display_key': ',h',
        \   'display_label': 'previous buffer'}),
        \ s:ExpectedMapSpec('n', ',,', 'Balternate',
        \   'classic buffer lifecycle', {
        \   'display_groups': ['buffer_alternate', 'buffer_lifecycle'],
        \   'display_key': ',,',
        \   'display_label': 'alternate buffer'}),
        \ s:ExpectedMapSpec('n', ',qo', 'copen',
        \   'classic quickfix window', {
        \   'display_groups': ['quickfix_window'],
        \   'display_key': ',qo',
        \   'display_label': 'open quickfix'}),
        \ s:ExpectedMapSpec('n', ',qc', 'cclose',
        \   'classic quickfix window', {
        \   'display_groups': ['quickfix_window'],
        \   'display_key': ',qc',
        \   'display_label': 'close quickfix'}),
        \ s:ExpectedMapSpec('n', ',z', 'ToggleMaximize',
        \   'classic window layout', {
        \   'display_groups': ['window_layout'],
        \   'display_key': ',z',
        \   'display_label': 'maximize'}),
        \ s:ExpectedMapSpec('n', ',=', 'resize', 'classic window layout', {
        \   'display_groups': ['window_layout'],
        \   'display_key': ',=',
        \   'display_label': 'grow height'}),
        \ s:ExpectedMapSpec('n', ',-', 'resize', 'classic window layout', {
        \   'display_groups': ['window_layout'],
        \   'display_key': ',-',
        \   'display_label': 'shrink height'}),
        \ s:ExpectedMapSpec('n', ',W', 's/\s\+$',
        \   'classic edit cleanup', {
        \   'display_groups': ['edit_cleanup', 'edit_cleanup_summary'],
        \   'display_key': ',W',
        \   'display_label': 'strip trailing whitespace'}),
        \ s:ExpectedMapSpec('v', ',W', 's/\s\+$',
        \   'classic edit cleanup', {
        \   'display_groups': ['edit_cleanup'],
        \   'display_key': 'v ,W',
        \   'display_label': 'strip selection whitespace'}),
        \ s:ExpectedMapSpec('n', ',*', '%s/\<', 'classic edit cleanup', {
        \   'display_groups': ['edit_cleanup', 'edit_cleanup_summary'],
        \   'display_key': ',*',
        \   'display_label': 'replace word'}),
        \ s:ExpectedMapSpec('v', ',*', 's///g', 'classic edit cleanup', {
        \   'display_groups': ['edit_cleanup'],
        \   'display_key': 'v ,*',
        \   'display_label': 'replace selection'}),
        \ s:ExpectedMapSpec('v', ',F', '=', 'classic edit cleanup', {
        \   'display_groups': ['edit_cleanup', 'edit_cleanup_summary'],
        \   'display_key': ',F',
        \   'display_label': 'indent selection'}),
        \ ])
    if get(g:, 'chopsticks_enable_lint', 1)
        \ && ChopsticksPluginDeclared('ale')
        call add(l:specs, s:ExpectedMapSpec('n', ',aD',
            \ 'ALEDetail', 'classic lint', {
            \ 'display_groups': ['lint_keymaps'],
            \ 'display_key': ',aD',
            \ 'display_label': 'lint detail'}))
        call add(l:specs, s:ExpectedMapSpec('n', ',af',
            \ 'ale_fix_on_save', 'classic lint', {
            \ 'display_groups': ['lint_keymaps'],
            \ 'display_key': ',af',
            \ 'display_label': 'format toggle'}))
    endif
    if ChopsticksRuntimeFeatureAvailable('terminal')
        call extend(l:specs, [
            \ s:ExpectedMapSpec('n', ',tv', ':terminal',
            \   'classic terminal entry', {
            \   'display_groups': ['terminal_entry'],
            \   'display_key': ',tv',
            \   'display_label': 'terminal'}),
            \ s:ExpectedMapSpec('n', ',th', ':terminal',
            \   'classic terminal split', {
            \   'display_groups': ['terminal_entry'],
            \   'display_key': ',th',
            \   'display_label': 'terminal split'}),
            \ ])
    endif
    if ChopsticksPluginDeclared('vim-markdown')
        call add(l:specs, s:ExpectedMapSpec('n', ',mt',
            \ 'Toc', 'classic markdown maps', {
            \ 'display_groups': ['markdown_maps'],
            \ 'display_key': ',mt',
            \ 'display_label': 'Toc'}))
    endif
    if ChopsticksPluginDeclared('previm')
        call add(l:specs, s:ExpectedMapSpec('n', ',mp',
            \ 'PrevimOpen', 'classic markdown maps', {
            \ 'display_groups': ['markdown_maps'],
            \ 'display_key': ',mp',
            \ 'display_label': 'PrevimOpen'}))
    endif
    if get(g:, 'chopsticks_enable_ui_extras', 1)
        call add(l:specs, s:ExpectedMapSpec('n', ',u',
            \ 'UndotreeToggle', 'classic undo tree', {
            \ 'display_groups': ['undo_tree'],
            \ 'display_key': ',u',
            \ 'display_label': 'undo history'}))
    else
        call add(l:specs, s:ForbiddenMapSpec('n', ',u',
            \ 'classic undo tree', {
            \ 'display_groups': ['undo_tree'],
            \ 'display_key': ',u'}))
    endif
    if get(g:, 'chopsticks_enable_reindent_file', 0)
        call add(l:specs, s:ExpectedMapSpec('n', ',F', 'gg=G',
            \ 'classic full-file reindent', {
            \ 'display_groups': ['full_file_reindent'],
            \ 'display_key': ',F',
            \ 'display_label': 'reindent file'}))
    else
        call add(l:specs, s:ForbiddenMapSpec('n', ',F',
            \ 'classic full-file reindent', {
            \ 'display_groups': ['full_file_reindent'],
            \ 'display_key': ',F'}))
    endif

    call extend(l:specs, [
        \ s:ForbiddenMapSpec('n', 's', 'classic native substitute'),
        \ s:ForbiddenMapSpec('n', ',gp', 'dangerous git push'),
        \ s:ForbiddenMapSpec('n', ',gl', 'dangerous git pull'),
        \ ])
    return l:specs
endfunction

function! s:SharedContractSpecs() abort
    let l:specs = []
    let l:tmux_ready = s:TmuxNavigatorReady()
    call extend(l:specs, s:CoreToggleSpecs())
    call extend(l:specs, s:CoreClipboardSpecs())
    call extend(l:specs, s:CoreLineMoveSpecs())
    if l:tmux_ready
        call extend(l:specs, [
            \ s:ExpectedMapSpec('n', '<C-h>', 'TmuxNavigateLeft',
            \   'tmux window navigation', {
            \   'display_groups': ['window_navigation'],
            \   'display_key': '<C-h>',
            \   'display_label': 'left'}),
            \ s:ExpectedMapSpec('n', '<C-j>', 'TmuxNavigateDown',
            \   'tmux window navigation', {
            \   'display_groups': ['window_navigation'],
            \   'display_key': '<C-j>',
            \   'display_label': 'down'}),
            \ s:ExpectedMapSpec('n', '<C-k>', 'TmuxNavigateUp',
            \   'tmux window navigation', {
            \   'display_groups': ['window_navigation'],
            \   'display_key': '<C-k>',
            \   'display_label': 'up'}),
            \ s:ExpectedMapSpec('n', '<C-l>', 'TmuxNavigateRight',
            \   'tmux window navigation', {
            \   'display_groups': ['window_navigation'],
            \   'display_key': '<C-l>',
            \   'display_label': 'right'}),
            \ ])
    else
        call extend(l:specs, [
            \ s:ExpectedMapSpec('n', '<C-h>', 'NavigateWindow',
            \   'window navigation', {
            \   'display_groups': ['window_navigation'],
            \   'display_key': '<C-h>',
            \   'display_label': 'left'}),
            \ s:ExpectedMapSpec('n', '<C-j>', 'NavigateWindow',
            \   'window navigation', {
            \   'display_groups': ['window_navigation'],
            \   'display_key': '<C-j>',
            \   'display_label': 'down'}),
            \ s:ExpectedMapSpec('n', '<C-k>', 'NavigateWindow',
            \   'window navigation', {
            \   'display_groups': ['window_navigation'],
            \   'display_key': '<C-k>',
            \   'display_label': 'up'}),
            \ s:ExpectedMapSpec('n', '<C-l>', 'NavigateWindow',
            \   'window navigation', {
            \   'display_groups': ['window_navigation'],
            \   'display_key': '<C-l>',
            \   'display_label': 'right'}),
            \ ])
    endif

    call extend(l:specs, [
        \ s:ExpectedMapSpec('n', '[<Space>', 'repeat(nr2char(10)',
        \   'blank line insertion', {
        \   'display_groups': ['blank_lines'],
        \   'display_key': '[<Space>',
        \   'display_label': 'insert line above'}),
        \ s:ExpectedMapSpec('n', ']<Space>', 'repeat(nr2char(10)',
        \   'blank line insertion', {
        \   'display_groups': ['blank_lines'],
        \   'display_key': ']<Space>',
        \   'display_label': 'insert line below'}),
        \ s:ExpectedMapSpec('n', '[q', 'cprev',
        \   'quickfix navigation', {
        \   'display_groups': ['quickfix_navigation'],
        \   'display_key': '[q',
        \   'display_label': 'previous quickfix'}),
        \ s:ExpectedMapSpec('n', ']q', 'cnext',
        \   'quickfix navigation', {
        \   'display_groups': ['quickfix_navigation'],
        \   'display_key': ']q',
        \   'display_label': 'next quickfix'}),
        \ s:ExpectedMapSpec('n', '[l', 'lprev',
        \   'location-list navigation', {
        \   'display_groups': ['loclist_navigation'],
        \   'display_key': '[l',
        \   'display_label': 'previous loclist'}),
        \ s:ExpectedMapSpec('n', ']l', 'lnext',
        \   'location-list navigation', {
        \   'display_groups': ['loclist_navigation'],
        \   'display_key': ']l',
        \   'display_label': 'next loclist'}),
        \ s:ExpectedMapSpec('n', '[x', '<<<<<<<',
        \   'git conflict navigation', {
        \   'display_groups': ['git_conflict_navigation'],
        \   'display_key': '[x',
        \   'display_label': 'previous conflict'}),
        \ s:ExpectedMapSpec('n', ']x', '<<<<<<<',
        \   'git conflict navigation', {
        \   'display_groups': ['git_conflict_navigation'],
        \   'display_key': ']x',
        \   'display_label': 'next conflict'}),
        \ s:ForbiddenMapSpec('n', '0', 'native line motion'),
        \ s:ForbiddenMapSpec('v', '0', 'native line motion'),
        \ s:ForbiddenMapSpec('n', 'Y', 'native yank'),
        \ s:ForbiddenMapSpec('n', 'Q', 'native Ex mode'),
        \ s:ForbiddenMapSpec('v', '//', 'native visual search'),
        \ s:ForbiddenMapSpec('n', 'gV', 'native visual repeat'),
        \ ])

    if get(g:, 'chopsticks_enable_lint', 1)
        \ && ChopsticksPluginDeclared('ale')
        call extend(l:specs, [
            \ s:ExpectedMapSpec('n', '[e', 'ALEPrevious',
            \   'lint navigation', {
            \   'display_groups': ['lint_keymaps'],
            \   'display_key': '[e',
            \   'display_label': 'previous lint'}),
            \ s:ExpectedMapSpec('n', ']e', 'ALENext',
            \   'lint navigation', {
            \   'display_groups': ['lint_keymaps'],
            \   'display_key': ']e',
            \   'display_label': 'next lint'}),
            \ ])
    endif

    if get(g:, 'chopsticks_enable_jk_escape', 0)
        call add(l:specs, s:ExpectedMapSpec('i', 'jk', '<Esc>',
            \ 'opt-in jk escape'))
    else
        call add(l:specs, s:ForbiddenMapSpec('i', 'jk',
            \ 'opt-in jk escape'))
    endif

    if get(g:, 'chopsticks_enable_ctrl_s_save', 0)
        call add(l:specs, s:ExpectedMapSpec('n', '<C-s>', ':w',
            \ 'opt-in Ctrl-S save'))
        call add(l:specs, s:ExpectedMapSpec('i', '<C-s>', ':w',
            \ 'opt-in Ctrl-S save'))
    else
        call add(l:specs, s:ForbiddenMapSpec('n', '<C-s>',
            \ 'opt-in Ctrl-S save'))
        call add(l:specs, s:ForbiddenMapSpec('i', '<C-s>',
            \ 'opt-in Ctrl-S save'))
    endif

    let l:auto_pairs = get(g:, 'chopsticks_enable_auto_pairs', 0)
        \ && exists('g:AutoPairsLoaded')
    let l:completion_keys = get(g:, 'chopsticks_enable_completion_keymaps', 0)
        \ && get(g:, 'chopsticks_enable_lsp', 1)

    if l:completion_keys
        call add(l:specs, s:ExpectedMapSpec('i', '<Tab>', 'pumvisible',
            \ 'opt-in completion keys', {
            \ 'display_groups': ['completion_keymaps'],
            \ 'display_key': 'Tab',
            \ 'key': '<Tab>',
            \ 'display_label': 'next completion'}))
        call add(l:specs, s:ExpectedMapSpec('i', '<S-Tab>', 'pumvisible',
            \ 'opt-in completion keys', {
            \ 'display_groups': ['completion_keymaps'],
            \ 'display_key': 'S-Tab',
            \ 'key': '<S-Tab>',
            \ 'display_label': 'previous completion'}))
        if l:auto_pairs
            call add(l:specs, s:AutoPairsMapSpec('<CR>',
                \ 'AutoPairsReturn', 'opt-in auto-pairs return', {
                \ 'display_groups': ['completion_keymaps'],
                \ 'display_key': 'CR',
                \ 'key': '<CR> auto-pairs',
                \ 'display_label': 'accept newline'}))
            call add(l:specs, s:ExpectedMapSpec('i', '<CR>',
                \ 'AutoPairsOldCRWrapper',
                \ 'completion return wrapped by auto-pairs', {
                \ 'display_groups': ['completion_keymaps'],
                \ 'display_key': 'CR',
                \ 'key': '<CR> completion wrapper',
                \ 'display_label': 'completion wrapper'}))
        else
            call add(l:specs, s:ExpectedMapSpec('i', '<CR>',
                \ 'asyncomplete#close_popup', 'opt-in completion keys', {
                \ 'display_groups': ['completion_keymaps'],
                \ 'display_key': 'CR',
                \ 'key': '<CR>',
                \ 'display_label': 'accept completion'}))
        endif
    else
        call add(l:specs, s:ForbiddenMapSpec('i', '<Tab>',
            \ 'opt-in completion keys'))
        call add(l:specs, s:ForbiddenMapSpec('i', '<S-Tab>',
            \ 'opt-in completion keys'))
        if l:auto_pairs
            call add(l:specs, s:AutoPairsMapSpec('<CR>',
                \ 'AutoPairsReturn', 'opt-in auto-pairs return'))
        else
            call add(l:specs, s:ForbiddenMapSpec('i', '<CR>',
                \ 'opt-in completion keys'))
        endif
    endif

    if l:auto_pairs
        call add(l:specs, s:AutoPairsMapSpec('<BS>', 'AutoPairsDelete',
            \ 'opt-in auto-pairs backspace'))
        call add(l:specs, s:AutoPairsMapSpec('<C-h>', 'AutoPairsDelete',
            \ 'opt-in auto-pairs Ctrl-H'))
        call add(l:specs, s:AutoPairsMapSpec('<Space>', 'AutoPairsSpace',
            \ 'opt-in auto-pairs space'))
    else
        call add(l:specs, s:ForbiddenMapSpec('i', '<BS>',
            \ 'opt-in auto-pairs backspace'))
        call add(l:specs, s:ForbiddenMapSpec('i', '<Space>',
            \ 'opt-in auto-pairs space'))
    endif

    if get(g:, 'chopsticks_enable_sudo_save_bang', 0)
        call add(l:specs, s:ExpectedMapSpec('c', 'w!!', 'sudo tee',
            \ 'opt-in sudo save'))
    else
        call add(l:specs, s:ForbiddenMapSpec('c', 'w!!',
            \ 'opt-in sudo save'))
    endif

    if ChopsticksRuntimeFeatureAvailable('terminal')
        if l:tmux_ready
            call extend(l:specs, [
                \ s:ExpectedMapSpec('t', '<C-h>', 'TmuxNavigateLeft',
                \   'tmux terminal navigation'),
                \ s:ExpectedMapSpec('t', '<C-j>', 'TmuxNavigateDown',
                \   'tmux terminal navigation'),
                \ s:ExpectedMapSpec('t', '<C-k>', 'TmuxNavigateUp',
                \   'tmux terminal navigation'),
                \ s:ExpectedMapSpec('t', '<C-l>', 'TmuxNavigateRight',
                \   'tmux terminal navigation'),
                \ ])
        elseif get(g:, 'chopsticks_enable_terminal_keymaps', 0)
            call extend(l:specs, [
                \ s:ExpectedMapSpec('t', '<Esc><Esc>', '<C-\>',
                \   'opt-in terminal escape'),
                \ s:ExpectedMapSpec('t', '<C-h>', 'NavigateWindow',
                \   'opt-in terminal navigation'),
                \ s:ExpectedMapSpec('t', '<C-j>', 'NavigateWindow',
                \   'opt-in terminal navigation'),
                \ s:ExpectedMapSpec('t', '<C-k>', 'NavigateWindow',
                \   'opt-in terminal navigation'),
                \ s:ExpectedMapSpec('t', '<C-l>', 'NavigateWindow',
                \   'opt-in terminal navigation'),
                \ ])
        else
            call extend(l:specs, [
                \ s:ForbiddenMapSpec('t', '<Esc><Esc>',
                \   'opt-in terminal escape'),
                \ s:ForbiddenMapSpec('t', '<C-h>',
                \   'opt-in terminal navigation'),
                \ s:ForbiddenMapSpec('t', '<C-j>',
                \   'opt-in terminal navigation'),
                \ s:ForbiddenMapSpec('t', '<C-k>',
                \   'opt-in terminal navigation'),
                \ s:ForbiddenMapSpec('t', '<C-l>',
                \   'opt-in terminal navigation'),
                \ ])
        endif
    endif
    return l:specs
endfunction

function! ChopsticksKeymapContractSpecs() abort
    let l:layout = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? 'space'
        \ : 'classic'
    let l:specs = l:layout ==# 'space'
        \ ? s:SpaceContractSpecs()
        \ : s:ClassicContractSpecs()
    call extend(l:specs, l:layout ==# 'space'
        \ ? s:SpaceLspBufferSpecs()
        \ : s:ClassicLspBufferSpecs())
    call extend(l:specs, s:SharedContractSpecs())
    return ChopsticksInfoSection('keymap contract', {
        \ 'layout': l:layout,
        \ 'specs': l:specs,
        \ })
endfunction

function! ChopsticksKeymapContractLines(group, ...) abort
    let l:indent = a:0 ? a:1 : '  '
    let l:key_width = a:0 > 1 ? a:2 : 9
    return s:KeymapContractLines(a:group, l:indent, l:key_width)
endfunction

function! ChopsticksKeymapContractSpecsFor(group, ...) abort
    let l:specs = s:KeymapContractGroup(a:group)
    return empty(l:specs) && a:0 ? copy(a:1) : l:specs
endfunction

function! ChopsticksKeymapContractKeys(group, ...) abort
    let l:keys = s:KeymapContractKeys(a:group)
    return empty(l:keys) && a:0 ? copy(a:1) : l:keys
endfunction

function! ChopsticksKeymapAuditIssues() abort
    let l:issues = []
    call s:AuditSpecs(l:issues, ChopsticksKeymapContractSpecs().specs)
    return l:issues
endfunction

function! ChopsticksKeymapAuditInfo() abort
    let l:issues = ChopsticksKeymapAuditIssues()
    let l:issue_count = len(l:issues)
    let l:layout = get(g:, 'chopsticks_space_keymaps', 1)
        \ ? 'space'
        \ : 'classic'
    let l:reason = l:issue_count == 0
        \ ? ':ChopsticksKeymapAudit'
        \ : l:issue_count . ' issue' . (l:issue_count == 1 ? '' : 's')
    let l:diagnostics = []
    for l:issue in l:issues
        call add(l:diagnostics, s:Diagnostic(l:issue))
    endfor
    return ChopsticksInfoSection('keymap audit', {
        \ 'layout': l:layout,
        \ 'command': ':ChopsticksKeymapAudit',
        \ 'ok': l:issue_count == 0,
        \ 'issue_count': l:issue_count,
        \ 'issues': l:issues,
        \ 'details': [
        \   ChopsticksInfoDetail('layout', l:layout),
        \   ChopsticksInfoDetail('command', ':ChopsticksKeymapAudit'),
        \ ],
        \ 'items': [
        \   ChopsticksInfoItem('keymap audit',
        \       l:issue_count == 0 ? 'ready' : 'missing', l:reason, {
        \           'diagnostic': l:issue_count == 0 ? 0 : 1,
        \           'severity': 'attention',
        \           'issue_label': 'ergonomic contract',
        \           'detail': l:issue_count == 0
        \               ? ''
        \               : l:issue_count . ' keymap audit issue'
        \                   . (l:issue_count == 1 ? '' : 's'),
        \           'action': ':ChopsticksKeymapAudit',
        \           'diagnostics': l:diagnostics,
        \       }),
        \ ],
        \ })
endfunction

function! s:OpenAudit() abort
    let l:audit = ChopsticksKeymapAuditInfo()
    let l:issues = get(l:audit, 'issues', [])
    let l:lines = [
        \ 'chopsticks keymap audit',
        \ repeat('-', 50),
        \ '',
        \ '  layout     ' . get(l:audit, 'layout', 'space'),
        \ '  command    ' . get(l:audit, 'command', ':ChopsticksKeymapAudit'),
        \ '',
        \ ]

    if empty(l:issues)
        call add(l:lines, '  OK  keymap contract passed')
    else
        call add(l:lines, '  --  keymap contract failed')
        call add(l:lines, '')
        for l:issue in l:issues
            call add(l:lines, '  - ' . l:issue)
        endfor
    endif

    call ChopsticksOpenScratchBuffer('__ChopsticksKeymapAudit__', l:lines, {
        \ 'height': 20,
        \ 'toggle': 0,
        \ })
endfunction

command! ChopsticksKeymapAudit call s:OpenAudit()
