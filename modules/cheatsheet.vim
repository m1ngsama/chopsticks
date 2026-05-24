" cheatsheet.vim — active keymap reference

function! s:OpenCheatSheet(lines) abort
    let l:name = '__ChopsticksCheatSheet__'
    if bufwinnr(l:name) > 0
        execute bufwinnr(l:name) . 'wincmd w | bd'
        return
    endif

    execute 'vertical botright new ' . l:name
    vertical resize 42
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nowrap nonumber norelativenumber signcolumn=no
    setlocal winfixwidth
    call setline(1, a:lines)
    setlocal nomodifiable readonly
    nnoremap <buffer> <silent> q :bd<CR>
    nnoremap <buffer> <silent> <leader>? :bd<CR>
endfunction

function! s:CheatSheet() abort
    let l:has_lsp = get(g:, 'chopsticks_enable_lsp', 1)
    let l:has_lint = get(g:, 'chopsticks_enable_lint', 1)
    let l:has_undotree = exists('g:plugs["undotree"]')
    let l:has_previm = exists('g:plugs["previm"]')

    if g:chopsticks_space_keymaps
        let l:lines = [
            \ '  chopsticks         <Space>? close',
            \ '  ─────────────────────────────────',
            \ '',
            \ '  trained loop:',
            \ '  files → s jump → gd/K',
            \ '  run → grep → git',
            \ '',
            \ '  ── fast path ─────────────',
            \ '  SPC SPC   files',
            \ '  SPC ,     buffers',
            \ '  SPC /     grep project',
            \ '  SPC Tab   last file',
            \ '  SPC e     sidebar (cwd)',
            \ '  SPC E     sidebar (file dir)',
            \ '',
            \ '  ── files/find ────────────',
            \ '  SPC ff    files',
            \ '  SPC fb    buffers',
            \ '  SPC fg    git files',
            \ '  SPC fr    recent files',
            \ '  SPC fl    lines in buffer',
            \ '  SPC sc    commands',
            \ '  SPC sm    marks',
            \ '  SPC s/    search history',
            \ '  SPC s:    command history',
            \ '  SPC sg    grep project',
            \ '  SPC sw    grep word',
            \ '  SPC st    tags',
            \ '',
            \ '  ── code ──────────────────',
            \ ]

        if l:has_lsp
            call extend(l:lines, [
                \ '  gd        definition',
                \ '  gr        references',
                \ '  gI        implementation',
                \ '  gy        type definition',
                \ '  K         hover docs',
                \ '  [d ]d     LSP diagnostics',
                \ '  SPC ca    code action',
                \ '  SPC cr    rename',
                \ '  SPC cf    format',
                \ '  SPC ci    LSP status',
                \ '  SPC co    outline',
                \ '  SPC cS    workspace symbols',
                \ '  :LspInstallServer  setup LSP',
                \ '  :ChopsticksStatus   check LSP setup',
                \ ])
        endif

        call extend(l:lines, [
            \ '  SPC rr    run file',
            \ '  SPC cW    strip trailing',
            \ '  SPC c=    re-indent file  (opt-in)',
            \ '  SPC =     re-indent       (v)',
            \ ])
        if l:has_previm
            call add(l:lines, '  ,mp       markdown preview')
        endif
        call add(l:lines, '  ,mt       table of contents')

        if l:has_lint
            call extend(l:lines, [
                \ '  [e ]e     ALE errors',
                \ '  SPC xd    ALE detail',
                \ '  SPC uf    format on save',
                \ ])
        endif

        call extend(l:lines, [
            \ '',
            \ '  ── edit ──────────────────',
            \ '  s+2ch     easymotion jump',
            \ '  gc        comment',
            \ '  cl / cc   native s / S substitute',
            \ '  SPC S+2ch jump fallback',
            \ '  cs"''      surround',
            \ ])

        if l:has_undotree
            call add(l:lines, '  SPC U     undo tree')
        endif

        call extend(l:lines, [
            \ '  SPC y/p   clipboard y/p  (v)',
            \ '  Alt+j/k   move line      (v)',
            \ '  SPC sr    replace word    (v)',
            \ '',
            \ '  ── git ───────────────────',
            \ '  SPC gs    status',
            \ '  SPC gd    diff',
            \ '  SPC gb    blame',
            \ '  SPC gc    commit',
            \ '  SPC gl    log graph',
            \ '  SPC gC    FZF commits',
            \ '  SPC gB    FZF buffer commits',
            \ '  [x ]x     conflict markers',
            \ '',
            \ '  ── windows ───────────────',
            \ '  Ctrl-hjkl windows',
            \ '  <C-w>hjkl native fallback',
            \ '  SPC bp/bn prev / next buf',
            \ '  SPC bd    close buffer',
            \ '  SPC bo    close other buffers',
            \ '  SPC z     maximize toggle',
            \ '  SPC tt/th terminal / split',
            \ '  ]q [q     next / prev qf',
            \ '  SPC xq/xQ open / close qf',
            \ '  SPC xl/xL open / close loclist',
            \ '',
            \ '  ── toggle ────────────────',
            \ '  F2        paste mode',
            \ '  F3        line numbers',
            \ '  F4        relative numbers',
            \ '  F6        invisible chars',
            \ '  SPC us    spell check',
            \ '',
            \ '  ── survival ──────────────',
            \ '  SPC w     save',
            \ '  SPC W     save all',
            \ '  SPC qq    quit',
            \ '  SPC qx    save + quit',
            \ '  Esc       exit insert',
            \ '  SPC fc    edit local config',
            \ '  SPC fv    edit vimrc',
            \ '  SPC fV    reload vimrc',
            \ '  :ChopsticksHelp    full help',
            \ '  :ChopsticksConfig  local config',
            \ '  :ChopsticksReload  reload config',
            \ '  :ChopsticksTutor   practice',
            \ '  :ChopsticksStatus  health',
            \ '  :ChopsticksBeta    beta test guide',
            \ '  :ChopsticksBetaLog beta notes',
            \ '  :ChopsticksBetaSession new beta note',
            \ ])

        call s:OpenCheatSheet(l:lines)
        return
    endif

    let l:lines = [
        \ '  chopsticks         ,? close',
        \ '  ─────────────────────────────',
        \ '',
        \ '  trained loop:',
        \ '  files → jump → inspect',
        \ '  run → grep → git',
        \ '',
        \ '  ── files ──────────────────',
        \ '  ,ff       files',
        \ '  ,b        buffers',
        \ '  ,rg       grep project',
        \ '  ,rG       grep word',
        \ '  ,e        sidebar (cwd)',
        \ '  ,E        sidebar (file dir)',
        \ '  ,,        last file',
        \ '  ,fh       recent files',
        \ '  ,fl       lines in buffer',
        \ '  ,fc       commands',
        \ '  ,fm       marks',
        \ '',
        \ '  ── code ──────────────────',
        \ ]

    if l:has_lsp
        call extend(l:lines, [
            \ '  ,dd       definition',
            \ '  ,dt       type definition',
            \ '  ,di       implementation',
            \ '  ,dr       references',
            \ '  ,dk       hover docs',
            \ '  ,rn       rename',
            \ '  ,ca       code action',
            \ '  ,f        format',
            \ '  ,o        outline',
            \ '  ,dp ,dn   LSP diagnostics',
            \ '  :LspInstallServer  setup LSP',
            \ '  :ChopsticksStatus   check LSP setup',
            \ ])
    endif

    call add(l:lines, '  ,cr       run file')
    if l:has_previm
        call add(l:lines, '  ,mp       markdown preview')
    endif
    call add(l:lines, '  ,mt       table of contents')

    if l:has_lint
        call extend(l:lines, [
            \ '  [e ]e     ALE errors',
            \ '  ,af       format on save',
            \ ])
    endif

    call extend(l:lines, [
        \ '',
        \ '  ── edit ──────────────────',
        \ '  gc        comment',
        \ '  ,S+2ch    easymotion jump',
        \ '  cs"''      surround',
        \ ])

    if l:has_undotree
        call add(l:lines, '  ,u        undo tree')
    endif

    call extend(l:lines, [
        \ '  ,y ,p     clipboard y/p  (v)',
        \ '  Alt+j/k   move line      (v)',
        \ '  ,*        replace word    (v)',
        \ '  ,F        re-indent       (v)',
        \ '  ,W        strip trailing',
        \ '',
        \ '  ── git ───────────────────',
        \ '  ,gs       status',
        \ '  ,gd       diff',
        \ '  ,gb       blame',
        \ '  ,gc       commit',
        \ '  ,gL       log graph',
        \ '  ,gC       FZF commits',
        \ '  [x ]x     conflict markers',
        \ '',
        \ '  ── windows ───────────────',
        \ '  Ctrl-hjkl windows',
        \ '  <C-w>hjkl native fallback',
        \ '  ,h ,l     prev / next buf',
        \ '  ,bd       close buffer',
        \ '  ,z        maximize toggle',
        \ '  ,= ,-     resize height',
        \ '  ,tv ,th   terminal v / h',
        \ '  ]q [q     next / prev qf',
        \ '  ,qo ,qc   open / close qf',
        \ '',
        \ '  ── toggle ────────────────',
        \ '  F2        paste mode',
        \ '  F3        line numbers',
        \ '  F4        relative numbers',
        \ '  F6        invisible chars',
        \ '  ,ss       spell check',
        \ '',
        \ '  ── survival ──────────────',
        \ '  ,w        save',
        \ '  ,q        quit',
        \ '  ,x        save + quit',
        \ '  Esc       exit insert',
        \ '  ,ec       edit local config',
        \ '  ,ev       edit vimrc',
        \ '  ,sv       reload vimrc',
        \ '  :ChopsticksHelp    full help',
        \ '  :ChopsticksConfig  local config',
        \ '  :ChopsticksReload  reload config',
        \ '  :ChopsticksTutor   practice',
        \ '  :ChopsticksStatus  health',
        \ '  :ChopsticksBeta    beta test guide',
        \ '  :ChopsticksBetaLog beta notes',
        \ '  :ChopsticksBetaSession new beta note',
        \ ])

    call s:OpenCheatSheet(l:lines)
endfunction
command! ChopsticksCheatSheet call s:CheatSheet()
nnoremap <silent> <leader>? :ChopsticksCheatSheet<CR>
