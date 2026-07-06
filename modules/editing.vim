" editing.vim — EasyMotion, undo history, and editing assist maps

function! s:SpaceLayout() abort
    return get(g:, 'chopsticks_space_keymaps', 1)
endfunction

function! s:FallbackVisibleJumpSpecs() abort
    if s:SpaceLayout()
        return [
            \ {'mode': 'n', 'lhs': 's', 'key': 's',
            \  'text': 'easymotion-overwin-f2'},
            \ {'mode': 'n', 'lhs': '<Space>S', 'key': 'SPC S',
            \  'text': 'easymotion-overwin-f2'},
            \ ]
    endif
    return [
        \ {'mode': 'n', 'lhs': ',S', 'key': ',S',
        \  'text': 'easymotion-overwin-f2'},
        \ {'mode': 'n', 'lhs': ',j', 'key': ',j',
        \  'text': 'easymotion-j'},
        \ {'mode': 'n', 'lhs': ',k', 'key': ',k',
        \  'text': 'easymotion-k'},
        \ ]
endfunction

function! s:FallbackVisibleJumpKeys() abort
    return s:SpaceLayout() ? ['s', 'SPC S'] : [',S']
endfunction

function! s:VisibleJumpSpecs() abort
    return ChopsticksKeymapContractSpecsOr('visible_jump',
        \ s:FallbackVisibleJumpSpecs())
endfunction

function! s:VisibleJumpKey() abort
    return join(ChopsticksKeymapContractKeysOr('visible_jump_summary',
        \ s:FallbackVisibleJumpKeys()), ' / ')
endfunction

function! s:FallbackUndoSpec() abort
    return s:SpaceLayout()
        \ ? {'mode': 'n', 'lhs': '<Space>U', 'key': 'SPC U',
        \     'text': 'UndotreeToggle'}
        \ : {'mode': 'n', 'lhs': ',u', 'key': ',u',
        \     'text': 'UndotreeToggle'}
endfunction

function! s:UndoSpec() abort
    return ChopsticksKeymapContractFirstSpecOr('undo_tree',
        \ s:FallbackUndoSpec())
endfunction

function! s:UndoKey() abort
    return get(s:UndoSpec(), 'key', s:SpaceLayout() ? 'SPC U' : ',u')
endfunction

function! s:UndoLhs() abort
    return get(s:UndoSpec(), 'lhs', s:SpaceLayout() ? '<Space>U' : ',u')
endfunction

function! s:FallbackCleanupSpecs() abort
    if s:SpaceLayout()
        return [
            \ {'mode': 'n', 'lhs': '<Space>cW', 'key': 'SPC cW',
            \  'text': '%s/\s\+$'},
            \ {'mode': 'v', 'lhs': '<Space>cW', 'key': 'v SPC cW',
            \  'text': 's/\s\+$'},
            \ {'mode': 'n', 'lhs': '<Space>sr', 'key': 'SPC sr',
            \  'text': '%s/\<'},
            \ {'mode': 'v', 'lhs': '<Space>sr', 'key': 'v SPC sr',
            \  'text': 's///g'},
            \ {'mode': 'v', 'lhs': '<Space>=', 'key': 'v SPC =',
            \  'text': '='},
            \ ]
    endif
    return [
        \ {'mode': 'n', 'lhs': ',W', 'key': ',W',
        \  'text': '%s/\s\+$'},
        \ {'mode': 'v', 'lhs': ',W', 'key': 'v ,W',
        \  'text': 's/\s\+$'},
        \ {'mode': 'n', 'lhs': ',*', 'key': ',*',
        \  'text': '%s/\<'},
        \ {'mode': 'v', 'lhs': ',*', 'key': 'v ,*',
        \  'text': 's///g'},
        \ {'mode': 'v', 'lhs': ',F', 'key': 'v ,F',
        \  'text': '='},
        \ ]
endfunction

function! s:FallbackCleanupKeys() abort
    return s:SpaceLayout() ? ['SPC cW', 'SPC sr', 'SPC ='] : [',W', ',*', ',F']
endfunction

function! s:CleanupSpecs() abort
    return ChopsticksKeymapContractSpecsOr('edit_cleanup',
        \ s:FallbackCleanupSpecs())
endfunction

function! s:CleanupKey() abort
    return join(ChopsticksKeymapContractKeysOr('edit_cleanup_summary',
        \ s:FallbackCleanupKeys()), '/')
endfunction

function! s:FallbackReindentSpec() abort
    return s:SpaceLayout()
        \ ? {'mode': 'n', 'lhs': '<Space>c=', 'key': 'SPC c=', 'text': 'gg=G'}
        \ : {'mode': 'n', 'lhs': ',F', 'key': ',F', 'text': 'gg=G'}
endfunction

function! s:ReindentSpec() abort
    return ChopsticksKeymapContractFirstSpecOr('full_file_reindent',
        \ s:FallbackReindentSpec())
endfunction

