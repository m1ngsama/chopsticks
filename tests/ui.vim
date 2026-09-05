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

function! s:AssertClipboardModuleLazy() abort
    " autoload/chopsticks/clipboard.vim backs ChopsticksSystemClipboardEnabled()
    " through `import autoload` in plugin/chopsticks.vim, which must not read
    " the module until something actually calls it -- that laziness is the
    " reason this architecture was chosen. Nothing above this point in
    " startup calls the shim, so this must still hold here. If a later
    " change makes the import eager, or adds module top-level code that runs
    " at source time, this fails right here, before any case gets a chance
    " to call the shim itself and mask the regression.
    let l:info = getscriptinfo(
        \ {'name': 'chopsticks[\/]clipboard\.vim$'})
    call assert_equal(1, len(l:info),
        \ 'autoload/chopsticks/clipboard.vim is not a known script: '
        \ . string(l:info))
    if len(l:info) == 1
        call assert_true(l:info[0].autoload,
            \ 'autoload/chopsticks/clipboard.vim was already sourced')
    endif
endfunction

function! s:AssertSessionModuleLazy() abort
    " autoload/chopsticks/session.vim backs ChopsticksSessionPath() and
    " ChopsticksProjectRoot() through `import autoload` in
    " plugin/chopsticks.vim. See s:AssertClipboardModuleLazy() for why this
    " must still hold here.
    let l:info = getscriptinfo(
        \ {'name': 'chopsticks[\/]session\.vim$'})
    call assert_equal(1, len(l:info),
        \ 'autoload/chopsticks/session.vim is not a known script: '
        \ . string(l:info))
    if len(l:info) == 1
        call assert_true(l:info[0].autoload,
            \ 'autoload/chopsticks/session.vim was already sourced')
    endif
endfunction

function! s:AssertHealthModuleLazy() abort
    " autoload/chopsticks/health.vim backs ChopsticksHealthLines() through
    " `import autoload` in plugin/chopsticks.vim. See
    " s:AssertClipboardModuleLazy() for why this must still hold here.
    let l:info = getscriptinfo(
        \ {'name': 'chopsticks[\/]health\.vim$'})
    call assert_equal(1, len(l:info),
        \ 'autoload/chopsticks/health.vim is not a known script: '
        \ . string(l:info))
    if len(l:info) == 1
        call assert_true(l:info[0].autoload,
            \ 'autoload/chopsticks/health.vim was already sourced')
    endif
endfunction

function! s:AssertIconsModuleLoaded() abort
    " Unlike clipboard.vim/session.vim/health.vim, icons.vim cannot still be
    " pending here. .vimrc calls the classic dotted autoload name
    " chopsticks#ui#icons#Enabled() (and friends) at its own script top
    " level (Fern, ALE sign, and which-key setup) -- not the
    " g:ChopsticksIcon()-style shim, which does not exist that early; see
    " plugin/chopsticks.vim's own comment -- well before this test ever
    " runs, so by now this module must already be loaded:
    " getscriptinfo()'s 'autoload' flag flips from true (still a pending
    " reference) to false once a script is actually sourced. This is the
    " deliberate, necessary result of solving startup's E117 hazard without
    " moving those top-level call sites; it does not mean autoload loading
    " became eager in general -- nothing sources this file merely because
    " plugin/chopsticks.vim also imports it (see s:AssertClipboardModuleLazy()
    " for a module that really does stay pending here).
    let l:info = getscriptinfo(
        \ {'name': 'chopsticks[\/]ui[\/]icons\.vim$'})
    call assert_equal(1, len(l:info),
        \ 'autoload/chopsticks/ui/icons.vim is not a known script: '
        \ . string(l:info))
    if len(l:info) == 1
        call assert_false(l:info[0].autoload,
            \ 'autoload/chopsticks/ui/icons.vim was not sourced yet')
    endif
endfunction

function! s:AssertThemeModuleLoaded() abort
    " See s:AssertIconsModuleLoaded(): .vimrc's top-level colorscheme setup
    " calls the classic dotted names chopsticks#ui#theme#Apply() and
    " chopsticks#ui#theme#DefineInterfaceColors() before this test ever
    " runs, so theme.vim must already be loaded by now too.
    let l:info = getscriptinfo(
        \ {'name': 'chopsticks[\/]ui[\/]theme\.vim$'})
    call assert_equal(1, len(l:info),
        \ 'autoload/chopsticks/ui/theme.vim is not a known script: '
        \ . string(l:info))
    if len(l:info) == 1
        call assert_false(l:info[0].autoload,
            \ 'autoload/chopsticks/ui/theme.vim was not sourced yet')
    endif
