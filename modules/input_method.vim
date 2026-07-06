" input_method.vim — opt-in input method switching

let g:chopsticks_enable_input_method = get(g:, 'chopsticks_enable_input_method', 0)
let g:chopsticks_input_method_cmd = get(g:, 'chopsticks_input_method_cmd', 'im-select')
let g:chopsticks_input_method_default = get(g:, 'chopsticks_input_method_default',
    \ ChopsticksRuntimeFeatureAvailable('mac') ? 'com.apple.keylayout.ABC' : '')
let g:chopsticks_input_method_restore = get(g:, 'chopsticks_input_method_restore', 1)
let g:chopsticks_input_method_disable_on_ssh = get(g:,
    \ 'chopsticks_input_method_disable_on_ssh', 1)
let g:chopsticks_input_method_filetypes = get(g:, 'chopsticks_input_method_filetypes', [])
let g:chopsticks_input_method_ignore_filetypes = get(g:,
    \ 'chopsticks_input_method_ignore_filetypes',
    \ ['fzf', 'help', 'netrw', 'qf'])

function! s:AsList(value) abort
    if type(a:value) == type([])
        return a:value
    endif
    if type(a:value) == type('') && !empty(a:value)
        return [a:value]
    endif
    return []
endfunction

function! s:RemoteSession() abort
    if exists('*ChopsticksRuntimeInfo')
        return ChopsticksRuntimeInfo().remote
    endif
    return !empty($SSH_CONNECTION) || !empty($SSH_CLIENT) || !empty($SSH_TTY)
endfunction

function! ChopsticksInputMethodInfo() abort
    let l:cmd = get(g:, 'chopsticks_input_method_cmd', 'im-select')
    let l:default = get(g:, 'chopsticks_input_method_default', '')
    let l:enabled = get(g:, 'chopsticks_enable_input_method', 0)
    let l:remote = s:RemoteSession()
    let l:disable_on_ssh = get(g:, 'chopsticks_input_method_disable_on_ssh', 1)

    let l:available = 0
    if !l:enabled
        let l:reason = 'disabled by default'
    elseif l:remote && l:disable_on_ssh
        let l:reason = 'disabled on SSH'
    elseif empty(l:cmd)
        let l:reason = 'missing input method command'
    elseif !ChopsticksToolAvailable(l:cmd)
        let l:reason = 'missing: ' . l:cmd
    elseif empty(l:default)
        let l:reason = 'missing default input source'
    else
        let l:available = 1
        let l:reason = 'ready'
    endif

    let l:buffer_enabled = 0
    if !l:available
        let l:buffer_reason = 'input method unavailable'
    elseif &buftype !=# ''
        let l:buffer_reason = 'buffer type: ' . &buftype
    else
        let l:allow = s:AsList(get(g:, 'chopsticks_input_method_filetypes', []))
        let l:ignore = s:AsList(get(g:, 'chopsticks_input_method_ignore_filetypes', []))
        if !empty(l:allow) && index(l:allow, &filetype) < 0
            let l:buffer_reason = 'filetype not allowed: ' . &filetype
        elseif index(l:ignore, &filetype) >= 0
            let l:buffer_reason = 'filetype ignored: ' . &filetype
        else
            let l:buffer_enabled = 1
            let l:buffer_reason = 'ready'
        endif
    endif

    if !l:enabled
        let l:state = 'off'
        let l:item_reason = l:reason
        let l:diagnostic = 0
        let l:severity = ''
        let l:action = ''
    elseif l:remote && l:disable_on_ssh
        let l:state = 'off'
        let l:item_reason = l:reason
        let l:diagnostic = 1
        let l:severity = 'info'
        let l:action = 'set g:chopsticks_input_method_disable_on_ssh = 0 to opt in'
    elseif l:available
        let l:state = 'ready'
        let l:item_reason = l:cmd
        let l:diagnostic = 0
        let l:severity = ''
        let l:action = ''
    else
        let l:state = 'missing'
        let l:item_reason = l:reason
        let l:diagnostic = 1
        let l:severity = 'setup'
        let l:action = 'configure g:chopsticks_input_method_cmd and default input'
    endif

    let l:items = [ChopsticksInfoItem('input method switch',
        \ l:state, l:item_reason, {
        \ 'diagnostic': l:diagnostic,
        \ 'severity': l:severity,
        \ 'detail': l:reason,
        \ 'action': l:action,
        \ })]
    let l:details = []
    if l:enabled
        call add(l:details, ChopsticksInfoDetail('default', l:default))
        call add(l:details, extend(ChopsticksInfoDetail('buffer',
            \ l:buffer_enabled ? 'enabled' : 'disabled'),
            \ {'reason': l:buffer_reason}, 'force'))
        if l:remote
            call add(l:details, ChopsticksInfoDetail('remote', 'SSH session'))
        endif
        call add(l:details,
            \ ChopsticksInfoDetail('command', ':ChopsticksInputMethodStatus'))
    endif

    return ChopsticksInfoSection('input method', {
        \ 'enabled': l:enabled,
        \ 'available': l:available,
        \ 'reason': l:reason,
        \ 'items': l:items,
        \ 'details': l:details,
        \ 'command': l:cmd,
        \ 'default': l:default,
        \ 'restore': get(g:, 'chopsticks_input_method_restore', 1),
        \ 'remote': l:remote,
        \ 'remote_source': exists('*ChopsticksRuntimeInfo')
        \     ? ChopsticksRuntimeInfo().remote_source
        \     : '',
        \ 'disable_on_ssh': l:disable_on_ssh,
        \ 'filetype': &filetype,
        \ 'buftype': &buftype,
        \ 'buffer_enabled': l:buffer_enabled,
        \ 'buffer_reason': l:buffer_reason,
        \ 'saved': get(b:, 'chopsticks_input_method_saved', ''),
        \ 'last': get(b:, 'chopsticks_input_method_last', ''),
        \ })