function! s:FallbackBlankLineSpecs() abort
    return [
        \ {'mode': 'n', 'lhs': '[<Space>', 'key': '[<Space>',
        \  'text': 'repeat(nr2char(10)'},
        \ {'mode': 'n', 'lhs': ']<Space>', 'key': ']<Space>',
        \  'text': 'repeat(nr2char(10)'},
        \ ]
endfunction

function! s:FallbackBlankLineKeys() abort
    return ['[<Space>', ']<Space>']
endfunction

function! s:BlankLineSpecs() abort
    return ChopsticksKeymapContractSpecsOr('blank_lines',
        \ s:FallbackBlankLineSpecs())
endfunction

function! s:BlankLineKey() abort
    return join(ChopsticksKeymapContractKeysOr('blank_lines',
        \ s:FallbackBlankLineKeys()), ' ')
endfunction

function! s:VisibleJumpItem() abort
    let l:declared = ChopsticksPluginDeclared('vim-easymotion')
    let l:installed = ChopsticksPluginInstalled('vim-easymotion')
    let l:missing = ChopsticksKeymapMissingKeys(s:VisibleJumpSpecs())
    if l:declared && l:installed && empty(l:missing)
        return ChopsticksInfoItem('visible jump', 'ready', s:VisibleJumpKey(),
            \ {'diagnostic': 0})
    endif
    let l:reason = !l:declared
        \ ? 'vim-easymotion not declared'
        \ : (!l:installed
        \     ? 'vim-easymotion not installed'
        \     : 'missing: ' . join(l:missing, ', '))
    return ChopsticksInfoDiagnosticItem('visible jump', 'missing',
        \ l:reason, 'visible jump',
        \ (!l:declared || !l:installed)
        \     ? ':PlugInstall and restart Vim'
        \     : ':ChopsticksKeymapAudit', {
        \ 'severity': (!l:declared || !l:installed) ? 'setup' : 'attention',
        \ 'detail': l:reason,
        \ })
endfunction

function! s:UndoTreeItem() abort
    if !get(g:, 'chopsticks_enable_ui_extras', 1)
        return ChopsticksInfoItem('undo tree', 'off',
            \ 'UI extras disabled by profile', {'diagnostic': 0})
    endif

    if ChopsticksPluginInstalled('undotree')
        \ && ChopsticksKeymapSpecReady(s:UndoSpec())
        return ChopsticksInfoItem('undo tree', 'ready', s:UndoKey(),
            \ {'diagnostic': 0})
    endif
    let l:reason = ChopsticksPluginDeclared('undotree')
        \ ? 'undotree not installed'
        \ : 'undotree not declared'
    if ChopsticksPluginInstalled('undotree')
        let l:reason = 'missing ' . s:UndoKey()
    endif
    return ChopsticksInfoDiagnosticItem('undo tree', 'missing',
        \ l:reason, 'undo tree', ':PlugInstall and restart Vim', {
        \ 'severity': 'setup',
        \ 'detail': l:reason,
        \ })
endfunction

