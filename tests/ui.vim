scriptencoding utf-8

let s:startup_errmsg = v:errmsg
" v:errmsg carries the message without a location, which is the half that
" matters when one platform raises an error no other does. The message history
" keeps whatever was reported around it.
let s:startup_messages = execute('messages')
set nomore

let s:case = $CHOPSTICKS_TEST_CASE
let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'cd ' . fnameescape(s:root)

function! s:AssertPublicInterface() abort
    if !empty(s:startup_errmsg)
        call assert_report('startup error: ' . s:startup_errmsg . ' | messages: '
            \ . substitute(trim(s:startup_messages), '\n', ' // ', 'g'))
    endif
    call assert_equal(2, exists(':ChopsticksUiDensity'))
    call assert_equal(2, exists(':ChopsticksTransparencyToggle'))
    call assert_equal(2, exists(':ChopsticksDashboard'))
    call assert_equal(2, exists(':ChopsticksSessionSave'))
    call assert_equal(2, exists(':ChopsticksSessionLoad'))
    call assert_equal(2, exists(':ChopsticksProjectGrep'))
    call assert_true(exists('*ChopsticksUiDensity'))
    call assert_true(exists('*ChopsticksSystemClipboardEnabled'))
    call assert_true(exists('*ChopsticksTransparencyEnabled'))
    call assert_true(exists('*ChopsticksDashboardEnabled'))
    call assert_true(exists('*ChopsticksStatusline'))
    call assert_true(exists('*ChopsticksTabline'))
    call assert_true(exists('*ChopsticksSessionPath'))
    call assert_equal(type(''), type(g:chopsticks_data_dir))
    call assert_match('[/\\]$', g:chopsticks_data_dir)
    call assert_equal(g:chopsticks_data_dir,
        \ simplify(fnamemodify(g:chopsticks_data_dir, ':p')))
    call assert_equal(1, strwidth(ChopsticksIcon('info')))
    call assert_match('^\%(minimal\|balanced\|rich\)$',
        \ ChopsticksUiDensity())
    call assert_equal('%!ChopsticksStatusline()', &statusline)
    call assert_equal('%!ChopsticksTabline()', &tabline)
    call assert_false(&exrc)
    call assert_false(&modeline)
endfunction

function! s:NormalBufferCount() abort
    let l:count = 0
    for l:buffer in getbufinfo({'buflisted': 1})
        if getbufvar(l:buffer.bufnr, '&buftype') ==# ''
            let l:count += 1
        endif
    endfor
    return l:count
endfunction

function! s:EditOneBuffer() abort
    silent edit README.md
    for l:buffer in getbufinfo({'buflisted': 1})
        if l:buffer.bufnr != bufnr('')
            \ && getbufvar(l:buffer.bufnr, '&buftype') ==# ''
            execute 'silent! bwipeout! ' . l:buffer.bufnr
        endif
    endfor
    call assert_equal(1, s:NormalBufferCount())
endfunction

function! s:AssertBufferline(one_buffer, two_buffers) abort
    call s:EditOneBuffer()
    call assert_equal(a:one_buffer, &showtabline)
    if a:one_buffer == 2
        call assert_match('README\.md', ChopsticksTabline())
    endif
    silent edit package.json
    call assert_equal(2, s:NormalBufferCount())
    call assert_equal(a:two_buffers, &showtabline)
    if a:two_buffers == 2
        call assert_match('README\.md', ChopsticksTabline())
        call assert_match('package\.json', ChopsticksTabline())
    endif
    execute 'silent! bwipeout! ' . bufnr('')
    call assert_equal(1, s:NormalBufferCount())
    call assert_equal(a:one_buffer, &showtabline)
endfunction

function! s:AssertAutomaticDashboard(expected) abort
    silent enew
    let v:errmsg = ''
    doautocmd VimEnter
    call assert_equal('', v:errmsg)
    call assert_equal(a:expected, ChopsticksDashboardEnabled())
    call assert_equal(a:expected ? 'chopsticks-dashboard' : '', &filetype)
endfunction

