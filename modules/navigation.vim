" navigation.vim — FZF, netrw, windows, layout, terminal

" ── netrw (built-in file browser) ───────────────────────────────────────────

let g:netrw_liststyle    = 3
let g:netrw_banner       = 0
let g:netrw_browse_split = 4
let g:netrw_winsize      = 25
let g:netrw_altv         = 1
let g:netrw_list_hide    = '\(^\|\s\s\)\zs\.\S\+'
let g:netrw_list_hide   .= ',\.pyc$,node_modules,\.git,__pycache__,\.DS_Store'

function! s:ToggleSidebar(...) abort
    let l:dir = a:0 ? a:1 : getcwd()
    if getbufvar(winbufnr(1), '&filetype') ==# 'netrw' && getwinvar(1, '&winfixwidth')
        let l:cur = winnr()
        1wincmd w
        close
        if l:cur > 1
            execute (l:cur - 1) . 'wincmd w'
        endif
        return
    endif
    execute 'topleft vertical 30new'
    execute 'Explore ' . fnameescape(l:dir)
    setlocal winfixwidth
    setlocal bufhidden=wipe
    wincmd p
endfunction

function! s:NavigateWindow(direction) abort
    execute 'wincmd ' . a:direction
endfunction

function! s:TmuxNavigatorReady() abort
    return get(g:, 'chopsticks_enable_tmux_navigator', 0)
        \ && !empty($TMUX)
        \ && exists('g:loaded_tmux_navigator')
        \ && ChopsticksCommandAvailable('TmuxNavigateLeft')
endfunction

function! s:SpecKeys(specs) abort
    let l:keys = []
    for l:spec in a:specs
        call add(l:keys, get(l:spec, 'key', get(l:spec, 'lhs', '')))
    endfor
    return l:keys
endfunction

function! s:FallbackProjectSearchSpecs() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return [
            \ {'mode': 'n', 'lhs': '<Space><Space>', 'key': 'SPC SPC', 'text': 'SmartFiles'},
            \ {'mode': 'n', 'lhs': '<Space>/', 'key': 'SPC /', 'text': 'Rg'},
            \ {'mode': 'n', 'lhs': '<Space>sw', 'key': 'SPC sw', 'text': 'RgWord'},
            \ {'mode': 'n', 'lhs': '<Space>st', 'key': 'SPC st', 'text': 'Tags'},
            \ ]
    endif

    return [
        \ {'mode': 'n', 'lhs': ',ff', 'key': ',ff', 'text': 'SmartFiles'},
        \ {'mode': 'n', 'lhs': ',rg', 'key': ',rg', 'text': 'Rg'},
        \ {'mode': 'n', 'lhs': ',rG', 'key': ',rG', 'text': 'RgWord'},
        \ {'mode': 'n', 'lhs': ',rt', 'key': ',rt', 'text': 'Tags'},
        \ ]
endfunction

function! s:FallbackProjectSearchKeys() abort
    return s:SpecKeys(s:FallbackProjectSearchSpecs())
endfunction

function! s:ProjectSearchSpecs() abort
    return ChopsticksKeymapContractSpecsOr('project_search',
        \ s:FallbackProjectSearchSpecs())
endfunction

function! s:ProjectSearchReason() abort
    return join(ChopsticksKeymapContractKeysOr('project_search',
        \ s:FallbackProjectSearchKeys())[0:1], '/')
endfunction

function! s:FallbackSidebarSpecs() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return [
            \ {'mode': 'n', 'lhs': '<Space>e', 'key': 'SPC e', 'text': 'ToggleSidebar'},
            \ {'mode': 'n', 'lhs': '<Space>E', 'key': 'SPC E', 'text': 'ToggleSidebar'},
            \ ]
    endif

    return [
        \ {'mode': 'n', 'lhs': ',e', 'key': ',e', 'text': 'ToggleSidebar'},
        \ {'mode': 'n', 'lhs': ',E', 'key': ',E', 'text': 'ToggleSidebar'},
        \ ]