function! s:EditCleanupItem() abort
    let l:missing = ChopsticksKeymapMissingKeys(s:CleanupSpecs())
    if empty(l:missing)
        return ChopsticksInfoItem('edit cleanup', 'ready', s:CleanupKey(),
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('edit cleanup', 'missing',
        \ 'missing: ' . join(l:missing, ', '), 'edit cleanup maps',
        \ ':ChopsticksKeymapAudit', {
        \ 'detail': 'missing edit cleanup maps: ' . join(l:missing, ', '),
        \ })
endfunction

function! s:BlankLinesItem() abort
    let l:missing = ChopsticksKeymapMissingKeys(s:BlankLineSpecs())
    if empty(l:missing)
        return ChopsticksInfoItem('blank lines', 'ready', s:BlankLineKey(),
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('blank lines', 'missing',
        \ 'missing: ' . join(l:missing, ', '), 'blank line maps',
        \ ':ChopsticksKeymapAudit', {
        \ 'detail': 'missing blank-line insertion maps: ' . join(l:missing, ', '),
        \ })
endfunction

function! s:FullFileReindentItem() abort
    if !get(g:, 'chopsticks_enable_reindent_file', 0)
        return ChopsticksInfoItem('full-file reindent', 'off',
            \ 'disabled by default', {'diagnostic': 0})
    endif

    let l:spec = s:ReindentSpec()
    if ChopsticksKeymapSpecReady(l:spec)
        return ChopsticksInfoItem('full-file reindent', 'ready',
            \ get(l:spec, 'key', 'reindent'), {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('full-file reindent', 'missing',
        \ 'missing ' . get(l:spec, 'key', 'reindent'), 'full-file reindent',
        \ 'review g:chopsticks_enable_reindent_file', {
        \ 'detail': 'full-file reindent is enabled but the map is missing',
        \ })
endfunction

" ── EasyMotion ──────────────────────────────────────────────────────────────

let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase  = 1

if ChopsticksPluginDeclared('vim-easymotion')
    if g:chopsticks_space_keymaps
        " In the canonical layout, cl/cc cover native s/S substitute behavior;
        " s becomes the fastest screen-local jump entry.
        nmap s <Plug>(easymotion-overwin-f2)
        nmap <Leader>S <Plug>(easymotion-overwin-f2)
    else
        nmap <Leader>S <Plug>(easymotion-overwin-f2)
        nmap <Leader>j <Plug>(easymotion-j)
        nmap <Leader>k <Plug>(easymotion-k)
    endif
endif

" ── UndoTree ────────────────────────────────────────────────────────────────

if ChopsticksPluginDeclared('undotree')
    nnoremap <F5>       :UndotreeToggle<CR>
    if g:chopsticks_space_keymaps
        nnoremap <leader>U  :UndotreeToggle<CR>
    else
        nnoremap <leader>u  :UndotreeToggle<CR>
    endif
endif

" ── Yank Highlight ──────────────────────────────────────────────────────────

if exists('##TextYankPost') && ChopsticksRuntimeFeatureAvailable('timers')
    function! s:YankHighlight() abort
        if v:event.operator !=# 'y' | return | endif
        let l:m = matchadd('IncSearch',
            \ printf('\%%>%dl\%%<%dl', line("'[") - 1, line("']") + 1))
        call timer_start(150, {-> execute('silent! call matchdelete(' . l:m . ')')})
    endfunction
    augroup ChopstickYankHL
        autocmd!
        autocmd TextYankPost * call s:YankHighlight()
    augroup END
endif

" ── Blank Line Insertion (replaces vim-unimpaired) ──────────────────────────

nnoremap <silent> [<Space> :<C-u>put! =repeat(nr2char(10), v:count1)<CR>'[
nnoremap <silent> ]<Space> :<C-u>put  =repeat(nr2char(10), v:count1)<CR>

" ── Editing Assist ─────────────────────────────────────────────────────────

if get(g:, 'chopsticks_enable_reindent_file', 0)
    if g:chopsticks_space_keymaps
        nnoremap <leader>c= gg=G``
    else
        nnoremap <leader>F gg=G``
    endif
endif

if g:chopsticks_space_keymaps
    vnoremap <leader>= =
    nnoremap <leader>cW :%s/\s\+$//<CR>:let @/=''<CR>
    vnoremap <leader>cW :s/\s\+$//<CR>:let @/=''<CR>gv
    nnoremap <leader>sr :%s/\<<C-r><C-w>\>//g<Left><Left>
    vnoremap <leader>sr :s///g<Left><Left><Left>
else
    vnoremap <leader>F =
    nnoremap <leader>W :%s/\s\+$//<CR>:let @/=''<CR>
    vnoremap <leader>W :s/\s\+$//<CR>:let @/=''<CR>gv
    nnoremap <leader>* :%s/\<<C-r><C-w>\>//g<Left><Left>
    vnoremap <leader>* :s///g<Left><Left><Left>
endif

" ── Auto-Clear Search Highlight ─────────────────────────────────────────────

augroup ChopstickSearchHL
    autocmd!
    autocmd CursorHold * if get(v:, 'hlsearch', 0) | let v:hlsearch = 0 | endif
augroup END

" ── Overlength Highlight (only chars past textwidth, not the whole column) ─

function! s:OverLengthApply() abort
    if exists('w:overlength_match')
        silent! call matchdelete(w:overlength_match)
        unlet w:overlength_match
    endif
    if &textwidth <= 0 || &buftype !=# '' | return | endif
    let w:overlength_match = matchadd('OverLength', '\%>' . &textwidth . 'v.\+', -1)
endfunction

function! s:OverLengthDefineHL() abort
    hi default OverLength ctermbg=52 ctermfg=NONE guibg=#3a1f1f guifg=NONE
endfunction

augroup ChopstickOverLength
    autocmd!
    autocmd ColorScheme    * call s:OverLengthDefineHL()
    autocmd OptionSet      textwidth call s:OverLengthApply()
    autocmd BufWinEnter,WinEnter,FileType * call s:OverLengthApply()
augroup END
call s:OverLengthDefineHL()

function! ChopsticksEditingInfo() abort
    return ChopsticksInfoSection('editing', {
        \ 'layout': s:SpaceLayout() ? 'space' : 'classic',
        \ 'full_file_reindent': get(g:, 'chopsticks_enable_reindent_file', 0),
        \ 'details': [
        \   ChopsticksInfoDetail('jump', s:VisibleJumpKey()),
        \   ChopsticksInfoDetail('cleanup', s:CleanupKey()),
        \   ChopsticksInfoDetail('indent',
        \       s:SpaceLayout() ? 'visual SPC =' : 'visual ,F'),
        \ ],
        \ 'items': [
        \   s:VisibleJumpItem(),
        \   s:UndoTreeItem(),
        \   s:EditCleanupItem(),
        \   s:BlankLinesItem(),
        \   s:FullFileReindentItem(),
        \ ],
        \ })
endfunction
