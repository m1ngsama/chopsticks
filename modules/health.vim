" health.vim — aggregate runtime health checks

let s:severity_order = ['attention', 'setup', 'optional', 'info']

function! s:KnownSeverity(value) abort
    return type(a:value) == type('') && index(s:severity_order, a:value) >= 0
endfunction

function! s:Severity(value, fallback) abort
    let l:fallback = s:KnownSeverity(a:fallback) ? a:fallback : 'attention'
    return s:KnownSeverity(a:value) ? a:value : l:fallback
endfunction

function! s:Slug(value) abort
    let l:text = type(a:value) == type('') ? a:value : string(a:value)
    let l:text = tolower(l:text)
    let l:text = substitute(l:text, '[^a-z0-9]\+', '-', 'g')
    let l:text = substitute(l:text, '^-', '', '')
    let l:text = substitute(l:text, '-$', '', '')
    return empty(l:text) ? 'check' : l:text
endfunction

function! s:IssueCode(domain, label) abort
    return s:Slug(a:domain) . '.' . s:Slug(a:label)
endfunction

function! s:Issue(severity, domain, label, detail, action) abort
    return {
        \ 'code': s:IssueCode(a:domain, a:label),
        \ 'severity': s:Severity(a:severity, 'attention'),
        \ 'domain': a:domain,
        \ 'label': a:label,
        \ 'detail': a:detail,
        \ 'action': a:action,
        \ }
endfunction

function! s:Add(issues, severity, domain, label, detail, action) abort
    call add(a:issues, s:Issue(a:severity, a:domain, a:label, a:detail, a:action))
endfunction

function! s:DiagnosticSeverity(diagnostic, defaults) abort
    if has_key(a:diagnostic, 'severity')
        return s:Severity(get(a:diagnostic, 'severity', ''), 'attention')
    endif
    return s:Severity(get(a:defaults, 'severity', 'attention'), 'attention')
endfunction

function! s:AddDiagnosticIssue(issues, domain, diagnostic, defaults) abort
    call s:Add(a:issues,
        \ s:DiagnosticSeverity(a:diagnostic, a:defaults),
        \ a:domain,
        \ get(a:diagnostic, 'issue_label',
        \     get(a:diagnostic, 'label', get(a:defaults, 'label', 'check'))),
        \ get(a:diagnostic, 'detail',
        \     get(a:diagnostic, 'reason',
        \         get(a:defaults, 'detail', 'not ready'))),
        \ get(a:diagnostic, 'action',
        \     get(a:defaults, 'action', 'reload chopsticks')))
endfunction

function! s:CheckDiagnosticItems(issues, domain, items, defaults) abort
    for l:item in a:items
        if !get(l:item, 'diagnostic', 0)
            continue
        endif
        call s:AddDiagnosticIssue(a:issues, a:domain, l:item, a:defaults)
    endfor
endfunction

function! s:CheckDiagnosticSections(issues, domain, sections, defaults) abort
    for l:section in a:sections
        let l:defaults = copy(a:defaults)
        if has_key(l:section, 'severity')
            let l:defaults.severity = s:Severity(
                \ get(l:section, 'severity', ''), 'attention')
        else
            let l:defaults.severity = s:Severity(
                \ get(a:defaults, 'severity', 'attention'), 'attention')
        endif
        call s:CheckDiagnosticItems(a:issues, a:domain,
            \ get(l:section, 'items', []), l:defaults)
        call s:CheckDiagnosticSections(a:issues, a:domain,
            \ get(l:section, 'sections', []), l:defaults)
    endfor
endfunction

function! s:AddInfoShapeIssue(issues, function_name, domain, interface_label, defaults, shape) abort
    call s:Add(a:issues,
        \ get(a:defaults, 'missing_severity', 'attention'),
        \ a:domain,
        \ a:interface_label,
        \ get(a:shape, 'detail',
        \     a:function_name . '() returned invalid diagnostic info'),
        \ get(a:shape, 'action',
        \     'return a valid info Dictionary from ' . a:function_name . '()'))
