set encoding=utf-8
scriptencoding utf-8

if has('nvim') || !has('patch-9.1.1947')
    echoerr 'chopsticks needs Vim 9.1.1947 or newer'
    finish
endif
let g:chopsticks_startup_started_at = reltime()
set t_RV= t_u7= t_RF= t_RB= ambiwidth=single
execute 'set runtimepath^=' . fnameescape(fnamemodify(resolve(expand('<sfile>:p')), ':h'))

let g:mapleader = "\<Space>"
let g:maplocalleader = ','

let g:chopsticks_data = expand(has('win32') ? '~/vimfiles' : '~/.vim')
let s:remote = !empty($SSH_CONNECTION) || !empty($SSH_CLIENT) || !empty($SSH_TTY)
if has('clipboard') && !s:remote
    \ && (has('mac') || has('win32') || !empty($DISPLAY) || !empty($WAYLAND_DISPLAY))
    execute 'set clipboard^=' . (has('unnamedplus') ? 'unnamedplus' : 'unnamed')
endif

let g:fern#renderer = chopsticks#ui#icons#Enabled() ? 'nerdfont' : 'default'
let g:fern#renderer#nerdfont#indent_markers = 1
let g:fern#renderer#nerdfont#leading = '  '
let g:fern#renderer#nerdfont#padding = ' '
let g:fern#renderer#nerdfont#root_symbol =
    \ chopsticks#ui#icons#Get('folder_open')
let g:fern#mark_symbol = chopsticks#ui#icons#Get('marker')
let g:fern#drawer_width = 34
let g:fern#hide_cursor = 1
let g:fern#default_hidden = 1
let g:fern#default_exclude =
    \ '^\%(\.git\|node_modules\|\.venv\|__pycache__\|dist\|build\|target\)$'
let g:fern_git_status#disable_ignored = 1

let g:surround_no_insert_mappings = 1
let g:gitgutter_map_keys = 0
let g:gitgutter_terminal_reports_focus = 0
let g:EasyMotion_do_mapping = 0

let g:which_key_vertical = 0
let g:which_key_hspace = 5
let g:which_key_centered = 1
let g:which_key_sep = '→'
let g:which_key_ignore_outside_mappings = 1

let g:netrw_liststyle = 3
let g:netrw_banner = 0
let g:netrw_browse_split = 4
let g:netrw_winsize = 25
let g:netrw_altv = 1
let g:netrw_keepdir = 0
let g:netrw_list_hide = '\(^\|\s\s\)\zs\.\S\+'
let g:netrw_list_hide .= ',\.pyc$,node_modules,\.git,__pycache__,\.DS_Store,dist,build'

let g:vsnip_snippet_dir = g:chopsticks_data . '/vsnip'

let g:fuzzbox_mappings = 0
let g:fuzzbox_preview = !s:remote
let g:fuzzbox_devicons = chopsticks#ui#icons#Enabled()
let g:fuzzbox_borderchars = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
let g:fuzzbox_keymaps = {'exit': ["\<Esc>", "\<C-c>", "\<C-g>", "\<C-q>"]}
let g:fuzzbox_window_defaults = {'width': 0.92, 'height': 0.84}

let g:fuzzbox_files_exclude_dir = [
    \ '.git/', '.cache/', '.cargo/', '.npm/', '.pnpm-store/', '.rustup/',
    \ '.bun/', '.codex/', 'Library/', 'node_modules/', 'plugged/',
    \ '.venv/', 'venv/', '__pycache__/', 'build/', 'dist/', 'target/', 'vendor/',
    \ ]

let g:ale_disable_lsp = 1
let g:ale_linters_explicit = 1
let g:ale_linters = {
    \ 'javascript': ['eslint'],
    \ 'typescript': ['eslint'],
    \ 'go': ['staticcheck'],
    \ 'python': ['ruff'],
    \ 'rust': ['cargo'],
    \ 'sh': ['shellcheck'],
    \ 'markdown': ['markdownlint', 'vale'],
    \ }
let g:ale_rust_cargo_use_clippy = executable('cargo-clippy') == 1
let g:ale_fixers = {
    \ '*': ['remove_trailing_lines', 'trim_whitespace'],
    \ 'javascript': ['prettier', 'eslint'],
    \ 'typescript': ['prettier', 'eslint'],
    \ 'go': ['goimports'],
    \ 'python': ['ruff_format'],
    \ 'rust': ['rustfmt'],
    \ 'json': ['prettier'],
    \ 'yaml': ['prettier'],
    \ 'html': ['prettier'],
    \ 'css': ['prettier'],
    \ 'scss': ['prettier'],
    \ 'less': ['prettier'],
    \ 'markdown': ['prettier'],
    \ }
let g:ale_fix_on_save = 0
let g:ale_lint_on_save = 0
let g:ale_lint_on_enter = 0
let g:ale_lint_on_filetype_changed = 0
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_virtualtext_cursor = 'disabled'
let g:ale_echo_msg_format = '%severity%: %s'
let g:ale_sign_error = chopsticks#ui#icons#Get('error')
let g:ale_sign_warning = chopsticks#ui#icons#Get('warning')
let g:ale_sign_info = chopsticks#ui#icons#Get('info')

let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_toml_frontmatter = 1
let g:vim_markdown_json_frontmatter = 1
let g:vim_markdown_follow_anchor = 1
let g:vim_markdown_strikethrough = 1
let g:vim_markdown_math = 1
let g:vim_markdown_auto_insert_bullets = 0
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_fenced_languages = [
    \ 'bash=sh', 'c++=cpp', 'css', 'go', 'html', 'javascript', 'json',
    \ 'python', 'ruby', 'rust', 'sql', 'typescript', 'viml=vim', 'yaml',
    \ ]