endfunction

function! s:FallbackSidebarKeys() abort
    return s:SpecKeys(s:FallbackSidebarSpecs())
endfunction

function! s:SidebarSpecs() abort
    return ChopsticksKeymapContractSpecsOr('file_sidebar',
        \ s:FallbackSidebarSpecs())
endfunction

function! s:SidebarReason() abort
    return join(ChopsticksKeymapContractKeysOr('file_sidebar',
        \ s:FallbackSidebarKeys()), '/')
endfunction

function! s:FallbackWindowNavigationSpecs(tmux_ready) abort
    if a:tmux_ready
        return [
            \ {'mode': 'n', 'lhs': '<C-h>', 'key': '<C-h>', 'text': 'TmuxNavigateLeft'},
            \ {'mode': 'n', 'lhs': '<C-j>', 'key': '<C-j>', 'text': 'TmuxNavigateDown'},
            \ {'mode': 'n', 'lhs': '<C-k>', 'key': '<C-k>', 'text': 'TmuxNavigateUp'},
            \ {'mode': 'n', 'lhs': '<C-l>', 'key': '<C-l>', 'text': 'TmuxNavigateRight'},
            \ ]
    endif

    return [
        \ {'mode': 'n', 'lhs': '<C-h>', 'key': '<C-h>', 'text': 'NavigateWindow'},
        \ {'mode': 'n', 'lhs': '<C-j>', 'key': '<C-j>', 'text': 'NavigateWindow'},
        \ {'mode': 'n', 'lhs': '<C-k>', 'key': '<C-k>', 'text': 'NavigateWindow'},
        \ {'mode': 'n', 'lhs': '<C-l>', 'key': '<C-l>', 'text': 'NavigateWindow'},
        \ ]
endfunction

function! s:WindowNavigationSpecs(tmux_ready) abort
    return ChopsticksKeymapContractSpecsOr('window_navigation',
        \ s:FallbackWindowNavigationSpecs(a:tmux_ready))
endfunction

function! s:FallbackWindowLayoutSpecs() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return [
            \ {'mode': 'n', 'lhs': '<Space>z', 'key': 'SPC z', 'text': 'ToggleMaximize'},
            \ ]
    endif

    return [
        \ {'mode': 'n', 'lhs': ',z', 'key': ',z', 'text': 'ToggleMaximize'},
        \ {'mode': 'n', 'lhs': ',=', 'key': ',=', 'text': 'resize'},
        \ {'mode': 'n', 'lhs': ',-', 'key': ',-', 'text': 'resize'},
        \ ]
endfunction

function! s:FallbackWindowLayoutKeys() abort
    return s:SpecKeys(s:FallbackWindowLayoutSpecs())
endfunction

function! s:WindowLayoutSpecs() abort
    return ChopsticksKeymapContractSpecsOr('window_layout',
        \ s:FallbackWindowLayoutSpecs())
endfunction

function! s:WindowLayoutReason() abort
    return join(ChopsticksKeymapContractKeysOr('window_layout',
        \ s:FallbackWindowLayoutKeys()), '/')
endfunction

function! s:WindowNavigationItem(adapter, missing) abort
    if empty(a:missing)
        return ChopsticksInfoItem('window navigation', 'ready', a:adapter,
            \ {'diagnostic': 0})
    endif

    let l:missing = join(a:missing, ', ')
    return ChopsticksInfoDiagnosticItem('window navigation', 'missing',
        \ 'missing: ' . l:missing, 'window navigation',
        \ ':ChopsticksKeymapAudit', {
        \   'detail': 'missing window navigation maps: ' . l:missing,
        \ })
endfunction

function! s:WindowLayoutItem(missing) abort
    if empty(a:missing)
        return ChopsticksInfoItem('window layout', 'ready',
            \ s:WindowLayoutReason(), {'diagnostic': 0})
    endif

    let l:missing = join(a:missing, ', ')
    return ChopsticksInfoDiagnosticItem('window layout', 'missing',
        \ 'missing: ' . l:missing, 'window layout',
        \ ':ChopsticksKeymapAudit', {
        \   'detail': 'missing window layout maps: ' . l:missing,
        \ })
