" env.vim — environment detection (must load first)

set nocompatible

let g:is_tty       = empty($TERM) || $TERM ==# 'dumb' || $TERM =~# 'linux'
                 \ || $TERM =~# 'screen' || &term =~# 'builtin'
let g:has_true_color = ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')

let s:profile_choices = ['minimal', 'engineer', 'full']
let s:keymap_choices = ['classic', 'space']

let g:chopsticks_requested_profile = get(g:, 'chopsticks_profile', 'engineer')
let g:chopsticks_profile_valid =
    \ index(s:profile_choices, g:chopsticks_requested_profile) >= 0
let g:chopsticks_profile = g:chopsticks_requested_profile
if !g:chopsticks_profile_valid
    let g:chopsticks_profile = 'engineer'
endif

let g:chopsticks_requested_keymap_style =
    \ get(g:, 'chopsticks_keymap_style', 'space')
let g:chopsticks_keymap_style_valid =
    \ index(s:keymap_choices, g:chopsticks_requested_keymap_style) >= 0
let g:chopsticks_keymap_style = g:chopsticks_requested_keymap_style
if !g:chopsticks_keymap_style_valid
    let g:chopsticks_keymap_style = 'space'
endif
let g:chopsticks_space_keymaps = g:chopsticks_keymap_style ==# 'space'

let s:profile_full = g:chopsticks_profile ==# 'full'
let s:profile_minimal = g:chopsticks_profile ==# 'minimal'

let g:chopsticks_enable_lsp = get(g:, 'chopsticks_enable_lsp',
    \ !s:profile_minimal)
let g:chopsticks_enable_lint = get(g:, 'chopsticks_enable_lint',
    \ !s:profile_minimal)
let g:chopsticks_enable_extra_languages = get(g:,
    \ 'chopsticks_enable_extra_languages', !s:profile_minimal)
let g:chopsticks_enable_ui_extras = get(g:, 'chopsticks_enable_ui_extras',
    \ !s:profile_minimal)
let g:chopsticks_enable_markdown_preview = get(g:,
    \ 'chopsticks_enable_markdown_preview', !s:profile_minimal)
let g:chopsticks_enable_auto_pairs = get(g:,
    \ 'chopsticks_enable_auto_pairs', 0)
let g:chopsticks_enable_terminal_keymaps = get(g:,
    \ 'chopsticks_enable_terminal_keymaps', 0)
let g:chopsticks_enable_tmux_navigator = get(g:,
    \ 'chopsticks_enable_tmux_navigator', 0)
let g:chopsticks_enable_input_method = get(g:,
    \ 'chopsticks_enable_input_method', 0)
let g:chopsticks_pin_plugins = get(g:, 'chopsticks_pin_plugins', 1)

let g:chopsticks_markdown_lint = get(g:, 'chopsticks_markdown_lint',
    \ s:profile_full)
let g:chopsticks_markdown_format_on_save = get(g:,
    \ 'chopsticks_markdown_format_on_save', s:profile_full)
let g:chopsticks_markdown_lsp = get(g:, 'chopsticks_markdown_lsp',
    \ s:profile_full)
let g:chopsticks_markdown_spell = get(g:, 'chopsticks_markdown_spell',
    \ s:profile_full)
let g:chopsticks_markdown_conceal = get(g:, 'chopsticks_markdown_conceal',
    \ s:profile_full)
let g:chopsticks_lsp_virtual_text = get(g:, 'chopsticks_lsp_virtual_text',
    \ s:profile_full && !g:is_tty)

function! s:Feature(label, available, reason) abort
    return {
        \ 'label': a:label,
        \ 'available': a:available ? 1 : 0,
        \ 'reason': a:available ? 'available' : a:reason,
        \ }
endfunction

function! s:RuntimeFeatureSpec(name) abort
    let l:name = substitute(tolower(a:name), '^+', '', '')
    let l:name = substitute(l:name, '-', '_', 'g')
    if l:name ==# 'popupwin'
        let l:name = 'popup'
    elseif l:name ==# 'timer'
        let l:name = 'timers'
    elseif l:name ==# 'macos'
        let l:name = 'mac'
    endif

    if l:name ==# 'terminal'
        return s:Feature('terminal', has('terminal'),
            \ 'Vim was built without +terminal')
    elseif l:name ==# 'job'
        return s:Feature('job', has('job'),
            \ 'Vim was built without +job')
    elseif l:name ==# 'timers'
        return s:Feature('timers', has('timers'),
            \ 'Vim was built without +timers')
    elseif l:name ==# 'popup'
        return s:Feature('popup',
            \ has('popupwin') || has('patch-8.1.1517'),
            \ 'Vim was built without popup support')
    elseif l:name ==# 'clipboard'
        return s:Feature('clipboard', has('clipboard'),
            \ 'Vim was built without +clipboard')
    elseif l:name ==# 'persistent_undo'
        return s:Feature('persistent_undo', has('persistent_undo'),
            \ 'Vim was built without +persistent_undo')
    elseif l:name ==# 'unix'
        return s:Feature('unix', has('unix'),
            \ 'not a Unix-like Vim runtime')
    elseif l:name ==# 'mac' || l:name ==# 'macunix'
        return s:Feature('mac', has('mac') || has('macunix'),
            \ 'not a macOS Vim runtime')
    endif
    return s:Feature(l:name, has(l:name),
        \ 'Vim was built without +' . l:name)
endfunction

function! ChopsticksRuntimeFeatureSpec(name) abort
    return copy(s:RuntimeFeatureSpec(a:name))
endfunction

function! ChopsticksRuntimeFeatureAvailable(name) abort
    return get(s:RuntimeFeatureSpec(a:name), 'available', 0)
endfunction

function! ChopsticksEnsureDir(path, ...) abort
    let l:path = expand(a:path)
    if empty(l:path)
        return 0
    endif
    if isdirectory(l:path)
        return 1
    endif
    try
        if a:0
            silent! call mkdir(l:path, 'p', a:1)
        else
            silent! call mkdir(l:path, 'p')
        endif
    catch
        return 0
    endtry
    return isdirectory(l:path)
endfunction

function! ChopsticksEnsureParentDir(path, ...) abort
    let l:dir = fnamemodify(a:path, ':h')
    return a:0 ? ChopsticksEnsureDir(l:dir, a:1) : ChopsticksEnsureDir(l:dir)
endfunction

function! ChopsticksEnsureManagedFile(path, lines) abort
    if !ChopsticksEnsureParentDir(a:path)
        return 0
    endif
    if !filereadable(a:path)
        call writefile(copy(a:lines), a:path)
    endif
    return filereadable(a:path)
endfunction

function! ChopsticksAppendManagedFile(path, lines) abort
    if !ChopsticksEnsureParentDir(a:path)
        return 0
    endif
    call writefile(copy(a:lines), a:path, 'a')
    return filereadable(a:path)
