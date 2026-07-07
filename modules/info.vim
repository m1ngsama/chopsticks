" info.vim - shared info shape, surface registry, and status adapters

function! ChopsticksInfoPath(path, field) abort
    return empty(a:path) ? a:field : a:path . '.' . a:field
endfunction

function! ChopsticksInfoShapeIssue(info, source, ...) abort
    let l:base_path = a:0 ? a:1 : ''
    for l:field in ['details', 'items', 'notes', 'sections', 'footers']
        if has_key(a:info, l:field)
            \ && type(get(a:info, l:field, [])) != type([])
            let l:path = ChopsticksInfoPath(l:base_path, l:field)
            return {
                \ 'ok': 0,
                \ 'detail': a:source . '.' . l:path . ' is not a List',
                \ 'action': 'return a List from ' . a:source . '.' . l:path,
                \ }
        endif
    endfor

    for l:field in ['details', 'items', 'sections']
        let l:path = ChopsticksInfoPath(l:base_path, l:field)
        let l:index = 0
        for l:entry in get(a:info, l:field, [])
            if type(l:entry) != type({})
                return {
                    \ 'ok': 0,
                    \ 'detail': a:source . '.' . l:path . '['
                    \     . l:index . '] is not a Dictionary',
                    \ 'action': 'return Dictionary entries from '
                    \     . a:source . '.' . l:path,
                    \ }
            endif
            let l:index += 1
        endfor
    endfor

    for l:field in ['notes', 'footers']
        let l:path = ChopsticksInfoPath(l:base_path, l:field)
        let l:index = 0
        for l:entry in get(a:info, l:field, [])
            if type(l:entry) != type('')
                return {
                    \ 'ok': 0,
                    \ 'detail': a:source . '.' . l:path . '['
                    \     . l:index . '] is not a String',
                    \ 'action': 'return String entries from '
                    \     . a:source . '.' . l:path,
                    \ }
            endif
            let l:index += 1
        endfor
    endfor

    let l:index = 0
    for l:section in get(a:info, 'sections', [])
        let l:path = ChopsticksInfoPath(l:base_path, 'sections')
            \ . '[' . l:index . ']'
        let l:issue = ChopsticksInfoShapeIssue(l:section, a:source, l:path)
        if !get(l:issue, 'ok', 0)
            return l:issue
        endif
        let l:index += 1
    endfor

    return {'ok': 1, 'detail': '', 'action': ''}
endfunction

function! ChopsticksInfoCall(function_name) abort
    let l:source = a:function_name . '()'
    if !exists('*' . a:function_name)
        return {
            \ 'ok': 0,
            \ 'status': 'missing',
            \ 'source': l:source,
            \ 'info': {},
            \ 'detail': a:function_name . '() is not loaded',
            \ 'exception': '',
            \ 'shape': {},
            \ }
    endif

    try
        let l:info = call(a:function_name, [])
    catch
        return {
            \ 'ok': 0,
            \ 'status': 'thrown',
            \ 'source': l:source,
            \ 'info': {},
            \ 'detail': a:function_name . '() failed: ' . v:exception,
            \ 'exception': v:exception,
            \ 'shape': {},
            \ }
    endtry

    if type(l:info) != type({})
        return {
            \ 'ok': 0,
            \ 'status': 'invalid-type',
            \ 'source': l:source,
            \ 'info': {},
            \ 'detail': a:function_name . '() returned invalid info',
            \ 'exception': '',
            \ 'shape': {},
            \ }
    endif

    let l:shape = ChopsticksInfoShapeIssue(l:info, l:source)
    if !get(l:shape, 'ok', 0)
        return {
            \ 'ok': 0,
            \ 'status': 'invalid-shape',
            \ 'source': l:source,
            \ 'info': l:info,
            \ 'detail': get(l:shape, 'detail', 'invalid info shape'),
            \ 'exception': '',
            \ 'shape': l:shape,
            \ }
    endif

    return {
        \ 'ok': 1,
        \ 'status': 'ready',
        \ 'source': l:source,
        \ 'info': l:info,
        \ 'detail': '',
        \ 'exception': '',
        \ 'shape': {},
        \ }
endfunction

function! ChopsticksInfoOr(function_name, fallback) abort
    let l:result = ChopsticksInfoCall(a:function_name)
    if get(l:result, 'status', 'missing') !=# 'ready'
        return copy(a:fallback)
    endif
    let l:info = get(l:result, 'info', {})
    return empty(l:info) ? copy(a:fallback) : copy(l:info)
endfunction

function! s:InfoSurface(spec) abort
    let l:spec = deepcopy(a:spec)
    let l:spec.status_reason = get(l:spec, 'status_reason',
        \ 'command not loaded')
    let l:spec.health_kind = get(l:spec, 'health_kind',
        \ has_key(l:spec, 'health_domain') ? 'required-items' : '')
    return l:spec
