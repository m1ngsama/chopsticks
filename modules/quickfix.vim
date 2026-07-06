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

function! s:FallbackNavigationKeys() abort
    return ['[q', ']q']
endfunction

function! s:NavigationSpecs() abort
    return ChopsticksKeymapContractSpecsOr('quickfix_navigation',
        \ s:FallbackNavigationSpecs())
endfunction

function! s:NavigationKey() abort
    return join(ChopsticksKeymapContractKeysOr('quickfix_navigation',
        \ s:FallbackNavigationKeys()), ' ')
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

augroup ChopstickQF
    autocmd!
    autocmd QuickFixCmdPost [^l]* cwindow
    autocmd QuickFixCmdPost l*    lwindow
augroup END

nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [q :cprev<CR>

function! ChopsticksQuickfixInfo() abort
    let l:qf_window = s:QfAutocmdExists('[^l]*')
    let l:loc_window = s:QfAutocmdExists('l*')
    let l:map_specs = s:NavigationSpecs()
    let l:missing_maps = ChopsticksKeymapMissingKeys(l:map_specs)
    return ChopsticksInfoSection('quickfix', {
        \ 'quickfix_count': len(getqflist()),
        \ 'loclist_count': len(getloclist(0)),
        \ 'quickfix_window': l:qf_window,
        \ 'location_window': l:loc_window,
        \ 'maps_ready': empty(l:missing_maps),
        \ 'missing_maps': l:missing_maps,
        \ 'details': [
        \   ChopsticksInfoDetail('quickfix', len(getqflist()) . ' entries'),
        \   ChopsticksInfoDetail('loclist', len(getloclist(0)) . ' entries'),
        \   ChopsticksInfoDetail('maps', s:NavigationKey()),
        \ ],
        \ 'items': [
        \   s:QuickfixWindowItem(l:qf_window),
        \   s:LocationWindowItem(l:loc_window),
        \   s:QuickfixNavigationItem(l:missing_maps),
        \ ],
        \ })
endfunction