endfunction

function! ChopsticksOpenManagedFile(path, opts) abort
    let l:new_file = !filereadable(a:path)
    let l:dir_ready = ChopsticksEnsureParentDir(a:path)
    if l:new_file && has_key(a:opts, 'file_seed_lines') && l:dir_ready
        call writefile(copy(get(a:opts, 'file_seed_lines', [])), a:path)
    endif

    execute 'edit ' . fnameescape(a:path)
    let l:filetype = get(a:opts, 'filetype', '')
    if !empty(l:filetype)
        execute 'setlocal filetype=' . l:filetype
    endif

    if l:new_file && has_key(a:opts, 'buffer_seed_lines')
        \ && line('$') == 1 && getline(1) ==# ''
        call setline(1, copy(get(a:opts, 'buffer_seed_lines', [])))
        if get(a:opts, 'mark_unmodified', 0)
            setlocal nomodified
        endif
    endif
    return {
        \ 'path': a:path,
        \ 'new_file': l:new_file,
        \ 'dir_ready': l:dir_ready,
        \ }
endfunction

function! s:ScratchBufferMap(lhs, rhs) abort
    if empty(a:lhs) || empty(a:rhs)
        return
    endif
    execute 'nnoremap <buffer> <silent> ' . a:lhs . ' ' . a:rhs
endfunction

function! ChopsticksOpenScratchBuffer(name, lines, opts) abort
    let l:name = a:name
    let l:existing_winnr = bufwinnr(l:name)
    let l:closed_existing = l:existing_winnr > 0
    if l:closed_existing
        execute l:existing_winnr . 'wincmd w | bd'
        if get(a:opts, 'toggle', 1)
            return {
                \ 'name': l:name,
                \ 'opened': 0,
                \ 'closed_existing': 1,
                \ }
        endif
    endif

    execute get(a:opts, 'split', 'botright new') . ' ' . fnameescape(l:name)
    if has_key(a:opts, 'height')
        execute 'resize ' . get(a:opts, 'height')
    endif
    if has_key(a:opts, 'width')
        execute 'vertical resize ' . get(a:opts, 'width')
    endif
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nowrap nonumber norelativenumber signcolumn=no
    if get(a:opts, 'winfixwidth', 0)
        setlocal winfixwidth
    endif
    call setline(1, copy(a:lines))
    setlocal nomodifiable readonly
    if get(a:opts, 'close_map', 1)
        call s:ScratchBufferMap('q', ':bd<CR>')
    endif
    for l:map in get(a:opts, 'mappings', [])
        call s:ScratchBufferMap(get(l:map, 'lhs', ''),
            \ get(l:map, 'rhs', ''))
    endfor

    return {
        \ 'name': l:name,
        \ 'opened': 1,
        \ 'closed_existing': l:closed_existing ? 1 : 0,
        \ 'bufnr': bufnr('%'),
        \ 'winnr': winnr(),
        \ }
endfunction

function! s:Flag(label, enabled, reason) abort
    return {
        \ 'label': a:label,
        \ 'enabled': a:enabled ? 1 : 0,
        \ 'reason': a:enabled ? 'enabled' : a:reason,
        \ }
endfunction

function! s:Display(value) abort
    return type(a:value) == type('') ? a:value : string(a:value)
endfunction

function! ChopsticksDisplayKeyLine(indent, key_width, key, label) abort
    return a:indent . printf('%-' . a:key_width . 's %s',
        \ a:key, a:label)
endfunction

function! s:StatusOffLine(name, reason) abort
    return '  off ' . a:name . '  (' . a:reason . ')'
endfunction

function! s:StatusStateLine(item) abort
    let l:label = get(a:item, 'label', get(a:item, 'ft', 'item'))
    let l:reason = get(a:item, 'reason', '')
    let l:detail = empty(l:reason) ? '' : '  (' . l:reason . ')'
    let l:value = get(a:item, 'value', '')
    let l:value_text = empty(l:value) ? '' : '  ' . l:value
    let l:state = get(a:item, 'state', 'missing')
    if l:state ==# 'off'
        return s:StatusOffLine(l:label, l:reason)
    endif
    if l:state ==# 'ready'
        return '  OK  ' . l:label . l:value_text . l:detail
    endif
    if l:state ==# 'optional'
        return '  opt ' . l:label . l:value_text . l:detail
    endif
    return '  --  ' . l:label . l:value_text . l:detail
endfunction

function! s:StatusDetailLine(detail, label_width) abort
    let l:reason = get(a:detail, 'reason', '')
    let l:suffix = empty(l:reason) ? '' : '  (' . l:reason . ')'
    return '  ' . printf('%-' . a:label_width . 's',
        \ get(a:detail, 'label', 'detail'))
        \ . get(a:detail, 'value', '') . l:suffix
endfunction

function! s:StatusSectionTitle(section) abort
    let l:suffix = get(a:section, 'suffix', '')
    return '── ' . get(a:section, 'title', 'section') . ' ──'
        \ . (empty(l:suffix) ? '' : '  (' . l:suffix . ')')
endfunction

function! s:StatusInfoLines(info) abort
    let l:lines = []
    for l:detail in get(a:info, 'details', [])
        call add(l:lines, s:StatusDetailLine(l:detail, 10))
    endfor
    for l:item in get(a:info, 'items', [])
        call add(l:lines, s:StatusStateLine(l:item))
    endfor
    for l:note in get(a:info, 'notes', [])
        call add(l:lines, '  ' . l:note)
    endfor
    return l:lines
endfunction

function! s:StatusInfoSection(info) abort
    let l:lines = [s:StatusSectionTitle(a:info)]
    call extend(l:lines, s:StatusInfoLines(a:info))
    call add(l:lines, '')
    call extend(l:lines, s:StatusInfoSections(a:info))
    return l:lines
endfunction

function! s:StatusInfoSections(info) abort
    let l:lines = []
    for l:section in get(a:info, 'sections', [])
        call extend(l:lines, s:StatusInfoSection(l:section))
    endfor
    return l:lines
endfunction

function! s:StatusInfoBlock(info) abort
    let l:lines = []
    if has_key(a:info, 'title')
        call extend(l:lines, s:StatusInfoSection(a:info))
    endif
    call extend(l:lines, s:StatusInfoSections(a:info))
    return l:lines
endfunction

function! s:StatusEmptyCounts() abort
    return {'ready': 0, 'missing': 0, 'optional': 0}
endfunction

function! s:StatusCountItem(counts, item) abort
    let l:state = get(a:item, 'state', 'missing')
    if l:state ==# 'ready'
        let a:counts.ready += 1
    elseif l:state ==# 'optional'
        let a:counts.optional += 1
    elseif l:state !=# 'off'
        let a:counts.missing += 1
    endif