function! s:AssertDashboardLayout() abort
    call s:EditOneBuffer()
    let l:showtabline = &showtabline
    let l:laststatus = &laststatus
    set lines=20
    let v:errmsg = ''
    ChopsticksDashboard
    call assert_equal('', v:errmsg)
    let l:lines = getline(1, '$')
    let l:text = join(l:lines, "\n")
    let l:widths = map(copy(l:lines), 'strwidth(v:val)')
    let l:window_width = winwidth(0)
    call assert_equal('chopsticks-dashboard', &filetype)
    call assert_equal('nofile', &buftype)
    call assert_false(buflisted(bufnr('')))
    call assert_false(&modifiable)
    call assert_false(&modified)
    call assert_equal(0, &showtabline)
    call assert_equal(0, &laststatus)
    call assert_match('CHOPSTICKS', l:text)
    call assert_match('\[f\]', l:text)
    call assert_equal('f', strpart(getline('.'), col('.') - 1, 1))
    call assert_equal(1,
        \ len(filter(copy(l:lines), 'v:val =~# "Find File"')))
    call assert_equal(1,
        \ len(filter(copy(l:lines), 'v:val =~# "Quit"')))
    call assert_true(empty(l:widths) || max(l:widths) <= l:window_width)
    call assert_match('\S', getline('.'))
    silent edit README.md
    call assert_equal(l:showtabline, &showtabline)
    call assert_equal(l:laststatus, &laststatus)

    " A real split changes winwidth() in Ex mode; changing 'columns' does not.
    vnew
    vertical resize 12
    let v:errmsg = ''
    ChopsticksDashboard
    let l:narrow_lines = getline(1, '$')
    let l:narrow_widths = map(copy(l:narrow_lines), 'strwidth(v:val)')
    call assert_equal('', v:errmsg)
    call assert_true(max(l:narrow_widths) <= winwidth(0))
    call assert_match('CHOPSTICKS', join(l:narrow_lines, "\n"))
    close!

    vnew
    vertical resize 1
    ChopsticksDashboard
    let l:item_line = line('.')
    let l:description_column = get(
        \ b:chopsticks_dashboard_desc_cols, string(l:item_line), 0)
    call assert_equal(l:description_column, col('.'))
    doautocmd CursorMoved
    call assert_equal(l:description_column, col('.'))
    call assert_true(max(map(getline(1, '$'), 'strwidth(v:val)'))
        \ <= winwidth(0))
    close!
endfunction

function! s:AssertWideDashboardLogo() abort
    let l:expected = [
        \ '███╗   ███╗ ██╗███╗   ██╗ ██████╗ ███████╗ █████╗ ███╗   ███╗ █████╗',
        \ '████╗ ████║███║████╗  ██║██╔════╝ ██╔════╝██╔══██╗████╗ ████║██╔══██╗',
        \ '██╔████╔██║╚██║██╔██╗ ██║██║  ███╗███████╗███████║██╔████╔██║███████║',
        \ '██║╚██╔╝██║ ██║██║╚██╗██║██║   ██║╚════██║██╔══██║██║╚██╔╝██║██╔══██║',
        \ '██║ ╚═╝ ██║ ██║██║ ╚████║╚██████╔╝███████║██║  ██║██║ ╚═╝ ██║██║  ██║',
        \ '╚═╝     ╚═╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝',
        \ ]
    set columns=140 lines=40
    ChopsticksDashboard
    let l:actual = filter(getline(1, '$'), 'v:val =~# ''[█╚]''')
    call assert_equal(l:expected,
        \ map(copy(l:actual), 'substitute(v:val, ''^ *'', '''', '''')'))
    let l:starts = map(copy(l:actual),
        \ 'strlen(matchstr(v:val, ''^ *''))')
    call assert_equal(repeat([l:starts[0]], len(l:starts)), l:starts)
    call assert_true(max(map(getline(1, '$'), 'strwidth(v:val)'))
        \ <= winwidth(0))
endfunction

function! s:AssertDensityCycle() abort
    let l:initial = ChopsticksUiDensity()
    let l:seen = {}
    let l:seen[l:initial] = 1
    for l:index in range(1, 3)
        silent ChopsticksUiDensity
        let l:seen[ChopsticksUiDensity()] = 1
    endfor
    call assert_equal(3, len(l:seen))
    call assert_equal(l:initial, ChopsticksUiDensity())
endfunction

