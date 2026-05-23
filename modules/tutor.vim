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
            \ '  1. survival',
            \ '     Esc        Normal mode',
            \ '     SPC ?      active cheat sheet',
            \ '     SPC w      save',
            \ '     SPC qx     save and quit',
            \ '     :ChopsticksHelp    full help',
            \ '     :ChopsticksStatus  health check',
            \ '     :ChopsticksBeta    beta checklist',
            \ '     :ChopsticksBetaLog beta notes',
            \ '     :ChopsticksBetaSession new note',
            \ '',
            \ '  2. find and switch',
            \ '     SPC SPC    find files',
            \ '     SPC /      grep project',
            \ '     SPC ,      buffers',
            \ '     SPC Tab    alternate buffer',
            \ '     SPC e/E    sidebar cwd / file dir',
            \ '',
            \ '  3. jump and edit',
            \ '     s + 2 chars  visible jump',
            \ '     SPC S        same jump fallback',
            \ '     cl / cc      native s / S substitute',
            \ '     gc           comment',
            \ '     SPC U        undo tree',
            \ '',
            \ '  4. code loop',
            \ '     gd / gr / K  definition / refs / docs',
            \ '     gI / gy      implementation / type',
            \ '     [d ]d        LSP diagnostics',
            \ '     SPC ca/cr/cf action / rename / format',
            \ '     SPC rr       run current file',
            \ '',
            \ '  5. git and windows',
            \ '     SPC gs/gd/gb status / diff / blame',
            \ '     SPC gl       log graph',
            \ '     <C-w>hjkl    split navigation',
            \ '     SPC z        maximize split',
            \ '',
            \ '  daily drill',
            \ '     Open a project, run SPC SPC, jump with s, inspect with gd/K,',
            \ '     edit with gc/SPC cf, check SPC gs, then save with SPC w.',
            \ ]
    else
        let l:lines = [
            \ '  chopsticks tutor        q close',
            \ '  ───────────────────────────────',
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
            \ '     <C-w>hjkl     split navigation',
            \ '',
            \ '  support',
            \ '     :ChopsticksHelp    full help',
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