endfunction

function! s:StatusAddCounts(total, counts) abort
    let a:total.ready += get(a:counts, 'ready', 0)
    let a:total.missing += get(a:counts, 'missing', 0)
    let a:total.optional += get(a:counts, 'optional', 0)
endfunction

function! s:StatusInfoCounts(info) abort
    let l:counts = s:StatusEmptyCounts()
    for l:item in get(a:info, 'items', [])
        call s:StatusCountItem(l:counts, l:item)
    endfor
    for l:section in get(a:info, 'sections', [])
        call s:StatusAddCounts(l:counts, s:StatusInfoCounts(l:section))
    endfor
    return l:counts
endfunction

function! s:StatusHeaderLines(info) abort
    let l:lines = ['chopsticks status', repeat('─', 50), '']
    for l:detail in get(a:info, 'details', [])
        call add(l:lines, s:StatusDetailLine(l:detail, 11))
    endfor
    call add(l:lines, '')
    return l:lines
endfunction

function! s:StatusCountsLine(counts) abort
    return '  ' . get(a:counts, 'ready', 0) . ' ready, '
        \ . get(a:counts, 'missing', 0) . ' missing, '
        \ . get(a:counts, 'optional', 0) . ' optional'
endfunction

function! ChopsticksStatusDisplay(header_info, infos) abort
    let l:lines = s:StatusHeaderLines(a:header_info)
    let l:footers = []
    let l:counts = s:StatusEmptyCounts()

    for l:info in a:infos
        call extend(l:footers, get(l:info, 'footers', []))
        call s:StatusAddCounts(l:counts, s:StatusInfoCounts(l:info))
        call extend(l:lines, s:StatusInfoBlock(l:info))
    endfor

    call add(l:lines, repeat('─', 50))
    call add(l:lines, s:StatusCountsLine(l:counts))
    if !empty(l:footers)
        call add(l:lines, '')
        for l:footer in l:footers
            call add(l:lines, '  ' . l:footer)
        endfor
    endif

    return {
        \ 'lines': l:lines,
        \ 'counts': l:counts,
        \ 'footers': l:footers,
        \ }
endfunction

function! ChopsticksLearningRowLines(rows, opts) abort
    let l:lines = []
    let l:indent = get(a:opts, 'indent', '')
    let l:key_width = get(a:opts, 'key_width', 0)
    for l:row in a:rows
        let l:line = get(l:row, 'line', '')
        if !empty(l:line)
            call add(l:lines, l:line)
            continue
        endif

        let l:key = get(l:row, 'key', '')
        let l:label = get(l:row, 'label', '')
        if has_key(l:row, 'gap')
            call add(l:lines, l:indent . l:key . get(l:row, 'gap', ' ')
                \ . l:label)
        elseif l:key_width > 0
            call add(l:lines, ChopsticksDisplayKeyLine(l:indent,
                \ l:key_width, l:key, l:label))
        else
            call add(l:lines, l:indent . l:key . ' ' . l:label)
        endif
    endfor
    return l:lines
endfunction

function! ChopsticksLearningRowLinesOr(rows, opts, fallback) abort
    return empty(a:rows)
        \ ? copy(a:fallback)
        \ : ChopsticksLearningRowLines(a:rows, a:opts)
endfunction

function! ChopsticksLearningTaskLine(info, indent, fallback_tasks) abort
    let l:tasks = get(a:info, 'tasks', [])
    if empty(l:tasks)
        let l:tasks = copy(a:fallback_tasks)
    endif
    return a:indent . 'task: ' . join(l:tasks, ', ')
endfunction

function! ChopsticksLearningDrillLine(info, fallback_steps) abort
    let l:steps = get(a:info, 'drill_steps', [])
    if empty(l:steps)
        let l:steps = copy(a:fallback_steps)
    endif
    return 'Repeat: ' . join(l:steps, ', ') . '.'
endfunction

function! s:EnabledLabels(items, fallback) abort
    let l:labels = []
    for l:item in a:items
        if get(l:item, 'enabled', 0)
            call add(l:labels, get(l:item, 'label', 'unknown'))
        endif
    endfor
    return empty(l:labels) ? a:fallback : join(l:labels, ', ')
endfunction

function! ChopsticksPluginSpec(name) abort
    if !exists('g:plugs') || !has_key(g:plugs, a:name)
        return {}
    endif
    return copy(get(g:plugs, a:name, {}))
endfunction

function! ChopsticksPluginDeclared(name) abort
    return exists('g:plugs') && has_key(g:plugs, a:name)
endfunction

function! ChopsticksPluginDir(name) abort
    let l:spec = ChopsticksPluginSpec(a:name)
    let l:dir = get(l:spec, 'dir', '')
    return empty(l:dir) ? '' : fnamemodify(l:dir, ':p')
endfunction

function! ChopsticksPluginInstalled(name) abort
    let l:dir = ChopsticksPluginDir(a:name)
    return !empty(l:dir) && isdirectory(l:dir)
endfunction

function! ChopsticksToolAvailable(cmd) abort
    return !empty(a:cmd) && executable(a:cmd)
endfunction

function! ChopsticksMissingTools(tools) abort
    let l:missing = []
    for l:tool in a:tools
        if !ChopsticksToolAvailable(l:tool)
            call add(l:missing, l:tool)
        endif
    endfor
    return l:missing
endfunction

function! ChopsticksToolState(label, cmd, optional, reason) abort
    let l:available = ChopsticksToolAvailable(a:cmd)
    return {
        \ 'label': a:label,
        \ 'cmd': a:cmd,
        \ 'optional': a:optional,
        \ 'reason': a:reason,
        \ 'available': l:available,
        \ 'enabled': 1,
        \ 'state': l:available ? 'ready' : (a:optional ? 'optional' : 'missing'),
        \ }
endfunction

function! ChopsticksToolOffState(label, reason) abort
    return {
        \ 'label': a:label,
        \ 'cmd': '',
        \ 'optional': 1,
        \ 'reason': a:reason,
        \ 'available': 0,
        \ 'enabled': 0,
        \ 'state': 'off',
        \ }
endfunction

function! ChopsticksLspLearningEnabledOr(fallback) abort
    if exists('*ChopsticksLspLearningEnabled')
        try
            return ChopsticksLspLearningEnabled()
        catch
            return a:fallback
        endtry
    endif

    let l:info = ChopsticksInfoOr('ChopsticksLspInfo', {})
    if !empty(l:info)
        return get(l:info, 'enabled',
            \ get(g:, 'chopsticks_enable_lsp', a:fallback))
            \ && get(get(l:info, 'stack', {}), 'state', '') !=# 'off'
    endif
    return a:fallback
endfunction