endfunction

function! s:HealthDefaults(severity, label, detail, action) abort
    return {
        \ 'severity': a:severity,
        \ 'label': a:label,
        \ 'detail': a:detail,
        \ 'action': a:action,
        \ }
endfunction

function! s:InfoSurfaceSpecs() abort
    return [
        \ s:InfoSurface({
        \   'name': 'health',
        \   'function': 'ChopsticksHealthInfo',
        \   'status_title': 'health',
        \   'status_label': 'doctor',
        \   'status_reason': ':ChopsticksDoctor unavailable; command not loaded',
        \ }),
        \ s:InfoSurface({
        \   'name': 'keymap',
        \   'function': 'ChopsticksKeymapAuditInfo',
        \   'status_title': 'keymap audit',
        \   'status_label': 'keymap audit',
        \   'status_reason': ':ChopsticksKeymapAudit unavailable; command not loaded',
        \   'health_kind': 'function',
        \   'health_function': 's:CheckKeymap',
        \ }),
        \ s:InfoSurface({
        \   'name': 'help',
        \   'function': 'ChopsticksHelpInfo',
        \   'status_title': 'help surface',
        \   'status_label': 'help surface',
        \   'health_domain': 'help',
        \   'health_interface_label': 'help surface interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'help surface', 'help surface not ready',
        \       ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'learning',
        \   'function': 'ChopsticksLearningInfo',
        \   'status_title': 'learning',
        \   'status_label': 'active cheat sheet',
        \   'health_domain': 'learning',
        \   'health_interface_label': 'learning interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'learning surface', 'learning surface not ready',
        \       ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'runtime',
        \   'function': 'ChopsticksRuntimeInfo',
        \   'status_title': 'runtime',
        \   'status_label': 'runtime',
        \   'health_domain': 'runtime',
        \   'health_interface_label': 'runtime interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'runtime', 'runtime issue', 'reload chopsticks'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'modules',
        \   'function': 'ChopsticksModuleInfo',
        \   'status_title': 'modules',
        \   'status_label': 'modules',
        \   'health_domain': 'modules',
        \   'health_interface_label': 'module interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'module', 'module failed to load', ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'core',
        \   'function': 'ChopsticksCoreInfo',
        \   'status_title': 'editor core',
        \   'status_label': 'editor core',
        \   'health_domain': 'core',
        \   'health_interface_label': 'editor core interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'editor core', 'editor core not ready',
        \       ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'commands',
        \   'function': 'ChopsticksCommandInfo',
        \   'status_title': 'command surface',
        \   'status_label': 'command surface',
        \   'health_domain': 'commands',
        \   'health_interface_label': 'command interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'command', 'missing public command',
        \       'check module load and command definition'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'local-config',
        \   'function': 'ChopsticksLocalConfigInfo',
        \   'status_title': 'local preferences',
        \   'status_label': 'local config',
        \   'health_domain': 'local-config',
        \   'health_interface_label': 'local config interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'local preferences', 'failed to load local config',
        \       ':ChopsticksConfig'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'utilities',
        \   'function': 'ChopsticksUtilityInfo',
        \   'status_title': 'utilities',
        \   'status_label': 'config actions',
        \   'health_domain': 'utilities',
        \   'health_interface_label': 'utility interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'utilities', 'utility actions not ready',
        \       ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'profile',
        \   'function': 'ChopsticksProfileInfo',
        \   'status_title': 'profile',
        \   'status_label': 'profile',
        \   'health_domain': 'profile',
        \   'health_interface_label': 'profile interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'profile value', 'not ready', ':ChopsticksConfig'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'ui',
        \   'function': 'ChopsticksUiInfo',
        \   'status_title': 'ui',
        \   'status_label': 'visual surface',
        \   'health_domain': 'ui',
        \   'health_interface_label': 'visual surface interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'visual surface', 'UI setup not ready',
        \       ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'languages',
        \   'function': 'ChopsticksLanguageInfo',
        \   'status_title': 'languages',
        \   'status_label': 'language surface',
        \   'health_domain': 'languages',
        \   'health_interface_label': 'language surface interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'language surface', 'language setup not ready',
        \       ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'plugins',
        \   'function': 'ChopsticksPluginInfo',
        \   'status_title': 'plugin reproducibility',
        \   'status_label': 'plugin locks',
        \   'health_domain': 'plugins',
        \   'health_interface_label': 'plugin interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'plugin reproducibility', 'not ready', ':PlugInstall'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'lint',
        \   'function': 'ChopsticksLintInfo',
        \   'status_title': 'lint',
        \   'status_label': 'ALE stack',
        \   'health_domain': 'lint',
        \   'health_interface_label': 'lint interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'ALE lint', 'lint setup not ready', ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'completion',
        \   'function': 'ChopsticksCompletionInfo',
        \   'status_title': 'completion',
        \   'status_label': 'completion engine',
        \   'health_domain': 'completion',
        \   'health_interface_label': 'completion interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'completion loop', 'completion setup not ready',
        \       ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'editing',
        \   'function': 'ChopsticksEditingInfo',
        \   'status_title': 'editing',
        \   'status_label': 'editing assist',
        \   'health_domain': 'editing',
        \   'health_interface_label': 'editing assist interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'editing assist', 'editing assist not ready',
        \       ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'navigation',
        \   'function': 'ChopsticksNavigationInfo',
        \   'status_title': 'navigation',
        \   'status_label': 'window navigation',
        \   'health_domain': 'navigation',
        \   'health_interface_label': 'navigation interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'navigation', 'not ready', ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'buffers',
        \   'function': 'ChopsticksBufferInfo',
        \   'status_title': 'buffers',
        \   'status_label': 'buffers',
        \   'health_domain': 'buffers',
        \   'health_interface_label': 'buffer lifecycle interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'buffer lifecycle', 'buffer lifecycle not ready',
        \       ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'quickfix',
        \   'function': 'ChopsticksQuickfixInfo',
        \   'status_title': 'quickfix',
        \   'status_label': 'quickfix',
        \   'health_domain': 'quickfix',
        \   'health_interface_label': 'quickfix interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'quickfix', 'quickfix not ready', ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'file-safety',
        \   'function': 'ChopsticksFileSafetyInfo',
        \   'status_title': 'file safety',
        \   'status_label': 'file safety',
        \   'health_domain': 'file-safety',
        \   'health_interface_label': 'file safety interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'file safety', 'file safety not ready',
        \       ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'git',
        \   'function': 'ChopsticksGitInfo',
        \   'status_title': 'git',
        \   'status_label': 'git loop',
        \   'health_domain': 'git',
        \   'health_interface_label': 'git interface',
        \   'health_defaults': s:HealthDefaults('setup',
        \       'git loop', 'git loop not ready', ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'runner',
        \   'function': 'ChopsticksRunnerInfo',
        \   'status_title': 'project run',
        \   'status_label': 'project run',
        \   'health_domain': 'runner',
        \   'health_interface_label': 'runner interface',
        \   'health_defaults': s:HealthDefaults('setup',
        \       'project run', 'runner not ready', ':ChopsticksStatus'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'beta',
        \   'function': 'ChopsticksBetaInfo',
        \   'status_title': 'release guide',
        \   'status_label': 'release guide',
        \   'status_enabled_only': 1,
        \ }),
        \ s:InfoSurface({
        \   'name': 'toolchain',
        \   'function': 'ChopsticksToolchainInfo',
        \   'status_title': 'toolchain',
        \   'status_label': 'toolchain',
        \   'health_domain': 'toolchain',
        \   'health_interface_label': 'toolchain interface',
        \   'health_defaults': s:HealthDefaults('optional',
        \       'toolchain', 'missing tool', ':ChopsticksStatus'),
        \   'health_options': {'check_items': 0, 'check_sections': 1},
        \ }),
        \ s:InfoSurface({
        \   'name': 'input-method',
        \   'function': 'ChopsticksInputMethodInfo',
        \   'status_title': 'input method',
        \   'status_label': 'input method switch',
        \   'health_domain': 'input-method',
        \   'health_interface_label': 'input method interface',
        \   'health_defaults': s:HealthDefaults('setup',
        \       'input method switch', 'not ready',
        \       'configure g:chopsticks_input_method_cmd and default input'),
        \ }),
        \ s:InfoSurface({
        \   'name': 'lsp',
        \   'function': 'ChopsticksLspInfo',
        \   'status_title': 'lsp servers',
        \   'status_label': 'vim-lsp stack',
        \   'health_domain': 'lsp',
        \   'health_interface_label': 'LSP interface',
        \   'health_defaults': s:HealthDefaults('attention',
        \       'LSP interface', 'LSP interface not ready',
        \       'reload chopsticks'),
        \ }),
        \ ]
endfunction

function! s:InfoSurfaceNames(kind) abort
    if a:kind ==# 'status'
        return [
            \ 'health', 'keymap', 'help', 'learning', 'runtime', 'modules',
            \ 'core', 'commands', 'local-config', 'utilities', 'profile',
            \ 'ui', 'languages', 'plugins', 'lint', 'completion', 'editing',
            \ 'navigation', 'buffers', 'quickfix', 'file-safety', 'git',
            \ 'runner', 'beta', 'toolchain', 'input-method', 'lsp',
            \ ]
    endif
    if a:kind ==# 'health'
        return [
            \ 'runtime', 'local-config', 'modules', 'core', 'commands',
            \ 'utilities', 'profile', 'plugins', 'ui', 'languages', 'lint',
            \ 'completion', 'keymap', 'help', 'learning', 'editing',
            \ 'navigation', 'buffers', 'quickfix', 'file-safety', 'git',
            \ 'runner', 'toolchain', 'lsp', 'input-method',
            \ ]
    endif
    return []
endfunction

function! ChopsticksInfoSurfaceSpecs() abort
    return deepcopy(s:InfoSurfaceSpecs())
endfunction

function! ChopsticksInfoSurfaceSpec(name) abort
    for l:spec in s:InfoSurfaceSpecs()
        if get(l:spec, 'name', '') ==# a:name
            return deepcopy(l:spec)
        endif
    endfor
    return {}
endfunction

function! ChopsticksInfoSurfaceSpecsFor(kind) abort
    let l:specs = []
    for l:name in s:InfoSurfaceNames(a:kind)
        let l:spec = ChopsticksInfoSurfaceSpec(l:name)
        if !empty(l:spec)
            call add(l:specs, l:spec)
        endif
    endfor
    return l:specs
endfunction

function! s:StatusMissingInfo(title, label, reason) abort
    return ChopsticksInfoSection(a:title, {
        \ 'details': [],
        \ 'items': [
        \   ChopsticksInfoItem(a:label, 'missing', a:reason),
        \ ],
        \ })
endfunction

function! s:StatusInfoFallback(spec) abort
    if has_key(a:spec, 'fallback')
        return copy(get(a:spec, 'fallback', {}))
    endif
    return s:StatusMissingInfo(
        \ get(a:spec, 'section_title', 'status'),
        \ get(a:spec, 'label', 'status'),
        \ get(a:spec, 'reason', 'command not loaded'))
endfunction

function! ChopsticksStatusInfoFromSpec(spec) abort
    let l:function_name = get(a:spec, 'function', '')
    let l:result = ChopsticksInfoCall(l:function_name)
    let l:status = get(l:result, 'status', 'missing')
    if l:status ==# 'missing'
        return s:StatusInfoFallback(a:spec)
    endif
    if l:status ==# 'thrown'
        return s:StatusMissingInfo(
            \ get(a:spec, 'section_title', 'status'),
            \ get(a:spec, 'label', 'status'),
            \ get(l:result, 'detail', l:function_name . '() failed'))
    endif
    if l:status ==# 'invalid-type'
        return s:StatusMissingInfo(
            \ get(a:spec, 'section_title', 'status'),
            \ get(a:spec, 'label', 'status'),
            \ l:function_name . '() returned invalid status info')
    endif
    if l:status ==# 'invalid-shape'
        return s:StatusMissingInfo(
            \ get(a:spec, 'section_title', 'status'),
            \ get(a:spec, 'label', 'status'),
            \ get(l:result, 'detail', 'invalid status info'))
    endif
    return get(l:result, 'info', {})
endfunction

function! ChopsticksInfoSection(title, ...) abort
    let l:section = a:0 ? copy(a:1) : {}
    let l:section.title = a:title
    return l:section
endfunction

function! ChopsticksInfoDetail(label, value) abort
    return {
        \ 'label': a:label,
        \ 'value': a:value,
        \ 'reason': '',
        \ }
endfunction

function! ChopsticksInfoItem(label, state, reason, ...) abort
    let l:item = {
        \ 'label': a:label,
        \ 'state': a:state,
        \ 'reason': a:reason,
        \ }
    if a:0
        call extend(l:item, a:1)
    endif
    return l:item
endfunction

function! ChopsticksInfoDiagnosticItem(label, state, reason, issue_label, action, ...) abort
    let l:opts = a:0 ? copy(a:1) : {}
    let l:detail = get(l:opts, 'detail', a:reason)
    let l:severity = get(l:opts, 'severity', 'attention')
    call extend(l:opts, {
        \ 'diagnostic': 1,
        \ 'severity': l:severity,
        \ 'issue_label': a:issue_label,
        \ 'detail': l:detail,
        \ 'action': a:action,
        \ }, 'force')
    return ChopsticksInfoItem(a:label, a:state, a:reason, l:opts)
endfunction

function! ChopsticksInfoItemValue(label, value, state, reason, ...) abort
    let l:item = a:0
        \ ? ChopsticksInfoItem(a:label, a:state, a:reason, a:1)
        \ : ChopsticksInfoItem(a:label, a:state, a:reason)
    let l:item.value = a:value
    return l:item
endfunction
