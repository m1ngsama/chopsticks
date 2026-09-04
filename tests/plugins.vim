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

function! s:RunStartup(expected_auto_lint) abort
    silent edit README.md
    tnoremap <Esc><Esc> <C-\><C-n>
    execute 'source ' . fnameescape(s:root . '/.vimrc')
    let l:key_lines = ChopsticksKeyLines()
    execute 'source ' . fnameescape(s:root . '/.vimrc')
    doautocmd VimEnter
    call assert_equal('0.2.0', get(g:, 'chopsticks_version', ''))
    for l:command in [
        \ 'ChopsticksHealth', 'ChopsticksCheatsheet',
        \ 'ChopsticksFindFiles', 'ChopsticksIconsToggle',
        \ 'ChopsticksUiDensity', 'ChopsticksTransparencyToggle',
        \ 'ChopsticksSessionSave', 'ChopsticksSessionLoad',
        \ 'MarkdownPasteImage',
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
    call assert_equal(0, get(g:, 'lsp_settings_lazyload', -1))
    if get(g:, 'loaded_lsp_settings', 0)
        call assert_false(exists('#vim_lsp_settings_initialize#VimEnter'))
        call assert_true(exists('#vim_lsp_settings_lazy#FileType'))
    endif
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
    call assert_match('FindFiles', maparg(';f', 'n'))
    call assert_match('ChopsticksProjectGrep', maparg(';r', 'n'))
    call assert_match('chopsticks#find#GitFiles', maparg("\<Space>fg", 'n'))
    call assert_equal('edit', get(g:fzf_action, 'ctrl-o', ''))
    call assert_equal('', maparg("\<Esc>\<Esc>", 't'))
    call assert_match('TableModeToggle', maparg(',tt', 'n'))
    call assert_match('ALELint', maparg(',l', 'n'))
    call assert_equal(l:key_lines, ChopsticksKeyLines())
    call assert_true(len(ChopsticksKeyLines()) >= 100)
    call assert_match('Esc / Ctrl-q', join(ChopsticksKeyLines(), "\n"))
    call assert_match('Fern q / Esc', join(ChopsticksKeyLines(), "\n"))
    call s:AssertWhichKeyGroupSyntax()
    call s:AssertEverforestSemanticColors()
    call s:AssertDiagnosticsPresentation()
    call s:AssertGitDiffPresentation()
    call s:AssertGitBranchPresentation()
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