function! ChopsticksLearningLoopEnabled(loop, lsp_loop, fallback) abort
    if has_key(a:lsp_loop, 'enabled')
        return get(a:lsp_loop, 'enabled', 0)
    endif
    if has_key(a:loop, 'lsp_enabled')
        return get(a:loop, 'lsp_enabled', 0)
    endif
    return ChopsticksLspLearningEnabledOr(a:fallback)
endfunction

function! ChopsticksLearningKey(info, key, fallback) abort
    return get(get(a:info, 'keys', {}), a:key, a:fallback)
endfunction

function! ChopsticksLearningInfoRowLinesOr(info, row_key, opts, fallback) abort
    return ChopsticksLearningRowLinesOr(get(a:info, a:row_key, []),
        \ a:opts, a:fallback)
endfunction

function! ChopsticksKeymapSpecIssue(spec) abort
    let l:kind = get(a:spec, 'kind', 'map')
    let l:label = get(a:spec, 'label', 'map')
    if l:kind ==# 'leader'
        if get(g:, get(a:spec, 'var', ''), '') !=# get(a:spec, 'expected', '')
            return get(a:spec, 'message', 'leader mismatch')
        endif
    elseif l:kind ==# 'map'
        let l:mode = get(a:spec, 'mode', 'n')
        let l:lhs = get(a:spec, 'lhs', '')
        let l:rhs = maparg(l:lhs, l:mode)
        if empty(l:rhs)
            return l:label . ': missing ' . l:mode . 'map ' . l:lhs
        endif
        if stridx(l:rhs, get(a:spec, 'text', get(a:spec, 'rhs', ''))) < 0
            return l:label . ': ' . l:lhs . ' maps to ' . l:rhs
        endif
    elseif l:kind ==# 'no_map'
        let l:mode = get(a:spec, 'mode', 'n')
        let l:lhs = get(a:spec, 'lhs', '')
        let l:rhs = maparg(l:lhs, l:mode)
        if !empty(l:rhs)
            return l:label . ': unexpected ' . l:mode . 'map '
                \ . l:lhs . ' -> ' . l:rhs
        endif
    elseif l:kind ==# 'auto_pairs_map'
        let l:lhs = get(a:spec, 'lhs', '')
        let l:info = maparg(l:lhs, 'i', 0, 1)
        if empty(l:info)
            return l:label . ': missing imap ' . l:lhs
        endif
        if !get(l:info, 'buffer', 0)
            return l:label . ': ' . l:lhs . ' is not buffer-local'
        endif
        let l:rhs = get(l:info, 'rhs', '')
        if stridx(l:rhs, get(a:spec, 'text', '')) < 0
            return l:label . ': ' . l:lhs . ' maps to ' . l:rhs
        endif
    endif
    return ''
endfunction

function! ChopsticksKeymapSpecReady(spec) abort
    return empty(ChopsticksKeymapSpecIssue(a:spec))
endfunction

function! ChopsticksKeymapMissingKeys(specs) abort
    let l:missing = []
    for l:spec in a:specs
        if !ChopsticksKeymapSpecReady(l:spec)
            call add(l:missing, get(l:spec, 'key',
                \ get(l:spec, 'lhs', 'map')))
        endif
    endfor
    return l:missing
endfunction

function! ChopsticksKeymapContractSpecsOr(group, fallback) abort
    if exists('*ChopsticksKeymapContractSpecsFor')
        let l:specs = ChopsticksKeymapContractSpecsFor(a:group, a:fallback)
        return empty(l:specs) ? copy(a:fallback) : l:specs
    endif
    return copy(a:fallback)
endfunction

function! ChopsticksKeymapContractFirstSpecOr(group, fallback) abort
    return get(ChopsticksKeymapContractSpecsOr(a:group, [a:fallback]),
        \ 0, a:fallback)
endfunction

function! ChopsticksKeymapContractKeysOr(group, fallback) abort
    if exists('*ChopsticksKeymapContractKeys')
        let l:keys = ChopsticksKeymapContractKeys(a:group, a:fallback)
        return empty(l:keys) ? copy(a:fallback) : l:keys
    endif
    return copy(a:fallback)
endfunction

function! ChopsticksKeymapContractLinesOr(group, indent, key_width, fallback) abort
    if exists('*ChopsticksKeymapContractLines')
        let l:lines = ChopsticksKeymapContractLines(a:group, a:indent,
            \ a:key_width)
        return empty(l:lines) ? copy(a:fallback) : l:lines
    endif
    return copy(a:fallback)
endfunction

function! s:RemoteSessionInfo() abort
    if !empty($SSH_CONNECTION)
        return {'remote': 1, 'source': 'SSH_CONNECTION'}
    endif
    if !empty($SSH_CLIENT)
        return {'remote': 1, 'source': 'SSH_CLIENT'}
    endif
    if !empty($SSH_TTY)
        return {'remote': 1, 'source': 'SSH_TTY'}
    endif
    return {'remote': 0, 'source': ''}
endfunction

function! ChopsticksRuntimeInfo() abort
    let l:remote = s:RemoteSessionInfo()
    let l:editor = has('nvim') ? 'neovim' : 'vim'
    let l:version = printf('%d.%d', v:version / 100, v:version % 100)
    let l:minimum = '8.2'
    let l:compatible = !has('nvim') && v:version >= 802
    let l:features = [
        \ ChopsticksRuntimeFeatureSpec('terminal'),
        \ ChopsticksRuntimeFeatureSpec('job'),
        \ ChopsticksRuntimeFeatureSpec('timers'),
        \ ChopsticksRuntimeFeatureSpec('popup'),
        \ ]
    let l:details = [
        \ ChopsticksInfoDetail('editor',
        \     l:editor . ' ' . l:version . '  minimum=' . l:minimum),
        \ ChopsticksInfoDetail('session',
        \     l:remote.remote ? 'SSH session  via ' . l:remote.source : 'local'),
        \ ChopsticksInfoDetail('terminal',
        \     (g:is_tty ? 'TTY mode' : 'rich terminal')
        \     . '  truecolor=' . (g:has_true_color ? 'yes' : 'no')),
        \ ]
    let l:items = []
    if l:editor !=# 'vim'
        call add(l:items, ChopsticksInfoItem('runtime gate', 'missing',
            \ 'requires Vim 8.2/9.x', {
            \   'diagnostic': 1,
            \   'severity': 'attention',
            \   'issue_label': 'editor',
            \   'detail': 'Neovim is not supported',
            \   'action': 'start Vim 8.2 or Vim 9.x',
            \ }))
    elseif v:version < 802
        call add(l:items, ChopsticksInfoItem('runtime gate', 'missing',
            \ 'requires Vim 8.2/9.x', {
            \   'diagnostic': 1,
            \   'severity': 'attention',
            \   'issue_label': 'Vim version',
            \   'detail': 'found ' . l:version . ', need ' . l:minimum . '+',
            \   'action': 'upgrade Vim',
            \ }))
    else
        call add(l:items, ChopsticksInfoItem('runtime gate', 'ready',
            \ 'Vim 8.2/9.x', {'diagnostic': 0}))
    endif
    for l:feature in l:features
        call add(l:items, ChopsticksInfoItem('+' . l:feature.label,
            \ get(l:feature, 'available', 0) ? 'ready' : 'missing',
            \ get(l:feature, 'available', 0) ? '' : l:feature.reason,
            \ get(l:feature, 'available', 0)
            \   ? {'diagnostic': 0}
            \   : {
            \       'diagnostic': 1,
            \       'severity': 'setup',
            \       'issue_label': get(l:feature, 'label', 'feature'),
            \       'detail': get(l:feature, 'reason', 'missing feature'),
            \       'action': 'install a fuller Vim build',
            \     }))
    endfor
    if l:remote.remote
        call add(l:items, ChopsticksInfoItem('remote session', 'ready',
            \ 'detected via ' . l:remote.source, {
            \   'diagnostic': 1,
            \   'severity': 'info',
            \   'issue_label': 'remote session',
            \   'detail': 'detected via ' . l:remote.source,
            \   'action': 'TTY and SSH-safe defaults are active',
            \ }))
    endif
    return ChopsticksInfoSection('runtime', {
        \ 'editor': l:editor,
        \ 'vim_version': v:version,
        \ 'version': l:version,
        \ 'minimum': l:minimum,
        \ 'compatible': l:compatible,
        \ 'remote': l:remote.remote,
        \ 'remote_source': l:remote.source,
        \ 'is_tty': g:is_tty,
        \ 'true_color': g:has_true_color,
        \ 'features': l:features,
        \ 'details': l:details,
        \ 'items': l:items,
        \ })
