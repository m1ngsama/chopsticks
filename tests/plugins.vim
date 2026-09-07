scriptencoding utf-8

set nomore

let s:case = $CHOPSTICKS_TEST_CASE
let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'cd ' . fnameescape(s:root)

function! s:AssertEditorAndExplorer(editor_type, explorer_type) abort
    let l:editor = {}
    let l:explorer = {}
    for l:window in getwininfo()
        let l:type = getbufvar(l:window.bufnr, '&filetype')
        if l:type ==# a:editor_type
            let l:editor = l:window
        elseif l:type ==# a:explorer_type
            let l:explorer = l:window
        endif
    endfor
    call assert_false(empty(l:editor))
    call assert_false(empty(l:explorer))
    if !empty(l:editor) && !empty(l:explorer)
        call assert_equal(l:editor.height, l:explorer.height)
        call assert_true(l:explorer.width < l:editor.width)
    endif
endfunction

" Mirrors .vimrc's s:is_remote, which is script-local and unreachable here.
function! s:IsRemote() abort
    return !empty($SSH_CONNECTION) || !empty($SSH_CLIENT) || !empty($SSH_TTY)
endfunction

" What the finder put on screen: every popup's title and contents. Polls
" because the sources are asynchronous jobs, and closes with <Esc> so the
" plugin runs its own exit path -- popup_clear() would destroy the popups
" behind its back, leaving its active flag set and a pending update timer to
" fire against a freed buffer.
function! s:FinderScreen(launch, expected) abort
    execute a:launch
    let l:screen = ''
    for l:attempt in range(50)
        let l:parts = []
        for l:popup_id in popup_list()
            call add(l:parts, get(popup_getoptions(l:popup_id), 'title', ''))
            call extend(l:parts, getbufline(winbufnr(l:popup_id), 1, '$'))
        endfor
        let l:screen = join(l:parts, "\n")
        if l:screen =~# a:expected
            break
        endif
        sleep 100m
    endfor
    call feedkeys("\<Esc>", 'xt')
    call assert_true(empty(popup_list()), a:launch . ' left a popup open')
    return l:screen
endfunction

" Every selector is launched from a working directory outside the project,
" because the finder is rooted by passing cwd to the job, never by moving Vim.
" Asserted here because this is the suite that has a plugin to assert it about.
function! s:AssertFinderSelectors() abort
    let l:before = getcwd()
    let l:outside = tempname() . '-outside'
    " Untracked and not ignored: the one thing that tells the file source and
    " git ls-files apart, and a grep hit no other directory can produce.
    let l:probe = s:root . '/untracked-probe.txt'
    try
        call mkdir(l:outside, 'p')
        call writefile(['chopsticks-probe-token'], l:probe)
        execute 'cd ' . fnameescape(l:outside)
        let l:files = s:FinderScreen('ChopFiles', 'untracked-probe')
        let l:grep = s:FinderScreen(
            \ "call chopsticks#find#Grep('chopsticks-probe-token')",
            \ 'untracked-probe\.txt:\d\+:')
        let l:git = s:FinderScreen('call chopsticks#find#GitFiles()', 'README.md')
        let l:recent = s:FinderScreen('ChopRecent', 'Recent Files')
        call assert_equal(resolve(l:outside), resolve(getcwd()))
    finally
        execute 'cd ' . fnameescape(l:before)
        call delete(l:outside, 'rf')
        call delete(l:probe)
    endtry
    call assert_match('README.md', l:files)
    " The headline behaviour change: the file source lists untracked files,
    " where git ls-files does not. Without this the l:git notmatch below could
    " pass against a FindFiles that had quietly gone back to Git-only.
    call assert_match('untracked-probe', l:files)
    call assert_match('> chopsticks-probe-token', l:grep)
    call assert_match('untracked-probe\.txt:\d\+:', l:grep)
    call assert_match('README.md', l:git)
    call assert_notmatch('untracked-probe', l:git)
    " Only the title separates the recent-file list from the buffer list, which
    " holds the same files in a session this short.
    call assert_match('Recent Files', l:recent)
endfunction

