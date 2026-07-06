" quickfix.vim — quickfix and location-list helpers

function! s:QfAutocmdExists(pattern) abort
    return exists('#ChopstickQF#QuickFixCmdPost#' . a:pattern)
endfunction

function! s:FallbackNavigationSpecs() abort
    return [
        \ {'mode': 'n', 'lhs': '[q', 'key': '[q', 'text': 'cprev'},
        \ {'mode': 'n', 'lhs': ']q', 'key': ']q', 'text': 'cnext'},
        \ ]
endfunction

function! s:FallbackLocationNavigationSpecs() abort
    return [
        \ {'mode': 'n', 'lhs': '[l', 'key': '[l', 'text': 'lprev'},
        \ {'mode': 'n', 'lhs': ']l', 'key': ']l', 'text': 'lnext'},
        \ ]
endfunction

function! s:FallbackNavigationKeys() abort
    return ['[q', ']q']
endfunction

function! s:FallbackLocationNavigationKeys() abort
    return ['[l', ']l']
endfunction

function! s:NavigationSpecs() abort
    return ChopsticksKeymapContractSpecsOr('quickfix_navigation',
        \ s:FallbackNavigationSpecs())
endfunction

function! s:LocationNavigationSpecs() abort
    return ChopsticksKeymapContractSpecsOr('loclist_navigation',
        \ s:FallbackLocationNavigationSpecs())
endfunction

function! s:NavigationKey() abort
    return join(ChopsticksKeymapContractKeysOr('quickfix_navigation',
        \ s:FallbackNavigationKeys()), ' ')
endfunction

function! s:LocationNavigationKey() abort
    return join(ChopsticksKeymapContractKeysOr('loclist_navigation',
        \ s:FallbackLocationNavigationKeys()), ' ')
endfunction

function! s:QuickfixWindowItem(ready) abort
    if a:ready
        return ChopsticksInfoItem('quickfix window', 'ready', 'cwindow',
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('quickfix window', 'missing',
        \ 'missing QuickFixCmdPost cwindow', 'quickfix auto window',
        \ 'reload chopsticks', {
        \ 'detail': 'missing QuickFixCmdPost cwindow autocmd',
        \ })
endfunction

function! s:LocationWindowItem(ready) abort
    if a:ready
        return ChopsticksInfoItem('location window', 'ready', 'lwindow',
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('location window', 'missing',
        \ 'missing QuickFixCmdPost lwindow', 'location list auto window',
        \ 'reload chopsticks', {
        \ 'detail': 'missing QuickFixCmdPost lwindow autocmd',
        \ })
endfunction

function! s:QuickfixNavigationItem(missing) abort
    if empty(a:missing)
        return ChopsticksInfoItem('quickfix navigation', 'ready',
            \ s:NavigationKey(), {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('quickfix navigation', 'missing',
        \ 'missing: ' . join(a:missing, ', '), 'quickfix navigation',
        \ ':ChopsticksKeymapAudit', {
        \ 'detail': 'missing quickfix navigation maps: ' . join(a:missing, ', '),
        \ })
endfunction

function! s:LocationNavigationItem(missing) abort
    if empty(a:missing)
        return ChopsticksInfoItem('location navigation', 'ready',
            \ s:LocationNavigationKey(), {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('location navigation', 'missing',
        \ 'missing: ' . join(a:missing, ', '), 'location navigation',
        \ ':ChopsticksKeymapAudit', {
        \ 'detail': 'missing location navigation maps: ' . join(a:missing, ', '),
        \ })
endfunction

augroup ChopstickQF
    autocmd!
    autocmd QuickFixCmdPost [^l]* cwindow
    autocmd QuickFixCmdPost l*    lwindow
augroup END

nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [q :cprev<CR>
nnoremap <silent> ]l :lnext<CR>
nnoremap <silent> [l :lprev<CR>

function! ChopsticksQuickfixInfo() abort
    let l:qf_window = s:QfAutocmdExists('[^l]*')
    let l:loc_window = s:QfAutocmdExists('l*')
    let l:map_specs = s:NavigationSpecs()
    let l:loc_map_specs = s:LocationNavigationSpecs()
    let l:missing_maps = ChopsticksKeymapMissingKeys(l:map_specs)
    let l:missing_loc_maps = ChopsticksKeymapMissingKeys(l:loc_map_specs)
    return ChopsticksInfoSection('quickfix', {
        \ 'quickfix_count': len(getqflist()),
        \ 'loclist_count': len(getloclist(0)),
        \ 'quickfix_window': l:qf_window,
        \ 'location_window': l:loc_window,
        \ 'maps_ready': empty(l:missing_maps) && empty(l:missing_loc_maps),
        \ 'missing_maps': l:missing_maps,
        \ 'missing_loc_maps': l:missing_loc_maps,
        \ 'details': [
        \   ChopsticksInfoDetail('quickfix', len(getqflist()) . ' entries'),
        \   ChopsticksInfoDetail('loclist', len(getloclist(0)) . ' entries'),
        \   ChopsticksInfoDetail('maps',
        \       s:NavigationKey() . ' / ' . s:LocationNavigationKey()),
        \ ],
        \ 'items': [
        \   s:QuickfixWindowItem(l:qf_window),
        \   s:LocationWindowItem(l:loc_window),
        \   s:QuickfixNavigationItem(l:missing_maps),
        \   s:LocationNavigationItem(l:missing_loc_maps),
        \ ],
        \ })
endfunction