endfunction

function! s:CheckInfoInterface(issues, function_name, domain, interface_label, defaults, ...) abort
    let l:options = a:0 ? a:1 : {}
    let l:check_items = get(l:options, 'check_items', 1)
    let l:check_sections = get(l:options, 'check_sections', 0)
    let l:result = ChopsticksInfoCall(a:function_name)
    let l:status = get(l:result, 'status', 'missing')
    if l:status ==# 'missing'
        call s:Add(a:issues,
            \ get(a:defaults, 'missing_severity', 'attention'),
            \ a:domain,
            \ a:interface_label,
            \ a:function_name . '() is not loaded',
            \ get(a:defaults, 'missing_action', 'reload chopsticks'))
        return {'handled': 1, 'info': {}}
    endif
    if l:status ==# 'thrown'
        call s:Add(a:issues,
            \ get(a:defaults, 'missing_severity', 'attention'),
            \ a:domain,
            \ a:interface_label,
            \ get(l:result, 'detail', a:function_name . '() failed'),
            \ 'fix ' . a:function_name . '() and reload chopsticks')
        return {'handled': 1, 'info': {}}
    endif
    if l:status ==# 'invalid-type'
        call s:Add(a:issues,
            \ get(a:defaults, 'missing_severity', 'attention'),
            \ a:domain,
            \ a:interface_label,
            \ a:function_name . '() returned invalid diagnostic info',
            \ 'return a Dictionary from ' . a:function_name . '()')
        return {'handled': 1, 'info': {}}
    endif
    let l:info = get(l:result, 'info', {})
    if l:status ==# 'invalid-shape'
        call s:AddInfoShapeIssue(a:issues, a:function_name, a:domain,
            \ a:interface_label, a:defaults, get(l:result, 'shape', {}))
        return {'handled': 1, 'info': l:info}
    endif

    if l:check_items && has_key(l:info, 'items')
        call s:CheckDiagnosticItems(a:issues, a:domain,
            \ get(l:info, 'items', []), a:defaults)
        return {'handled': 1, 'info': l:info}
    endif
    if l:check_sections && has_key(l:info, 'sections')
        call s:CheckDiagnosticSections(a:issues, a:domain,
            \ get(l:info, 'sections', []), a:defaults)
        return {'handled': 1, 'info': l:info}
    endif

    return {'handled': 0, 'info': l:info}
endfunction

function! s:CheckRequiredItemInterface(issues, function_name, domain, interface_label, defaults, ...) abort
    let l:options = a:0 ? a:1 : {}
    let l:result = s:CheckInfoInterface(a:issues, a:function_name,
        \ a:domain, a:interface_label, a:defaults, l:options)
    if get(l:result, 'handled', 0)
        return
    endif

    call s:Add(a:issues,
        \ get(a:defaults, 'missing_severity', 'attention'),
        \ a:domain,
        \ a:interface_label,
        \ a:function_name . '() returned no diagnostic items',
        \ 'return an items list from ' . a:function_name . '()')
endfunction

function! s:AddKeymapIssue(issues, diagnostic) abort
    call s:AddDiagnosticIssue(a:issues, 'keymap', a:diagnostic, {
        \ 'severity': 'attention',
        \ 'label': 'ergonomic contract',
        \ 'detail': 'keymap audit issue',
        \ 'action': ':ChopsticksKeymapAudit',
        \ })
endfunction

function! s:CheckKeymapItems(issues, items) abort
    for l:item in a:items
        let l:diagnostics = get(l:item, 'diagnostics', [])
        if !empty(l:diagnostics)
            for l:diagnostic in l:diagnostics
                call s:AddKeymapIssue(a:issues, l:diagnostic)
            endfor
            continue
        endif
        if get(l:item, 'diagnostic', 0)
            call s:AddKeymapIssue(a:issues, l:item)
        endif
    endfor
