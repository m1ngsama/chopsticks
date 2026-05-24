" tutor.vim — guided practice for chopsticks keymaps

function! s:OpenTutor(lines) abort
    let l:name = '__ChopsticksTutor__'
    if bufwinnr(l:name) > 0
        execute bufwinnr(l:name) . 'wincmd w | bd'
        return 0
    endif

    execute 'botright new ' . l:name
    resize 38
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nowrap nonumber norelativenumber signcolumn=no
    call setline(1, a:lines)
    setlocal nomodifiable readonly
    nnoremap <buffer> <silent> q :bd<CR>
    return 1
endfunction

function! s:ChopsticksTutor() abort
    if g:chopsticks_space_keymaps
        let l:lines = [
            \ '  chopsticks tutor        q close',
            \ '  ───────────────────────────────',
            \ '',
            \ '  Goal: train one long-term project loop around Vim.',
            \ '  Keep Vim editing habits; standardize the surrounding work.',
            \ '',
            \ '  1. trained loop',
            \ '     SPC SPC    open a project file',
            \ '     s + 2 chars jump to visible text',
            \ '     gd / gr / K inspect definition / refs / docs',
            \ '     SPC rr     run current file',
            \ '     SPC /      grep project',
            \ '     SPC gs     check git status',
            \ '     SPC ?      active cheat sheet',
            \ '',
            \ '  2. survival',
            \ '     Esc        Normal mode',
            \ '     SPC w      save',
            \ '     SPC qx     save and quit',
            \ '     SPC fc     edit local config',
            \ '     SPC fV     reload config',
            \ '     :ChopsticksHelp    full help',
            \ '     :ChopsticksConfig  local config',
            \ '     :ChopsticksReload  reload config',
            \ '     :ChopsticksStatus  health check',
            \ '     :ChopsticksBeta    beta checklist',
            \ '     :ChopsticksBetaLog beta notes',
            \ '     :ChopsticksBetaSession new note',
            \ '',
            \ '  3. find and switch',
            \ '     SPC SPC    find files',
            \ '     SPC /      grep project',
            \ '     SPC ,      buffers',
            \ '     SPC Tab    alternate buffer',
            \ '     SPC e/E    sidebar cwd / file dir',
            \ '',
            \ '  4. jump and edit',
            \ '     s + 2 chars  visible jump',
            \ '     SPC S        same jump fallback',
            \ '     cl / cc      native s / S substitute',
            \ '     gc           comment',
            \ '     SPC U        undo tree',
            \ '',
            \ '  5. code loop',
            \ '     gd / gr / K  definition / refs / docs',
            \ '     gI / gy      implementation / type',
            \ '     [d ]d        LSP diagnostics',
            \ '     SPC ca/cr/cf action / rename / format',
            \ '     SPC rr       run current file',
            \ '',
            \ '  6. git and windows',
            \ '     SPC gs/gd/gb status / diff / blame',
            \ '     SPC gl       log graph',
            \ '     Ctrl-h/j/k/l split navigation',
            \ '     <C-w>hjkl    native fallback',
            \ '     SPC e, Ctrl-h/l  enter/leave sidebar',
            \ '     SPC z        maximize split',
            \ '',
            \ '  daily drill',
            \ '     Repeat: SPC SPC, s, gd/K, edit, SPC rr, SPC /, SPC gs.',
            \ ]
    else
        let l:lines = [
            \ '  chopsticks tutor        q close',
            \ '  ───────────────────────────────',
            \ '',
            \ '  Goal: train one long-term project loop around Vim.',
            \ '',
            \ '  classic layout',
            \ '     ,?         active cheat sheet',
            \ '     ,w / ,x    save / save and quit',
            \ '     ,ff        find files',
            \ '     ,rg        grep project',
            \ '     ,b         buffers',
            \ '     ,,         alternate buffer',
            \ '',
            \ '  code loop',
            \ '     ,dd / ,dr  definition / refs',
            \ '     ,dk        hover docs',
            \ '     ,ca / ,rn  action / rename',
            \ '     ,f         format',
            \ '     ,cr        run current file',
            \ '',
            \ '  edit and git',
            \ '     ,S + 2 chars  EasyMotion jump',
            \ '     gc            comment',
            \ '     ,u            undo tree',
            \ '     ,gs/,gd/,gb   status / diff / blame',
            \ '     Ctrl-h/j/k/l  split navigation',
            \ '     <C-w>hjkl     native fallback',
            \ '',
            \ '  support',
            \ '     ,ec       edit local config',
            \ '     ,sv       reload config',
            \ '     :ChopsticksHelp    full help',
            \ '     :ChopsticksConfig  local config',
            \ '     :ChopsticksReload  reload config',
            \ '     :ChopsticksStatus  health check',
            \ '     :ChopsticksBeta    beta checklist',
            \ '     :ChopsticksBetaLog beta notes',
            \ '     :ChopsticksBetaSession new note',
            \ '     README.md          full reference',
            \ '     QUICKSTART.md      5-minute path',
            \ ]
    endif

    if s:OpenTutor(l:lines)
        nnoremap <buffer> <silent> ? :ChopsticksCheatSheet<CR>
    endif
endfunction
command! ChopsticksTutor call s:ChopsticksTutor()
