" buffers.vim — buffer lifecycle commands and keymaps

function! s:BufferDisplay(buf) abort
    let l:name = bufname(a:buf)
    return empty(l:name) ? '[No Name]' : fnamemodify(l:name, ':~:.')
endfunction

function! s:ListedBufferCount() abort
    return len(filter(range(1, bufnr('$')), 'buflisted(v:val)'))
endfunction

function! s:AlternateBufferNumber() abort
    let l:buf = bufnr('#')
    return l:buf > 0 && buflisted(l:buf) ? l:buf : -1
endfunction

function! s:AlternateDisplay() abort
    let l:buf = s:AlternateBufferNumber()
    return l:buf < 0 ? 'none' : '#' . l:buf . ' ' . s:BufferDisplay(l:buf)
endfunction

function! s:FallbackKeySpecs() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return {
            \ 'close': {'lhs': '<Space>bd', 'key': 'SPC bd', 'text': 'Bclose'},
            \ 'close_all': {'lhs': '<Space>ba', 'key': 'SPC ba',
            \   'text': 'BcloseAll'},
            \ 'close_others': {'lhs': '<Space>bo', 'key': 'SPC bo',
            \   'text': 'BcloseOthers'},
            \ 'next': {'lhs': '<Space>bn', 'key': 'SPC bn', 'text': 'bnext'},
            \ 'previous': {'lhs': '<Space>bp', 'key': 'SPC bp', 'text': 'bprevious'},
            \ 'alternate': {'lhs': '<Space><Tab>', 'key': 'SPC Tab', 'text': 'Balternate'},
            \ }
    endif
    return {
        \ 'close': {'lhs': ',bd', 'key': ',bd', 'text': 'Bclose'},
        \ 'close_all': {'lhs': ',ba', 'key': ',ba', 'text': 'BcloseAll'},
        \ 'close_others': {'lhs': ',bo', 'key': ',bo', 'text': 'BcloseOthers'},
        \ 'next': {'lhs': ',l', 'key': ',l', 'text': 'bnext'},
        \ 'previous': {'lhs': ',h', 'key': ',h', 'text': 'bprevious'},
        \ 'alternate': {'lhs': ',,', 'key': ',,', 'text': 'Balternate'},
        \ }
endfunction

function! s:KeySpecs() abort
    let l:fallback = s:FallbackKeySpecs()
    let l:navigation = ChopsticksKeymapContractSpecsOr('buffer_navigation',
        \ [l:fallback.next, l:fallback.previous])
    return {
        \ 'close': ChopsticksKeymapContractFirstSpecOr('buffer_close',
        \   l:fallback.close),
        \ 'close_all': ChopsticksKeymapContractFirstSpecOr('buffer_close_all',
        \   l:fallback.close_all),
        \ 'close_others': ChopsticksKeymapContractFirstSpecOr(
        \   'buffer_close_others', l:fallback.close_others),
        \ 'next': get(l:navigation, 0, l:fallback.next),
        \ 'previous': get(l:navigation, 1, l:fallback.previous),
        \ 'alternate': ChopsticksKeymapContractFirstSpecOr('buffer_alternate',
        \   l:fallback.alternate),
        \ }
endfunction

function! s:BufferCommandItem(label, command, spec) abort
    let l:command = ':' . a:command
    let l:command_ready = ChopsticksCommandAvailable(a:command)
    let l:map_ready = ChopsticksKeymapSpecReady(a:spec)
    if l:command_ready && l:map_ready
        return ChopsticksInfoItem(a:label, 'ready',
            \ get(a:spec, 'key', l:command), {'diagnostic': 0})
    endif
    let l:reason = l:command_ready
        \ ? 'missing ' . get(a:spec, 'key', a:label . ' map')
        \ : 'missing ' . l:command
    return ChopsticksInfoDiagnosticItem(a:label, 'missing', l:reason,
        \ a:label, l:command_ready ? ':ChopsticksKeymapAudit' : 'reload chopsticks', {
        \ 'detail': l:reason,
        \ })
endfunction

function! s:BufferCloseItem(spec) abort
    let l:command_ready = ChopsticksCommandAvailable('Bclose')
    let l:map_ready = ChopsticksKeymapSpecReady(a:spec)
    if l:command_ready && l:map_ready
        return ChopsticksInfoItem('buffer close', 'ready', ':Bclose',
            \ {'diagnostic': 0})
    endif
    let l:reason = l:command_ready
        \ ? 'missing ' . get(a:spec, 'key', 'buffer close map')
        \ : 'missing :Bclose'
    return ChopsticksInfoDiagnosticItem('buffer close', 'missing',
        \ l:reason, 'buffer close',
        \ l:command_ready ? ':ChopsticksKeymapAudit' : 'reload chopsticks', {
        \ 'detail': l:reason,
        \ })
endfunction

