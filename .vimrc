set encoding=utf-8
scriptencoding utf-8

" chopsticks — a modern, Vim-only development and Markdown writing setup

" Global because the dashboard footer that reports it cannot see this file's
" s: scope, and captured in the first lines so it covers the whole of startup.
" The guard honours an existing value: a user could skew it, but it is a
" cosmetic number nothing decides anything from.
if !exists('g:chopsticks_startup_started_at')
    let g:chopsticks_startup_started_at = reltime()
endif
let s:is_windows = has('win32') || has('win64')
let g:chopsticks_version = '0.2.0'

if has('nvim')
    echoerr 'chopsticks targets Vim, not Neovim'
    finish
endif
if !has('patch-9.1.1947')
    echoerr 'chopsticks requires Vim 9.1.1947 or newer'
    finish
endif

" Terminal capability replies can arrive too late and leak onto a transparent
" dashboard. The interface sets its colors and width policy explicitly.
if !has('gui_running')
    set t_RV= t_u7= t_RF= t_RB= ambiwidth=single
endif

if empty($MYVIMRC)
    let $MYVIMRC = expand('<sfile>:p')
endif

" Vim's plugin-loading pass only sources plugin/**/*.vim from directories
" already on 'runtimepath', and -u pointing here does not add this one, so it
" is added before that pass runs.
"
" $MYVIMRC cannot locate it: the documented install symlinks this file to
" ~/.vimrc, so $MYVIMRC names the symlink and ':h' gives $HOME; the Windows
" install sources this file from a separate _vimrc entirely. <sfile> gives this
" file's real location in both. The rule that Vim9 modules must not read their
" own path does not apply here -- this file is never copied.
"
" The guard keeps :source $MYVIMRC from duplicating the entry.
let s:chopsticks_root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
if index(split(&runtimepath, ','), s:chopsticks_root) < 0
    execute 'set runtimepath^=' . fnameescape(s:chopsticks_root)
endif

unlet s:chopsticks_root

let g:mapleader = "\<Space>"
let g:maplocalleader = ','

let s:is_remote = !empty($SSH_CONNECTION) || !empty($SSH_CLIENT) || !empty($SSH_TTY)
let s:is_rich_terminal = !s:is_remote && has('termguicolors')
    \ && ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')

function! s:NormalizeDirectory(value, fallback) abort
    let l:value = type(a:value) == type('') && !empty(a:value)
        \ ? a:value : a:fallback
    let l:directory = simplify(fnamemodify(expand(l:value), ':p'))
    if l:directory !~# '[/\\]$'
        " ':p' appends a separator only for a directory that exists, so this
        " runs for one that does not, where a hardcoded '/' gave 'C:\dir/'.
        " tests/ui.vim and session.vim repeat this rule; all three must agree,
        " or fixing one moves the failure to whichever comparison the others
        " feed.
        let l:directory .= s:is_windows && l:directory =~# '\\' ? '\' : '/'
    endif
    return l:directory
endfunction

function! s:DirectoryFileType(path) abort
    " getftype() follows a directory symlink when its name ends in a slash.
    let l:path = substitute(a:path, '[/\\]$', '', '')
    if empty(l:path)
        let l:path = a:path
    elseif s:is_windows && l:path =~? '^\a:$'
        let l:path .= '/'
    endif
    return getftype(l:path)
endfunction

" Vim's native user runtime is ~/.vim on Unix and ~/vimfiles on Windows.
" Keep generated state and optional plugins together under the same root.
let s:default_data_dir = s:is_windows ? '~/vimfiles' : '~/.vim'
let g:chopsticks_data_dir = s:NormalizeDirectory(
    \ get(g:, 'chopsticks_data_dir', s:default_data_dir),
    \ s:default_data_dir)

" Keep machine-specific preferences outside this tracked configuration.  The
" path is overridable so repeatable harnesses can opt out without changing a
" user's file.
let s:local_config = get(g:, 'chopsticks_local_config',
    \ g:chopsticks_data_dir . 'chopsticks.local.vim')
if type(s:local_config) == type('') && !empty(s:local_config)
    let s:local_config = expand(s:local_config)
    if filereadable(s:local_config)
        execute 'source ' . fnameescape(s:local_config)
    endif
endif
unlet s:local_config

" A local config is executable code and may replace the public value.  Restore
" the invariant before any path is derived from it.
let g:chopsticks_data_dir = s:NormalizeDirectory(
    \ get(g:, 'chopsticks_data_dir', s:default_data_dir),
    \ s:default_data_dir)

" Personal switches. Override these before sourcing this file when needed.
let g:chopsticks_markdown_spell = get(g:, 'chopsticks_markdown_spell', 1)
let g:chopsticks_markdown_conceal = get(g:, 'chopsticks_markdown_conceal', 0)
let g:chopsticks_markdown_image_dir = get(g:, 'chopsticks_markdown_image_dir', 'assets')
let g:chopsticks_auto_lint = get(g:, 'chopsticks_auto_lint', 0)
let g:chopsticks_long_line_threshold =
    \ get(g:, 'chopsticks_long_line_threshold', 4096)