endfunction

function! s:ProjectSearchItem(missing_maps, missing_commands, missing_tools) abort
    if empty(a:missing_maps) && empty(a:missing_commands) && empty(a:missing_tools)
        return ChopsticksInfoItem('project search', 'ready',
            \ s:ProjectSearchReason(), {'diagnostic': 0})
    endif

    let l:parts = []
    if !empty(a:missing_maps)
        call add(l:parts, 'maps: ' . join(a:missing_maps, ', '))
    endif
    if !empty(a:missing_commands)
        call add(l:parts, 'commands: ' . join(a:missing_commands, ', '))
    endif
    if !empty(a:missing_tools)
        call add(l:parts, 'tools: ' . join(a:missing_tools, ', '))
    endif
    let l:detail = 'missing project search ' . join(l:parts, '; ')
    return ChopsticksInfoDiagnosticItem('project search', 'missing',
        \ join(l:parts, '; '), 'project search',
        \ ':PlugInstall or ./install.sh --install-tools', {
        \ 'severity': 'setup',
        \ 'detail': l:detail,
        \ })
endfunction

function! s:SidebarItem(missing_maps, missing_commands) abort
    if empty(a:missing_maps) && empty(a:missing_commands)
        return ChopsticksInfoItem('file sidebar', 'ready', s:SidebarReason(),
            \ {'diagnostic': 0})
    endif

    let l:parts = []
    if !empty(a:missing_maps)
        call add(l:parts, 'maps: ' . join(a:missing_maps, ', '))
    endif
    if !empty(a:missing_commands)
        call add(l:parts, 'commands: ' . join(a:missing_commands, ', '))
    endif
    let l:detail = 'missing file sidebar ' . join(l:parts, '; ')
    return ChopsticksInfoDiagnosticItem('file sidebar', 'missing',
        \ join(l:parts, '; '), 'file sidebar',
        \ ':ChopsticksKeymapAudit', {
        \ 'detail': l:detail,
        \ })
endfunction

nnoremap <silent> <C-h> :<C-U>call <SID>NavigateWindow('h')<CR>
nnoremap <silent> <C-j> :<C-U>call <SID>NavigateWindow('j')<CR>
nnoremap <silent> <C-k> :<C-U>call <SID>NavigateWindow('k')<CR>
nnoremap <silent> <C-l> :<C-U>call <SID>NavigateWindow('l')<CR>

nnoremap <silent> <leader>e :call <SID>ToggleSidebar()<CR>
nnoremap <silent> <leader>E :call <SID>ToggleSidebar(expand('%:p:h'))<CR>

function! s:NetrwKeymaps() abort
    setlocal bufhidden=wipe
    nnoremap <buffer> <silent> <C-h> :<C-U>call <SID>NavigateWindow('h')<CR>
    nnoremap <buffer> <silent> <C-j> :<C-U>call <SID>NavigateWindow('j')<CR>
    nnoremap <buffer> <silent> <C-k> :<C-U>call <SID>NavigateWindow('k')<CR>
    nnoremap <buffer> <silent> <C-l> :<C-U>call <SID>NavigateWindow('l')<CR>
endfunction

augroup ChopstickNetrw
    autocmd!
    autocmd FileType netrw call s:NetrwKeymaps()
augroup END

" ── FZF ─────────────────────────────────────────────────────────────────────

function! s:SmartFiles() abort
    if isdirectory('.git') || finddir('.git', '.;') !=# ''
        GFiles
    else
        Files
    endif
endfunction