function! s:BufferNavigationItem(specs) abort
    let l:missing = ChopsticksKeymapMissingKeys(a:specs)
    let l:reason = empty(l:missing)
        \ ? get(a:specs[0], 'key', 'next') . '/'
        \     . get(a:specs[1], 'key', 'previous')
        \ : 'missing: ' . join(l:missing, ', ')
    if empty(l:missing)
        return ChopsticksInfoItem('buffer navigation', 'ready', l:reason,
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('buffer navigation', 'missing',
        \ l:reason, 'buffer navigation', ':ChopsticksKeymapAudit', {
        \ 'detail': 'missing buffer navigation maps: ' . join(l:missing, ', '),
        \ })
endfunction

function! s:AlternateBufferItem(spec) abort
    let l:command_ready = ChopsticksCommandAvailable('Balternate')
    let l:map_ready = ChopsticksKeymapSpecReady(a:spec)
    if l:command_ready && l:map_ready
        return ChopsticksInfoItem('alternate buffer', 'ready',
            \ get(a:spec, 'key', 'alternate'), {'diagnostic': 0})
    endif
    let l:reason = l:command_ready
        \ ? 'missing ' . get(a:spec, 'key', 'alternate map')
        \ : 'missing :Balternate'
    return ChopsticksInfoDiagnosticItem('alternate buffer', 'missing',
        \ l:reason, 'alternate buffer',
        \ l:command_ready ? ':ChopsticksKeymapAudit' : 'reload chopsticks', {
        \ 'detail': l:reason,
        \ })
endfunction

function! s:Warn(message) abort
    echohl WarningMsg
    echom a:message
    echohl None
endfunction

function! s:ListedBuffers() abort
    return filter(range(1, bufnr('$')), 'buflisted(v:val)')
endfunction

function! s:ModifiedBuffers(buffers) abort
    return filter(copy(a:buffers), 'getbufvar(v:val, "&modified")')
endfunction

function! s:BufferListDisplay(buffers) abort
    return join(map(copy(a:buffers), 's:BufferDisplay(v:val)'), ', ')
endfunction

command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
    let l:currentBufNum   = bufnr("%")
    let l:alternateBufNum = bufnr("#")
    if getbufvar(l:currentBufNum, '&modified')
        call s:Warn('Bclose: buffer has unsaved changes; write it or use :bdelete! explicitly')
        return
    endif
    if buflisted(l:alternateBufNum)
        buffer #
    else
        bnext
    endif
    if bufnr("%") == l:currentBufNum
        new
    endif
    if buflisted(l:currentBufNum)
        execute 'bdelete ' . l:currentBufNum
    endif
endfunction

command! Balternate call <SID>AlternateBuffer()
function! <SID>AlternateBuffer() abort
    if buflisted(bufnr('#'))
        buffer #
        return
    endif
    call s:Warn('Balternate: no listed alternate buffer')
endfunction

command! BcloseOthers call <SID>CloseOtherBuffers()
function! <SID>CloseOtherBuffers() abort
    let l:current = bufnr('%')
    let l:targets = filter(s:ListedBuffers(), 'v:val != l:current')
    let l:modified = s:ModifiedBuffers(l:targets)
    if !empty(l:modified)
        call s:Warn('BcloseOthers: unsaved buffers: '
            \ . s:BufferListDisplay(l:modified))
        return
    endif
    for l:buf in l:targets
        if buflisted(l:buf)
            execute 'bdelete ' . l:buf
        endif
    endfor
endfunction

command! BcloseAll call <SID>CloseAllBuffers()
function! <SID>CloseAllBuffers() abort
    let l:targets = s:ListedBuffers()
    let l:modified = s:ModifiedBuffers(l:targets)
    if !empty(l:modified)
        call s:Warn('BcloseAll: unsaved buffers: '
            \ . s:BufferListDisplay(l:modified))
        return
    endif
    for l:buf in l:targets
        if buflisted(l:buf)
            execute 'bdelete ' . l:buf
        endif
    endfor
    if empty(s:ListedBuffers())
        enew
    endif
endfunction

if g:chopsticks_space_keymaps
    nnoremap <leader>bd :Bclose<cr>
    nnoremap <leader>ba :BcloseAll<cr>
    nnoremap <leader>bo :BcloseOthers<cr>
    nnoremap <leader>bn :bnext<cr>
    nnoremap <leader>bp :bprevious<cr>
    nnoremap <leader><Tab> :Balternate<cr>
else
    nnoremap <leader>bd :Bclose<cr>
    nnoremap <leader>ba :BcloseAll<cr>
    nnoremap <leader>bo :BcloseOthers<cr>
    nnoremap <leader>l  :bnext<cr>
    nnoremap <leader>h  :bprevious<cr>
    nnoremap <leader><leader> :Balternate<cr>
endif

function! ChopsticksBufferInfo() abort
    let l:keys = s:KeySpecs()
    let l:navigation_specs = [l:keys.next, l:keys.previous]
    return ChopsticksInfoSection('buffers', {
        \ 'listed_count': s:ListedBufferCount(),
        \ 'current_buffer': bufnr('%'),
        \ 'alternate_buffer': s:AlternateBufferNumber(),
        \ 'details': [
        \   ChopsticksInfoDetail('listed', s:ListedBufferCount() . ' buffers'),
        \   ChopsticksInfoDetail('current', s:BufferDisplay(bufnr('%'))),
        \   ChopsticksInfoDetail('alternate', s:AlternateDisplay()),
        \ ],
        \ 'items': [
        \   s:BufferCloseItem(l:keys.close),
        \   s:BufferCommandItem('close all buffers', 'BcloseAll',
        \       l:keys.close_all),
        \   s:BufferCommandItem('close other buffers', 'BcloseOthers',
        \       l:keys.close_others),
        \   s:BufferNavigationItem(l:navigation_specs),
        \   s:AlternateBufferItem(l:keys.alternate),
        \ ],
        \ })
endfunction