let g:chopsticks_ui_density = get(g:, 'chopsticks_ui_density', 'balanced')
let g:chopsticks_colorscheme = get(g:, 'chopsticks_colorscheme', 'everforest')
let g:chopsticks_transparent_background = get(g:, 'chopsticks_transparent_background', 'auto')
let g:chopsticks_dashboard = get(g:, 'chopsticks_dashboard', 'auto')
let g:chopsticks_bufferline = get(g:, 'chopsticks_bufferline', 'auto')
let g:chopsticks_system_clipboard = get(g:, 'chopsticks_system_clipboard', 'auto')
let s:default_session_dir = g:chopsticks_data_dir . '.sessions'
let g:chopsticks_session_dir = get(g:, 'chopsticks_session_dir',
    \ s:default_session_dir)
let g:chopsticks_session_dir = s:NormalizeDirectory(
    \ g:chopsticks_session_dir, s:default_session_dir)
let g:chopsticks_icons = get(g:, 'chopsticks_icons', 'auto')
let g:chopsticks_use_fern = get(g:, 'chopsticks_use_fern', 1)

function! s:ResolveSwitch(value, automatic) abort
    if type(a:value) == type(0)
        return a:value != 0
    elseif type(a:value) == type(v:true)
        return a:value
    elseif type(a:value) == type('')
        let l:value = tolower(a:value)
        if index(['0', 'off', 'false', 'no'], l:value) >= 0
            return 0
        elseif index(['1', 'on', 'true', 'yes'], l:value) >= 0
            return 1
        endif
    endif
    return a:automatic
endfunction

let g:chopsticks_auto_lint = s:ResolveSwitch(
    \ g:chopsticks_auto_lint, 0)

let s:clipboard_auto_enabled = !s:is_remote && has('clipboard')
    \ && (has('macunix') || has('win32') || has('win64')
    \     || !empty($DISPLAY) || !empty($WAYLAND_DISPLAY))
if has('clipboard')
    \ && s:ResolveSwitch(g:chopsticks_system_clipboard,
    \     s:clipboard_auto_enabled)
    \ && index(split(&clipboard, ','), 'unnamedplus') < 0
    set clipboard+=unnamedplus
endif
unlet s:clipboard_auto_enabled