if ChopsticksPluginDeclared('fzf.vim')
    if g:chopsticks_space_keymaps
        nnoremap <leader><Space> :call <SID>SmartFiles()<CR>
        nnoremap <leader>, :Buffers<CR>
        nnoremap <leader>/ :Rg<CR>
        nnoremap <leader>ff :call <SID>SmartFiles()<CR>
        nnoremap <leader>fb :Buffers<CR>
        nnoremap <leader>fg :GFiles<CR>
        nnoremap <leader>fr :History<CR>
        nnoremap <leader>fl :BLines<CR>
        nnoremap <leader>fL :Lines<CR>
        nnoremap <leader>s/ :History/<CR>
        nnoremap <leader>s: :History:<CR>
        nnoremap <leader>sc :Commands<CR>
        nnoremap <leader>sm :Marks<CR>
        nnoremap <leader>sg :Rg<CR>
        nnoremap <leader>sw :RgWord<CR>
        nnoremap <leader>st :Tags<CR>
        nnoremap <leader>gC :Commits<CR>
        nnoremap <leader>gB :BCommits<CR>
    else
        nnoremap <leader>ff :call <SID>SmartFiles()<CR>
        nnoremap <leader>b  :Buffers<CR>
        nnoremap <leader>rg :Rg<CR>
        nnoremap <leader>rG :RgWord<CR>
        nnoremap <leader>rt :Tags<CR>
        nnoremap <leader>gF :GFiles<CR>
        nnoremap <leader>fh :History<CR>
        nnoremap <leader>fc :Commands<CR>
        nnoremap <leader>fm :Marks<CR>
        nnoremap <leader>fl :BLines<CR>
        nnoremap <leader>fL :Lines<CR>
        nnoremap <leader>f/ :History/<CR>
        nnoremap <leader>f: :History:<CR>
        nnoremap <leader>gC :Commits<CR>
        nnoremap <leader>gB :BCommits<CR>
    endif
endif