endfunction

function! ChopsticksLocalConfigInfo() abort
    let l:path = expand(get(g:, 'chopsticks_resolved_local_config',
        \ get(g:, 'chopsticks_local_config', '~/.config/chopsticks.vim')))
    let l:exists = get(g:, 'chopsticks_local_config_exists',
        \ filereadable(l:path))
    let l:loaded = get(g:, 'chopsticks_local_config_loaded', 0)
    let l:error = get(g:, 'chopsticks_local_config_error', '')
    let l:source = get(g:, 'chopsticks_local_config_source', 'xdg')
    let l:throwpoint = get(g:, 'chopsticks_local_config_throwpoint', '')
    let l:ok = !l:exists || (l:loaded && empty(l:error))
    let l:details = [
        \ ChopsticksInfoDetail('path', l:path),
        \ ChopsticksInfoDetail('source', l:source),
        \ ChopsticksInfoDetail('commands', s:CommandHeader('config',
        \     ':ChopsticksConfig  :ChopsticksReload')),
        \ ]
    let l:items = []
    if !l:exists
        call add(l:items, ChopsticksInfoItem('local config', 'off',
            \ 'not created yet', {'diagnostic': 0}))
    elseif l:ok
        call add(l:items, ChopsticksInfoItem('local config', 'ready', 'loaded',
            \ {'diagnostic': 0}))
    else
        call add(l:items, ChopsticksInfoItem('local config', 'missing',
            \ empty(l:error) ? 'not loaded' : l:error, {
            \   'diagnostic': 1,
            \   'severity': 'attention',
            \   'issue_label': 'local preferences',
            \   'detail': empty(l:error) ? 'failed to load local config' : l:error,
            \   'action': ':ChopsticksConfig',
            \ }))
        if !empty(l:throwpoint)
            call add(l:details, ChopsticksInfoDetail('throw', l:throwpoint))
        endif
    endif
    return ChopsticksInfoSection('local preferences', {
        \ 'path': l:path,
        \ 'source': l:source,
        \ 'exists': l:exists,
        \ 'loaded': l:loaded,
        \ 'ok': l:ok,
        \ 'error': l:error,
        \ 'throwpoint': l:throwpoint,
        \ 'details': l:details,
        \ 'items': l:items,
        \ })
endfunction

function! s:LearningEntrypointKey(fallback) abort
    let l:info = ChopsticksInfoOr('ChopsticksLearningEntrypointInfo', {})
    let l:key = get(l:info, 'key', '')
    if !empty(l:key)
        return l:key
    endif
    return get(ChopsticksKeymapContractKeysOr('learning_entrypoint',
        \ [a:fallback]), 0, a:fallback)
endfunction

function! ChopsticksStatusHeaderInfo() abort
    let l:local = ChopsticksLocalConfigInfo()
    let l:help_key = s:LearningEntrypointKey(
        \ get(g:, 'chopsticks_space_keymaps', 1) ? 'SPC ?' : ',?')
    return ChopsticksInfoSection('status header', {
        \ 'details': [
        \   ChopsticksInfoDetail('help',
        \       s:CommandHeader('help',
        \           ':ChopsticksHelp  :ChopsticksTutor') . '  ' . l:help_key),
        \   ChopsticksInfoDetail('config', get(l:local, 'path', '')),
        \   ChopsticksInfoDetail('commands',
        \       s:CommandHeader('config',
        \           ':ChopsticksConfig  :ChopsticksReload')),
        \ ],
        \ })
endfunction