let g:pencil#wrapModeDefault = 'soft'
let g:pencil#conceallevel = 0
let g:pencil#cursorwrap = 0
let g:pencil#mode_indicators = {'hard': 'H', 'auto': 'A', 'soft': 'S', 'off': ''}

augroup pencil_autoformat
    autocmd!
augroup END
augroup pencil_cursorwrap
    autocmd!
augroup END

let g:bullets_enabled_file_types = ['markdown', 'text', 'gitcommit']
let g:bullets_set_mappings = 0
let g:bullets_renumber_on_change = 1
let g:bullets_nested_checkboxes = 1
let g:bullets_checkbox_markers = ' .oOX'

let g:table_mode_disable_mappings = 1
let g:table_mode_disable_tableize_mappings = 1
let g:table_mode_corner = '|'

let g:previm_enable_realtime = 1
let g:previm_wsl_mode = executable('wslview') == 1
let g:previm_open_cmd = has('mac') ? 'open' : has('win32') ? 'rundll32 url.dll,FileProtocolHandler'
    \ : g:previm_wsl_mode ? 'wslview' : 'xdg-open'

let g:goyo_width = 96
let g:goyo_height = '90%'
let g:goyo_linenr = 0
let g:limelight_default_coefficient = 0.7
let g:limelight_paragraph_span = 1
let g:limelight_priority = -1

call plug#begin(g:chopsticks_data . '/plugged')

Plug 'vim-fuzzbox/fuzzbox.vim', {'commit': '4f9f653158b1d27e6217c97a9da6fbcc00c31cb3'}
Plug 'lambdalisue/vim-fern', {'commit': '3bbca3c87a57cdc87495b91a695b8eda722a1de1'}
Plug 'lambdalisue/vim-nerdfont', {'commit': '3a28b3f061a8b6de751175cc3f91f072d4bfc811'}
Plug 'lambdalisue/vim-fern-renderer-nerdfont', {'commit': '325629c68eb543229715b68920fbcb92b206beb6'}
Plug 'lambdalisue/vim-glyph-palette', {'commit': '675f0ad64e2c4b823bffc1907d469deefaf6e3bd'}
Plug 'lambdalisue/vim-fern-git-status', {'commit': '151336335d3b6975153dad77e60049ca7111da8e'}
Plug 'tpope/vim-vinegar', {'commit': 'bb1bcddf43cfebe05eb565a84ab069b357d0b3d6'}
Plug 'easymotion/vim-easymotion', {'commit': 'b3cfab2a6302b3b39f53d9fd2cd997e1127d7878', 'on': '<Plug>(easymotion'}

Plug 'tpope/vim-fugitive', {'commit': '3b753cf8c6a4dcde6edee8827d464ba9b8c4a6f0'}
Plug 'tpope/vim-rhubarb', {'commit': '5496d7c94581c4c9ad7430357449bb57fc59f501'}
Plug 'airblade/vim-gitgutter', {'commit': '90b75207bd9b55d8ac4af15f72b4e935462014d0'}
Plug 'tpope/vim-dispatch', {'commit': 'a2ff28abdb2d89725192db5b8562977d392a4d3f'}

Plug 'tpope/vim-surround', {'commit': '3d188ed2113431cf8dac77be61b842acb64433d9'}
Plug 'tpope/vim-commentary', {'commit': '64a654ef4a20db1727938338310209b6a63f60c9'}
Plug 'tpope/vim-repeat', {'commit': '65846025c15494983dafe5e3b46c8f88ab2e9635'}
Plug 'tpope/vim-sleuth', {'commit': 'be69bff86754b1aa5adcbb527d7fcd1635a84080'}
Plug 'tpope/vim-abolish', {'commit': 'dcbfe065297d31823561ba787f51056c147aa682'}
Plug 'tpope/vim-speeddating', {'commit': 'c17eb01ebf5aaf766c53bab1f6592710e5ffb796'}
Plug 'wellle/targets.vim', {'commit': '6325416da8f89992b005db3e4517aaef0242602e'}
Plug 'jiangmiao/auto-pairs', {'commit': '39f06b873a8449af8ff6a3eee716d3da14d63a76'}
Plug 'mbbill/undotree', {'commit': '6fa6b57cda8459e1e4b2ca34df702f55242f4e4d', 'on': 'UndotreeToggle'}

Plug 'dense-analysis/ale', {'commit': '199a95d386cb856c27e5b90d4e3ea8bd45a58c23'}
Plug 'yegappan/lsp', {'commit': 'e38a68d3de2e6afe45139fcaa6814eec69f3f8fe'}
Plug 'hrsh7th/vim-vsnip', {'commit': '9bcfabea653abdcdac584283b5097c3f8760abaa'}
Plug 'hrsh7th/vim-vsnip-integ', {'commit': 'c7c93934dece8315db3649bdc6898b76358a8b8d'}