function! ChopsticksNavigationInfo() abort
    let l:tmux_ready = s:TmuxNavigatorReady()
    let l:search_specs = s:ProjectSearchSpecs()
    let l:sidebar_specs = s:SidebarSpecs()
    let l:window_specs = s:WindowNavigationSpecs(l:tmux_ready)
    let l:layout_specs = s:WindowLayoutSpecs()
    let l:missing_search_maps = ChopsticksKeymapMissingKeys(l:search_specs)
    let l:missing_sidebar_maps = ChopsticksKeymapMissingKeys(l:sidebar_specs)
    let l:missing_window_maps = ChopsticksKeymapMissingKeys(l:window_specs)
    let l:missing_layout_maps = ChopsticksKeymapMissingKeys(l:layout_specs)
    let l:missing_search_commands =
        \ ChopsticksMissingCommands(['Files', 'Buffers', 'GFiles', 'Rg', 'RgWord', 'Tags'])
    let l:missing_sidebar_commands = ChopsticksMissingCommands(['Explore'])
    let l:missing_search_tools = ChopsticksMissingTools(['fzf', 'rg'])
    let l:terminal_available = ChopsticksRuntimeFeatureAvailable('terminal')
    let l:terminal_maps = l:terminal_available
        \ && !empty(maparg('<C-h>', 't'))
        \ && !empty(maparg('<C-j>', 't'))
        \ && !empty(maparg('<C-k>', 't'))
        \ && !empty(maparg('<C-l>', 't'))
    let l:tmux_declared = ChopsticksPluginDeclared('vim-tmux-navigator')

    if l:tmux_ready
        let l:window_adapter = 'tmux navigator'
    else
        let l:window_adapter = 'vim splits'
    endif

    if !l:terminal_available
        let l:terminal_adapter = 'unavailable'
        let l:terminal_reason = 'Vim has no terminal feature'
    elseif l:tmux_ready && l:terminal_maps
        let l:terminal_adapter = 'tmux navigator'
        let l:terminal_reason = 'tmux navigator maps active'
    elseif get(g:, 'chopsticks_enable_terminal_keymaps', 0) && l:terminal_maps
        let l:terminal_adapter = 'vim terminal maps'
        let l:terminal_reason = 'terminal keymaps enabled'
    elseif get(g:, 'chopsticks_enable_terminal_keymaps', 0)
        let l:terminal_adapter = 'missing'
        let l:terminal_reason = 'terminal keymaps enabled but missing maps'
    else
        let l:terminal_adapter = 'off'
        let l:terminal_reason = 'disabled by default'
    endif

    if !get(g:, 'chopsticks_enable_tmux_navigator', 0)
        let l:tmux_reason = 'disabled by default'
    elseif empty($TMUX)
        let l:tmux_reason = 'not inside tmux'
    elseif !l:tmux_declared
        let l:tmux_reason = 'plugin not declared'
    elseif !exists('g:loaded_tmux_navigator')
        let l:tmux_reason = 'plugin not loaded yet'
    elseif !l:tmux_ready
        let l:tmux_reason = 'commands missing'
    else
        let l:tmux_reason = 'loaded'
    endif

    let l:terminal_state =
        \ l:terminal_adapter ==# 'missing'
        \ ? 'missing'
        \ : (l:terminal_adapter ==# 'off'
        \     || l:terminal_adapter ==# 'unavailable'
        \     ? 'off'
        \     : 'ready')
    let l:terminal_item_reason = l:terminal_state ==# 'ready'
        \ ? l:terminal_adapter
        \ : l:terminal_reason
    let l:tmux_state = l:tmux_ready ? 'ready' : 'off'
    let l:tmux_diagnostic = get(g:, 'chopsticks_enable_tmux_navigator', 0)
        \ && !empty($TMUX)
        \ && !l:tmux_ready
    if l:terminal_adapter ==# 'missing'
        let l:terminal_item = ChopsticksInfoDiagnosticItem(
            \ 'terminal navigation', l:terminal_state,
            \ l:terminal_item_reason, 'terminal navigation',
            \ 'review g:chopsticks_enable_terminal_keymaps', {
            \   'detail': l:terminal_reason,
            \ })
    else
        let l:terminal_item = ChopsticksInfoItem('terminal navigation',
            \ l:terminal_state, l:terminal_item_reason, {
            \   'diagnostic': 0,
            \   'severity': 'attention',
            \   'issue_label': 'terminal navigation',
            \   'detail': l:terminal_reason,
            \   'action': 'review g:chopsticks_enable_terminal_keymaps',
            \ })
    endif
    if l:tmux_diagnostic
        let l:tmux_item = ChopsticksInfoDiagnosticItem('tmux navigator',
            \ l:tmux_state, l:tmux_reason, 'tmux navigator',
            \ ':PlugInstall and restart Vim', {
            \   'severity': 'setup',
            \   'detail': l:tmux_reason,
            \ })
    else
        let l:tmux_item = ChopsticksInfoItem('tmux navigator',
            \ l:tmux_state, l:tmux_reason, {
            \   'diagnostic': 0,
            \   'severity': 'setup',
            \   'issue_label': 'tmux navigator',
            \   'detail': l:tmux_reason,
            \   'action': ':PlugInstall and restart Vim',
            \ })
    endif
    let l:items = [
        \ s:ProjectSearchItem(l:missing_search_maps,
        \     l:missing_search_commands, l:missing_search_tools),
        \ s:SidebarItem(l:missing_sidebar_maps, l:missing_sidebar_commands),
        \ s:WindowNavigationItem(l:window_adapter, l:missing_window_maps),
        \ s:WindowLayoutItem(l:missing_layout_maps),
        \ l:terminal_item,
        \ l:tmux_item,
        \ ]

    return ChopsticksInfoSection('navigation', {
        \ 'window_adapter': l:window_adapter,
        \ 'search_maps': s:SpecKeys(l:search_specs),
        \ 'missing_search_maps': l:missing_search_maps,
        \ 'missing_search_commands': l:missing_search_commands,
        \ 'missing_search_tools': l:missing_search_tools,
        \ 'sidebar_maps': s:SpecKeys(l:sidebar_specs),
        \ 'missing_sidebar_maps': l:missing_sidebar_maps,
        \ 'missing_sidebar_commands': l:missing_sidebar_commands,
        \ 'window_maps': s:SpecKeys(l:window_specs),
        \ 'missing_window_maps': l:missing_window_maps,
        \ 'window_layout_maps': s:SpecKeys(l:layout_specs),
        \ 'missing_layout_maps': l:missing_layout_maps,
        \ 'items': l:items,
        \ 'terminal_available': l:terminal_available,
        \ 'terminal_keymaps_enabled': get(g:, 'chopsticks_enable_terminal_keymaps', 0),
        \ 'terminal_maps': l:terminal_maps,
        \ 'terminal_adapter': l:terminal_adapter,
        \ 'terminal_reason': l:terminal_reason,
        \ 'tmux_env': !empty($TMUX),
        \ 'tmux_opt_in': get(g:, 'chopsticks_enable_tmux_navigator', 0),
        \ 'tmux_declared': l:tmux_declared,
        \ 'tmux_loaded': exists('g:loaded_tmux_navigator'),
        \ 'tmux_ready': l:tmux_ready,
        \ 'tmux_reason': l:tmux_reason,
        \ })