endfunction

function! s:AssertRuntimepathContainsRoot() abort
    " README.md's documented install symlinks .vimrc into $HOME (and, on
    " Windows, sources it from a separate _vimrc). $MYVIMRC then names the
    " symlink or launcher, not this repository, so .vimrc must find its own
    " real directory without relying on $MYVIMRC when it adds itself to
    " 'runtimepath' -- otherwise plugin/chopsticks.vim silently never loads.
    " The 'symlink-install' case starts Vim the way the README install does
    " (a real ~/.vimrc symlink, not -u pointing straight at this file), so
    " this only passes when .vimrc resolves its own location correctly.
    call assert_true(index(split(&runtimepath, ','), s:root) >= 0,
        \ 'chopsticks root missing from runtimepath: ' . &runtimepath)
endfunction

function! s:AssertPublicInterface() abort
    if !empty(s:startup_errmsg)
        call assert_report('startup error: ' . s:startup_errmsg . ' | messages: '
            \ . substitute(trim(s:startup_messages), '\n', ' // ', 'g'))
    endif
    call s:AssertClipboardModuleLazy()
    call s:AssertSessionModuleLazy()
    call s:AssertHealthModuleLazy()
    call s:AssertIconsModuleLoaded()
    call s:AssertThemeModuleLoaded()
    call assert_equal(2, exists(':ChopsticksUiDensity'))
    call assert_equal(2, exists(':ChopsticksTransparencyToggle'))
    call assert_equal(2, exists(':ChopsticksIconsToggle'))
    call assert_equal(2, exists(':ChopsticksTheme'))
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
    call assert_true(exists('*ChopsticksProjectRoot'))
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