Plug 'preservim/vim-markdown', {'commit': '1bc9d0cd8e1cc3e901b0a49c2b50a843f1c89397', 'for': 'markdown'}
Plug 'preservim/vim-pencil', {'commit': '6d70438a8886eaf933c38a7a43a61adb0a7815ed'}
Plug 'bullets-vim/bullets.vim', {'commit': '81570b98ca44b4100b3ddcf8d9ca74b9a9b0c884', 'for': ['markdown', 'text', 'gitcommit']}
Plug 'dhruvasagar/vim-table-mode', {'commit': 'bb025308a45c67c7c8f0763ba37bc2ee3f534df0', 'for': 'markdown'}
Plug 'previm/previm', {'commit': '29524dba1dfad1e77a8670b8c133af96f31582a7', 'for': 'markdown'}
Plug 'junegunn/goyo.vim', {'commit': '9c72fdf2d202914318581f9f0dd09fd102f8504d', 'on': 'Goyo'}
Plug 'junegunn/limelight.vim', {'commit': '617064e84e896f6f36b5e559f8e6486d632f68ed', 'on': 'Limelight'}

Plug 'liuchengxu/vim-which-key', {'commit': '72a4267b46a76f541b3e9500a7503575575d4f57'}
Plug 'sainnhe/everforest', {'commit': '85a86eb62409e3ec88713bff3d1b9d7374e112e4'}

call plug#end()

filetype plugin indent on
syntax enable