endfunction

let g:fzf_layout = { 'down': '40%' }

if g:is_tty
    let g:fzf_preview_window = []
else
    let g:fzf_preview_window = ['right:50%', 'ctrl-/']
endif

function! s:Preview() abort
    return g:is_tty ? {} : fzf#vim#with_preview()
endfunction

command! -bang -nargs=* Rg
    \ call fzf#vim#grep(
    \   'rg --column --line-number --no-heading --color=always --smart-case -- '
    \   .shellescape(<q-args>), 1, s:Preview(), <bang>0)
command! -bang -nargs=* RgWord
    \ call fzf#vim#grep(
    \   'rg --column --line-number --no-heading --color=always --smart-case -F -- '
    \   .shellescape(expand('<cword>')), 1, s:Preview(), <bang>0)
command! -bang -nargs=? GFiles call fzf#vim#gitfiles(<q-args>, s:Preview(), <bang>0)

" ── Window Maximize Toggle ──────────────────────────────────────────────────

function! s:ToggleMaximize() abort
    if exists('t:maximize_session')
        execute t:maximize_session
        unlet t:maximize_session
        echo 'Window: restored'
    else
        let t:maximize_session = winrestcmd()
        resize | vertical resize
        echo 'Window: MAXIMIZED'
    endif
endfunction
if g:chopsticks_space_keymaps
    nnoremap <silent> <leader>z :call <SID>ToggleMaximize()<CR>
else
    nnoremap <silent> <leader>z :call <SID>ToggleMaximize()<CR>
    nnoremap <silent> <Leader>= :exe "resize " . (winheight(0) * 3/2)<CR>
    nnoremap <silent> <Leader>- :exe "resize " . (winheight(0) * 2/3)<CR>
endif

" ── Terminal ────────────────────────────────────────────────────────────────

if ChopsticksRuntimeFeatureAvailable('terminal')
    if g:chopsticks_space_keymaps
        nnoremap <leader>tt :terminal<CR>
        nnoremap <leader>th :terminal ++rows=10<CR>
    else
        nnoremap <leader>tv :terminal<CR>
        nnoremap <leader>th :terminal ++rows=10<CR>
    endif
    if g:chopsticks_enable_terminal_keymaps
        tnoremap <Esc><Esc> <C-\><C-n>
        tnoremap <C-h> <C-\><C-n>:<C-U>call <SID>NavigateWindow('h')<CR>
        tnoremap <C-j> <C-\><C-n>:<C-U>call <SID>NavigateWindow('j')<CR>
        tnoremap <C-k> <C-\><C-n>:<C-U>call <SID>NavigateWindow('k')<CR>
        tnoremap <C-l> <C-\><C-n>:<C-U>call <SID>NavigateWindow('l')<CR>
    endif
endif
