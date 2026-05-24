" beta.vim — in-editor release-candidate checklist

let g:chopsticks_beta_label = get(g:, 'chopsticks_beta_label', '2.3.0')

function! s:OpenBetaGuide() abort
    let l:name = '__ChopsticksBeta__'
    if bufwinnr(l:name) > 0
        execute bufwinnr(l:name) . 'wincmd w | bd'
        return
    endif

    execute 'botright new ' . l:name
    resize 34
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nowrap nonumber norelativenumber signcolumn=no

    let l:lines = [
        \ '  chopsticks 2.3.0      q close',
        \ '  ─────────────────────────────',
        \ '',
        \ '  goal',
        \ '     Prove this can be the long-term project loop.',
        \ '     Record real editing friction before release.',
        \ '',
        \ '  daily loop',
        \ '     SPC SPC   find file',
        \ '     s + 2ch   jump on screen',
        \ '     gd / gr   definition / references',
        \ '     K         hover docs',
        \ '     SPC /     grep project',
        \ '     SPC rr    run current file',
        \ '     SPC gs    git status',
        \ '     SPC cf    format',
        \ '     SPC ?     active cheat sheet',
        \ '     :ChopsticksBetaSession  new note block',
        \ '',
        \ '  record',
        \ '     task: project navigation, code, grep, git, LSP, Markdown, SSH',
        \ '     first key tried when stuck',
        \ '     whether SPC ?, :ChopsticksTutor, or :ChopsticksStatus answered it',
        \ '     any key that felt slow, awkward, surprising, or easy to mistype',
        \ '',
        \ '  exit criteria',
        \ '     s as jump still feels worth the native override',
        \ '     no high-frequency action needs an undocumented key',
        \ '     window/sidebar navigation beats native <C-w> only',
        \ '     README, QUICKSTART, SPC ?, and tutor teach the same layout',
        \ '     no private wiki is needed to remember the daily loop',
        \ '     quick/vim tests pass locally and over SSH',
        \ '',
        \ '  files',
        \ '     BETA.md        release checklist and rollback',
        \ '     :ChopsticksBetaLog      editable local release notes',
        \ '     :ChopsticksBetaSession  append a new session block',
        \ '     QUICKSTART.md  five-minute path',
        \ '     README.md      complete reference',
        \ ]

    call setline(1, l:lines)
    setlocal nomodifiable readonly
    nnoremap <buffer> <silent> q :bd<CR>
    nnoremap <buffer> <silent> ? :ChopsticksCheatSheet<CR>
endfunction

function! s:BetaLogPath() abort
    let l:configured = get(g:, 'chopsticks_beta_log', '')
    if !empty(l:configured)
        return expand(l:configured)
    endif

    let l:xdg = !empty($XDG_CONFIG_HOME) && $XDG_CONFIG_HOME =~# '^/'
        \ ? $XDG_CONFIG_HOME
        \ : '~/.config'
    return expand(l:xdg . '/chopsticks-2.3.0.md')
endfunction

function! s:SessionBlock() abort
    return [
        \ '',
        \ '## ' . strftime('%Y-%m-%d %H:%M'),
        \ '',
        \ '- Task:',
        \ '- First key tried when stuck:',
        \ '- Did SPC ?, :ChopsticksTutor, or :ChopsticksStatus answer it:',
        \ '- Friction:',
        \ '- Decision:',
        \ ]
endfunction

function! s:EnsureBetaLog(path) abort
    let l:path = a:path
    let l:dir = fnamemodify(l:path, ':h')
    if !isdirectory(l:dir)
        call mkdir(l:dir, 'p')
    endif

    if !filereadable(l:path)
        call writefile([
            \ '# chopsticks 2.3.0 release log',
            \ '',
            \ 'Use :ChopsticksBeta for the release checklist. Keep one session block per real editing session.',
            \ ] + s:SessionBlock(), l:path)
    endif
endfunction

function! s:OpenBetaLog() abort
    let l:path = s:BetaLogPath()
    call s:EnsureBetaLog(l:path)
    execute 'edit ' . fnameescape(l:path)
    setlocal filetype=markdown
endfunction

function! s:AppendBetaSession() abort
    let l:path = s:BetaLogPath()
    call s:EnsureBetaLog(l:path)
    call writefile(s:SessionBlock(), l:path, 'a')
    execute 'edit ' . fnameescape(l:path)
    setlocal filetype=markdown
    normal! G
endfunction

command! ChopsticksBeta call s:OpenBetaGuide()
command! ChopsticksBetaLog call s:OpenBetaLog()
command! ChopsticksBetaSession call s:AppendBetaSession()