function! s:RunStartup(expected_auto_lint) abort
    silent edit README.md
    tnoremap <Esc><Esc> <C-\><C-n>
    execute 'source ' . fnameescape(s:root . '/.vimrc')
    let l:key_lines = ChopsticksKeyLines()
    execute 'source ' . fnameescape(s:root . '/.vimrc')
    doautocmd VimEnter
    call assert_equal('0.3.2', get(g:, 'chopsticks_version', ''))
    for l:command in [
        \ 'ChopHealth', 'ChopKeys',
        \ 'ChopFiles', 'ChopIcons',
        \ 'ChopDensity', 'ChopTransparency',
        \ 'ChopSave', 'ChopLoad',
        \ 'MdPaste',
        \ ]
        call assert_equal(2, exists(':' . l:command), l:command)
    endfor
    call assert_equal('everforest', get(g:, 'colors_name', ''))
    call assert_true(ChopsticksIconsEnabled())
    call assert_equal(1, strwidth(ChopsticksIcon('file')))
    let l:health = ChopsticksHealthLines()
    call assert_match('Nerd Font', join(l:health, "\n"))
    call assert_match('Fern drawer', join(l:health, "\n"))
    call assert_match(a:expected_auto_lint
        \ ? 'linting\s\+automatic on enter and save'
        \ : 'linting\s\+manual (,l / :ALELint)', join(l:health, "\n"))
    call assert_true(index(l:health, '[ok] all declared plugins installed') >= 0)
    call assert_equal('markdown', &filetype)
    call assert_equal('markdown', &syntax)
    call assert_true(&l:wrap)
    call assert_true(exists('*g:LspAddServer'))
    call assert_true(exists('*g:LspOptionsSet'))
    call assert_false(exists('*asyncomplete#force_refresh'))
    call assert_true(exists('#User#LspAttached'))
    " The snippet plugins are what make an LSP completion item that arrives as
    " a snippet expand instead of landing as literal ${1:...} text.
    call assert_true(exists('g:loaded_vsnip'))
    call assert_true(exists('g:loaded_vsnip_integ'))
    call assert_equal(v:true, g:LspOptionsGet().vsnipSupport)
    " Set by vim-vsnip-integ, not by us, and asserted anyway: it is the
    " capability that makes a server send a snippet at all, so losing the
    " plugin that sets it would leave vsnipSupport routing an empty path.
    call assert_equal(v:true, g:LspOptionsGet().snippetSupport)
    call assert_equal(g:chopsticks_data_dir . 'vsnip', g:vsnip_snippet_dir)
    " The option must follow the plugin, not the configuration's hope: with it
    " on and vsnip missing, every completion raises E117 inside the client.
    " Asked directly rather than through a second Options() pass, which the
    " aleSupport comment there explains is unsafe to repeat.
    unlet g:loaded_vsnip
    call assert_false(chopsticks#lsp#SnippetSupport())
    let g:loaded_vsnip = 1
    call assert_true(chopsticks#lsp#SnippetSupport())
    call assert_equal(v:false, g:LspOptionsGet().autoComplete)
    call assert_equal(v:true, g:LspOptionsGet().omniComplete)
    call assert_equal(v:true, g:LspOptionsGet().ignoreMissingServer)
    call assert_equal(v:true, g:LspOptionsGet().aleSupport)
    call assert_equal(a:expected_auto_lint, g:chopsticks_auto_lint)
    call assert_equal(a:expected_auto_lint, g:ale_lint_on_enter)
    call assert_equal(a:expected_auto_lint, g:ale_lint_on_save)
    call assert_equal(a:expected_auto_lint, g:ale_lint_on_filetype_changed)
    call assert_equal(a:expected_auto_lint,
        \ exists('#ALEEvents#BufWinEnter'))
    call assert_equal(a:expected_auto_lint, exists('#ALEEvents#FileType'))
    call assert_match('WhichKey', maparg("\<Space>", 'n'))
    call assert_match('WhichKey', maparg(',', 'n'))
    call assert_match('chopsticks#explorer#Root', maparg("\<Space>e", 'n'))
    " Select mode, not only insert: vim-vsnip leaves a placeholder selected,
    " and an insert mapping never fires there.
    for l:key in ['<Tab>', '<S-Tab>']
        call assert_match('chopsticks#lsp#SelectTab', maparg(l:key, 's'), l:key)
        call assert_match('chopsticks#lsp#Completion', maparg(l:key, 'i'), l:key)
    endfor
    call assert_match('FindFiles', maparg(';f', 'n'))
    call assert_equal(2, exists(':FuzzyFiles'))
    call assert_equal(0, exists(':Files'))
    " What the dashboard's Find Text entry is keyed on. The UI suite has no
    " plugin and can only stub it.
    call assert_equal(2, exists(':FuzzyGrep'))
    call assert_equal(0, g:fuzzbox_mappings)
    " The plugin's own <leader>f* defaults would land on our Files group.
    call assert_equal('', maparg("\<Space>fb", 'n'))
    call assert_equal(["\<Esc>", "\<C-c>", "\<C-g>", "\<C-q>"], g:fuzzbox_keymaps.exit)
    call assert_equal(chopsticks#ui#icons#Enabled(), g:fuzzbox_devicons)
    call assert_equal(s:IsRemote() ? 0 : 1, g:fuzzbox_preview)
    call assert_equal(['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
        \ g:fuzzbox_borderchars)
    " width/height, not max*: the plugin ignores maxheight and drops to 0.5
    " when the preview is off, so max* alone would halve the finder over SSH.
    call assert_equal(0.92, g:fuzzbox_window_defaults.width)
    call assert_equal(0.84, g:fuzzbox_window_defaults.height)
    call assert_false(has_key(g:fuzzbox_window_defaults, 'maxwidth'))
    " Scoped to files. The list replaced a file-source filter; applied globally
    " it would also narrow project grep and hide most of the recent-file list.
    for l:excluded in ['Library/', 'node_modules/', 'plugged/']
        call assert_true(index(g:fuzzbox_files_exclude_dir, l:excluded) >= 0,
            \ l:excluded)
    endfor
    " Every entry, not only those three. The plugin builds rg's -g '!<entry>'
    " and fd's -E <entry> straight from this list, and either one without the
    " slash matches the name at any depth, files included -- a ./build script
    " would leave the finder with nothing said.
    for l:excluded in g:fuzzbox_files_exclude_dir
        call assert_match('/$', l:excluded, l:excluded)
    endfor
    " The plugin defines g:fuzzbox_exclude_dir itself and grep and mru fall back
    " to it, so what proves the scoping is that ours did NOT leak into it.
    call assert_equal(['.git', '.hg', '.svn'], g:fuzzbox_exclude_dir)
    " Our own colour, not merely that the group exists -- the plugin defines
    " every fuzzbox* group itself, so hlexists() alone cannot fail.
    call assert_match('guifg=#859289', execute('highlight fuzzboxBorder'))
    call assert_match('guifg=#a7c080',
        \ execute('highlight fuzzboxMatching'))
    call assert_match('guibg=#343f44',
        \ execute('highlight fuzzboxSelectionSign'))
    call assert_match('chopsticks#find#GitFiles', maparg("\<Space>fg", 'n'))
    call s:AssertFinderSelectors()
    " Every mapping that names a command, checked by resolving the name it
    " names. Matching the right-hand side as a substring passes on a command
    " nothing defines, and that miss only surfaces under the user's fingers.
    for [l:key, l:command] in [
        \ ["\<Space>\<Space>", 'FuzzyBuffers'], ["\<Space>,", 'FuzzyBuffers'],
        \ ["\<Space>fr", 'FuzzyMru'], ["\<Space>/", 'FuzzyInBuffer'],
        \ ["\<Space>sb", 'FuzzyInBuffer'], ["\<Space>sc", 'FuzzyCommands'],
        \ ["\<Space>sg", 'ChopGrep'], ["\<Space>sh", 'FuzzyHelp'],
        \ ["\<Space>sw", 'ChopGrep'], [';b', 'FuzzyBuffers'],
        \ [';h', 'FuzzyHelp'], [';l', 'FuzzyInBuffer'],
        \ [';r', 'ChopGrep'], ['\', 'FuzzyBuffers'],
        \ ]
        call assert_equal(l:command,
            \ matchstr(maparg(l:key, 'n'), '^:\zs\u\w*'), string(l:key))
        call assert_equal(2, exists(':' . l:command), l:command)
    endfor
    " The loop above only reads right-hand sides that name a command, so the
    " bindings that call a function are invisible to it and could be deleted
    " with every suite still green.
    for l:key in ["\<C-p>", "\<Space>ff", ';f']
        call assert_match('chopsticks#find#FindFiles',
            \ maparg(l:key, 'n'), string(l:key))
    endfor
    call assert_equal('', maparg("\<Space>sB", 'n'))
    call assert_equal('', maparg("\<Space>sm", 'n'))
    call assert_equal('', maparg("\<Esc>\<Esc>", 't'))
    call assert_match('TableModeToggle', maparg(',tt', 'n'))
    call assert_match('ALELint', maparg(',l', 'n'))
    call assert_equal(l:key_lines, ChopsticksKeyLines())
    call assert_true(len(ChopsticksKeyLines()) >= 100)
    call assert_match('Esc / Ctrl-q', join(ChopsticksKeyLines(), "\n"))
    " The Start here block teaches four prefixes by naming keys it does not
    " own. Checked here and not in the UI suite because the ; row teaches the
    " finder, which nothing binds without the plugin. Written as the sheet
    " prints them, so a rename shows up as a row that stopped existing.
    let l:sheet = join(ChopsticksKeyLines(), "\n")
    call assert_match('\nStart here\n', l:sheet)
    " The section the UI suite cannot see: these keys exist only with the
    " finder installed, which is the difference between the two suites.
    call assert_match('\nFast find\n', l:sheet)
    for l:key in chopsticks#keys#StarterCoverage()
        call assert_match('\n  ' . escape(l:key, '\.*$^~[]') . '\s',
            \ l:sheet, 'Start here names an unbound key: ' . l:key)
    endfor
    call assert_match('Fern q / Esc', join(ChopsticksKeyLines(), "\n"))
    call s:AssertWhichKeyGroupSyntax()
    call s:AssertEverforestSemanticColors()
    call s:AssertDiagnosticsPresentation()
    call s:AssertGitDiffPresentation()
    call s:AssertGitBranchPresentation()
    call s:AssertAleKeepsTheGutter()
endfunction

" aleSupport does not clear autoHighlightDiags up front: the plugin clears it
" when the first server starts, which for `vim file.c` is at FileType, before
" VimEnter. Anything of ours that re-applies the LSP options on a later
" startup event therefore undoes the hand-off and puts two signs, ALE's and
" the LSP's, on every diagnostic line. No server can start here, so the
" hand-off is replayed by hand, then every path that still reaches Options().
function! s:AssertAleKeepsTheGutter() abort
    call g:LspOptionsSet({'autoHighlightDiags': v:false})
    if exists('#User#LspSetup')
        doautocmd <nomodeline> User LspSetup
    endif
    call chopsticks#lsp#Ensure('c')
    call assert_equal(v:false, g:LspOptionsGet().autoHighlightDiags)
endfunction

function! s:GuiColor(group, attribute) abort
    return synIDattr(synIDtrans(hlID(a:group)), a:attribute, 'gui')
endfunction

function! s:AssertEverforestSemanticColors() abort
    let l:expectations = [
        \ ['ChopStatusInsert', 'bg', 'Blue'],
        \ ['ChopStatusVisual', 'bg', 'Purple'],
        \ ['ChopStatusCommand', 'bg', 'Aqua'],
        \ ['ChopStatusInfo', 'fg', 'Blue'],
        \ ['ChopDashboardLogo', 'fg', 'Blue'],
        \ ['ChopDashboardIcon', 'fg', 'Aqua'],
        \ ['ChopDashboardKey', 'fg', 'Orange'],
        \ ['ChopStatusGitAdd', 'fg', 'Green'],
        \ ['ChopStatusGitChange', 'fg', 'Yellow'],
        \ ['ChopStatusGitDelete', 'fg', 'Red'],
        \ ]
    for l:expectation in l:expectations
        let l:actual = s:GuiColor(l:expectation[0], l:expectation[1])
        let l:expected = s:GuiColor(l:expectation[2], 'fg')
        call assert_false(empty(l:expected), l:expectation[2])
        call assert_equal(l:expected, l:actual, l:expectation[0])
    endfor
endfunction

function! s:AssertWhichKeyGroupSyntax() abort
    let l:source_buffer = bufnr('')
    silent keepalt enew
    call setline(1, '  f → +󰈔 Files')
    setfiletype which_key
    syntax sync fromstart
    let l:column = match(getline(1), '+') + 1
    call assert_equal('WhichKeyGroup',
        \ synIDattr(synID(1, l:column, 1), 'name'))
    let l:test_buffer = bufnr('')
    execute 'silent buffer ' . l:source_buffer
    execute 'silent bwipeout! ' . l:test_buffer
endfunction

function! s:AssertDiagnosticsPresentation() abort
    let l:buffer = bufnr('')
    call ale#statusline#Count(l:buffer)
    let l:had_info = has_key(g:ale_buffer_info, l:buffer)
    let l:saved_info = l:had_info
        \ ? deepcopy(g:ale_buffer_info[l:buffer]) : {}
    let g:ale_buffer_info[l:buffer] = {'count': {
        \ 'error': 2, 'style_error': 0,
        \ 'warning': 0, 'style_warning': 0, 'info': 0,
        \ }}
    let l:errors = ChopsticksDiagnostics(l:buffer)
    call assert_match('%#ChopStatusError#.*2', l:errors)
    call assert_notmatch('ChopStatusWarning', l:errors)
    call assert_notmatch('ChopStatusInfo', l:errors)

    let g:ale_buffer_info[l:buffer].count = {
        \ 'error': 0, 'style_error': 0,
        \ 'warning': 3, 'style_warning': 1, 'info': 5,
        \ }
    let l:notices = ChopsticksDiagnostics(l:buffer)
    call assert_notmatch('ChopStatusError', l:notices)
    call assert_match('%#ChopStatusWarning#.*4', l:notices)
    call assert_match('%#ChopStatusInfo#.*5', l:notices)
    if l:had_info
        let g:ale_buffer_info[l:buffer] = l:saved_info
    else
        call remove(g:ale_buffer_info, l:buffer)
    endif
endfunction

function! s:AssertGitDiffPresentation() abort
    let l:buffer = bufnr('')
    let l:saved = getbufvar(l:buffer, 'gitgutter')
    call setbufvar(l:buffer, 'gitgutter', {'summary': [2, 0, 4]})
    let l:summary = ChopsticksGitDiff(l:buffer)
    call assert_match('%#ChopStatusGitAdd#.*2', l:summary)
    call assert_notmatch('ChopStatusGitChange', l:summary)
    call assert_match('%#ChopStatusGitDelete#.*4', l:summary)
    call setbufvar(l:buffer, 'gitgutter', l:saved)
endfunction

" The branch segment had no assertion at all until the guard behind it was
" found stuck false, so nothing would have noticed it going quiet. This
" checks the rendered statusline, not just the helper, because that is the
" surface a person actually sees.
function! s:AssertGitBranchPresentation() abort
    call assert_true(exists('*FugitiveHead'), 'fugitive is expected here')
    " A CI checkout is usually on a detached HEAD, where fugitive reports no
    " branch and an absent segment is correct. Only the presence of a name
    " makes this assertable, so the empty case checks the rendering path
    " runs at all rather than asserting a segment that should not be there.
    let l:branch = FugitiveHead(0, bufnr(''))
    if empty(l:branch)
        call assert_true(type(ChopsticksStatusline()) == type(''))
        return
    endif
    call assert_match(l:branch, ChopsticksStatusline())
endfunction

function! s:AssertFernNodeToggle(key) abort
    call assert_true(search('\<tests\>/', 'w') > 0)
    let l:node_line = line('.')
    let l:closed_lines = line('$')
    call feedkeys(a:key, 'xt')
    sleep 300m
    call assert_equal(l:node_line, line('.'))
    call assert_true(line('$') > l:closed_lines)
    call feedkeys(a:key, 'xt')
    sleep 300m
    call assert_equal(l:node_line, line('.'))
    call assert_equal(l:closed_lines, line('$'))
endfunction

function! s:AssertFernParentOrCollapse() abort
    call assert_true(search('\<tests\>/', 'w') > 0)
    let l:node_line = line('.')
    let l:closed_lines = line('$')
    call feedkeys('l', 'xt')
    sleep 300m
    call feedkeys('j', 'xt')
    call assert_true(line('.') > l:node_line)
    call feedkeys('h', 'xt')
    sleep 300m
    call assert_equal(l:node_line, line('.'))
    call feedkeys('h', 'xt')
    sleep 300m
    call assert_equal(l:closed_lines, line('$'))
    call assert_equal(l:node_line, line('.'))
endfunction

function! s:RunFernToggle() abort
    silent edit README.md
    call feedkeys("\<Space>e", 'xt')
    sleep 300m
    call assert_equal('fern', &filetype)
    call assert_equal(2, winnr('$'))
    call assert_match('󰂺 README.md', getline('.'))
    call assert_match('chopsticks-fern-toggle-node', maparg('l', 'n'))
    call assert_match(':close', maparg('q', 'n'))
    call assert_equal('nerdfont', g:fern#renderer)
    call s:AssertFernNodeToggle("\<CR>")
    call s:AssertFernNodeToggle('l')
    call s:AssertFernParentOrCollapse()
    call feedkeys('q', 'xt')
    call assert_equal('markdown', &filetype)
    call assert_equal(1, winnr('$'))
    for l:key in ["\<Esc>", "\<Space>e"]
        call feedkeys("\<Space>e", 'xt')
        call feedkeys(l:key, 'xt')
        call assert_equal('markdown', &filetype)
        call assert_equal(1, winnr('$'))
    endfor
    call feedkeys("\<Space>e", 'xt')
    wincmd p
    let l:content_window = win_getid()
    call feedkeys("\<Space>e", 'xt')
    call assert_equal('markdown', &filetype)
    call assert_equal(1, winnr('$'))
    call assert_equal(l:content_window, win_getid())
endfunction

function! s:RunFernDirectory() abort
    sleep 300m
    call assert_equal('fern', &filetype)
    call assert_equal(2, winnr('$'))
    call assert_true(search('README.md', 'w') > 0)
    call feedkeys("\<CR>", 'xt')
    sleep 300m
    call assert_equal('markdown', &filetype)
    call assert_equal(2, winnr('$'))
    call s:AssertEditorAndExplorer('markdown', 'fern')
    call feedkeys("\<Space>e", 'xt')
    call assert_equal('markdown', &filetype)
    call assert_equal(1, winnr('$'))
endfunction

function! s:RunNetrwToggle() abort
    silent edit README.md
    call feedkeys("\<Space>e", 'xt')
    call assert_equal('netrw', &filetype)
    call assert_equal(2, winnr('$'))
    call feedkeys("\<Space>e", 'xt')
    call assert_equal('markdown', &filetype)
    call assert_equal(1, winnr('$'))
endfunction

function! s:RunNetrwDirectory() abort
    sleep 300m
    call assert_equal('netrw', &filetype)
    call assert_equal(2, winnr('$'))
    call assert_true(search('README.md', 'w') > 0)
    call feedkeys("\<CR>", 'xt')
    sleep 300m
    call assert_equal('markdown', &filetype)
    call assert_equal(2, winnr('$'))
    call s:AssertEditorAndExplorer('markdown', 'netrw')
    call feedkeys("\<Space>e", 'xt')
    call assert_equal('markdown', &filetype)
    call assert_equal(1, winnr('$'))
endfunction

try
    if s:case ==# 'startup'
        call s:RunStartup(0)
    elseif s:case ==# 'auto-lint'
        call s:RunStartup(1)
    elseif s:case ==# 'fern-toggle'
        call s:RunFernToggle()
    elseif s:case ==# 'fern-directory'
        call s:RunFernDirectory()
    elseif s:case ==# 'netrw-toggle'
        call s:RunNetrwToggle()
    elseif s:case ==# 'netrw-directory'
        call s:RunNetrwDirectory()
    else
        call assert_report('unknown plugin test case: ' . s:case)
    endif
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