function! s:AssertStatuslineDensity() abort
    call s:EditOneBuffer()
    set columns=160
    let l:lines = {}
    for l:density in ['minimal', 'balanced', 'rich']
        execute 'silent ChopsticksUiDensity ' . l:density
        call assert_equal(l:density, ChopsticksUiDensity())
        call assert_equal(2, &laststatus)
        let l:lines[l:density] = ChopsticksStatusline()
        call assert_match('%f', l:lines[l:density])
        call assert_match('%l:%c', l:lines[l:density])
        call assert_match('%#ChopStatus\w\+#', l:lines[l:density])
        call assert_notmatch("[\r\n]", l:lines[l:density])
    endfor
    call assert_notmatch('%P', l:lines.minimal)
    call assert_match('%P', l:lines.balanced)
    call assert_match('%P', l:lines.rich)
    call assert_notmatch('%y', l:lines.minimal)
    call assert_true(strlen(l:lines.minimal) < strlen(l:lines.rich))
    " Ex mode has a fixed 80-column window, so rich deliberately contracts to
    " balanced; full rich status content requires a screen above 109 columns.
    call assert_equal(l:lines.balanced, l:lines.rich)
    let l:writing = ChopsticksWritingMode()
    call assert_true(empty(l:writing)
        \ || stridx(l:lines.balanced, l:writing) >= 0)
endfunction

function! s:AssertStatuslineContext() abort
    silent ChopsticksUiDensity rich
    call s:EditOneBuffer()
    setlocal modified readonly spell
    let l:other_window = win_getid()
    silent belowright split package.json
    let l:active_window = win_getid()
    setlocal nomodified noreadonly nospell

    let g:statusline_winid = l:other_window
    let l:other_line = ChopsticksStatusline()
    call assert_match('^%#ChopStatusMuted# - ', l:other_line)
    call assert_match(' + ', l:other_line)
    call assert_match('RO', l:other_line)
    call assert_match('SPELL', l:other_line)

    let g:statusline_winid = l:active_window
    let l:active_line = ChopsticksStatusline()
    call assert_notmatch('^%#ChopStatusMuted# - ', l:active_line)
    call assert_notmatch('RO', l:active_line)
    call assert_notmatch('SPELL', l:active_line)
    unlet g:statusline_winid
    only
endfunction

function! s:VisibleTabline(line) abort
    let l:line = substitute(a:line, '%#[^#]*#', '', 'g')
    let l:line = substitute(l:line, '%=', '', 'g')
    return substitute(l:line, '%%', '%', 'g')
endfunction

function! s:AssertTablineWidth() abort
    silent ChopsticksUiDensity rich
    call s:EditOneBuffer()
    for l:index in range(1, 20)
        execute 'badd ' . fnameescape(printf(
            \ 'test-buffer-%02d-with-a-long-name.txt', l:index))
    endfor
    set columns=12
    let l:visible = s:VisibleTabline(ChopsticksTabline())
    call assert_true(strwidth(l:visible) <= &columns)
endfunction

function! s:NormalizedDirectory(path) abort
    let l:directory = simplify(fnamemodify(expand(a:path), ':p'))
    return l:directory =~# '[/\\]$' ? l:directory : l:directory . '/'
endfunction

function! s:DefaultDataDirectory() abort
    return s:NormalizedDirectory(has('win32') || has('win64')
        \ ? '~/vimfiles' : '~/.vim')
endfunction

function! s:AssertDataDirectory(expected, session_is_derived) abort
    let l:expected = s:NormalizedDirectory(a:expected)
    call assert_equal(l:expected, g:chopsticks_data_dir)
    call assert_equal(l:expected . '.backup//', &backupdir)
    call assert_equal(l:expected . '.swap//', &directory)
    call assert_equal(l:expected . '.view', &viewdir)
    if has('persistent_undo')
        call assert_equal(l:expected . '.undo', &undodir)
    endif
    for l:directory in [
        \ l:expected . '.backup',
        \ l:expected . '.swap',
        \ l:expected . '.undo',
        \ l:expected . '.view',
        \ ]
        call assert_true(isdirectory(l:directory), l:directory)
    endfor
    if a:session_is_derived
        call assert_equal(l:expected . '.sessions/',
            \ g:chopsticks_session_dir)
        call assert_true(isdirectory(g:chopsticks_session_dir))
    endif
endfunction

function! s:AssertCustomDataDirectory() abort
    call s:AssertDataDirectory($CHOPSTICKS_TEST_DATA_DIR, 1)
    call assert_equal('loaded-from-data-dir',
        \ get(g:, 'chopsticks_test_local_config', ''))
    call assert_equal(g:chopsticks_data_dir . 'plugged',
        \ get(g:, 'chopsticks_test_plug_directory', ''))
    call assert_true(get(g:, 'chopsticks_test_plugin_count', 0) > 0)