function! ChopsticksModuleInfo() abort
    let l:manifest = get(g:, 'chopsticks_module_manifest', [])
    let l:loads = get(g:, 'chopsticks_module_loads', [])
    let l:seen = {}
    let l:failed = []
    let l:duplicates = []
    let l:manifest_seen = {}
    for l:name in l:manifest
        if has_key(l:manifest_seen, l:name) && index(l:duplicates, l:name) < 0
            call add(l:duplicates, l:name)
        endif
        let l:manifest_seen[l:name] = 1
    endfor

    let l:files = []
    for l:path in globpath(g:chopsticks_dir . '/modules', '*.vim', 0, 1)
        call add(l:files, fnamemodify(l:path, ':t:r'))
    endfor
    call sort(l:files)

    let l:unlisted = []
    for l:name in l:files
        if index(l:manifest, l:name) < 0
            call add(l:unlisted, l:name)
        endif
    endfor

    for l:entry in l:loads
        let l:seen[get(l:entry, 'name', '')] = 1
        if !get(l:entry, 'loaded', 0)
            call add(l:failed, l:entry)
        endif
    endfor

    let l:missing = []
    for l:name in l:manifest
        if !has_key(l:seen, l:name)
            call add(l:missing, l:name)
        endif
    endfor

    let l:declared_count = len(l:manifest)
    let l:file_count = len(l:files)
    let l:loaded_count = len(filter(copy(l:loads), 'get(v:val, "loaded", 0)'))
    let l:inventory_ok = empty(l:duplicates) && empty(l:unlisted)
    let l:load_ok = empty(l:failed) && empty(l:missing)
    let l:ok = l:inventory_ok && l:load_ok

    let l:details = [
        \ ChopsticksInfoDetail('declared', l:declared_count),
        \ ChopsticksInfoDetail('files', l:file_count),
        \ ChopsticksInfoDetail('loaded', l:loaded_count . '/' . l:declared_count),
        \ ]

    let l:items = []
    if l:inventory_ok
        call add(l:items, ChopsticksInfoItem('module inventory', 'ready',
            \ 'manifest matches modules/*.vim', {'diagnostic': 0}))
    else
        if !empty(l:duplicates)
            call add(l:items, ChopsticksInfoItem('duplicate manifest', 'missing',
                \ join(l:duplicates, ', '), {
                \   'diagnostic': 1,
                \   'severity': 'attention',
                \   'issue_label': 'module manifest',
                \   'detail': 'duplicate entries: '
                \       . join(l:duplicates, ', '),
                \   'action': 'deduplicate g:chopsticks_module_manifest',
                \ }))
        endif
        if !empty(l:unlisted)
            call add(l:items, ChopsticksInfoItem('unlisted files', 'missing',
                \ join(l:unlisted, ', '), {
                \   'diagnostic': 1,
                \   'severity': 'attention',
                \   'issue_label': 'module inventory',
                \   'detail': 'files not in manifest: '
                \       . join(l:unlisted, ', '),
                \   'action': 'add them to g:chopsticks_module_manifest or remove the files',
                \ }))
        endif
    endif

    if l:load_ok
        call add(l:items, ChopsticksInfoItem('module load', 'ready',
            \ 'all modules loaded', {'diagnostic': 0}))
    else
        for l:entry in l:failed
            let l:reason = get(l:entry, 'error', 'failed to load')
            if !empty(get(l:entry, 'throwpoint', ''))
                let l:reason .= ' / ' . get(l:entry, 'throwpoint', '')
            endif
            call add(l:items, ChopsticksInfoItem(get(l:entry, 'name', 'module'),
                \ 'missing', l:reason, {
                \   'diagnostic': 1,
                \   'severity': 'attention',
                \   'issue_label': get(l:entry, 'name', 'module'),
                \   'detail': get(l:entry, 'error', 'module failed to load'),
                \   'action': ':ChopsticksStatus',
                \ }))
        endfor
        if !empty(l:missing)
            call add(l:items, ChopsticksInfoItem('missing', 'missing',
                \ join(l:missing, ', '), {
                \   'diagnostic': 1,
                \   'severity': 'attention',
                \   'issue_label': 'module manifest',
                \   'detail': 'not loaded: ' . join(l:missing, ', '),
                \   'action': 'check .vimrc module manifest',
                \ }))
        endif
    endif

    return ChopsticksInfoSection('modules', {
        \ 'manifest': copy(l:manifest),
        \ 'files': l:files,
        \ 'loads': copy(l:loads),
        \ 'declared_count': l:declared_count,
        \ 'file_count': l:file_count,
        \ 'loaded_count': l:loaded_count,
        \ 'failed': l:failed,
        \ 'missing': l:missing,
        \ 'duplicates': l:duplicates,
        \ 'unlisted': l:unlisted,
        \ 'inventory_ok': l:inventory_ok,
        \ 'ok': l:ok,
        \ 'details': l:details,
        \ 'items': l:items,
        \ })
endfunction

function! s:PublicCommand(name, owner, purpose, ...) abort
    let l:command = {
        \ 'name': a:name,
        \ 'owner': a:owner,
        \ 'purpose': a:purpose,
        \ 'available': ChopsticksCommandAvailable(a:name),
        \ }
    if a:0
        call extend(l:command, a:1)
    endif
    return l:command
endfunction

function! ChopsticksCommandAvailable(name) abort
    let l:name = substitute(a:name, '^:', '', '')
    return !empty(l:name) && exists(':' . l:name) == 2
endfunction

function! ChopsticksMissingCommands(commands) abort
    let l:missing = []
    for l:command in a:commands
        let l:name = substitute(l:command, '^:', '', '')
        if !ChopsticksCommandAvailable(l:name)
            call add(l:missing, ':' . l:name)
        endif
    endfor
    return l:missing
endfunction

function! s:CommandCatalog() abort
    return [
        \ s:PublicCommand('ChopsticksHelp', 'help', 'native Vim help',
        \   {'header': 'help',
        \    'groups': ['survival'], 'display_label': 'full help'}),
        \ s:PublicCommand('ChopsticksConfig', 'utilities',
        \   'edit local preferences',
        \   {'header': 'config',
        \    'groups': ['survival'], 'display_label': 'local config'}),
        \ s:PublicCommand('ChopsticksReload', 'utilities',
        \   'reload chopsticks',
        \   {'header': 'config',
        \    'groups': ['survival'], 'display_label': 'reload config'}),
        \ s:PublicCommand('ChopsticksTutor', 'tutor', 'guided practice',
        \   {'header': 'help',
        \    'groups': ['survival'], 'display_label': 'practice'}),
        \ s:PublicCommand('ChopsticksCheatSheet', 'cheatsheet', 'active keymap reference'),
        \ s:PublicCommand('ChopsticksStatus', 'status', 'runtime diagnostics',
        \   {'groups': ['survival'], 'display_label': 'health'}),
        \ s:PublicCommand('ChopsticksDoctor', 'health',
        \   'actionable health issues',
        \   {'groups': ['survival'], 'display_label': 'issues'}),
        \ s:PublicCommand('ChopsticksKeymapAudit', 'keymap',
        \   'ergonomic contract',
        \   {'groups': ['survival'], 'display_label': 'key audit'}),
        \ s:PublicCommand('ChopsticksInputMethodStatus', 'input_method', 'input method status'),
        \ s:PublicCommand('ChopsticksInputMethodEnable', 'input_method', 'enable input method switch'),
        \ s:PublicCommand('ChopsticksInputMethodDisable', 'input_method', 'disable input method switch'),
        \ s:PublicCommand('ChopsticksInputMethodToggle', 'input_method', 'toggle input method switch'),
        \ s:PublicCommand('ChopsticksBeta', 'beta', 'release checklist',
        \   {'groups': ['survival', 'beta'],
        \    'display_label': 'release checklist'}),
        \ s:PublicCommand('ChopsticksBetaLog', 'beta',
        \   'editable release notes',
        \   {'groups': ['survival', 'beta'],
        \    'display_label': 'release notes'}),
        \ s:PublicCommand('ChopsticksBetaSession', 'beta',
        \   'append release note session',
        \   {'groups': ['survival', 'beta'],
        \    'display_label': 'new release note'}),
        \ ]
endfunction