endfunction

function! s:Available() abort
    return ChopsticksInputMethodInfo().available
endfunction

function! s:BufferEnabled() abort
    return ChopsticksInputMethodInfo().buffer_enabled
endfunction

function! s:Run(args) abort
    let l:cmd = shellescape(g:chopsticks_input_method_cmd)
    for l:arg in a:args
        let l:cmd .= ' ' . shellescape(l:arg)
    endfor
    if ChopsticksRuntimeFeatureAvailable('unix')
        let l:cmd .= ' 2>/dev/null'
    endif

    let l:out = system(l:cmd)
    if v:shell_error != 0
        return ''
    endif
    return substitute(l:out, '[\r\n]\+$', '', '')
endfunction

function! s:Current() abort
    return s:Run([])
endfunction

function! s:Select(input_source) abort
    if empty(a:input_source)
        return
    endif
    call s:Run([a:input_source])
endfunction

function! s:SwitchToDefault() abort
    if !s:BufferEnabled()
        return
    endif

    let l:current = s:Current()
    if empty(l:current)
        return
    endif

    let b:chopsticks_input_method_last = l:current
    if l:current ==# g:chopsticks_input_method_default
        unlet! b:chopsticks_input_method_saved
        return
    endif

    let b:chopsticks_input_method_saved = l:current
    call s:Select(g:chopsticks_input_method_default)
endfunction

function! s:Restore() abort
    if !s:BufferEnabled() || !get(g:, 'chopsticks_input_method_restore', 1)
        return
    endif

    let l:target = get(b:, 'chopsticks_input_method_saved', '')
    if empty(l:target) || l:target ==# g:chopsticks_input_method_default
        return
    endif

    call s:Select(l:target)
endfunction

function! s:Status() abort
    let l:info = ChopsticksInputMethodInfo()
    let l:state = l:info.enabled
        \ ? 'enabled'
        \ : 'disabled'
    echo 'input method: ' . l:state
    echo 'available: ' . (l:info.available ? 'yes' : 'no') . ' (' . l:info.reason . ')'
    echo 'buffer: ' . (l:info.buffer_enabled ? 'enabled' : 'disabled') . ' (' . l:info.buffer_reason . ')'
    echo 'remote: ' . (l:info.remote ? 'yes' : 'no')
    echo 'command: ' . l:info.command
    echo 'default: ' . l:info.default
    echo 'restore: ' . (l:info.restore ? 'yes' : 'no')
    echo 'saved: ' . l:info.saved
    echo 'last: ' . l:info.last
endfunction

function! s:Enable() abort
    let g:chopsticks_enable_input_method = 1
    let l:info = ChopsticksInputMethodInfo()
    if l:info.available
        echo 'chopsticks input method enabled'
    else
        echohl WarningMsg
        echom 'chopsticks input method enabled, but ' . l:info.reason
        echohl None
    endif
endfunction

function! s:Disable() abort
    let g:chopsticks_enable_input_method = 0
    echo 'chopsticks input method disabled'
endfunction

function! s:Toggle() abort
    if get(g:, 'chopsticks_enable_input_method', 0)
        call s:Disable()
    else
        call s:Enable()
    endif
endfunction

augroup ChopsticksInputMethod
    autocmd!
    autocmd InsertLeave * call s:SwitchToDefault()
    autocmd InsertEnter * call s:Restore()
augroup END

command! ChopsticksInputMethodStatus call s:Status()
command! ChopsticksInputMethodEnable call s:Enable()
command! ChopsticksInputMethodDisable call s:Disable()
command! ChopsticksInputMethodToggle call s:Toggle()