endfunction

function! s:AssertExplicitPathOverrides() abort
    call s:AssertDataDirectory($CHOPSTICKS_TEST_DATA_DIR, 0)
    call assert_equal('loaded-from-explicit-path',
        \ get(g:, 'chopsticks_test_local_config', ''))
    call assert_equal(s:NormalizedDirectory(
        \ $CHOPSTICKS_TEST_SESSION_DIR), g:chopsticks_session_dir)
endfunction

function! s:AssertPathContainment() abort
    let l:definition = execute('function /PathInside')
    let l:name = matchstr(l:definition, '<SNR>\d\+_PathInside')
    call assert_false(empty(l:name))
    if empty(l:name)
        return
    endif
    let l:PathInside = function(l:name)
    let l:inside = s:root . '/README.md'
    let l:outside = fnamemodify(s:root, ':h')
        \ . '/chopsticks-sibling/README.md'
    call assert_true(call(l:PathInside, [l:inside, s:root]))
    call assert_true(call(l:PathInside, [s:root, s:root . '/']))
    call assert_false(call(l:PathInside, [l:outside, s:root]))
    if has('win32') || has('win64')
        let l:windows_inside = substitute(toupper(l:inside), '/', '\\', 'g')
        let l:windows_root = substitute(tolower(s:root), '/', '\\', 'g')
        call assert_true(call(l:PathInside,
            \ [l:windows_inside, l:windows_root]))
    else
        call assert_false(call(l:PathInside,
            \ [toupper(l:inside), s:root]))
    endif
endfunction

function! s:AssertProjectRootSpecialCharacters() abort
    let l:definition = execute('function /ProjectRoot')
    let l:name = matchstr(l:definition, '<SNR>\d\+_ProjectRoot')
    call assert_false(empty(l:name))
    if empty(l:name)
        return
    endif
    let l:ProjectRoot = function(l:name)
    let l:test_root = tempname() . '-project,with;markers'
    let l:nested = l:test_root . '/nested'
    let l:previous_directory = getcwd()
    call mkdir(l:test_root . '/.git', 'p')
    call mkdir(l:nested, 'p')
    try
        execute 'silent edit ' . fnameescape(l:nested . '/note.md')
        call assert_equal(fnamemodify(l:test_root, ':p'),
            \ call(l:ProjectRoot, []))
    finally
        silent! bwipeout!
        execute 'lcd ' . fnameescape(l:previous_directory)
        call delete(l:test_root, 'rf')
    endtry
endfunction

function! s:AssertProjectCommandsStayRooted() abort
    let l:definition = execute('function /ProjectFzfSpec')
    let l:name = matchstr(l:definition, '<SNR>\d\+_ProjectFzfSpec')
    call assert_false(empty(l:name))
    if empty(l:name)
        return
    endif
    let l:ProjectFzfSpec = function(l:name)
    let l:outside = tempname() . '-outside-project'
    let l:previous = getcwd()
    call mkdir(l:outside, 'p')
    try
        execute 'silent edit ' . fnameescape(s:root . '/README.md')
        execute 'cd ' . fnameescape(l:outside)
        call assert_equal(0, haslocaldir())
        let l:spec = call(l:ProjectFzfSpec, [])
        call assert_equal(fnamemodify(s:root, ':p'),
            \ fnamemodify(l:spec.dir, ':p'))
        call assert_equal(fnamemodify(l:outside, ':p'),
            \ fnamemodify(getcwd(), ':p'))
        call assert_equal(0, haslocaldir())
    finally
        execute 'cd ' . fnameescape(l:previous)
        call delete(l:outside, 'rf')
    endtry
endfunction

function! s:AssertStartupTimeIsStable() abort
    call assert_equal(1, argc())
    call assert_equal('README.md', fnamemodify(bufname(''), ':t'))
    doautocmd VimEnter
    call assert_true(exists('g:chopsticks_startup_ms'))
    if !exists('g:chopsticks_startup_ms')
        return
    endif
    call assert_true(g:chopsticks_startup_ms >= 0)
    let l:startup_ms = g:chopsticks_startup_ms
    execute 'source ' . fnameescape(s:root . '/.vimrc')
    call assert_equal(l:startup_ms, g:chopsticks_startup_ms)
    ChopsticksDashboard
    call assert_equal(l:startup_ms, g:chopsticks_startup_ms)