function! s:CommandHeader(group, fallback) abort
    let l:commands = []
    for l:command in s:CommandCatalog()
        if get(l:command, 'header', '') ==# a:group
            call add(l:commands, ':' . get(l:command, 'name', 'Chopsticks'))
        endif
    endfor
    return empty(l:commands) ? a:fallback : join(l:commands, '  ')
endfunction

function! ChopsticksCommandHeader(group, fallback) abort
    return s:CommandHeader(a:group, a:fallback)
endfunction

function! ChopsticksCommandHeaderOr(group, fallback) abort
    if exists('*ChopsticksCommandHeader')
        let l:header = ChopsticksCommandHeader(a:group, a:fallback)
        return empty(l:header) ? a:fallback : l:header
    endif
    return a:fallback
endfunction

function! s:CommandInGroup(command, group) abort
    return index(get(a:command, 'groups', []), a:group) >= 0
endfunction

function! s:CommandDisplayLine(command, indent) abort
    let l:name = ':' . get(a:command, 'name', 'Chopsticks')
    let l:label = get(a:command, 'display_label',
        \ get(a:command, 'purpose', ''))
    return ChopsticksDisplayKeyLine(a:indent, 22, l:name, l:label)
endfunction

function! s:CommandLines(group, indent) abort
    let l:lines = []
    for l:command in s:CommandCatalog()
        if s:CommandInGroup(l:command, a:group)
            call add(l:lines, s:CommandDisplayLine(l:command, a:indent))
        endif
    endfor
    return l:lines
endfunction

function! ChopsticksCommandLines(group, ...) abort
    return s:CommandLines(a:group, a:0 ? a:1 : '  ')
endfunction

function! ChopsticksCommandLinesOr(group, indent, fallback) abort
    if exists('*ChopsticksCommandLines')
        let l:lines = ChopsticksCommandLines(a:group, a:indent)
        return empty(l:lines) ? copy(a:fallback) : l:lines
    endif
    return copy(a:fallback)
endfunction

function! s:CommandNames(commands) abort
    return map(copy(a:commands), "get(v:val, 'name', '')")
endfunction

function! s:OwnerCommandNames(owner) abort
    let l:names = []
    for l:command in s:CommandCatalog()
        if get(l:command, 'owner', '') ==# a:owner
            call add(l:names, get(l:command, 'name', ''))
        endif
    endfor
    call filter(l:names, '!empty(v:val)')
    return l:names
endfunction

function! ChopsticksCommandNames(owner, ...) abort
    let l:names = s:OwnerCommandNames(a:owner)
    return empty(l:names) && a:0 ? copy(a:1) : l:names
endfunction

function! ChopsticksCommandNamesOr(owner, fallback) abort
    if exists('*ChopsticksCommandNames')
        let l:names = ChopsticksCommandNames(a:owner, a:fallback)
        return empty(l:names) ? copy(a:fallback) : l:names
    endif
    return copy(a:fallback)
endfunction

function! s:DiscoveredChopsticksCommands() abort
    let l:commands = []
    for l:name in getcompletion('Chopsticks', 'command')
        if l:name =~# '^Chopsticks'
            call add(l:commands, l:name)
        endif
    endfor
    return uniq(sort(l:commands))
endfunction

function! ChopsticksCommandInfo() abort
    let l:commands = s:CommandCatalog()
    let l:declared_names = s:CommandNames(l:commands)
    let l:discovered = s:DiscoveredChopsticksCommands()
    let l:missing = []
    for l:command in l:commands
        if !get(l:command, 'available', 0)
            call add(l:missing, l:command)
        endif
    endfor
    let l:unlisted = []
    for l:name in l:discovered
        if index(l:declared_names, l:name) < 0
            call add(l:unlisted, l:name)
        endif
    endfor
    let l:declared_count = len(l:commands)
    let l:available_count = l:declared_count - len(l:missing)
    let l:discovered_count = len(l:discovered)
    let l:details = [
        \ ChopsticksInfoDetail('available', l:available_count . '/' . l:declared_count),
        \ ChopsticksInfoDetail('defined', l:discovered_count),
        \ ]
    let l:items = []
    if empty(l:missing) && empty(l:unlisted)
        call add(l:items, ChopsticksInfoItem('command surface', 'ready',
            \ 'catalog matches Vim commands', {'diagnostic': 0}))
    else
        for l:command in l:missing
            call add(l:items, ChopsticksInfoItem(':' . get(l:command, 'name', 'Command'),
                \ 'missing', get(l:command, 'owner', 'module'), {
                \   'diagnostic': 1,
                \   'severity': 'attention',
                \   'issue_label': get(l:command, 'name', 'command'),
                \   'detail': 'missing public command from '
                \       . get(l:command, 'owner', 'module'),
                \   'action': 'check module load and command definition',
                \ }))
        endfor
        for l:name in l:unlisted
            call add(l:items, ChopsticksInfoItem(':' . l:name, 'missing',
                \ 'unlisted', {
                \   'diagnostic': 1,
                \   'severity': 'attention',
                \   'issue_label': l:name,
                \   'detail': 'public command is defined but missing from command catalog',
                \   'action': 'add command to ChopsticksCommandInfo() catalog or remove command definition',
                \ }))
        endfor
    endif
    return ChopsticksInfoSection('command surface', {
        \ 'commands': l:commands,
        \ 'discovered': l:discovered,
        \ 'declared_count': l:declared_count,
        \ 'available_count': l:available_count,
        \ 'discovered_count': l:discovered_count,
        \ 'missing': l:missing,
        \ 'unlisted': l:unlisted,
        \ 'ok': empty(l:missing) && empty(l:unlisted),
        \ 'details': l:details,
        \ 'items': l:items,
        \ })
endfunction

