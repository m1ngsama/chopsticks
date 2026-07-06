" utilities.vim — config, reload, clipboard, and opt-in shell helpers

function! s:SpecKeys(specs) abort
    let l:keys = []
    for l:spec in a:specs
        call add(l:keys, get(l:spec, 'key', get(l:spec, 'lhs', '')))
    endfor
    return l:keys
endfunction

function! s:FallbackConfigSpecs() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return [
            \ {'mode': 'n', 'lhs': '<Space>fc', 'key': 'SPC fc', 'text': 'ChopsticksConfig'},
            \ {'mode': 'n', 'lhs': '<Space>fv', 'key': 'SPC fv', 'text': '$MYVIMRC'},
            \ {'mode': 'n', 'lhs': '<Space>fV', 'key': 'SPC fV', 'text': 'ChopsticksReload'},
            \ ]
    endif

    return [
        \ {'mode': 'n', 'lhs': ',ec', 'key': ',ec', 'text': 'ChopsticksConfig'},
        \ {'mode': 'n', 'lhs': ',ev', 'key': ',ev', 'text': '$MYVIMRC'},
        \ {'mode': 'n', 'lhs': ',sv', 'key': ',sv', 'text': 'ChopsticksReload'},
        \ ]
endfunction

function! s:FallbackConfigKeys() abort
    return get(g:, 'chopsticks_space_keymaps', 1)
        \ ? ['SPC fc', 'SPC fv', 'SPC fV']
        \ : [',ec', ',ev', ',sv']
endfunction

function! s:FallbackPathCopySpecs() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return [
            \ {'mode': 'n', 'lhs': '<Space>fp', 'key': 'SPC fp', 'text': 'expand("%:p")'},
            \ {'mode': 'n', 'lhs': '<Space>fn', 'key': 'SPC fn', 'text': 'expand("%:t")'},
            \ ]
    endif

    return [
        \ {'mode': 'n', 'lhs': ',cp', 'key': ',cp', 'text': 'expand("%:p")'},
        \ {'mode': 'n', 'lhs': ',cf', 'key': ',cf', 'text': 'expand("%:t")'},
        \ ]
endfunction

function! s:FallbackPathCopyKeys() abort
    return get(g:, 'chopsticks_space_keymaps', 1)
        \ ? ['SPC fp', 'SPC fn']
        \ : [',cp', ',cf']
endfunction

function! s:ConfigSpecs() abort
    return ChopsticksKeymapContractSpecsOr('utility_config',
        \ s:FallbackConfigSpecs())
endfunction

function! s:ConfigReason() abort
    return join(ChopsticksKeymapContractKeysOr('utility_config',
        \ s:FallbackConfigKeys()), '/')
endfunction

function! s:PathCopySpecs() abort
    return ChopsticksKeymapContractSpecsOr('utility_path_copy',
        \ s:FallbackPathCopySpecs())
endfunction

function! s:PathCopyReason() abort
    return join(ChopsticksKeymapContractKeysOr('utility_path_copy',
        \ s:FallbackPathCopyKeys()), '/')
endfunction

function! s:ConfigActionsItem(missing_maps, missing_commands) abort
    if empty(a:missing_maps) && empty(a:missing_commands)
        return ChopsticksInfoItem('config actions', 'ready', s:ConfigReason(),
            \ {'diagnostic': 0})
    endif

    let l:parts = []
    if !empty(a:missing_maps)
        call add(l:parts, 'maps: ' . join(a:missing_maps, ', '))
    endif
    if !empty(a:missing_commands)
        call add(l:parts, 'commands: ' . join(a:missing_commands, ', '))
    endif
    let l:detail = 'missing config actions ' . join(l:parts, '; ')
    return ChopsticksInfoDiagnosticItem('config actions', 'missing',
        \ join(l:parts, '; '), 'config actions',
        \ ':ChopsticksKeymapAudit', {'detail': l:detail})
endfunction

function! s:PathCopyItem(missing_maps) abort
    if !ChopsticksRuntimeFeatureAvailable('clipboard')
        return ChopsticksInfoItem('path copy', 'off',
            \ 'Vim has no clipboard feature', {'diagnostic': 0})
    endif
    if empty(a:missing_maps)
        return ChopsticksInfoItem('path copy', 'ready', s:PathCopyReason(),
            \ {'diagnostic': 0})
    endif

    let l:detail = 'missing path copy maps: ' . join(a:missing_maps, ', ')
    return ChopsticksInfoDiagnosticItem('path copy', 'missing',
        \ 'missing: ' . join(a:missing_maps, ', '), 'path copy',
        \ ':ChopsticksKeymapAudit', {'detail': l:detail})
endfunction

function! s:SaveAllItem() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return ChopsticksInfoItem('classic save all', 'off',
            \ 'space layout uses SPC W', {'diagnostic': 0})
    endif
    if ChopsticksKeymapSpecReady({'mode': 'n', 'lhs': ',wa', 'text': ':wa'})
        return ChopsticksInfoItem('classic save all', 'ready', ',wa',
            \ {'diagnostic': 0})
    endif

    return ChopsticksInfoDiagnosticItem('classic save all', 'missing',
        \ 'missing: ,wa', 'classic save all',
        \ ':ChopsticksKeymapAudit', {
        \ 'detail': 'missing classic save-all map: ,wa',
        \ })
endfunction