endfunction

function! s:AssertFzfFallback() abort
    call assert_notequal(1, executable('fzf'))
    call assert_equal(2, exists(':Files'))
    call assert_equal(2, exists(':History'))
    call assert_equal(2, exists(':Rg'))
    call assert_equal('', maparg(';f', 'n'))
    call assert_equal('', maparg(';r', 'n'))
    call assert_match('\[--\]\s\+fzf\s\+optional / missing',
        \ join(ChopsticksHealthLines(), "\n"))

    ChopsticksDashboard
    call assert_notmatch('Find Text', join(getline(1, '$'), "\n"))
    call assert_notmatch('fzf command executed',
        \ execute('ChopsticksRecentFiles'))
    call assert_notmatch('fzf command executed',
        \ execute('ChopsticksFindFiles'))
endfunction

function! s:AssertSession() abort
    call assert_false(&sessionoptions =~# '\<\%(curdir\|terminal\)\>')
    let l:expected_directory = fnamemodify(
        \ expand('~/.chopsticks-session-tests'), ':p')
    call assert_equal(l:expected_directory, g:chopsticks_session_dir)

    " Session names must distinguish equal project basenames.  Otherwise two
    " unrelated checkouts such as work/app and personal/app overwrite each
    " other's layout.
    let l:had_project_root = exists('b:chopsticks_project_root')
    let l:saved_project_root = get(b:, 'chopsticks_project_root', '')
    let b:chopsticks_project_root = g:chopsticks_data_dir
        \ . 'session-root-one/shared-name'
    let l:first_project_path = ChopsticksSessionPath()
    let b:chopsticks_project_root = g:chopsticks_data_dir
        \ . 'session-root-two/shared-name'
    let l:second_project_path = ChopsticksSessionPath()
    call assert_notequal(l:first_project_path, l:second_project_path)
    call assert_match('shared-name-[0-9a-f]\{16}-vim'
        \ . v:version . '\.vim$', l:first_project_path)
    if l:had_project_root
        let b:chopsticks_project_root = l:saved_project_root
    else
        unlet b:chopsticks_project_root
    endif

    call s:EditOneBuffer()
    silent rightbelow vsplit package.json
    call assert_equal(2, winnr('$'))
    let l:layout_kind = winlayout()[0]
    let l:path = ChopsticksSessionPath()
    call assert_match('-[0-9a-f]\{16}-vim'
        \ . v:version . '\.vim$', l:path)
    let v:errmsg = ''
    silent ChopsticksSessionSave
    call assert_equal('', v:errmsg)
    call assert_true(filereadable(l:path))
    if exists('*getfperm') && !has('win32') && !has('win64')
        call assert_equal('rwx------', getfperm(g:chopsticks_session_dir))
        call assert_equal('rw-------', getfperm(l:path))

        " Loading is a source operation, so a group/world-writable session is
        " executable input and must be rejected before it can change layout.
        call setfperm(l:path, 'rw-rw-rw-')
        let l:window_count = winnr('$')
        let l:refusal = execute('ChopsticksSessionLoad')
        call assert_match('refusing a session writable by other users',
            \ l:refusal)
        call assert_equal(l:window_count, winnr('$'))
        call setfperm(l:path, 'rw-------')
    endif

    " Never follow or overwrite a pre-created predictable temporary path.
    let l:temporary = l:path . '.tmp-' . getpid()
    call writefile(['do not overwrite'], l:temporary)
    call assert_match('refusing an existing session temporary path',
        \ execute('ChopsticksSessionSave'))
    call assert_equal(['do not overwrite'], readfile(l:temporary))
    call delete(l:temporary)

    " A readable directory is not executable session input. This guard is
    " platform-independent and remains active for a forced load.
    let l:regular_session = l:path . '.regular'
    call assert_equal(0, rename(l:path, l:regular_session))
    call assert_equal(1, mkdir(l:path))
    let l:window_count = winnr('$')
    call assert_match('refusing a non-regular session file',
        \ execute('ChopsticksSessionLoad!'))
    call assert_equal(l:window_count, winnr('$'))
    call assert_equal(0, delete(l:path, 'd'))
    call assert_equal(0, rename(l:regular_session, l:path))

    ChopsticksDashboard
    call assert_equal(l:path, ChopsticksSessionPath())
    call assert_match('open a project buffer before saving a session',
        \ execute('ChopsticksSessionSave'))
    silent edit package.json
    call assert_equal(l:path, ChopsticksSessionPath())
    only
    silent enew
    call setline(1, 'unsaved session-load guard')
    setlocal modified
    let l:modified_buffer = bufnr('')
    let l:modified_layout = winlayout()
    let l:refusal = execute('ChopsticksSessionLoad')
    call assert_match('refusing to restore with 1 modified listed buffer',
        \ l:refusal)
    call assert_equal(l:modified_buffer, bufnr(''))
    call assert_equal(l:modified_layout, winlayout())
    call assert_equal('unsaved session-load guard', getline(1))
    call assert_true(&modified)
    let v:errmsg = ''
    silent ChopsticksSessionLoad!
    call assert_equal('', v:errmsg)
    call assert_false(exists('g:SessionLoad'))
    call assert_equal(2, winnr('$'))
    call assert_equal(l:layout_kind, winlayout()[0])
    let l:names = map(getwininfo(),
        \ 'fnamemodify(bufname(v:val.bufnr), ":t")')
    call assert_true(index(l:names, 'README.md') >= 0)
    call assert_true(index(l:names, 'package.json') >= 0)
endfunction

function! s:IsTransparent(group) abort
    let l:id = hlID(a:group)
    let l:gui = synIDattr(l:id, 'bg', 'gui')
    let l:cterm = synIDattr(l:id, 'bg', 'cterm')
    return (empty(l:gui) || l:gui ==# 'NONE')
        \ && (empty(l:cterm) || l:cterm ==# 'NONE')
endfunction

function! s:AssertTransparencyToggle(initial) abort
    call assert_equal(a:initial, ChopsticksTransparencyEnabled())
    call assert_equal(a:initial, s:IsTransparent('Normal'))
    silent ChopsticksTransparencyToggle
    call assert_equal(!a:initial, ChopsticksTransparencyEnabled())
    call assert_equal(!a:initial, s:IsTransparent('Normal'))
    silent ChopsticksTransparencyToggle
    call assert_equal(a:initial, ChopsticksTransparencyEnabled())
    call assert_equal(a:initial, s:IsTransparent('Normal'))
endfunction

function! s:AssertConfigurationFallbacks() abort
    let l:saved_density = g:chopsticks_ui_density
    let l:saved_transparency = g:chopsticks_transparent_background
    let l:saved_dashboard = g:chopsticks_dashboard
    let l:saved_bufferline = g:chopsticks_bufferline
    try
        " Public helpers should remain total when a local config contains the
        " wrong type, and invalid commands must leave the last valid choice in
        " place.
        let g:chopsticks_ui_density = []
        let g:chopsticks_transparent_background = []
        let g:chopsticks_dashboard = []
        let g:chopsticks_bufferline = []
        call assert_equal('balanced', ChopsticksUiDensity())
        call assert_false(ChopsticksTransparencyEnabled())
        call assert_true(ChopsticksDashboardEnabled())

        let g:chopsticks_ui_density = 'rich'
        silent ChopsticksUiDensity unsupported
        call assert_equal('rich', ChopsticksUiDensity())

        for l:value in [0, '0', 'off', 'false', 'no']
            let g:chopsticks_transparent_background = l:value
            call assert_false(ChopsticksTransparencyEnabled())
        endfor
        for l:value in [1, '1', 'on', 'true', 'yes']
            let g:chopsticks_transparent_background = l:value
            call assert_true(ChopsticksTransparencyEnabled())
        endfor
    finally
        let g:chopsticks_ui_density = l:saved_density
        let g:chopsticks_transparent_background = l:saved_transparency
        let g:chopsticks_dashboard = l:saved_dashboard
        let g:chopsticks_bufferline = l:saved_bufferline
    endtry
endfunction

function! s:RunCase() abort
    call s:AssertPublicInterface()
    if s:case ==# 'default'
        call s:AssertDataDirectory(s:DefaultDataDirectory(), 1)
        call s:AssertPathContainment()
        call s:AssertProjectRootSpecialCharacters()
        call s:AssertProjectCommandsStayRooted()
        call assert_equal('balanced', g:chopsticks_ui_density)
        call assert_equal('auto', g:chopsticks_transparent_background)
        call assert_equal('auto', g:chopsticks_dashboard)
        call assert_equal('auto', g:chopsticks_bufferline)
        call assert_equal('auto', g:chopsticks_system_clipboard)
        call assert_equal('everforest', g:chopsticks_colorscheme)
        let l:desktop_clipboard = has('clipboard')
            \ && (has('macunix') || has('win32') || has('win64')
            \     || !empty($DISPLAY) || !empty($WAYLAND_DISPLAY))
        call assert_equal(l:desktop_clipboard,
            \ ChopsticksSystemClipboardEnabled())
        call assert_false(ChopsticksTransparencyEnabled())
        call s:AssertConfigurationFallbacks()
        call s:AssertAutomaticDashboard(1)
        command! Rg echo
        ChopsticksDashboard
        let l:dashboard = join(getline(1, '$'), "\n")
        if executable('rg') == 1 && executable('fzf') == 1
            call assert_match('Find Text', l:dashboard)
        else
            call assert_notmatch('Find Text', l:dashboard)
        endif
        call s:AssertBufferline(0, 2)
        call s:AssertDashboardLayout()
        call s:AssertDensityCycle()
    elseif s:case ==# 'minimal'
        call assert_equal('minimal', ChopsticksUiDensity())
        call s:AssertAutomaticDashboard(0)
        command! Rg echo
        ChopsticksDashboard
        call assert_notmatch('Find Text', join(getline(1, '$'), "\n"))
        call assert_notmatch('Restore Session', join(getline(1, '$'), "\n"))
        call s:AssertBufferline(0, 0)
    elseif s:case ==# 'rich'
        call assert_equal('rich', ChopsticksUiDensity())
        call s:AssertAutomaticDashboard(1)
        command! Rg echo
        ChopsticksDashboard
        let l:dashboard = join(getline(1, '$'), "\n")
        if executable('rg') == 1 && executable('fzf') == 1
            call assert_match('Find Text', l:dashboard)
        else
            call assert_notmatch('Find Text', l:dashboard)
        endif
        call s:AssertBufferline(2, 2)
    elseif s:case ==# 'density'
        call s:AssertStatuslineDensity()
    elseif s:case ==# 'status-context'
        call s:AssertStatuslineContext()
    elseif s:case ==# 'tabline-width'
        call s:AssertTablineWidth()
    elseif s:case ==# 'transparent'
        call assert_equal('industry', g:colors_name)
        call s:AssertTransparencyToggle(1)
    elseif s:case ==# 'opaque'
        call assert_equal('industry', g:colors_name)
        call s:AssertTransparencyToggle(0)
    elseif s:case ==# 'theme-valid'
        call assert_equal('industry', g:colors_name)
    elseif s:case ==# 'theme-fallback'
        call assert_equal('default', g:colors_name)
    elseif s:case ==# 'dashboard-off'
        call s:AssertStartupTimeIsStable()
        call s:AssertAutomaticDashboard(0)
    elseif s:case ==# 'dashboard-on'
        call s:AssertAutomaticDashboard(1)
    elseif s:case ==# 'dashboard-wide'
        call s:AssertWideDashboardLogo()
    elseif s:case ==# 'bufferline-off'
        call s:AssertBufferline(0, 0)
    elseif s:case ==# 'bufferline-on'
        call s:AssertBufferline(2, 2)
    elseif s:case ==# 'data-dir-override'
        call s:AssertCustomDataDirectory()
    elseif s:case ==# 'data-dir-invalid-type'
        call s:AssertDataDirectory(s:DefaultDataDirectory(), 1)
    elseif s:case ==# 'data-dir-empty'
        call s:AssertDataDirectory(s:DefaultDataDirectory(), 1)
    elseif s:case ==# 'path-overrides'
        call s:AssertExplicitPathOverrides()
    elseif s:case ==# 'fzf-unavailable'
        call s:AssertFzfFallback()
    elseif s:case ==# 'session'
        call s:AssertSession()
    else
        call assert_report('unknown UI test case: ' . s:case)
    endif
endfunction

try
    call s:RunCase()
catch
    call assert_report(v:exception . ' at ' . v:throwpoint)
endtry

if !empty(v:errors)
    if !empty($CHOPSTICKS_TEST_ERRORS)
        call writefile(v:errors, $CHOPSTICKS_TEST_ERRORS)
    endif
    cquit
endif
qall!