endfunction

function! s:CheckKeymap(issues) abort
    if !exists('*ChopsticksKeymapAuditIssues')
        call s:Add(a:issues, 'attention', 'keymap', 'ergonomic contract',
            \ 'keymap audit interface is not loaded', 'reload chopsticks')
        return
    endif

    if exists('*ChopsticksKeymapAuditInfo')
        let l:audit = ChopsticksKeymapAuditInfo()
        if has_key(l:audit, 'items')
            call s:CheckKeymapItems(a:issues, get(l:audit, 'items', []))
            return
        endif
        for l:issue in get(l:audit, 'issues', [])
            call s:Add(a:issues, 'attention', 'keymap',
                \ 'ergonomic contract', l:issue, ':ChopsticksKeymapAudit')
        endfor
        return
    endif

    for l:issue in ChopsticksKeymapAuditIssues()
        call s:Add(a:issues, 'attention', 'keymap', 'ergonomic contract',
            \ l:issue, ':ChopsticksKeymapAudit')
    endfor
endfunction

function! s:Summary(issues) abort
    let l:summary = {'attention': 0, 'setup': 0, 'optional': 0, 'info': 0}
    for l:issue in a:issues
        let l:severity = s:Severity(get(l:issue, 'severity', 'info'), 'info')
        let l:summary[l:severity] = get(l:summary, l:severity, 0) + 1
    endfor
    return l:summary
endfunction

function! s:SummaryRows(summary) abort
    let l:rows = []
    for l:severity in s:severity_order
        call add(l:rows, {
            \ 'severity': l:severity,
            \ 'count': get(a:summary, l:severity, 0),
            \ })
    endfor
    return l:rows
endfunction

function! s:SummaryLine(rows) abort
    let l:parts = []
    for l:row in a:rows
        call add(l:parts, get(l:row, 'severity', 'info') . '='
            \ . get(l:row, 'count', 0))
    endfor
    return join(l:parts, ' ')
endfunction

function! s:SummaryDetails(state, summary_line) abort
    return [
        \ ChopsticksInfoDetail('doctor', a:state . '  ' . a:summary_line),
        \ ChopsticksInfoDetail('command', ':ChopsticksDoctor'),
        \ ]
endfunction

function! s:State(summary) abort
    if get(a:summary, 'attention', 0) > 0
        return 'attention'
    endif
    if get(a:summary, 'setup', 0) > 0
        return 'needs setup'
    endif
    return 'ready'
endfunction

function! s:OrderedIssues(issues) abort
    let l:ordered = []
    for l:severity in s:severity_order
        for l:issue in a:issues
            if s:Severity(get(l:issue, 'severity', 'info'), 'info') ==# l:severity
                call add(l:ordered, l:issue)
            endif
        endfor
    endfor
    return l:ordered
endfunction

function! s:HealthCheck(name, function_name) abort
    return {'kind': 'function', 'name': a:name, 'function': a:function_name}
endfunction

function! s:RequiredItemHealthCheck(name, function_name, domain, interface_label, defaults, ...) abort
    let l:check = {
        \ 'kind': 'required-items',
        \ 'name': a:name,
        \ 'function': a:function_name,
        \ 'domain': a:domain,
        \ 'interface_label': a:interface_label,
        \ 'defaults': copy(a:defaults),
        \ }
    if a:0
        let l:check.options = copy(a:1)
    endif
    return l:check
endfunction

function! s:HealthCheckFromSurface(surface) abort
    if get(a:surface, 'health_kind', '') ==# 'function'
        return s:HealthCheck(
            \ get(a:surface, 'name', 'health'),
            \ get(a:surface, 'health_function', ''))
    endif

    return s:RequiredItemHealthCheck(
        \ get(a:surface, 'name', 'health'),
        \ get(a:surface, 'function', ''),
        \ get(a:surface, 'health_domain', get(a:surface, 'name', 'health')),
        \ get(a:surface, 'health_interface_label',
        \     get(a:surface, 'name', 'health') . ' interface'),
        \ get(a:surface, 'health_defaults', {}),
        \ get(a:surface, 'health_options', {}))