function! ChopsticksDashboardEnabled() abort
    return s:ResolveSwitch(g:chopsticks_dashboard,
        \ ChopsticksUiDensity() !=# 'minimal')
endfunction

" From here down this file reaches the modules by dotted autoload name
" (chopsticks#ui#icons#Get()) rather than through the g:Chopsticks* shims.
" Much of the setup below runs at this file's top level, before the shims
" exist, and a redraw can force even a deferred-looking call to run there, so
" one convention everywhere beats proving which case applies per call site.
" See plugin/chopsticks.vim's header.
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

" ── Plugin policy ───────────────────────────────────────────────────────────

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

let g:fzf_layout = {'window': {'width': 0.92, 'height': 0.84}}
let g:fzf_action = {
    \ 'ctrl-t': 'tab split',
    \ 'ctrl-x': 'split',
    \ 'ctrl-v': 'vsplit',
    \ 'ctrl-o': 'edit',
    \ }
let g:fzf_vim = {
    \ 'preview_window': s:is_remote ? [] : ['right,55%', 'ctrl-/'],
    \ 'gfiles_options': ['--bind', chopsticks#find#AbortKeys()] + chopsticks#find#VisualOptions(),
    \ }

let g:ale_disable_lsp = 1
let g:ale_linters_explicit = 1
let g:ale_linters = {
    \ 'javascript': ['eslint'],
    \ 'typescript': ['eslint'],
    \ 'go': ['staticcheck'],
    \ 'sh': ['shellcheck'],
    \ 'markdown': ['markdownlint', 'vale'],
    \ }
let g:ale_fixers = {
    \ '*': ['remove_trailing_lines', 'trim_whitespace'],
    \ 'javascript': ['prettier', 'eslint'],
    \ 'typescript': ['prettier', 'eslint'],
    \ 'go': ['goimports'],
    \ 'json': ['prettier'],
    \ 'yaml': ['prettier'],
    \ 'html': ['prettier'],
    \ 'css': ['prettier'],
    \ 'scss': ['prettier'],
    \ 'less': ['prettier'],
    \ 'markdown': ['prettier'],
    \ }
let g:ale_fix_on_save = 0
let g:ale_lint_on_save = g:chopsticks_auto_lint
let g:ale_lint_on_enter = g:chopsticks_auto_lint
let g:ale_lint_on_filetype_changed = g:chopsticks_auto_lint
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_virtualtext_cursor = 'disabled'
let g:ale_echo_msg_format = '%severity%: %s'
let g:ale_sign_error = chopsticks#ui#icons#Get('error')
let g:ale_sign_warning = chopsticks#ui#icons#Get('warning')
let g:ale_sign_info = chopsticks#ui#icons#Get('info')

" vim-lsp-settings' VimEnter lazy path replays BufEnter for every loaded
" buffer.  Initializing its lightweight filetype dispatcher while plugins are
" sourced avoids parsing and sending an initial file twice, which matters for
" large Markdown documents without changing when a language server starts.
let g:lsp_settings_lazyload = 0
let g:lsp_diagnostics_virtual_text_enabled = 0
let g:lsp_diagnostics_highlights_enabled = !s:is_remote
let g:lsp_document_highlight_enabled = !s:is_remote
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_float_cursor = 1
let g:asyncomplete_auto_completeopt = 0

let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_conceal = g:chopsticks_markdown_conceal
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

" Pencil clears these buffer-local groups before first use. Pre-create them so
" Vim 9 does not emit E216 while doing that initial cleanup.
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
let g:table_mode_corner = '|'

let g:previm_enable_realtime = 1
if has('macunix')
    let g:previm_open_cmd = '/usr/bin/open'
elseif executable('xdg-open') == 1
    let g:previm_open_cmd = 'xdg-open'
endif

let g:goyo_width = 96
let g:goyo_height = '90%'
let g:goyo_linenr = 0
let g:limelight_default_coefficient = 0.7
let g:limelight_paragraph_span = 1
let g:limelight_priority = -1

" vim-plug is optional. Startup never downloads software. Source it directly
" because a custom data directory is not necessarily on 'runtimepath'.
let s:vim_plug = g:chopsticks_data_dir . 'autoload/plug.vim'
if filereadable(s:vim_plug)
    execute 'source ' . fnameescape(s:vim_plug)
    call plug#begin(g:chopsticks_data_dir . 'plugged')

    " Find and navigate.
    Plug 'junegunn/fzf', {'commit': '3337be9d450cd349e99273a2d3985ceaf5f3753f'}
    Plug 'junegunn/fzf.vim', {'commit': 'd2a59a992a2455f609c0fde2ebd84427ea8f919a'}
    Plug 'lambdalisue/vim-fern', {'commit': '3bbca3c87a57cdc87495b91a695b8eda722a1de1'}
    Plug 'lambdalisue/vim-nerdfont', {'commit': '3a28b3f061a8b6de751175cc3f91f072d4bfc811'}
    Plug 'lambdalisue/vim-fern-renderer-nerdfont', {'commit': '325629c68eb543229715b68920fbcb92b206beb6'}
    Plug 'lambdalisue/vim-glyph-palette', {'commit': '675f0ad64e2c4b823bffc1907d469deefaf6e3bd'}
    Plug 'lambdalisue/vim-fern-git-status', {'commit': '151336335d3b6975153dad77e60049ca7111da8e'}
    Plug 'tpope/vim-vinegar', {'commit': 'bb1bcddf43cfebe05eb565a84ab069b357d0b3d6'}
    Plug 'easymotion/vim-easymotion', {'commit': 'b3cfab2a6302b3b39f53d9fd2cd997e1127d7878', 'on': '<Plug>(easymotion'}

    " Git and project commands.
    Plug 'tpope/vim-fugitive', {'commit': '3b753cf8c6a4dcde6edee8827d464ba9b8c4a6f0'}
    Plug 'tpope/vim-rhubarb', {'commit': '5496d7c94581c4c9ad7430357449bb57fc59f501'}
    Plug 'airblade/vim-gitgutter', {'commit': '90b75207bd9b55d8ac4af15f72b4e935462014d0'}
    Plug 'tpope/vim-dispatch', {'commit': 'a2ff28abdb2d89725192db5b8562977d392a4d3f'}

    " Editing language.
    Plug 'tpope/vim-surround', {'commit': '3d188ed2113431cf8dac77be61b842acb64433d9'}
    Plug 'tpope/vim-commentary', {'commit': '64a654ef4a20db1727938338310209b6a63f60c9'}
    Plug 'tpope/vim-repeat', {'commit': '65846025c15494983dafe5e3b46c8f88ab2e9635'}
    Plug 'tpope/vim-sleuth', {'commit': 'be69bff86754b1aa5adcbb527d7fcd1635a84080'}
    Plug 'tpope/vim-abolish', {'commit': 'dcbfe065297d31823561ba787f51056c147aa682'}
    Plug 'tpope/vim-speeddating', {'commit': 'c17eb01ebf5aaf766c53bab1f6592710e5ffb796'}
    Plug 'wellle/targets.vim', {'commit': '6325416da8f89992b005db3e4517aaef0242602e'}
    Plug 'jiangmiao/auto-pairs', {'commit': '39f06b873a8449af8ff6a3eee716d3da14d63a76'}
    Plug 'mbbill/undotree', {'commit': '6fa6b57cda8459e1e4b2ca34df702f55242f4e4d', 'on': 'UndotreeToggle'}

    " Diagnostics, formatting, LSP, completion.
    Plug 'dense-analysis/ale', {'commit': '199a95d386cb856c27e5b90d4e3ea8bd45a58c23'}
    Plug 'prabirshrestha/vim-lsp', {'commit': 'e10d186452743beb7b43d2b3427020832f930c2b'}
    Plug 'mattn/vim-lsp-settings', {'commit': 'b0c9bacfe98ff6bc4c5f6b0fffdc085d252387e0'}
    Plug 'prabirshrestha/asyncomplete.vim', {'commit': '17b654a87a834d4e835fb7467e562b4421ad9310'}
    Plug 'prabirshrestha/asyncomplete-lsp.vim', {'commit': 'da23f4418a6301feac7b99e1728fb79acb243d69'}

    " Markdown and prose.
    Plug 'preservim/vim-markdown', {'commit': '1bc9d0cd8e1cc3e901b0a49c2b50a843f1c89397', 'for': 'markdown'}
    " Pencil defines shared autocommand groups during startup; do not lazy-load it.
    Plug 'preservim/vim-pencil', {'commit': '6d70438a8886eaf933c38a7a43a61adb0a7815ed'}
    Plug 'bullets-vim/bullets.vim', {'commit': '81570b98ca44b4100b3ddcf8d9ca74b9a9b0c884', 'for': ['markdown', 'text', 'gitcommit']}
    Plug 'dhruvasagar/vim-table-mode', {'commit': 'bb025308a45c67c7c8f0763ba37bc2ee3f534df0', 'for': 'markdown'}
    Plug 'previm/previm', {'commit': '29524dba1dfad1e77a8670b8c133af96f31582a7', 'on': 'PrevimOpen'}
    Plug 'junegunn/goyo.vim', {'commit': '9c72fdf2d202914318581f9f0dd09fd102f8504d', 'on': 'Goyo'}
    Plug 'junegunn/limelight.vim', {'commit': '617064e84e896f6f36b5e559f8e6486d632f68ed', 'on': 'Limelight'}

    " Interface.
    Plug 'liuchengxu/vim-which-key', {'commit': '72a4267b46a76f541b3e9500a7503575575d4f57'}
    Plug 'sainnhe/everforest', {'commit': '85a86eb62409e3ec88713bff3d1b9d7374e112e4'}

    call plug#end()
endif
unlet s:vim_plug

filetype plugin indent on
syntax enable

" ── Vim defaults ────────────────────────────────────────────────────────────

set number relativenumber cursorline
set scrolloff=10 sidescrolloff=5 nowrap
set incsearch hlsearch ignorecase smartcase
set noexrc nomodeline
set showcmd showmatch wildmenu wildignorecase
set wildmode=longest:full,full
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
set completeopt=menuone,noinsert,noselect
if exists('*popup_create')
    set completeopt+=popup
endif
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

if exists('+breakindent')
    set breakindent
endif
if exists('+smoothscroll')
    set smoothscroll
endif
if exists('+splitkeep')
    set splitkeep=screen
endif
if exists('+jumpoptions')
    set jumpoptions=stack
endif
if exists('+belloff')
    set belloff=all
endif
if exists('+wildoptions')
    set wildoptions=pum,tagfile
endif
if exists('+spelloptions')
    set spelloptions+=camel
endif
if exists('+editorconfig')
    set editorconfig
endif

if executable('rg') == 1
    set grepprg=rg\ --vimgrep\ --smart-case
    set grepformat=%f:%l:%c:%m
endif

" Keep all recovery files out of projects.
let s:state_dirs = {
    \ 'backup': g:chopsticks_data_dir . '.backup',
    \ 'swap': g:chopsticks_data_dir . '.swap',
    \ 'undo': g:chopsticks_data_dir . '.undo',
    \ 'view': g:chopsticks_data_dir . '.view',
    \ 'session': g:chopsticks_session_dir,
    \ }
for s:state_dir in values(s:state_dirs)
    silent! call mkdir(s:state_dir, 'p', 0700)
    if exists('*setfperm') && s:DirectoryFileType(s:state_dir) ==# 'dir'
        silent! call setfperm(s:state_dir, 'rwx------')
    endif
endfor
set backup writebackup swapfile
let &backupdir = s:state_dirs.backup . '//'
let &directory = s:state_dirs.swap . '//'
let &viewdir = s:state_dirs.view
if has('persistent_undo')
    let &undodir = s:state_dirs.undo
    set undofile
endif
unlet s:state_dir

set listchars=tab:→\ ,trail:·,extends:›,precedes:‹,nbsp:␣
execute 'set fillchars+=eob:\ '
" has('termguicolors') only reports that Vim was built with the feature. The
" Windows console rejects the option at assignment time with E954, so the
" capability is only known once it has been set.
if s:is_rich_terminal
    try
        set termguicolors
    catch /:E954:/
        " The console rejects the assignment in either direction, so clearing
        " the option explicitly raises E954 a second time. The failed set left
        " it off already.
        let s:is_rich_terminal = 0
    endtry
endif
set background=dark

call chopsticks#ui#theme#Apply()

" ── Interface: statusline and buffer tabline ───────────────────────────────

" These wrappers stay here, not in plugin/chopsticks.vim: 'statusline' and
" 'tabline' name two of them and the `redrawtabline` below evaluates 'tabline'
" during this file's own execution, where a global that does not exist yet is
" E117 at startup.
"
" Only globals something outside the modules calls are here. The variadic
" signatures are fixed by their callers: tests/plugins.vim passes a buffer
" argument where tests/ui.vim passes none.
function! ChopsticksUiDensity() abort
    return chopsticks#ui#statusline#UiDensity()
endfunction

function! ChopsticksStatusline() abort
    return chopsticks#ui#statusline#Render()
endfunction

function! ChopsticksTabline() abort
    return chopsticks#ui#bufferline#Render()
endfunction

function! ChopsticksGitDiff(...) abort
    return call('chopsticks#ui#statusline#GitDiff', a:000)
endfunction

function! ChopsticksDiagnostics(...) abort
    return call('chopsticks#ui#statusline#Diagnostics', a:000)
endfunction

function! ChopsticksWritingMode(...) abort
    return call('chopsticks#ui#statusline#WritingMode', a:000)
endfunction

" Here because it is the only one needing s:ResolveSwitch(), which is this
" file's own.
function! ChopsticksBufferlineEnabled() abort
    let l:density = ChopsticksUiDensity()
    return s:ResolveSwitch(g:chopsticks_bufferline,
        \ l:density ==# 'rich'
        \ || (l:density ==# 'balanced'
        \     && chopsticks#ui#bufferline#FileBufferCount() > 1))
endfunction

set statusline=%!ChopsticksStatusline()
set tabline=%!ChopsticksTabline()
call chopsticks#ui#bufferline#Refresh()

" icons.vim owns the fern/ALE variables a toggle re-applies. What a toggle also
" has to refresh but is not an icon concern -- g:fzf_vim, the dashboard, the
" status and tab lines -- stays here, driven by the guarded
" `User ChopsticksIconsToggled` icons.vim fires (see the augroup below).
function! s:RefreshIconDependents() abort
    let g:fzf_vim.gfiles_options =
        \ ['--bind', chopsticks#find#AbortKeys()] + chopsticks#find#VisualOptions()
    if &filetype ==# 'chopsticks-dashboard'
        call chopsticks#ui#dashboard#Render()
    endif
    redrawstatus!
    execute 'redrawtabline'
endfunction

command! -nargs=? ChopsticksUiDensity call chopsticks#ui#statusline#SetUiDensity(<q-args>)

function! s:HandleResize() abort
    wincmd =
    if &filetype ==# 'chopsticks-dashboard'
        call chopsticks#ui#dashboard#Render()
    endif
endfunction

augroup ChopsticksInterface
    autocmd!
    " Apply()'s :colorscheme triggers this synchronously at top level, before
    " the shims exist. :ChopsticksTheme fires it again long after startup; the
    " dotted name covers both.
    autocmd ColorScheme * call chopsticks#ui#theme#DefineInterfaceColors()
    autocmd User ChopsticksIconsToggled call s:RefreshIconDependents()
    autocmd BufEnter * if &filetype ==# 'chopsticks-dashboard' | call chopsticks#ui#dashboard#Enter() | call chopsticks#ui#dashboard#Render() | endif
    autocmd BufLeave * if &filetype ==# 'chopsticks-dashboard' | call chopsticks#ui#dashboard#Leave() | endif
    autocmd BufEnter,BufAdd,BufWinEnter * call chopsticks#ui#bufferline#Refresh()
    autocmd BufDelete,BufWipeout * call chopsticks#ui#bufferline#ScheduleRefresh()
    autocmd CursorMoved * if &filetype ==# 'chopsticks-dashboard' | call chopsticks#ui#dashboard#LockCursor() | endif
    autocmd FocusGained * if &filetype ==# 'chopsticks-dashboard' | call chopsticks#ui#dashboard#LockCursor() | redraw! | endif
    autocmd VimResized * call s:HandleResize()
augroup END
call chopsticks#ui#theme#DefineInterfaceColors()

" ── Shared actions ─────────────────────────────────────────────────────────

" This file cannot use a Vim9 :import: vimlint's legacy parser does not
" understand `import autoload` and fails to parse the file if one is added.
" Sessions are reached through the plugin/chopsticks.vim shims instead.

command! -bang -nargs=* ChopsticksProjectGrep
    \ call chopsticks#find#Grep(<q-args>, <bang>0)

command! ChopsticksFindFiles call chopsticks#find#FindFiles()

command! ChopsticksRecentFiles call chopsticks#find#RecentFiles()

call chopsticks#find#DefineCommands()

call chopsticks#keys#Reset()
let g:which_key_map = {}
let g:which_key_local_map = {'name': chopsticks#keys#Group('Markdown')}

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

" tests/ui.vim asserts this global, and it is the one piece of the key
" catalogue anything outside these files reads.
function! ChopsticksKeyLines() abort
    return chopsticks#keys#Lines()
endfunction

command! ChopsticksKeys call chopsticks#keys#Show()
command! ChopsticksCheatsheet call chopsticks#keys#Show()

" ── Markdown and prose ─────────────────────────────────────────────────────

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
    \ ['n*', ',?', 'Markdown help'],
    \ ['n*', ',c', 'Toggle conceal'],
    \ ['n*', ',f', 'Format with Prettier'],
    \ ['n*', ',g', 'Preview with Glow'],
    \ ['n*', ',i', 'Paste clipboard image'],
    \ ['n*', ',l', 'Lint now'],
    \ ['n*', ',o', 'Open heading outline'],
    \ ['n*', ',O', 'Insert table of contents'],
    \ ['n*', ',p', 'Browser preview'],
    \ ['n*', ',s', 'Toggle spelling'],
    \ ['n*', ',tr', 'Realign table'],
    \ ['n*', ',tt', 'Toggle table mode'],
    \ ['x*', ',tc', 'Tableize selection'],
    \ ['n*', ',x', 'Toggle task checkbox'],
    \ ['n*', ',z', 'Focus mode'],
    \ ]
    call chopsticks#keys#Catalog('Markdown', s:markdown_key[0], s:markdown_key[1], s:markdown_key[2])
endfor
unlet s:markdown_key

command! -nargs=? -complete=file MarkdownPasteImage call chopsticks#markdown#PasteImage(<q-args>)
command! MarkdownGlow call chopsticks#markdown#Glow()
command! MarkdownHelp call chopsticks#markdown#Help()

" ── LSP and completion ─────────────────────────────────────────────────────

inoremap <silent><expr> <Tab> chopsticks#lsp#CompletionTab()
inoremap <silent><expr> <S-Tab> chopsticks#lsp#CompletionBackTab()

" ── Core mappings ──────────────────────────────────────────────────────────

" Save from any editing mode without moving either hand off the home row.
nnoremap <silent> <C-s> :update<CR>
inoremap <silent> <C-s> <C-o>:update<CR>
xnoremap <silent> <C-s> :<C-u>update<CR>gv
call chopsticks#keys#Catalog('Essentials', 'n/i/x', 'Ctrl-s', 'Save file')
call s:LeaderN(['?'], ':ChopsticksCheatsheet<CR>', 'Essentials', 'Full cheatsheet')
call s:LeaderN(['e'], ':call chopsticks#explorer#Root()<CR>', 'Files', 'Explore project root')
call s:LeaderN(['E'], ':call chopsticks#explorer#Here()<CR>', 'Files', 'Explore current file directory')

" Wrapped prose moves by screen line; counts retain physical-line semantics.
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
nnoremap <silent> <leader><Bar> <C-w>v
call chopsticks#keys#WhichKeyAdd(['<Bar>'], 'Windows', 'Split right')
call chopsticks#keys#Catalog('Windows', 'n', 'SPC |', 'Split right')
call s:LeaderN(['w', 'h'], '<C-w>h', 'Windows', 'Focus left')
call s:LeaderN(['w', 'j'], '<C-w>j', 'Windows', 'Focus down')
call s:LeaderN(['w', 'k'], '<C-w>k', 'Windows', 'Focus up')
call s:LeaderN(['w', 'l'], '<C-w>l', 'Windows', 'Focus right')
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
if has('clipboard')
    call s:LeaderN(['y'], '"+y', 'Editing', 'Yank to system clipboard')
    call s:LeaderX(['y'], '"+y', 'Editing', 'Yank to system clipboard')
    call s:LeaderN(['Y'], '"+Y', 'Editing', 'Yank line to system clipboard')
endif
call chopsticks#keys#Catalog('Editing', 'n', 'x', 'Delete character without changing registers')

nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <C-d> <C-d>zz
xnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
xnoremap <C-u> <C-u>zz
call chopsticks#keys#Catalog('Navigation', 'n', 'n / N', 'Search result centered')
call chopsticks#keys#Catalog('Navigation', 'n/x', 'Ctrl-d / Ctrl-u', 'Half-page centered')

nnoremap <silent> [<Space> :<C-u>put! =repeat(nr2char(10), v:count1)<CR>'[
nnoremap <silent> ]<Space> :<C-u>put =repeat(nr2char(10), v:count1)<CR>
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
call s:LeaderN(['b', 'd'], ':bdelete<CR>', 'Buffers', 'Delete buffer')
call s:LeaderN(['b', 'n'], ':bnext<CR>', 'Buffers', 'Next buffer')
call s:LeaderN(['b', 'p'], ':bprevious<CR>', 'Buffers', 'Previous buffer')
call s:LeaderN(['b', 'o'], ':call chopsticks#actions#DeleteOtherBuffers()<CR>', 'Buffers', 'Delete other unmodified buffers')

call s:LeaderN(['f', 'n'], ':enew<CR>', 'Files', 'New file')
call s:LeaderN(['f', 's'], ':update<CR>', 'Files', 'Save file')
call s:LeaderN(['f', 'S'], ':wall<CR>', 'Files', 'Save all files')
call s:LeaderN(['f', 'd'], ':lcd %:p:h<CR>:pwd<CR>', 'Files', 'Use file directory locally')
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
call s:LeaderN(['u', 'i'], ':ChopsticksIconsToggle<CR>', 'Toggles', 'Toggle Nerd Font icons')
call s:LeaderN(['u', 'b'], ':ChopsticksTransparencyToggle<CR>', 'Toggles', 'Toggle background transparency')
call s:LeaderN(['u', 'd'], ':ChopsticksUiDensity<CR>', 'Toggles', 'Cycle UI density')

call chopsticks#keys#Catalog('Files', 'n*', 'Fern h / l', 'Collapse / open node')
call chopsticks#keys#Catalog('Files', 'n*', 'Fern s / v / t', 'Open in split / vsplit / tab')
call chopsticks#keys#Catalog('Files', 'n*', 'Fern N / r / x', 'New path / rename / mark')
call chopsticks#keys#Catalog('Files', 'n*', 'Fern . / R', 'Toggle hidden files / reload')
call chopsticks#keys#Catalog('Files', 'n*', 'Fern q / Esc', 'Close drawer')

call s:LeaderN(['q', 'w'], ':confirm quit<CR>', 'Quit', 'Close window')
call s:LeaderN(['q', 'q'], ':confirm qall<CR>', 'Quit', 'Quit Vim')
call s:LeaderN(['q', 's'], ':ChopsticksSessionSave<CR>', 'Quit', 'Save project session')
call s:LeaderN(['q', 'l'], ':ChopsticksSessionLoad<CR>', 'Quit', 'Restore project session')

if has('terminal')
    call s:LeaderN(['t', 't'], ':call chopsticks#ui#window#Terminal([], ''tab'')<CR>', 'Terminal', 'Terminal in new tab')
    call s:LeaderN(['t', 's'], ':call chopsticks#ui#window#Terminal([], ''split'')<CR>', 'Terminal', 'Terminal below')
    if !empty(maparg("\<Esc>\<Esc>", 't'))
        execute 'tunmap <Esc><Esc>'
    endif
    call chopsticks#keys#Catalog('Terminal', 't', 'Ctrl-w N', 'Leave terminal mode')
endif

call s:LeaderN(['<Tab>', '<Tab>'], ':tabnew<CR>', 'Tabs', 'New tab')
call s:LeaderN(['<Tab>', '['], ':tabprevious<CR>', 'Tabs', 'Previous tab')
call s:LeaderN(['<Tab>', ']'], ':tabnext<CR>', 'Tabs', 'Next tab')
call s:LeaderN(['<Tab>', 'd'], ':tabclose<CR>', 'Tabs', 'Close tab')
call s:LeaderN(['<Tab>', 'o'], ':tabonly<CR>', 'Tabs', 'Close other tabs')
call s:LeaderN(['<Tab>', 'f'], ':tabfirst<CR>', 'Tabs', 'First tab')
call s:LeaderN(['<Tab>', 'l'], ':tablast<CR>', 'Tabs', 'Last tab')

call s:LeaderN(['g', 'g'], ':call chopsticks#actions#Lazygit()<CR>', 'Git', 'Lazygit at project root')

" ── Plugin mappings ────────────────────────────────────────────────────────

function! s:PluginMaps() abort
    if exists(':Files') == 2 && executable('fzf') == 1
        call chopsticks#keys#Catalog('Fast find', 't', 'Esc / Ctrl-q', 'Close finder')
        call s:LeaderN(['<Space>'], ':Buffers<CR>', 'Buffers', 'Find open buffers')
        call s:LeaderN([','], ':Buffers<CR>', 'Buffers', 'Find open buffers')
        call s:LeaderN(['f', 'f'], ':call chopsticks#find#FindFiles()<CR>', 'Files', 'Find files')
        call s:LeaderN(['f', 'g'], ':call chopsticks#find#GitFiles()<CR>', 'Files', 'Find Git files')
        call s:LeaderN(['f', 'r'], ':History<CR>', 'Files', 'Recent files')
        call s:LeaderN(['/'], ':BLines<CR>', 'Search', 'Search current buffer')
        call s:LeaderN(['s', 'b'], ':BLines<CR>', 'Search', 'Search current buffer')
        call s:LeaderN(['s', 'B'], ':Lines<CR>', 'Search', 'Search open buffers')
        call s:LeaderN(['s', 'c'], ':Commands<CR>', 'Search', 'Search commands')
        call s:LeaderN(['s', 'h'], ':Helptags<CR>', 'Search', 'Search Vim help')
        call s:LeaderN(['s', 'm'], ':Maps<CR>', 'Search', 'Search mappings')
        call s:DirectN('<C-p>', ':call chopsticks#find#FindFiles()<CR>', 'Ctrl-p', 'Fast find', 'Find files')
        call s:DirectN(';f', ':call chopsticks#find#FindFiles()<CR>', ';f', 'Fast find', 'Find files')
        call s:DirectN(';b', ':Buffers<CR>', ';b', 'Fast find', 'Find open buffers')
        call s:DirectN(';l', ':BLines<CR>', ';l', 'Fast find', 'Search current buffer')
        call s:DirectN(';h', ':Helptags<CR>', ';h', 'Fast find', 'Search Vim help')
        call s:DirectN('<Bslash>', ':Buffers<CR>', '\', 'Fast find', 'Find open buffers')
    endif
    if exists(':Rg') == 2 && executable('rg') == 1
        \ && executable('fzf') == 1
        call s:LeaderN(['s', 'g'], ':ChopsticksProjectGrep<CR>', 'Search', 'Grep project')
        call s:LeaderN(['s', 'w'], ':ChopsticksProjectGrep <C-r><C-w><CR>', 'Search', 'Grep word under cursor')
        call s:DirectN(';r', ':ChopsticksProjectGrep<CR>', ';r', 'Fast find', 'Grep project')
    endif
    if exists(':Git') == 2 && executable('git') == 1
        call s:LeaderN(['g', 's'], ':Git status<CR>', 'Git', 'Git status')
        call s:LeaderN(['g', 'd'], ':Gdiffsplit<CR>', 'Git', 'Diff current file')
        call s:LeaderN(['g', 'b'], ':Git blame<CR>', 'Git', 'Blame current file')
        call s:LeaderN(['g', 'o'], ':GBrowse<CR>', 'Git', 'Open remote file')
    endif
    if exists(':ALEPrevious') == 2
        call s:DirectN('[e', ':ALEPrevious<CR>', '[e', 'Diagnostics', 'Previous ALE problem')
        call s:DirectN(']e', ':ALENext<CR>', ']e', 'Diagnostics', 'Next ALE problem')
        call s:LeaderN(['x', 'd'], ':ALEDetail<CR>', 'Diagnostics', 'Diagnostic detail')
        call s:LeaderN(['u', 'f'],
            \ ':let g:ale_fix_on_save = !g:ale_fix_on_save<Bar>' .
            \ 'echo ''Format on save: '' . (g:ale_fix_on_save ? ''ON'' : ''OFF'')<CR>',
            \ 'Toggles', 'Toggle format on save')
    endif
    if exists(':Make') == 2
        call s:LeaderN(['r', 'r'], ':update<Bar>Make<CR>', 'Run', 'Run project task')
    else
        call s:LeaderN(['r', 'r'], ':update<Bar>make<CR>', 'Run', 'Run make')
    endif
    if exists(':UndotreeToggle') == 2
        call s:LeaderN(['u', 'U'], ':UndotreeToggle<CR>', 'Toggles', 'Toggle undo tree')
    endif
    call s:LeaderN(['f', 'H'], ':ChopsticksDashboard<CR>', 'Files', 'Start screen')
    if exists(':Goyo') == 2
        call s:LeaderN(['z'], ':Goyo<CR>', 'Essentials', 'Focus mode')
    endif
    if exists('g:plugs') && has_key(g:plugs, 'vim-easymotion')
        nmap <silent> <leader>j <Plug>(easymotion-overwin-w)
        call chopsticks#keys#WhichKeyAdd(['j'], 'Navigation', 'Jump to visible target')
        call chopsticks#keys#Catalog('Navigation', 'n', 'SPC j', 'Jump to visible target')
    endif
endfunction

function! s:RegisterWhichKey() abort
    if exists(':WhichKey') != 2
        return
    endif
    call which_key#register('<Space>', 'g:which_key_map')
    call which_key#register(',', 'g:which_key_local_map')
    nnoremap <silent> <leader> :<C-u>WhichKey '<Space>'<CR>
    xnoremap <silent> <leader> :<C-u>WhichKeyVisual '<Space>'<CR>
endfunction

function! s:PluginsReady() abort
    call chopsticks#find#DefineCommands()
    call s:PluginMaps()
    call s:RegisterWhichKey()
endfunction

" Plugin commands are available after plug#end(), including vim-plug's lazy
" command shims. Install the maps now and repeat on VimEnter for fresh installs.
call s:PluginMaps()
call s:RegisterWhichKey()

" ── Autocommands ───────────────────────────────────────────────────────────

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
    " 'breakindent' is global, so guard every buffer and not only prose ones.
    " BufWinEnter runs after filetype setup, which is where it gets re-enabled.
    autocmd BufWinEnter * call chopsticks#markdown#GuardLongLines()
    autocmd QuickFixCmdPost [^l]* cwindow
    autocmd QuickFixCmdPost l* lwindow
    autocmd FileType fern call chopsticks#explorer#FernSetup()
    autocmd FileType which_key call chopsticks#keys#Setup()
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
    autocmd User lsp_buffer_enabled call chopsticks#lsp#Maps()
    autocmd User GoyoEnter nested call chopsticks#markdown#GoyoEnter()
    autocmd User GoyoLeave nested call chopsticks#markdown#GoyoLeave()
augroup END

augroup ChopsticksPlugins
    autocmd!
    autocmd VimEnter * call <SID>PluginsReady()
augroup END

augroup ChopsticksDirectory
    autocmd!
    autocmd BufEnter * nested call chopsticks#explorer#MaybeOpenDirectory()
augroup END

augroup ChopsticksDashboard
    autocmd!
    autocmd VimEnter * call chopsticks#startup#CaptureMs()
    autocmd VimEnter * call chopsticks#startup#MaybeOpenDashboard()
augroup END

if v:vim_did_enter
    call s:PluginMaps()
    call s:RegisterWhichKey()
endif
" A command-line :source can run after the first file was read but before
" VimEnter.  Reapply buffer-local writing defaults without relying on an LSP
" plugin to replay FileType as a side effect.
if &filetype ==# 'markdown'
    call chopsticks#markdown#Setup()
endif
