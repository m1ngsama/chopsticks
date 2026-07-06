" core.vim — general settings, basic keymaps, performance, indentation
" filetype/syntax already enabled by plug#end() in plugins.vim

set number
set relativenumber

if !g:is_tty
    set cursorline
endif

set nobackup
set scrolloff=10
set nowrap
set incsearch
set ignorecase
set smartcase
set showcmd
set showmode
set hlsearch
set history=1000
set wildmenu
set wildmode=list:longest
set wildignorecase
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx
set wildignore+=*/node_modules/*,*/.git/*,*/__pycache__/*,*/dist/*,*/build/*
set mouse=a
set encoding=utf-8
set foldmethod=indent
set foldlevel=99
set splitbelow
set splitright
set backspace=indent,eol,start
set nrformats-=octal
set autoread
set cmdheight=1
set hidden
set whichwrap+=<,>,h,l
set magic
set showmatch
set mat=2
set noerrorbells
set novisualbell
set t_vb=
set ttimeout
" Wait long enough on SSH/TTY for multi-byte key codes to arrive intact —
" 10ms fragments F-keys, arrows, and Alt-prefixes when one-way latency > 10ms.
" 50ms is well under perceptible <Esc>→Normal delay locally.
let &ttimeoutlen = g:is_tty ? 50 : 10

if $COLORTERM ==# 'gnome-terminal'
    set t_Co=256
endif

if has("gui_running")
    set guioptions-=T
    set guioptions-=e
    set t_Co=256
    set guitablabel=%M\ %t
endif

set display+=lastline
set ffs=unix,dos,mac
set writebackup

if ChopsticksRuntimeFeatureAvailable('unix')
    let s:swap_dir = expand(get(g:, 'chopsticks_swap_dir', '~/.vim/.swap'))
    let &directory = s:swap_dir . '//,/tmp//'
    call ChopsticksEnsureDir(s:swap_dir, 0700)
endif
set swapfile

if ChopsticksRuntimeFeatureAvailable('persistent_undo')
    set undofile
    let &undodir = expand('~/.vim/.undo')
    call ChopsticksEnsureDir(&undodir, 0700)
endif

" ── Text, Tab and Indent ────────────────────────────────────────────────────

if g:is_tty
    set listchars=tab:>-,trail:.,extends:>,precedes:<,nbsp:_
else
    set listchars=tab:→\ ,trail:·,extends:▸,precedes:◂,nbsp:·
endif

set expandtab
set smarttab
set shiftwidth=4
set tabstop=4
set lbr
set tw=0
set autoindent
set smartindent

" ── Leader ──────────────────────────────────────────────────────────────────

if g:chopsticks_space_keymaps
    let mapleader = "\<Space>"
    let maplocalleader = ","
else
    let mapleader = ","
endif

" ── Basic Keymaps ───────────────────────────────────────────────────────────

if g:chopsticks_space_keymaps
    nnoremap <leader>w :w<cr>
    nnoremap <leader>W :wa<cr>
    nnoremap <leader>q :q<cr>

    nnoremap <silent> <leader>uh :noh<cr>

    nnoremap <leader>fd :lcd %:p:h<cr>:pwd<cr>
else
    nnoremap <leader>w :w<cr>
    nnoremap <leader>q :q<cr>
    nnoremap <leader>x :x<cr>

    nnoremap <silent> <leader><cr> :noh<cr>

    nnoremap <leader>cd :lcd %:p:h<cr>:pwd<cr>
endif

nnoremap <leader>v `[v`]

nnoremap <M-j> :m .+1<CR>==
nnoremap <M-k> :m .-2<CR>==
vnoremap <M-j> :m '>+1<CR>gv=gv
vnoremap <M-k> :m '<-2<CR>gv=gv

if g:chopsticks_space_keymaps
    nnoremap <silent> <leader>us :setlocal spell!<CR>:echo 'Spell: ' . (&spell ? 'ON' : 'OFF')<CR>
else
    nnoremap <silent> <leader>ss :setlocal spell!<CR>:echo 'Spell: ' . (&spell ? 'ON' : 'OFF')<CR>
endif

nnoremap <silent> <F2> :set paste!<CR>:echo 'Paste: ' . (&paste ? 'ON' : 'OFF')<CR>
nnoremap <silent> <F3> :set invnumber<CR>:echo 'Line numbers: ' . (&number ? 'ON' : 'OFF')<CR>
nnoremap <silent> <F4> :set invrelativenumber<CR>:echo 'Relative numbers: ' . (&relativenumber ? 'ON' : 'OFF')<CR>
nnoremap <silent> <F6> :set list!<CR>:echo 'List chars: ' . (&list ? 'ON' : 'OFF')<CR>

if get(g:, 'chopsticks_enable_jk_escape', 0)
    inoremap jk <Esc>
endif

vnoremap < <gv
vnoremap > >gv

nnoremap n nzzzv
nnoremap N Nzzzv

vnoremap <leader>/ y/\V<C-r>=escape(@",'/\')<CR><CR>

if get(g:, 'chopsticks_enable_ctrl_s_save', 0)
    nnoremap <silent> <C-s> :w<CR>
    inoremap <silent> <C-s> <C-o>:w<CR>
endif

nnoremap <C-d> <C-d>zz
vnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
vnoremap <C-u> <C-u>zz

if ChopsticksRuntimeFeatureAvailable('clipboard')
    nnoremap <leader>y "+y
    vnoremap <leader>y "+y
    nnoremap <leader>Y "+Y
    nnoremap <leader>p "+p
    vnoremap <leader>p "+p
    nnoremap <leader>P "+P
    vnoremap <leader>P "+P
endif

if g:chopsticks_space_keymaps
    nnoremap <leader>xq :copen<CR>
    nnoremap <leader>xQ :cclose<CR>
    nnoremap <leader>xl :lopen<CR>
    nnoremap <leader>xL :lclose<CR>
else
    nnoremap <leader>qo :copen<CR>
    nnoremap <leader>qc :cclose<CR>
endif

augroup ChopstickResize
    autocmd!
    autocmd VimResized * wincmd =
augroup END

" ── Performance ─────────────────────────────────────────────────────────────

set synmaxcol=200
set lazyredraw
set complete-=i

if ChopsticksToolAvailable('rg')
    set grepprg=rg\ --vimgrep\ --smart-case
    set grepformat=%f:%l:%c:%m
endif
set updatetime=300
set shortmess+=cI

if g:is_tty
    set signcolumn=auto
    set synmaxcol=120
endif
" non-TTY signcolumn is set in ui.vim (=yes, fixed-width to prevent jitter)

" ── Project-Local Config ────────────────────────────────────────────────────

if get(g:, 'chopsticks_enable_exrc', 0)
    set exrc
    set secure
endif
set sessionoptions=blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal

if has("patch-8.1.0360")
    silent! set diffopt+=internal
    silent! set diffopt+=context:3
    silent! set diffopt+=algorithm:histogram
    silent! set diffopt+=indent-heuristic
endif

" ── Format Options ──────────────────────────────────────────────────────────

augroup ChopstickFormatOptions
    autocmd!
    autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o formatoptions+=j
augroup END

augroup ChopstickPaste
    autocmd!
    autocmd InsertLeave * set nopaste
augroup END

set timeoutlen=500

function! s:LayoutLabel() abort
    return get(g:, 'chopsticks_space_keymaps', 1) ? 'space' : 'classic'
endfunction

function! s:FallbackSurvivalMapSpecs() abort
    if get(g:, 'chopsticks_space_keymaps', 1)
        return [
            \ {'lhs': '<Space>w', 'key': 'SPC w', 'text': ':w'},
            \ {'lhs': '<Space>W', 'key': 'SPC W', 'text': ':wa'},
            \ {'lhs': '<Space>q', 'key': 'SPC q', 'text': ':q'},
            \ {'lhs': '<Space>uh', 'key': 'SPC uh', 'text': ':noh'},
            \ {'lhs': '<Space>fd', 'key': 'SPC fd', 'text': ':lcd'},
            \ ]
    endif

    return [
        \ {'lhs': ',w', 'key': ',w', 'text': ':w'},
        \ {'lhs': ',q', 'key': ',q', 'text': ':q'},
        \ {'lhs': ',x', 'key': ',x', 'text': ':x'},
        \ {'lhs': ',<CR>', 'key': ',<CR>', 'text': ':noh'},
        \ {'lhs': ',cd', 'key': ',cd', 'text': ':lcd'},
        \ ]
endfunction

function! s:FallbackSurvivalKeys() abort
    return get(g:, 'chopsticks_space_keymaps', 1)
        \ ? ['SPC w', 'SPC W', 'SPC q', 'SPC uh', 'SPC fd']
        \ : [',w', ',q', ',x', ',<CR>', ',cd']
endfunction

function! s:SurvivalMapSpecs() abort
    return ChopsticksKeymapContractSpecsOr('core_survival',
        \ s:FallbackSurvivalMapSpecs())
endfunction

function! s:SurvivalReason() abort
    return join(ChopsticksKeymapContractKeysOr('core_survival',
        \ s:FallbackSurvivalKeys()), '/')
endfunction

function! s:VisualSearchKey() abort
    return get(g:, 'chopsticks_space_keymaps', 1) ? '<Space>/' : ',/'
endfunction

function! s:SearchMotionSpecs() abort
    return [
        \ {'mode': 'n', 'lhs': 'n', 'key': 'n', 'text': 'zzzv'},
        \ {'mode': 'n', 'lhs': 'N', 'key': 'N', 'text': 'zzzv'},
        \ {'mode': 'n', 'lhs': '<C-d>', 'key': 'Ctrl-d', 'text': 'zz'},
        \ {'mode': 'n', 'lhs': '<C-u>', 'key': 'Ctrl-u', 'text': 'zz'},
        \ {'mode': 'v', 'lhs': '<C-d>', 'key': 'v Ctrl-d', 'text': 'zz'},
        \ {'mode': 'v', 'lhs': '<C-u>', 'key': 'v Ctrl-u', 'text': 'zz'},
        \ {'mode': 'v', 'lhs': s:VisualSearchKey(),
        \  'key': get(g:, 'chopsticks_space_keymaps', 1) ? 'SPC /' : ',/',
        \  'text': 'escape'},
        \ ]
endfunction

function! s:SpellKey() abort
    return get(g:, 'chopsticks_space_keymaps', 1) ? '<Space>us' : ',ss'
endfunction

function! s:FallbackCoreToggleMapSpecs() abort
    return [
        \ {'mode': 'n', 'lhs': '<F2>', 'key': 'F2', 'text': 'paste'},
        \ {'mode': 'n', 'lhs': '<F3>', 'key': 'F3', 'text': 'number'},
        \ {'mode': 'n', 'lhs': '<F4>', 'key': 'F4',
        \  'text': 'relativenumber'},
        \ {'mode': 'n', 'lhs': '<F6>', 'key': 'F6', 'text': 'list'},
        \ {'mode': 'n', 'lhs': s:SpellKey(),
        \  'key': get(g:, 'chopsticks_space_keymaps', 1) ? 'SPC us' : ',ss',
        \  'text': 'spell'},
        \ ]
endfunction

function! s:FallbackCoreToggleKeys() abort
    return get(g:, 'chopsticks_space_keymaps', 1)
        \ ? ['F2', 'F3', 'F4', 'F6', 'SPC us']
        \ : ['F2', 'F3', 'F4', 'F6', ',ss']
endfunction

function! s:CoreToggleMapSpecs() abort
    return ChopsticksKeymapContractSpecsOr('core_toggles',
        \ s:FallbackCoreToggleMapSpecs())
endfunction

function! s:ToggleReason() abort
    let l:keys = ChopsticksKeymapContractKeysOr('core_toggles',
        \ s:FallbackCoreToggleKeys())
    if len(l:keys) >= 5
        return join(l:keys[0:3], '/') . ' + ' . l:keys[4]
    endif
    return join(l:keys, '/')
endfunction

function! s:ExpectedTtimeoutlen() abort
    return get(g:, 'is_tty', 0) ? 50 : 10
endfunction

function! s:ExpectedSynmaxcol() abort
    return get(g:, 'is_tty', 0) ? 120 : 200
endfunction

function! s:ListHasOption(value, option) abort
    return index(split(a:value, ','), a:option) >= 0
endfunction

function! s:GrepAdapter() abort
    if ChopsticksToolAvailable('rg')
        return &grepprg =~# '^rg\>' ? 'rg' : 'rg not active'
    endif
    return 'default'
endfunction

function! s:EditorDefaultsItem() abort
    let l:ready = &number
        \ && &relativenumber
        \ && &scrolloff == 10
        \ && &hidden
        \ && &splitbelow
        \ && &splitright
        \ && &autoread
        \ && &encoding ==# 'utf-8'
    if l:ready
        return ChopsticksInfoItem('editor defaults', 'ready',
            \ 'numbers/splits/buffers', {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('editor defaults', 'missing',
        \ 'baseline options changed', 'editor defaults',
        \ 'reload chopsticks or review local option overrides', {
        \   'detail': 'baseline editor options are not active',
        \ })
endfunction

function! s:SurvivalMapsItem() abort
    let l:missing = ChopsticksKeymapMissingKeys(s:SurvivalMapSpecs())
    if empty(l:missing)
        return ChopsticksInfoItem('survival maps', 'ready',
            \ s:SurvivalReason(), {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('survival maps', 'missing',
        \ 'missing: ' . join(l:missing, ', '), 'survival maps',
        \ ':ChopsticksKeymapAudit', {
        \   'detail': 'missing survival maps: ' . join(l:missing, ', '),
        \ })
endfunction

function! s:SearchMotionItem() abort
    let l:missing = ChopsticksKeymapMissingKeys(s:SearchMotionSpecs())
    if empty(l:missing)
        return ChopsticksInfoItem('search motion', 'ready',
            \ 'centered search/scroll', {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('search motion', 'missing',
        \ 'center maps changed', 'search motion',
        \ ':ChopsticksKeymapAudit', {
        \   'detail': 'centered search, scroll, or visual-search maps are missing',
        \ })
endfunction

function! s:CoreTogglesItem() abort
    let l:missing = ChopsticksKeymapMissingKeys(s:CoreToggleMapSpecs())
    if empty(l:missing)
        return ChopsticksInfoItem('core toggles', 'ready',
            \ s:ToggleReason(), {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('core toggles', 'missing',
        \ 'missing: ' . join(l:missing, ', '), 'core toggles',
        \ ':ChopsticksKeymapAudit', {
        \   'detail': 'missing core toggle maps: ' . join(l:missing, ', '),
        \ })
endfunction

function! s:PersistenceItem() abort
    let l:swap_dir = expand(get(g:, 'chopsticks_swap_dir', '~/.vim/.swap'))
    let l:swap_ready = !ChopsticksRuntimeFeatureAvailable('unix')
        \ || stridx(&directory, l:swap_dir) >= 0
    let l:undo_ready = !ChopsticksRuntimeFeatureAvailable('persistent_undo')
        \ || &undofile
    let l:ready = &swapfile && &writebackup && l:swap_ready && l:undo_ready
    if l:ready
        return ChopsticksInfoItem('persistence', 'ready',
            \ ChopsticksRuntimeFeatureAvailable('persistent_undo')
            \ ? 'swap/writebackup/undo' : 'swap/writebackup',
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('persistence', 'missing',
        \ 'swap/writebackup/undo changed', 'persistence',
        \ 'reload chopsticks or review local file-safety overrides', {
        \   'detail': 'swap, writebackup, or persistent undo defaults are not active',
        \ })
endfunction

function! s:PerformanceItem() abort
    let l:ready = &timeoutlen == 500
        \ && &ttimeout
        \ && &ttimeoutlen == s:ExpectedTtimeoutlen()
        \ && &lazyredraw
        \ && !s:ListHasOption(&complete, 'i')
        \ && &synmaxcol == s:ExpectedSynmaxcol()
        \ && (!ChopsticksToolAvailable('rg') || &grepprg =~# '^rg\>')
    if l:ready
        return ChopsticksInfoItem('performance', 'ready',
            \ get(g:, 'is_tty', 0) ? 'TTY timing' : 'rich timing',
            \ {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('performance', 'missing',
        \ 'timing/search defaults changed', 'performance',
        \ 'reload chopsticks or review local performance overrides', {
        \   'detail': 'timing, completion scan, synmaxcol, or grep defaults changed',
        \ })
endfunction

function! s:AutocmdHygieneItem() abort
    let l:ready = exists('#ChopstickResize#VimResized#*')
        \ && exists('#ChopstickFormatOptions#FileType#*')
        \ && exists('#ChopstickPaste#InsertLeave#*')
    if l:ready
        return ChopsticksInfoItem('autocmd hygiene', 'ready',
            \ 'resize/format/paste', {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('autocmd hygiene', 'missing',
        \ 'missing core autocmds', 'autocmd hygiene',
        \ 'reload chopsticks', {
        \   'detail': 'resize, formatoptions, or paste-reset autocmds are missing',
        \ })
endfunction

function! s:ProjectLocalConfigItem() abort
    if !get(g:, 'chopsticks_enable_exrc', 0)
        return ChopsticksInfoItem('project-local config', 'off',
            \ 'disabled by default', {'diagnostic': 0})
    endif
    if &exrc && &secure
        return ChopsticksInfoItem('project-local config', 'ready',
            \ 'exrc+secure', {'diagnostic': 0})
    endif
    return ChopsticksInfoDiagnosticItem('project-local config', 'missing',
        \ 'exrc opt-in incomplete', 'project-local config',
        \ 'reload chopsticks after setting g:chopsticks_enable_exrc', {
        \   'detail': 'g:chopsticks_enable_exrc is set but exrc/secure are not active',
        \ })
endfunction

function! ChopsticksCoreInfo() abort
    return ChopsticksInfoSection('editor core', {
        \ 'layout': s:LayoutLabel(),
        \ 'timing': 'timeout=' . &timeoutlen
        \     . ' ttimeout=' . &ttimeoutlen . 'ms',
        \ 'grep': s:GrepAdapter(),
        \ 'details': [
        \   ChopsticksInfoDetail('layout', s:LayoutLabel()),
        \   ChopsticksInfoDetail('timing',
        \       'timeout=' . &timeoutlen
        \       . ' ttimeout=' . &ttimeoutlen . 'ms'),
        \   ChopsticksInfoDetail('grep', s:GrepAdapter()),
        \ ],
        \ 'items': [
        \   s:EditorDefaultsItem(),
        \   s:SurvivalMapsItem(),
        \   s:SearchMotionItem(),
        \   s:CoreTogglesItem(),
        \   s:PersistenceItem(),
        \   s:PerformanceItem(),
        \   s:AutocmdHygieneItem(),
        \   s:ProjectLocalConfigItem(),
        \ ],
        \ })
endfunction