function! ChopsticksProfileInfo() abort
    let l:features = [
        \ s:Flag('LSP', get(g:, 'chopsticks_enable_lsp', 1),
        \     'disabled by profile'),
        \ s:Flag('ALE', get(g:, 'chopsticks_enable_lint', 1),
        \     'disabled by profile'),
        \ s:Flag('extra languages',
        \     get(g:, 'chopsticks_enable_extra_languages', 1),
        \     'disabled by profile'),
        \ s:Flag('UI extras', get(g:, 'chopsticks_enable_ui_extras', 1),
        \     'disabled by profile'),
        \ s:Flag('Markdown preview',
        \     get(g:, 'chopsticks_enable_markdown_preview', 1),
        \     'disabled by profile'),
        \ ]
    let l:opt_ins = [
        \ s:Flag('jk escape', get(g:, 'chopsticks_enable_jk_escape', 0),
        \     'disabled by default'),
        \ s:Flag('Ctrl-S save', get(g:, 'chopsticks_enable_ctrl_s_save', 0),
        \     'disabled by default'),
        \ s:Flag(':w!! sudo save',
        \     get(g:, 'chopsticks_enable_sudo_save_bang', 0),
        \     'disabled by default'),
        \ s:Flag('completion keymaps',
        \     get(g:, 'chopsticks_enable_completion_keymaps', 0),
        \     'disabled by default'),
        \ s:Flag('auto-pairs', get(g:, 'chopsticks_enable_auto_pairs', 0),
        \     'disabled by default'),
        \ s:Flag('terminal keymaps',
        \     get(g:, 'chopsticks_enable_terminal_keymaps', 0),
        \     'disabled by default'),
        \ s:Flag('tmux navigator',
        \     get(g:, 'chopsticks_enable_tmux_navigator', 0),
        \     'disabled by default'),
        \ s:Flag('project-local exrc',
        \     get(g:, 'chopsticks_enable_exrc', 0),
        \     'disabled by default'),
        \ s:Flag('full-file reindent',
        \     get(g:, 'chopsticks_enable_reindent_file', 0),
        \     'disabled by default'),
        \ s:Flag('input method',
        \     get(g:, 'chopsticks_enable_input_method', 0),
        \     'disabled by default'),
        \ ]
    let l:markdown = [
        \ s:Flag('lint', get(g:, 'chopsticks_markdown_lint', 0),
        \     'disabled by default'),
        \ s:Flag('format-on-save',
        \     get(g:, 'chopsticks_markdown_format_on_save', 0),
        \     'disabled by default'),
        \ s:Flag('LSP', get(g:, 'chopsticks_markdown_lsp', 0),
        \     'disabled by default'),
        \ s:Flag('spell', get(g:, 'chopsticks_markdown_spell', 0),
        \     'disabled by default'),
        \ s:Flag('conceal', get(g:, 'chopsticks_markdown_conceal', 0),
        \     'disabled by default'),
        \ s:Flag('virtual text', get(g:, 'chopsticks_lsp_virtual_text', 0),
        \     g:is_tty ? 'disabled in TTY mode' : 'disabled by default'),
        \ ]
    let l:details = [
        \ ChopsticksInfoDetail('profile', g:chopsticks_profile),
        \ ChopsticksInfoDetail('keymap', g:chopsticks_keymap_style),
        \ ChopsticksInfoDetail('runtime',
        \     (g:is_tty ? 'TTY mode' : 'rich terminal')
        \     . '  truecolor=' . (g:has_true_color ? 'yes' : 'no')),
        \ ChopsticksInfoDetail('plugins',
        \     get(g:, 'chopsticks_pin_plugins', 1) ? 'pinned' : 'unpinned'),
        \ ChopsticksInfoDetail('features', s:EnabledLabels(l:features, 'core only')),
        \ ChopsticksInfoDetail('opt-ins', s:EnabledLabels(l:opt_ins, 'none')),
        \ ChopsticksInfoDetail('markdown',
        \     s:EnabledLabels(l:markdown, 'quiet defaults')),
        \ ]
    let l:items = []
    if !g:chopsticks_profile_valid
        call add(l:items, ChopsticksInfoItemValue('requested profile',
            \ s:Display(g:chopsticks_requested_profile), 'missing',
            \ 'using ' . g:chopsticks_profile, {
            \   'diagnostic': 1,
            \   'severity': 'attention',
            \   'issue_label': 'profile value',
            \   'detail': 'invalid profile: '
            \       . s:Display(g:chopsticks_requested_profile)
            \       . '; using ' . g:chopsticks_profile,
            \   'action': 'set g:chopsticks_profile to '
            \       . join(s:profile_choices, ', '),
            \ }))
    endif
    if !g:chopsticks_keymap_style_valid
        call add(l:items, ChopsticksInfoItemValue('requested keymap',
            \ s:Display(g:chopsticks_requested_keymap_style), 'missing',
            \ 'using ' . g:chopsticks_keymap_style, {
            \   'diagnostic': 1,
            \   'severity': 'attention',
            \   'issue_label': 'keymap value',
            \   'detail': 'invalid keymap: '
            \       . s:Display(g:chopsticks_requested_keymap_style)
            \       . '; using ' . g:chopsticks_keymap_style,
            \   'action': 'set g:chopsticks_keymap_style to '
            \       . join(s:keymap_choices, ', '),
            \ }))
    endif
    if !get(g:, 'chopsticks_pin_plugins', 1)
        call add(l:items, ChopsticksInfoItem('plugin locks', 'off',
            \ 'plugin pinning is disabled', {
            \   'diagnostic': 1,
            \   'severity': 'info',
            \   'detail': 'plugin pinning is disabled',
            \   'action': 'set g:chopsticks_pin_plugins = 1 after testing updates',
            \ }))
    endif
    return ChopsticksInfoSection('profile', {
        \ 'profile': g:chopsticks_profile,
        \ 'requested_profile': g:chopsticks_requested_profile,
        \ 'requested_profile_display':
        \     s:Display(g:chopsticks_requested_profile),
        \ 'profile_valid': g:chopsticks_profile_valid,
        \ 'profile_choices': copy(s:profile_choices),
        \ 'keymap': g:chopsticks_keymap_style,
        \ 'requested_keymap': g:chopsticks_requested_keymap_style,
        \ 'requested_keymap_display':
        \     s:Display(g:chopsticks_requested_keymap_style),
        \ 'keymap_valid': g:chopsticks_keymap_style_valid,
        \ 'keymap_choices': copy(s:keymap_choices),
        \ 'space_keymaps': g:chopsticks_space_keymaps,
        \ 'is_tty': g:is_tty,
        \ 'true_color': g:has_true_color,
        \ 'pin_plugins': get(g:, 'chopsticks_pin_plugins', 1),
        \ 'features': l:features,
        \ 'opt_ins': l:opt_ins,
        \ 'markdown': l:markdown,
        \ 'details': l:details,
        \ 'items': l:items,
        \ })
endfunction

" Skip built-in plugins we never use.
" Modern plugins check g:loaded_X; older ones (gzip, logiPat, rrhelper,
" spellfile) check the unscoped loaded_X form, so we set both.
let g:loaded_2html_plugin      = 1
let g:loaded_getscriptPlugin   = 1
let g:loaded_gzip              = 1 | let loaded_gzip              = 1
let g:loaded_logiPat           = 1 | let loaded_logiPat           = 1
let g:loaded_rrhelper          = 1 | let loaded_rrhelper          = 1
let g:loaded_tarPlugin         = 1
let g:loaded_vimballPlugin     = 1
let g:loaded_zipPlugin         = 1
let g:loaded_tutor_mode_plugin = 1
let g:loaded_spellfile_plugin  = 1 | let loaded_spellfile_plugin  = 1
let g:loaded_openPlugin        = 1
let g:loaded_manpager_plugin   = 1
