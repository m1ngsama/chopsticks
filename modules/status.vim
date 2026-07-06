" status.vim — health diagnostics

function! s:ToolchainFallbackInfo() abort
    return {'sections': [], 'footers': []}
endfunction

function! s:LspFallbackInfo() abort
    let l:stack = ChopsticksInfoItem('vim-lsp stack', 'missing',
        \ 'command not loaded')
    return ChopsticksInfoSection('lsp servers', {
        \ 'enabled': 0,
        \ 'stack': copy(l:stack),
        \ 'servers': [],
        \ 'items': [copy(l:stack)],
        \ 'commands_loaded': 0,
        \ 'current_filetype': &filetype,
        \ 'markdown_lsp': 0,
        \ 'suffix': ':LspInstallServer to install',
        \ 'notes': [],
        \ 'footers': [],
        \ })
endfunction

function! s:BetaFallbackInfo() abort
    return ChopsticksInfoSection('release candidate', {
        \   'enabled': 0,
        \   'details': [],
        \   'items': [],
        \ })
endfunction

function! s:StatusHeaderHelpKey() abort
    let l:fallback = get(g:, 'chopsticks_space_keymaps', 1) ? 'SPC ?' : ',?'
    let l:info = ChopsticksInfoOr('ChopsticksLearningEntrypointInfo', {})
    let l:key = get(l:info, 'key', '')
    if !empty(l:key)
        return l:key
    endif
    let l:keys = ChopsticksKeymapContractKeysOr('learning_entrypoint',
        \ [l:fallback])
    return get(l:keys, 0, l:fallback)
endfunction

function! s:StatusHeaderFallbackInfo() abort
    return ChopsticksInfoSection('status header', {
        \ 'details': [
        \   ChopsticksInfoDetail('help',
        \       ChopsticksCommandHeaderOr('help',
        \           ':ChopsticksHelp  :ChopsticksTutor') . '  '
        \       . s:StatusHeaderHelpKey()),
        \   ChopsticksInfoDetail('config',
        \       expand(get(g:, 'chopsticks_resolved_local_config', ''))),
        \   ChopsticksInfoDetail('commands',
        \       ChopsticksCommandHeaderOr('config',
        \           ':ChopsticksConfig  :ChopsticksReload')),
        \ ],
        \ })
endfunction

function! s:StatusHeaderInfo() abort
    let l:fallback = s:StatusHeaderFallbackInfo()
    let l:info = ChopsticksInfoOr('ChopsticksStatusHeaderInfo', l:fallback)
    return get(l:info, 'title', '') ==# 'status header' ? l:info : l:fallback
endfunction

function! s:StatusInfoSpec(function_name, title, label, reason, ...) abort
    let l:spec = {
        \ 'function': a:function_name,
        \ 'section_title': a:title,
        \ 'label': a:label,
        \ 'reason': a:reason,
        \ }
    if a:0
        call extend(l:spec, a:1, 'force')
    endif
    return l:spec
endfunction

function! s:StatusFallbackFor(name) abort
    if a:name ==# 'beta'
        return s:BetaFallbackInfo()
    endif
    if a:name ==# 'toolchain'
        return s:ToolchainFallbackInfo()
    endif
    if a:name ==# 'lsp'
        return s:LspFallbackInfo()
    endif
    return {}
endfunction

function! s:StatusInfoSpecFromSurface(surface) abort
    let l:name = get(a:surface, 'name', '')
    let l:spec = s:StatusInfoSpec(
        \ get(a:surface, 'function', ''),
        \ get(a:surface, 'status_title', l:name),
        \ get(a:surface, 'status_label', l:name),
        \ get(a:surface, 'status_reason', 'command not loaded'))
    let l:fallback = s:StatusFallbackFor(l:name)
    if !empty(l:fallback)
        let l:spec.fallback = l:fallback
    endif
    if get(a:surface, 'status_enabled_only', 0)
        let l:spec.enabled_only = 1
    endif
    return l:spec
endfunction

function! s:StatusInfoFromSpec(spec) abort
    return ChopsticksStatusInfoFromSpec(a:spec)
endfunction

function! s:IncludeStatusInfo(info, spec) abort
    if get(a:spec, 'enabled_only', 0)
        return get(a:info, 'enabled', 0)
    endif
    return 1
endfunction

function! s:StatusInfoRegistry() abort
    let l:registry = []
    for l:surface in ChopsticksInfoSurfaceSpecsFor('status')
        call add(l:registry, s:StatusInfoSpecFromSurface(l:surface))
    endfor
    return l:registry
endfunction

function! s:StatusInfos() abort
    let l:infos = []
    for l:spec in s:StatusInfoRegistry()
        let l:info = s:StatusInfoFromSpec(l:spec)
        if s:IncludeStatusInfo(l:info, l:spec)
            call add(l:infos, l:info)
        endif
    endfor
    return l:infos
endfunction

function! s:ChopsticksStatus() abort
    let l:display = ChopsticksStatusDisplay(s:StatusHeaderInfo(),
        \ s:StatusInfos())

    call ChopsticksOpenScratchBuffer('__ChopsticksStatus__',
        \ get(l:display, 'lines', []), {
        \ 'height': 45,
        \ 'toggle': 0,
        \ })
endfunction
command! ChopsticksStatus call s:ChopsticksStatus()