set number relativenumber cursorline
set scrolloff=10 sidescrolloff=5 nowrap
set incsearch hlsearch ignorecase smartcase
set noexrc nomodeline
set showcmd showmatch wildmenu wildignorecase
set wildmode=noselect:lastused,full
set wildignore=*.pyc
set wildignore+=*/node_modules/*,*/.git/*,*/__pycache__/*,*/dist/*,*/build/*
set mouse=a
set splitbelow splitright
set backspace=indent,eol,start
set nrformats-=octal
set autoread hidden confirm
set whichwrap+=<,>,h,l
set noerrorbells novisualbell
set t_vb=
set ttimeout ttimeoutlen=50 timeoutlen=500
set display+=lastline
set fileformats=unix,dos,mac
set expandtab smarttab shiftwidth=4 tabstop=4 softtabstop=4
set autoindent textwidth=0
set synmaxcol=300 lazyredraw updatetime=300
set complete-=i
set completeopt=menuone,noinsert,noselect,popup
set pumheight=15
set shortmess+=cI
set signcolumn=yes
set title
set noshowmode noruler
set laststatus=2 showtabline=0
set sessionoptions=blank,buffers,folds,tabpages,winsize
set viewoptions=cursor,folds,slash,unix
set switchbuf=useopen,usetab,newtab
set tags=./tags;,tags;
set path+=**

set breakindent smoothscroll splitkeep=screen jumpoptions=stack belloff=all
set wildoptions=pum,tagfile spelloptions+=camel

if executable('rg')
    set grepprg=rg\ --vimgrep\ --smart-case grepformat=%f:%l:%c:%m
endif

let s:state_dirs = {
    \ 'backup': g:chopsticks_data . '/.backup',
    \ 'swap': g:chopsticks_data . '/.swap',
    \ 'undo': g:chopsticks_data . '/.undo',
    \ 'view': g:chopsticks_data . '/.view',
    \ 'session': g:chopsticks_data . '/.sessions',
    \ }
for s:state_dir in values(s:state_dirs)
    silent! call mkdir(s:state_dir, 'p', 0700)
endfor
set backup writebackup swapfile
let &backupdir = s:state_dirs.backup . '//'
let &directory = s:state_dirs.swap . '//'
let &viewdir = s:state_dirs.view
let &undodir = s:state_dirs.undo
set undofile
unlet s:state_dir

set listchars=tab:→\ ,trail:·,extends:›,precedes:‹,nbsp:␣
execute 'set fillchars+=eob:\ '
if $COLORTERM =~# '^\%(truecolor\|24bit\)$' || !empty($WT_SESSION)
    try
        set termguicolors
    catch /E954/
    endtry
endif
set background=dark

call chopsticks#ui#theme#Apply()

set statusline=%!chopsticks#ui#statusline#Render()
set tabline=%!chopsticks#ui#bufferline#Render()
call chopsticks#ui#bufferline#Refresh()

function! s:HandleResize() abort
    wincmd =
    if exists('*chopsticks#ui#window#Fit')
        call chopsticks#ui#window#Fit()
    endif
    if &filetype ==# 'chopsticks-dashboard'
        call chopsticks#ui#dashboard#Render()
    endif
endfunction

augroup ChopsticksInterface
    autocmd!
    autocmd ColorScheme * call chopsticks#ui#theme#DefineInterfaceColors()
    autocmd BufEnter * if &filetype ==# 'chopsticks-dashboard' | call chopsticks#ui#dashboard#Enter() | call chopsticks#ui#dashboard#Render() | endif
    autocmd WinEnter,BufWinEnter * if &filetype ==# 'chopsticks-dashboard' | call chopsticks#ui#dashboard#Focus(v:true) | endif
    autocmd WinLeave * if &filetype ==# 'chopsticks-dashboard' | call chopsticks#ui#dashboard#Focus(v:false) | endif
    autocmd WinEnter,WinLeave,WinNew,WinClosed,BufEnter,BufWritePost * call chopsticks#ui#winlabel#Refresh()
    autocmd WinScrolled,WinResized,VimResized * call chopsticks#ui#winlabel#Refresh()
    autocmd TextChanged,TextChangedI * call chopsticks#ui#winlabel#OnTextChanged()
    autocmd BufEnter,BufAdd,BufWinEnter,WinEnter * call chopsticks#ui#bufferline#Refresh()
    autocmd BufDelete,BufWipeout,WinClosed * call chopsticks#ui#bufferline#ScheduleRefresh()
    autocmd CursorMoved * if &filetype ==# 'chopsticks-dashboard' | call chopsticks#ui#dashboard#LockCursor() | endif
    autocmd FocusGained * if &filetype ==# 'chopsticks-dashboard' | call chopsticks#ui#dashboard#LockCursor() | redraw! | endif
    autocmd VimResized * call s:HandleResize()
augroup END
call chopsticks#ui#theme#DefineInterfaceColors()

command! -nargs=* ChopGrep call chopsticks#find#Grep(<q-args>)

command! ChopFiles call chopsticks#find#FindFiles()

command! ChopRecent call chopsticks#find#RecentFiles()
command! -nargs=* -complete=file ChopDebug
    \ call chopsticks#debug#Start(<q-args>)

call chopsticks#keys#Reset()
let g:which_key_map = {}

function! s:LeaderN(parts, rhs, group, description) abort
    execute 'nnoremap <silent> <leader>' . join(a:parts, '') . ' ' . a:rhs
    call chopsticks#keys#WhichKeyAdd(a:parts, a:group, a:description)
    call chopsticks#keys#Catalog(a:group, 'n', chopsticks#keys#LeaderLabel(a:parts), a:description)
endfunction

function! s:LeaderX(parts, rhs, group, description) abort
    execute 'xnoremap <silent> <leader>' . join(a:parts, '') . ' ' . a:rhs
    call chopsticks#keys#WhichKeyAdd(a:parts, a:group, a:description)
    call chopsticks#keys#Catalog(a:group, 'x', chopsticks#keys#LeaderLabel(a:parts), a:description)
endfunction

function! s:DirectN(lhs, rhs, label, group, description) abort
    execute 'nnoremap <silent> ' . a:lhs . ' ' . a:rhs
    call chopsticks#keys#Catalog(a:group, 'n', a:label, a:description)
endfunction

command! ChopKeys call chopsticks#keys#Show()
command! -bar ChopSave call chopsticks#session#Save()
command! -bar -bang ChopLoad call chopsticks#session#Load(<bang>0)
command! ChopDash call chopsticks#ui#dashboard#Open()

let g:which_key_local_map = {
    \ 'name': chopsticks#keys#Group('Markdown'),
    \ '?': 'Markdown help',
    \ 'c': 'Toggle conceal',
    \ 'f': 'Format with Prettier',
    \ 'g': 'Preview with Glow',
    \ 'i': 'Paste clipboard image',
    \ 'l': 'Lint now',
    \ 'o': 'Open heading outline',
    \ 'O': 'Insert table of contents',
    \ 'p': 'Browser preview',
    \ 's': 'Toggle spelling',
    \ 't': {
        \ 'name': chopsticks#keys#Group('Table'),
        \ 'c': 'Tableize selection',
        \ 'r': 'Realign table',
        \ 't': 'Toggle table mode',
        \ },
    \ 'x': 'Toggle task checkbox',
    \ 'z': 'Focus mode',
    \ }

for s:markdown_key in [
    \ ['Writing', 'n*', ',?', 'Markdown help'],
    \ ['Writing', 'n*', ',z', 'Focus mode'],
    \ ['Writing', 'n*', ',s', 'Toggle spelling'],
    \ ['Writing', 'n*', ']s / [s', 'Next / previous misspelling'],
    \ ['Writing', 'n*', 'z=', 'Spelling suggestions'],
    \ ['Writing', 'n*', ',c', 'Toggle conceal'],
    \ ['Writing', 'n*', 'gqap', 'Format paragraph'],
    \ ['Writing', 'n*', 'g Ctrl-g', 'Word count'],
    \ ['Structure', 'n*', ',x', 'Toggle task checkbox'],
    \ ['Structure', 'n*', 'gN', 'Renumber list'],
    \ ['Structure', 'n*', ']] / [[', 'Next / previous heading'],
    \ ['Structure', 'n*', ']u', 'Parent heading'],
    \ ['Structure', 'n*', ',o', 'Open heading outline'],
    \ ['Structure', 'n*', ',O', 'Insert table of contents'],
    \ ['Table', 'n*', ',tt', 'Toggle table mode'],
    \ ['Table', 'n*', ',tr', 'Realign table'],
    \ ['Table', 'x*', ',tc', 'Tableize selection'],
    \ ['Links', 'n*', 'gx / ge', 'Open URL / edit linked Markdown'],
    \ ['Links', 'n*', ',p', 'Browser preview'],
    \ ['Links', 'n*', ',g', 'Preview with Glow'],
    \ ['Links', 'n*', ',i', 'Paste clipboard image'],
    \ ['Links', 'n*', ',l', 'Lint now'],
    \ ['Links', 'n*', ',f', 'Format with Prettier'],
    \ ]
    call chopsticks#keys#Catalog(s:markdown_key[0], s:markdown_key[1],
        \ s:markdown_key[2], s:markdown_key[3])
endfor
unlet s:markdown_key

command! -nargs=? -complete=file MdPaste call chopsticks#markdown#PasteImage(<q-args>)
command! MdGlow call chopsticks#markdown#Glow()
command! MdHelp call chopsticks#markdown#Help()

inoremap <silent><expr> <Tab> chopsticks#lsp#CompletionTab()
inoremap <silent><expr> <S-Tab> chopsticks#lsp#CompletionBackTab()
snoremap <silent><expr> <Tab> chopsticks#lsp#SelectTab(1)
snoremap <silent><expr> <S-Tab> chopsticks#lsp#SelectTab(-1)

cnoremap <expr> <Up> wildmenumode() ? "\<C-e>\<Up>" : "\<Up>"
cnoremap <expr> <Down> wildmenumode() ? "\<C-e>\<Down>" : "\<Down>"
call chopsticks#keys#Catalog('Essentials', 'c', 'Tab / Up / Down',
    \ 'Command-line suggestions, then history')

nnoremap <silent> <C-s> <Cmd>call chopsticks#actions#Save()<CR>
inoremap <silent> <C-s> <Cmd>call chopsticks#actions#Save()<CR>
xnoremap <silent> <C-s> <Cmd>call chopsticks#actions#Save()<CR>
call chopsticks#keys#Catalog('Essentials', 'n/i/x', 'Ctrl-s', 'Save file')
call s:LeaderN(['?'], ':ChopKeys<CR>', 'Essentials', 'Full cheatsheet')
call s:LeaderN(['e'], ':call chopsticks#explorer#Root()<CR>', 'Files', 'Explore project root')
call s:LeaderN(['E'], ':call chopsticks#explorer#Here()<CR>', 'Files', 'Explore current file directory')

nnoremap <silent><expr> j v:count == 0 ? 'gj' : 'j'
nnoremap <silent><expr> k v:count == 0 ? 'gk' : 'k'
xnoremap <silent><expr> j v:count == 0 ? 'gj' : 'j'
xnoremap <silent><expr> k v:count == 0 ? 'gk' : 'k'
nnoremap <silent> <Esc> :nohlsearch<CR><Esc>
call chopsticks#keys#Catalog('Navigation', 'n/x', 'j / k', 'Screen line; count uses physical line')
call chopsticks#keys#Catalog('Navigation', 'n', 'Esc', 'Clear search highlight')

call s:DirectN('<C-h>', '<C-w>h', 'Ctrl-h', 'Windows', 'Focus left window')
call s:DirectN('<C-j>', '<C-w>j', 'Ctrl-j', 'Windows', 'Focus lower window')
call s:DirectN('<C-k>', '<C-w>k', 'Ctrl-k', 'Windows', 'Focus upper window')
call s:DirectN('<C-l>', '<C-w>l', 'Ctrl-l', 'Windows', 'Focus right window')
call s:DirectN('sh', '<C-w>h', 'sh', 'Windows', 'Focus left window')
call s:DirectN('sj', '<C-w>j', 'sj', 'Windows', 'Focus lower window')
call s:DirectN('sk', '<C-w>k', 'sk', 'Windows', 'Focus upper window')
call s:DirectN('sl', '<C-w>l', 'sl', 'Windows', 'Focus right window')
call s:DirectN('ss', ':split<CR>', 'ss', 'Windows', 'Split below')
call s:DirectN('sv', ':vsplit<CR>', 'sv', 'Windows', 'Split right')
call s:DirectN('sq', ':confirm close<CR>', 'sq', 'Windows', 'Close window')
call s:DirectN('s=', '<C-w>=', 's=', 'Windows', 'Balance windows')
call s:DirectN('se', ':call chopsticks#explorer#Here()<CR>', 'se', 'Windows', 'Explore current file directory')
call s:DirectN('<C-Up>', ':resize +2<CR>', 'Ctrl-Up', 'Windows', 'Increase height')
call s:DirectN('<C-Down>', ':resize -2<CR>', 'Ctrl-Down', 'Windows', 'Decrease height')
call s:DirectN('<C-Left>', ':vertical resize -2<CR>', 'Ctrl-Left', 'Windows', 'Decrease width')
call s:DirectN('<C-Right>', ':vertical resize +2<CR>', 'Ctrl-Right', 'Windows', 'Increase width')
call s:LeaderN(['-'], '<C-w>s', 'Windows', 'Split below')
call s:LeaderN(['<Bar>'], '<C-w>v', 'Windows', 'Split right')
call s:LeaderN(['w', 'h'], '<C-w>h', 'Windows', 'Focus left window')
call s:LeaderN(['w', 'j'], '<C-w>j', 'Windows', 'Focus lower window')
call s:LeaderN(['w', 'k'], '<C-w>k', 'Windows', 'Focus upper window')
call s:LeaderN(['w', 'l'], '<C-w>l', 'Windows', 'Focus right window')
call s:LeaderN(['w', 's'], '<C-w>s', 'Windows', 'Split below')
call s:LeaderN(['w', 'v'], '<C-w>v', 'Windows', 'Split right')
call s:LeaderN(['w', 'd'], '<C-w>c', 'Windows', 'Close window')
call s:LeaderN(['w', '='], '<C-w>=', 'Windows', 'Balance windows')

nnoremap <M-j> :<C-u>execute 'move .+' . v:count1<CR>==
nnoremap <M-k> :<C-u>execute 'move .-' . (v:count1 + 1)<CR>==
inoremap <M-j> <Esc>:move .+1<CR>==gi
inoremap <M-k> <Esc>:move .-2<CR>==gi
xnoremap <M-j> :<C-u>execute "'<,'>move '>+" . v:count1<CR>gv=gv
xnoremap <M-k> :<C-u>execute "'<,'>move '<-" . (v:count1 + 1)<CR>gv=gv
xnoremap < <gv
xnoremap > >gv
call chopsticks#keys#Catalog('Editing', 'n/i/x', 'Alt-j / Alt-k', 'Move line or selection')
call chopsticks#keys#Catalog('Editing', 'x', '< / >', 'Indent and keep selection')

nnoremap <silent> x "_x
call s:LeaderN(['p'], '"0p', 'Editing', 'Paste without clobbering yank')
call s:LeaderN(['P'], '"0P', 'Editing', 'Paste last yank before cursor')
call s:LeaderX(['p'], '"_dP', 'Editing', 'Paste without replacing yank')
call chopsticks#keys#WhichKeyAdd(['p'], 'Editing', 'Paste without clobbering yank')
call s:LeaderN(['v'], '`[v`]', 'Editing', 'Reselect last change')
call s:LeaderN(['y'], '"+y', 'Editing', 'Yank to system clipboard')
call s:LeaderX(['y'], '"+y', 'Editing', 'Yank to system clipboard')
call s:LeaderN(['Y'], '"+Y', 'Editing', 'Yank line to system clipboard')
call chopsticks#keys#Catalog('Editing', 'n', 'x', 'Delete character without changing registers')

nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <C-d> <C-d>zz
xnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
xnoremap <C-u> <C-u>zz
call chopsticks#keys#Catalog('Navigation', 'n', 'n / N', 'Search result centered')
call chopsticks#keys#Catalog('Navigation', 'n/x', 'Ctrl-d / Ctrl-u', 'Half-page centered')

nnoremap <silent> [<Space> :<C-u>put! =repeat(nr2char(10), v:count1)<CR>']+
nnoremap <silent> ]<Space> :<C-u>put =repeat(nr2char(10), v:count1)<CR>'[-
call chopsticks#keys#Catalog('Editing', 'n', '[SPC / ]SPC', 'Insert blank line above / below')
call s:LeaderN(['s', 'r'], ':%s/\<<C-r><C-w>\>//g<Left><Left>', 'Search', 'Replace word under cursor')
call s:LeaderX(['s', 'r'], ':s///g<Left><Left><Left>', 'Search', 'Replace in selection')
call chopsticks#keys#WhichKeyAdd(['s', 'r'], 'Search', 'Replace text')
call s:LeaderX(['s', 's'], 'y/\V<C-r>=escape(@",''/\'')<CR><CR>', 'Search', 'Search visual selection')

call s:DirectN(']q', ':cnext<CR>', ']q', 'Diagnostics', 'Next quickfix item')
call s:DirectN('[q', ':cprevious<CR>', '[q', 'Diagnostics', 'Previous quickfix item')
call s:DirectN(']l', ':lnext<CR>', ']l', 'Diagnostics', 'Next location item')
call s:DirectN('[l', ':lprevious<CR>', '[l', 'Diagnostics', 'Previous location item')
call s:DirectN(']b', ':bnext<CR>', ']b', 'Buffers', 'Next buffer')
call s:DirectN('[b', ':bprevious<CR>', '[b', 'Buffers', 'Previous buffer')
call s:DirectN('L', ':bnext<CR>', 'L', 'Buffers', 'Next buffer')
call s:DirectN('H', ':bprevious<CR>', 'H', 'Buffers', 'Previous buffer')
nnoremap <silent> ]x /^\(<<<<<<<\|=======\|>>>>>>>\)<CR>
nnoremap <silent> [x ?^\(<<<<<<<\|=======\|>>>>>>>\)<CR>
call chopsticks#keys#Catalog('Diagnostics', 'n', '[x / ]x', 'Previous / next conflict marker')
call s:LeaderN(['x', 'q'], ':call chopsticks#actions#ToggleQuickfix()<CR>', 'Diagnostics', 'Toggle quickfix list')
call s:LeaderN(['x', 'l'], ':call chopsticks#actions#ToggleLocationList()<CR>', 'Diagnostics', 'Toggle location list')

call s:LeaderN(['b', 'b'], ':buffer #<CR>', 'Buffers', 'Switch to other buffer')
call s:LeaderN(['b', 'd'], ':call chopsticks#actions#DeleteBuffer()<CR>', 'Buffers', 'Delete buffer')
call s:LeaderN(['b', 'n'], ':bnext<CR>', 'Buffers', 'Next buffer')
call s:LeaderN(['b', 'p'], ':bprevious<CR>', 'Buffers', 'Previous buffer')
call s:LeaderN(['b', 'o'], ':call chopsticks#actions#DeleteOtherBuffers()<CR>', 'Buffers', 'Delete other unmodified buffers')

call s:LeaderN(['f', 'n'], ':enew<CR>', 'Files', 'New file')
call s:LeaderN(['f', 's'], '<Cmd>call chopsticks#actions#Save()<CR>', 'Files', 'Save file')
call s:LeaderN(['f', 'S'], ':wall<CR>', 'Files', 'Save all files')
call s:LeaderN(['f', 'd'], ':silent lcd %:p:h<Bar>echo fnamemodify(getcwd(), '':~'')<CR>', 'Files', 'Use file directory locally')
call s:LeaderN(['f', 'e'], ':call chopsticks#explorer#Root()<CR>', 'Files', 'Explore project root')
call s:LeaderN(['f', 'E'], ':call chopsticks#explorer#Here()<CR>', 'Files', 'Explore current file directory')
call s:LeaderN(['f', 'v'], ':edit $MYVIMRC<CR>', 'Files', 'Edit Vim config')
call s:LeaderN(['f', 'R'], ':source $MYVIMRC<CR>', 'Files', 'Reload Vim config')
call s:LeaderN(['f', 'y'], ':call chopsticks#actions#CopyPath(1)<CR>', 'Files', 'Copy relative path')
call s:LeaderN(['f', 'Y'], ':call chopsticks#actions#CopyPath(0)<CR>', 'Files', 'Copy absolute path')

call s:LeaderN(['u', 'h'], ':nohlsearch<CR>', 'Toggles', 'Clear search highlight')
call s:LeaderN(['u', 'n'], ':set number! number?<CR>', 'Toggles', 'Toggle line numbers')
call s:LeaderN(['u', 'r'], ':set relativenumber! relativenumber?<CR>', 'Toggles', 'Toggle relative numbers')
call s:LeaderN(['u', 'l'], ':set list! list?<CR>', 'Toggles', 'Toggle invisible characters')
call s:LeaderN(['u', 'w'], ':set wrap! wrap?<CR>', 'Toggles', 'Toggle wrapping')
call s:LeaderN(['u', 's'], ':set spell! spell?<CR>', 'Toggles', 'Toggle spelling')

call chopsticks#keys#Catalog('Files', 'n*', 'Fern h / l', 'Collapse / open node')
call chopsticks#keys#Catalog('Files', 'n*', 'Fern s / v / t', 'Open in split / vsplit / tab')
call chopsticks#keys#Catalog('Files', 'n*', 'Fern N / r / x', 'New path / rename / mark')
call chopsticks#keys#Catalog('Files', 'n*', 'Fern . / R', 'Toggle hidden files / reload')
call chopsticks#keys#Catalog('Files', 'n*', 'Fern q / Esc', 'Close drawer')

call s:LeaderN(['q', 'w'], ':confirm quit<CR>', 'Quit', 'Close window')
call s:LeaderN(['q', 'q'], ':confirm qall<CR>', 'Quit', 'Quit Vim')
call s:LeaderN(['q', 's'], ':ChopSave<CR>', 'Quit', 'Save project session')
call s:LeaderN(['q', 'l'], ':ChopLoad<CR>', 'Quit', 'Restore project session')

call s:LeaderN(['t', 't'], ':call chopsticks#ui#window#Terminal([], ''tab'')<CR>', 'Terminal', 'Terminal in new tab')
call s:LeaderN(['t', 's'], ':call chopsticks#ui#window#Terminal([], ''split'')<CR>', 'Terminal', 'Terminal below')
call chopsticks#keys#Catalog('Terminal', 't', 'Ctrl-w N', 'Leave terminal mode')

call s:LeaderN(['<Tab>', '<Tab>'], ':tabnew<CR>', 'Tabs', 'New tab')
call s:LeaderN(['<Tab>', '['], ':tabprevious<CR>', 'Tabs', 'Previous tab')
call s:LeaderN(['<Tab>', ']'], ':tabnext<CR>', 'Tabs', 'Next tab')
call s:LeaderN(['<Tab>', 'd'], ':tabclose<CR>', 'Tabs', 'Close tab')
call s:LeaderN(['<Tab>', 'o'], ':tabonly<CR>', 'Tabs', 'Close other tabs')
call s:LeaderN(['<Tab>', 'f'], ':tabfirst<CR>', 'Tabs', 'First tab')
call s:LeaderN(['<Tab>', 'l'], ':tablast<CR>', 'Tabs', 'Last tab')

call s:LeaderN(['g', 'g'], ':call chopsticks#actions#Lazygit()<CR>', 'Git', 'Lazygit at project root')

call s:LeaderN(['r', 'r'], ':update<Bar>Make<CR>', 'Run', 'Run project task')
call s:LeaderN(['u', 'U'], ':UndotreeToggle<CR>', 'Toggles', 'Toggle undo tree')
call s:LeaderN(['r', 'd'], ':ChopDebug<CR>', 'Run', 'Debug with termdebug')
call s:LeaderN(['f', 'H'], ':ChopDash<CR>', 'Files', 'Start screen')
call s:LeaderN(['z'], ':Goyo<CR>', 'Essentials', 'Focus mode')
nmap <silent> <leader>j <Plug>(easymotion-overwin-w)
call chopsticks#keys#WhichKeyAdd(['j'], 'Navigation', 'Jump to visible target')
call chopsticks#keys#Catalog('Navigation', 'n', 'SPC j', 'Jump to visible target')
call chopsticks#keys#Catalog('Fast find', 't', 'Esc / Ctrl-q', 'Close finder')
call s:LeaderN(['<Space>'], ':FuzzyBuffers<CR>', 'Buffers', 'Find open buffers')
call s:LeaderN([','], ':FuzzyBuffers<CR>', 'Buffers', 'Find open buffers')
call s:LeaderN(['f', 'f'], ':call chopsticks#find#FindFiles()<CR>', 'Files', 'Find files')
call s:LeaderN(['f', 'g'], ':call chopsticks#find#GitFiles()<CR>', 'Files', 'Find Git files')
call s:LeaderN(['f', 'r'], ':FuzzyMru<CR>', 'Files', 'Recent files')
call s:LeaderN(['/'], ':FuzzyInBuffer<CR>', 'Search', 'Search current buffer')
call s:LeaderN(['s', 'b'], ':FuzzyInBuffer<CR>', 'Search', 'Search current buffer')
call s:LeaderN(['s', 'c'], ':FuzzyCommands<CR>', 'Search', 'Search commands')
call s:LeaderN(['s', 'g'], ':ChopGrep<CR>', 'Search', 'Grep project')
call s:LeaderN(['s', 'h'], ':FuzzyHelp<CR>', 'Search', 'Search Vim help')
call s:LeaderN(['s', 'w'], ':ChopGrep <C-r><C-w><CR>', 'Search', 'Grep word under cursor')
call s:DirectN('<C-p>', ':call chopsticks#find#FindFiles()<CR>', 'Ctrl-p', 'Fast find', 'Find files')
call s:DirectN(';f', ':call chopsticks#find#FindFiles()<CR>', ';f', 'Fast find', 'Find files')
call s:DirectN(';b', ':FuzzyBuffers<CR>', ';b', 'Fast find', 'Find open buffers')
call s:DirectN(';l', ':FuzzyInBuffer<CR>', ';l', 'Fast find', 'Search current buffer')
call s:DirectN(';h', ':FuzzyHelp<CR>', ';h', 'Fast find', 'Search Vim help')
call s:DirectN(';r', ':ChopGrep<CR>', ';r', 'Fast find', 'Grep project')
call s:DirectN('<Bslash>', ':FuzzyBuffers<CR>', '\', 'Fast find', 'Find open buffers')
call s:LeaderN(['g', 's'], ':Git<CR>', 'Git', 'Git status')
call s:LeaderN(['g', 'd'], ':Gdiffsplit<CR>', 'Git', 'Diff current file')
call s:LeaderN(['g', 'b'], ':Git blame<CR>', 'Git', 'Blame current file')
call s:LeaderN(['g', 'o'], ':GBrowse<CR>', 'Git', 'Open remote file')
call s:DirectN('[e', ':ALEPrevious<CR>', '[e', 'Diagnostics', 'Previous ALE problem')
call s:DirectN(']e', ':ALENext<CR>', ']e', 'Diagnostics', 'Next ALE problem')
call s:LeaderN(['x', 'd'], ':ALEDetail<CR>', 'Diagnostics', 'Diagnostic detail')
call s:LeaderN(['u', 'f'],
    \ ':let g:ale_fix_on_save = !g:ale_fix_on_save<Bar>' .
    \ 'echo ''Format on save: '' . (g:ale_fix_on_save ? ''ON'' : ''OFF'')<CR>',
    \ 'Toggles', 'Toggle format on save')

call which_key#register('<Space>', 'g:which_key_map')
call which_key#register(',', 'g:which_key_local_map')
nnoremap <silent> <leader> :<C-u>WhichKey '<Space>'<CR>
xnoremap <silent> <leader> :<C-u>WhichKeyVisual '<Space>'<CR>

augroup Chopsticks
    autocmd!
    autocmd FocusGained,BufEnter * silent! checktime
    autocmd InsertLeave * set nopaste
    autocmd FileType * setlocal formatoptions-=c formatoptions-=r
        \ formatoptions-=o formatoptions+=j
    autocmd BufReadPost * if line("'\"") >= 1 && line("'\"") <= line('$')
        \ && &filetype !~# 'commit'
        \ && index(['xxd', 'gitrebase', 'tutor'], &filetype) < 0 && !&diff |
        \ execute "normal! g`\"" | endif
    autocmd BufWritePre * call chopsticks#actions#MakeParent(expand('<afile>'))
    autocmd BufReadPost * if getfsize(expand('<afile>')) > 10 * 1024 * 1024 |
        \ setlocal syntax= | let b:ale_enabled = 0 | endif
    autocmd BufWinEnter * call chopsticks#markdown#GuardLongLines()
    autocmd QuickFixCmdPost [^l]* cwindow
    autocmd QuickFixCmdPost l* lwindow
    autocmd FileType fern call chopsticks#explorer#FernSetup()
    autocmd FileType which_key call chopsticks#keys#Setup()
    autocmd CmdlineChanged [:\/\?] call wildtrigger()
    autocmd FileType netrw setlocal bufhidden=wipe
    autocmd FileType qf nnoremap <silent><buffer> q :close<CR>
    autocmd BufNewFile,BufRead *.mdx setfiletype markdown
    autocmd FileType markdown call chopsticks#markdown#Setup()
    autocmd FileType text,gitcommit,mail call chopsticks#markdown#ProseSetup()
    autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4 textwidth=88
    autocmd FileType javascript,typescript setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2 textwidth=100
    autocmd FileType go setlocal noexpandtab shiftwidth=4 tabstop=4 softtabstop=0 textwidth=120
    autocmd FileType rust setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4 textwidth=100
    autocmd FileType c,cpp setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4 textwidth=80
    autocmd FileType html,css,yaml,json,dockerfile setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2
    autocmd FileType sh setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2 textwidth=80
    autocmd FileType make setlocal noexpandtab shiftwidth=8 tabstop=8 softtabstop=0
    autocmd User LspAttached call chopsticks#lsp#Maps()
    autocmd FileType * call chopsticks#lsp#Ensure(expand('<amatch>'))
    autocmd User GoyoEnter nested call chopsticks#markdown#GoyoEnter()
    autocmd User GoyoLeave nested call chopsticks#markdown#GoyoLeave()
    autocmd BufEnter * nested call chopsticks#explorer#MaybeOpenDirectory()
    autocmd VimEnter * let g:chopsticks_startup_ms = reltimefloat(reltime(g:chopsticks_startup_started_at)) * 1000
    autocmd VimEnter * if argc() == 0 && bufname('%') ==# '' && &buftype ==# '' && line('$') == 1 && getline(1) ==# '' && !&modified | call chopsticks#ui#dashboard#Open() | endif
augroup END

if exists('*chopsticks#lsp#Catalog')
    call chopsticks#lsp#Catalog()
endif
if &filetype ==# 'markdown'
    call chopsticks#markdown#Setup()
endif