endfunction

function! s:HealthCheckRegistry() abort
    let l:registry = []
    for l:surface in ChopsticksInfoSurfaceSpecsFor('health')
        call add(l:registry, s:HealthCheckFromSurface(l:surface))
    endfor
    return l:registry
endfunction

function! s:RunHealthCheck(issues, check) abort
    if get(a:check, 'kind', 'function') ==# 'required-items'
        call s:CheckRequiredItemInterface(a:issues,
            \ get(a:check, 'function', ''),
            \ get(a:check, 'domain', get(a:check, 'name', 'health')),
            \ get(a:check, 'interface_label',
            \     get(a:check, 'name', 'health') . ' interface'),
            \ get(a:check, 'defaults', {}),
            \ get(a:check, 'options', {}))
        return
    endif

    call call(get(a:check, 'function', ''), [a:issues])
endfunction

function! s:RunHealthChecks(issues) abort
    for l:check in s:HealthCheckRegistry()
        call s:RunHealthCheck(a:issues, l:check)
    endfor
endfunction

function! ChopsticksHealthInfo() abort
    let l:issues = []
    call s:RunHealthChecks(l:issues)

    let l:issues = s:OrderedIssues(l:issues)
    let l:summary = s:Summary(l:issues)
    let l:summary_rows = s:SummaryRows(l:summary)
    let l:state = s:State(l:summary)
    let l:summary_line = s:SummaryLine(l:summary_rows)
    return ChopsticksInfoSection('health', {
        \ 'state': l:state,
        \ 'summary': l:summary,
        \ 'summary_rows': l:summary_rows,
        \ 'summary_line': l:summary_line,
        \ 'severity_order': copy(s:severity_order),
        \ 'details': s:SummaryDetails(l:state, l:summary_line),
        \ 'issues': l:issues,
        \ })
endfunction

function! s:SummaryCountLine(row) abort
    return ChopsticksDisplayKeyLine('  ', 9,
        \ get(a:row, 'severity', 'info'), get(a:row, 'count', 0))
endfunction

function! s:IssueLine(issue) abort
    let l:line = '  ' . get(a:issue, 'severity', 'info')
        \ . '  [' . get(a:issue, 'code', 'health.check') . ']'
        \ . '  ' . get(a:issue, 'domain', 'runtime')
        \ . ' / ' . get(a:issue, 'label', 'check')
        \ . '  (' . get(a:issue, 'detail', 'no detail') . ')'
    let l:action = get(a:issue, 'action', '')
    return empty(l:action) ? l:line : l:line . '  -> ' . l:action
endfunction

function! s:OpenDoctor() abort
    let l:health = ChopsticksHealthInfo()
    let l:summary = l:health.summary
    let l:summary_rows = get(l:health, 'summary_rows', s:SummaryRows(l:summary))
    let l:lines = [
        \ 'chopsticks doctor',
        \ repeat('-', 50),
        \ '',
        \ '  state     ' . l:health.state,
        \ ]
    for l:row in l:summary_rows
        call add(l:lines, s:SummaryCountLine(l:row))
    endfor
    call add(l:lines, '')

    if empty(l:health.issues)
        call add(l:lines, '  OK  no health issues detected')
    else
        for l:issue in l:health.issues
            call add(l:lines, s:IssueLine(l:issue))
        endfor
    endif

    call ChopsticksOpenScratchBuffer('__ChopsticksDoctor__', l:lines, {
        \ 'height': 30,
        \ 'toggle': 0,
        \ })
endfunction

command! ChopsticksDoctor call s:OpenDoctor()