function! s:SudoSaveItem() abort
    if !get(g:, 'chopsticks_enable_sudo_save_bang', 0)
        return ChopsticksInfoItem('sudo save', 'off', 'disabled by default',
            \ {'diagnostic': 0})
    endif
    if ChopsticksKeymapSpecReady({'mode': 'c', 'lhs': 'w!!',
        \ 'text': 'sudo tee'})
        return ChopsticksInfoItem('sudo save', 'ready', 'w!!',
            \ {'diagnostic': 0})
    endif

    return ChopsticksInfoDiagnosticItem('sudo save', 'missing',
        \ 'missing: w!!', 'sudo save', ':ChopsticksKeymapAudit', {
        \ 'detail': 'missing sudo-save command-line map: w!!',
        \ })
endfunction

function! s:LocalConfigPath() abort
    if exists('*ChopsticksLocalConfigInfo')
        return ChopsticksLocalConfigInfo().path
    endif
    let l:xdg = !empty($XDG_CONFIG_HOME) && $XDG_CONFIG_HOME =~# '^/'
        \ ? $XDG_CONFIG_HOME
        \ : '~/.config'
    return expand(get(g:, 'chopsticks_resolved_local_config',
        \ get(g:, 'chopsticks_local_config', l:xdg . '/chopsticks.vim')))
endfunction

function! s:EditLocalConfig() abort
    let l:path = s:LocalConfigPath()
    call ChopsticksOpenManagedFile(l:path, {
        \ 'filetype': 'vim',
        \ 'buffer_seed_lines': [
        \   '" chopsticks local preferences',
        \   "let g:chopsticks_profile = 'engineer'",
        \   "let g:chopsticks_keymap_style = 'space'",
        \   '',
        \   '" Optional habits:',
        \   '" let g:chopsticks_enable_jk_escape = 1',
        \   '" let g:chopsticks_enable_ctrl_s_save = 1',
        \   '" let g:chopsticks_enable_auto_pairs = 1',
        \   '" let g:chopsticks_enable_input_method = 1',
        \ ],
        \ 'mark_unmodified': 1,
        \ })
endfunction

function! s:ReloadChopsticks() abort
    unlet! g:chopsticks_loaded
    execute 'source ' . fnameescape($MYVIMRC)
    echo 'chopsticks reloaded'
endfunction

command! ChopsticksConfig call s:EditLocalConfig()
command! ChopsticksReload call s:ReloadChopsticks()

if !g:chopsticks_space_keymaps
    nnoremap <leader>wa :wa<CR>
endif

if g:chopsticks_space_keymaps
    nnoremap <leader>fc :ChopsticksConfig<CR>
    nnoremap <leader>fv :edit $MYVIMRC<CR>
    nnoremap <leader>fV :ChopsticksReload<CR>
else
    nnoremap <leader>ec :ChopsticksConfig<CR>
    nnoremap <leader>ev :edit $MYVIMRC<CR>
    nnoremap <leader>sv :ChopsticksReload<CR>
endif

if ChopsticksRuntimeFeatureAvailable('clipboard')
    if g:chopsticks_space_keymaps
        nnoremap <leader>fp :let @+ = expand("%:p")<CR>:echo "Copied: " . expand("%:p")<CR>
        nnoremap <leader>fn :let @+ = expand("%:t")<CR>:echo "Copied: " . expand("%:t")<CR>
    else
        nnoremap <leader>cp :let @+ = expand("%:p")<CR>:echo "Copied: " . expand("%:p")<CR>
        nnoremap <leader>cf :let @+ = expand("%:t")<CR>:echo "Copied: " . expand("%:t")<CR>
    endif
endif

if get(g:, 'chopsticks_enable_sudo_save_bang', 0)
    cnoremap w!! w !sudo tee > /dev/null %
endif

function! ChopsticksUtilityInfo() abort
    let l:config_specs = s:ConfigSpecs()
    let l:path_specs = s:PathCopySpecs()
    let l:config_missing = ChopsticksKeymapMissingKeys(l:config_specs)
    let l:clipboard_available = ChopsticksRuntimeFeatureAvailable('clipboard')
    let l:path_missing = l:clipboard_available
        \ ? ChopsticksKeymapMissingKeys(l:path_specs)
        \ : []
    let l:command_missing =
        \ ChopsticksMissingCommands(['ChopsticksConfig', 'ChopsticksReload'])

    return ChopsticksInfoSection('utilities', {
        \ 'details': [
        \   ChopsticksInfoDetail('config', s:ConfigReason()),
        \   ChopsticksInfoDetail('path', l:clipboard_available
        \       ? s:PathCopyReason()
        \       : 'clipboard unavailable'),
        \   ChopsticksInfoDetail('sudo',
        \       get(g:, 'chopsticks_enable_sudo_save_bang', 0)
        \       ? 'w!!'
        \       : 'disabled'),
        \ ],
        \ 'config_maps': s:SpecKeys(l:config_specs),
        \ 'missing_config_maps': l:config_missing,
        \ 'missing_commands': l:command_missing,
        \ 'path_copy_maps': s:SpecKeys(l:path_specs),
        \ 'missing_path_copy_maps': l:path_missing,
        \ 'clipboard_available': l:clipboard_available,
        \ 'sudo_save_enabled': get(g:, 'chopsticks_enable_sudo_save_bang', 0),
        \ 'items': [
        \   s:ConfigActionsItem(l:config_missing, l:command_missing),
        \   s:PathCopyItem(l:path_missing),
        \   s:SaveAllItem(),
        \   s:SudoSaveItem(),
        \ ],
        \ })
endfunction