" Must match .vimrc's s:NormalizeDirectory() and
" autoload/chopsticks/session.vim's NormalizeDirectory() exactly, including
" which separator is appended. When these three disagreed, fixing the
" production copy alone only moved the Windows failure from one assertion to
" another.
function! s:NormalizedDirectory(path) abort
    let l:directory = simplify(fnamemodify(expand(a:path), ':p'))
    if l:directory =~# '[/\\]$'
        return l:directory
    endif
    let l:windows = has('win32') || has('win64')
    return l:directory . (l:windows && l:directory =~# '\\' ? '\' : '/')
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
        " The derived session directory goes through .vimrc's
        " s:NormalizeDirectory() like any other, so it ends in whichever
        " separator that function appends -- not a hardcoded '/'.
        call assert_equal(s:NormalizedDirectory(l:expected . '.sessions'),
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
    " ProjectRoot() moved into autoload/chopsticks/session.vim (Vim9 script)
    " and is reached through the public ChopsticksProjectRoot() global (see
    " plugin/chopsticks.vim) instead of the <SNR> function-name reflection
    " used elsewhere in this file for .vimrc's own private legacy helpers:
    " that reflection only works on legacy `function!` definitions, not a
    " Vim9 `def`.
    let l:test_root = tempname() . '-project,with;markers'
    let l:nested = l:test_root . '/nested'
    let l:previous_directory = getcwd()
    call mkdir(l:test_root . '/.git', 'p')
    call mkdir(l:nested, 'p')
    try
        execute 'silent edit ' . fnameescape(l:nested . '/note.md')
        call assert_equal(fnamemodify(l:test_root, ':p'),
            \ ChopsticksProjectRoot())
    finally
        silent! bwipeout!
        execute 'lcd ' . fnameescape(l:previous_directory)
        call delete(l:test_root, 'rf')
    endtry
endfunction

function! s:AssertProjectCommandsStayRooted() abort
    " The spec builder used to be a script-local function in .vimrc, found
    " here by searching :function output for its <SNR> name. It is now
    " chopsticks#find#ProjectSpec() and is called directly below.
    "
    " Two ways of writing this are silently vacuous, and both were tried
    " here. Searching :function output finds nothing once the name changes,
    " and exists('*chopsticks#find#ProjectSpec') is 0 until something has
    " already loaded the module -- exists() does not trigger autoloading. A
    " guard on either one turns the whole assertion into an early return
    " that reports success. Calling the function is what loads it, so this
    " calls it and lets a genuine failure raise.
    let l:outside = tempname() . '-outside-project'
    let l:previous = getcwd()
    call mkdir(l:outside, 'p')
    try
        execute 'silent edit ' . fnameescape(s:root . '/README.md')
        execute 'cd ' . fnameescape(l:outside)
        call assert_equal(0, haslocaldir())
        let l:spec = chopsticks#find#ProjectSpec()
        call assert_equal(fnamemodify(s:root, ':p'),
            \ fnamemodify(l:spec.dir, ':p'))
        " resolve() on both sides: on macOS tempname() hands back a
        " /var/... path while getcwd() reports the /private/var/... the
        " symlink points at, so comparing them unresolved fails on a
        " correct working directory.
        call assert_equal(resolve(fnamemodify(l:outside, ':p')),
            \ resolve(fnamemodify(getcwd(), ':p')))
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
    " Derived from the same string the harness hands g:chopsticks_session_dir,
    " through the same normaliser, so the two cannot disagree about which
    " separator terminates the path.
    let l:expected_directory =
        \ s:NormalizedDirectory('~/.chopsticks-session-tests')
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

function! s:AssertHealth() abort
    let l:lines = ChopsticksHealthLines()
    call assert_equal(type([]), type(l:lines))
    call assert_true(len(l:lines) > 0)
    call assert_equal(2, exists(':ChopsticksHealth'))
    call assert_match('Language servers', join(l:lines, "\n"))
    " Every lang/ file is listed whether or not its binary is installed, so an
    " absent server is visible here rather than only as silence in a buffer.
    for l:language in ['bash', 'c', 'go', 'python', 'rust', 'typescript']
        call assert_match(l:language, join(l:lines, "\n"),
            \ 'health report omits language: ' . l:language)
    endfor
endfunction

" Characterization of the key catalog and the mappings it documents.
" Written before the key code moves out of .vimrc, so that a failure
" afterwards means the move broke something rather than that nothing was
" watching. The specific keys asserted here are the ones README.md lists, so
" this also catches the cheatsheet drifting away from the documentation.
function! s:AssertKeys() abort
    let l:lines = ChopsticksKeyLines()
    call assert_equal(type([]), type(l:lines))
    " The sheet is around 190 lines with about 17 blank separators. A lower
    " bound well under that still catches a move that dropped whole groups,
    " without breaking every time a key is added.
    call assert_true(len(l:lines) > 150,
        \ 'key catalog is suspiciously short: ' . len(l:lines))
    call assert_equal(2, exists(':ChopsticksKeys'))
    call assert_equal(2, exists(':ChopsticksCheatsheet'))
    call assert_match('cheatsheet', l:lines[0])

    " Blank lines are the section separators, so they are expected; what
    " would be wrong is the sheet becoming mostly blank.
    let l:blank = len(filter(copy(l:lines), {_, l -> empty(trim(l))}))
    call assert_true(l:blank * 4 < len(l:lines),
        \ 'key catalog is mostly blank: ' . l:blank . '/' . len(l:lines))

    " Leader mappings, from README's key table. '?' and 'h' are the two the
    " dashboard footer advertises, and a footer naming a key that does not
    " exist outside the dashboard is how they were unreachable before.
    for l:key in ['e', 'p', 'P', '?', 'h']
        call assert_true(!empty(maparg('<Space>' . l:key, 'n')),
            \ 'missing leader mapping: <Space>' . l:key)
    endfor

    " Both entry points the footer names must be findable in the sheet itself.
    call assert_match('Full cheatsheet', join(l:lines, "\n"))
    call assert_match('Health report', join(l:lines, "\n"))

    " Direct mappings, also from README.
    for l:key in ['ss', 'sv', 'sq', 'sh', 'sj', 'sk', 'sl']
        call assert_true(!empty(maparg(l:key, 'n')),
            \ 'missing window mapping: ' . l:key)
    endfor
    for l:key in ['H', 'L']
        call assert_true(!empty(maparg(l:key, 'n')),
            \ 'missing buffer mapping: ' . l:key)
    endfor

    " The catalogue must mention the groups the which-key tree is built from.
    let l:joined = join(l:lines, "\n")
    for l:group in ['Files', 'Windows', 'Buffers', 'Git', 'Toggles']
        call assert_match(l:group, l:joined,
            \ 'key catalog does not mention group: ' . l:group)
    endfor
endfunction

function! s:AssertLspRegistry() abort
    " Bookkeeping must happen even with no plugin present: this filetype is
    " Ensure()d before g:LspAddServer exists, so this only passes if
    " registered[name] = true runs before the plugin guard returns.
    call assert_false(exists('*g:LspAddServer'))
    call chopsticks#lsp#Ensure('nopluginfiletype')
    call assert_true(index(chopsticks#lsp#Registered(), 'nopluginfiletype') >= 0)

    function! g:LspAddServer(servers) abort
    endfunction

    " A filetype with no lang/ file must be recorded as seen, so the miss is
    " paid once per session rather than on every FileType.
    call chopsticks#lsp#Ensure('nosuchfiletype')
    call assert_true(index(chopsticks#lsp#Registered(), 'nosuchfiletype') >= 0)

    " Aliases collapse: cpp is served by lang/c.vim, javascript by
    " lang/typescript.vim, so neither adds a second key.
    call chopsticks#lsp#Ensure('c')
    call chopsticks#lsp#Ensure('cpp')
    call assert_equal(1, len(filter(copy(chopsticks#lsp#Registered()),
        \ {_, v -> v ==# 'c'})))
    call assert_false(index(chopsticks#lsp#Registered(), 'cpp') >= 0)

    call chopsticks#lsp#Ensure('javascript')
    call assert_true(index(chopsticks#lsp#Registered(), 'typescript') >= 0)
    call assert_false(index(chopsticks#lsp#Registered(), 'javascript') >= 0)

    " An empty filetype is not a filetype.
    call chopsticks#lsp#Ensure('')
    call assert_false(index(chopsticks#lsp#Registered(), '') >= 0)

    delfunction g:LspAddServer
endfunction

function! s:AssertLangFiles() abort
    " Stub the plugin's entry point and source each file for real, so a typo
    " in a language nobody on CI has a server for still fails here.
    let g:chopsticks_test_lsp_servers = []
    function! g:LspAddServer(servers) abort
        call extend(g:chopsticks_test_lsp_servers, a:servers)
    endfunction

    let l:expected = {
        \ 'c': ['c', 'cpp'],
        \ 'typescript': ['typescript', 'javascript'],
        \ 'go': ['go'],
        \ 'rust': ['rust'],
        \ 'python': ['python'],
        \ 'bash': ['sh'],
        \ }
    for l:name in sort(keys(l:expected))
        let g:chopsticks_test_lsp_servers = []
        let l:file = globpath(&runtimepath, 'lang/' . l:name . '.vim', 0, 1)
        call assert_false(empty(l:file), 'missing lang file: ' . l:name)
        if empty(l:file)
            continue
        endif
        execute 'source' fnameescape(l:file[0])
        call assert_equal(1, len(g:chopsticks_test_lsp_servers),
            \ l:name . ' must register exactly one server')
        if empty(g:chopsticks_test_lsp_servers)
            continue
        endif
        let l:server = g:chopsticks_test_lsp_servers[0]
        for l:key in ['name', 'filetype', 'path', 'args']
            call assert_true(has_key(l:server, l:key),
                \ l:name . ' server is missing ' . l:key)
        endfor
        call assert_equal(l:expected[l:name], l:server.filetype,
            \ l:name . ' registers the wrong filetypes')
        call assert_equal(type([]), type(l:server.args),
            \ l:name . ' args must be a list')
    endfor
    delfunction g:LspAddServer
    unlet g:chopsticks_test_lsp_servers
endfunction

" The options must reach the plugin before any server does: g:LspAddServer()
" freezes each server's omni-completion flag from the options in force when it
" runs, and a FileType fires before the plugin's own LspSetup event. Both
" globals are stubbed, so the order is observable with no plugin installed.
function! s:AssertLspOptionsOrder() abort
    let g:chopsticks_test_lsp_calls = []
    let g:chopsticks_test_lsp_options = {}
    function! g:LspOptionsSet(options) abort
        call add(g:chopsticks_test_lsp_calls, 'options')
        let g:chopsticks_test_lsp_options = a:options
    endfunction
    function! g:LspAddServer(servers) abort
        call add(g:chopsticks_test_lsp_calls, 'server')
    endfunction

    call chopsticks#lsp#Ensure('c')
    call assert_equal(['options', 'server'], g:chopsticks_test_lsp_calls,
        \ 'Ensure() must set the options before it registers a server')
    call assert_equal(v:false, get(g:chopsticks_test_lsp_options,
        \ 'autoComplete', v:null))
    call assert_equal(v:true, get(g:chopsticks_test_lsp_options,
        \ 'omniComplete', v:null))

    delfunction g:LspOptionsSet
    delfunction g:LspAddServer
    unlet g:chopsticks_test_lsp_calls
    unlet g:chopsticks_test_lsp_options
endfunction

" User LspAttached never fires without a server, so nothing else would exercise
" Maps(). Call it directly; the stub satisfies its plugin guard.
function! s:AssertLspMaps() abort
    function! g:LspAddServer(servers) abort
    endfunction

    new
    call chopsticks#lsp#Maps()
    for l:key in ['gd', 'gr', 'K', '<leader>cl']
        call assert_true(!empty(maparg(l:key ==# '<leader>cl'
            \ ? "\<Space>cl" : l:key, 'n')),
            \ 'Maps() did not bind ' . l:key)
    endfor
    call assert_match('Code outline', join(ChopsticksKeyLines(), "\n"))
    call assert_match('Registered LSP servers', join(ChopsticksKeyLines(), "\n"))
    close

    delfunction g:LspAddServer
endfunction

" Characterization of Markdown and prose setup, for the same reason.
function! s:AssertMarkdown() abort
    call assert_equal(2, exists(':MarkdownPasteImage'))
    call assert_equal(2, exists(':MarkdownGlow'))
    call assert_equal(2, exists(':MarkdownHelp'))

    silent edit README.md
    call assert_equal('markdown', &filetype)
    call assert_equal(',', get(g:, 'maplocalleader', ''))

    " The LocalLeader mappings Chopsticks defines unconditionally. Comma is
    " the Markdown LocalLeader, and maparg() wants the resolved key, not the
    " <LocalLeader> spelling. The other documented Markdown keys -- ,o ,z ,tt
    " ,f ,l and friends -- are guarded on their plugin being present, so
    " asserting them here would make this a test of what is installed.
    for l:key in ['?', 's', 'c', 'g', 'i']
        call assert_true(!empty(maparg(',' . l:key, 'n')),
            \ 'missing Markdown mapping: ,' . l:key)
        call assert_true(get(maparg(',' . l:key, 'n', 0, 1), 'buffer', 0),
            \ 'Markdown mapping is not buffer-local: ,' . l:key)
    endfor

    " Prose buffers get spell checking when the switch is on, and the
    " long-line guard leaves 'breakindent' alone on an ordinary document.
    call assert_equal(g:chopsticks_markdown_spell ? 1 : 0, &l:spell ? 1 : 0)

    " Press the keys, do not merely count them. A <ScriptCmd> mapping that
    " points at a function which throws still satisfies maparg(), so an
    " existence check passes while the feature is broken -- which is exactly
    " how a Vim9 bool-strictness error shipped green here once already.
    let l:before = &l:conceallevel
    let v:errmsg = ''
    call feedkeys(",c", 'xt')
    call assert_equal('', v:errmsg, ',c raised: ' . v:errmsg)
    call assert_notequal(l:before, &l:conceallevel,
        \ ',c did not change conceallevel')
    call feedkeys(",c", 'xt')
    call assert_equal(l:before, &l:conceallevel,
        \ ',c did not toggle back')

    let v:errmsg = ''
    call feedkeys(",?", 'xt')
    call assert_equal('', v:errmsg, ',? raised: ' . v:errmsg)
    call assert_equal('[chopsticks-markdown]', bufname('%'))
    call feedkeys("q", 'xt')

    " The long-line guard runs on every buffer that reaches a window, so a
    " throw here would fire constantly rather than only on a keypress.
    let v:errmsg = ''
    call chopsticks#markdown#GuardLongLines()
    call assert_equal('', v:errmsg, 'GuardLongLines raised: ' . v:errmsg)
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
    elseif s:case ==# 'health'
        call s:AssertHealth()
    elseif s:case ==# 'keys'
        call s:AssertKeys()
    elseif s:case ==# 'lsp-registry'
        call s:AssertLspRegistry()
    elseif s:case ==# 'lsp-lang-files'
        call s:AssertLangFiles()
    elseif s:case ==# 'lsp-options-order'
        call s:AssertLspOptionsOrder()
    elseif s:case ==# 'lsp-maps'
        call s:AssertLspMaps()
    elseif s:case ==# 'markdown'
        call s:AssertMarkdown()
    elseif s:case ==# 'symlink-install'
        call s:AssertRuntimepathContainsRoot()
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

" Record that this script ran all the way here. run_ui_test refuses a case
" that exits 0 without leaving this behind, because Vim can be made to quit
" early -- by a stray :qall in a mapping a case triggers, for instance --
" and an early quit looks exactly like a pass: silent, exit 0, no assertions
" recorded. Without this marker such a case reports success while having
" tested nothing.
if !empty($CHOPSTICKS_TEST_COMPLETED)
    call writefile(['completed: ' . s:case], $CHOPSTICKS_TEST_COMPLETED)
endif
qall!
