set encoding=utf-8
scriptencoding utf-8

" chopsticks — a modern, Vim-only development and Markdown writing setup

" Global rather than script-local because the dashboard's footer reports the
" startup time and now lives in autoload/chopsticks/ui/dashboard.vim, which
" cannot see this file's s: scope. It has to be captured here, in the first
" lines, so the figure covers the whole of startup.
"
" Being a global does mean a user could set it before this file runs and
" skew the reported figure. That is a cosmetic number on the dashboard
" footer, not something Chopsticks decides anything from, so the guard below
" deliberately honours an existing value rather than overwriting it.
if !exists('g:chopsticks_startup_started_at')
    let g:chopsticks_startup_started_at = reltime()
endif
let s:directory_startup_opened = 0
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

" plugin/ and autoload/ hold the Vim9 modules this file delegates public
" Chopsticks* globals to. Vim's automatic plugin-loading pass only sources
" plugin/**/*.vim from directories already on 'runtimepath', and starting
" Vim with -u pointing at this file does not add its own directory to
" 'runtimepath' automatically, so it is added explicitly before that pass
" runs.
"
" $MYVIMRC cannot be used to find that directory: the documented install
" (README.md) symlinks this file to ~/.vimrc, so $MYVIMRC names the symlink,
" and fnamemodify(..., ':h') on it gives $HOME, not this repository. The
" documented Windows install instead sources this file from a separate
" _vimrc, so there $MYVIMRC names a different file in a different directory
" entirely. resolve(expand('<sfile>:p')) gives this file's own real location
" in both cases. Vim9 modules under plugin/ and autoload/ must not depend on
" their own path (the linter sources a copy from a temporary directory), but
" that rule does not apply to this legacy script: it is always sourced from
" its real location, never copied, so <sfile> here is safe and correct.
"
" The guard keeps a manual reload (:source $MYVIMRC) from duplicating the
" 'runtimepath' entry.
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
        let l:directory .= '/'
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

" From here down, this file reaches autoload/chopsticks/ui/icons.vim and
" autoload/chopsticks/ui/theme.vim through Vim's classic dotted autoload
" names (chopsticks#ui#icons#Get(), chopsticks#ui#icons#Enabled(),
" chopsticks#ui#icons#Group(), chopsticks#ui#theme#Apply(),
" chopsticks#ui#theme#DefineInterfaceColors()) instead of the
" g:ChopsticksIcon()-style shim plugin/chopsticks.vim declares for the same
" functions. This file's own icon, ALE-sign, which-key, colorscheme, and
" statusline/tabline setup all run from its own script top level, several of
" them behind an immediate `redraw`/`redrawstatus!`/`redrawtabline` (which
" forces 'statusline'/'tabline' to evaluate right there, not lazily) -- all
" of that is well before Vim's automatic plugin-loading pass would source
" plugin/chopsticks.vim and define that shim, so calling it would fail with
" E117. The classic dotted name needs no shim and no `import`: Vim resolves
" it against 'runtimepath' (already set above) the moment it is first
" referenced, the same way g:ChopsticksIcon() eventually will, just without
" waiting for plugin/chopsticks.vim. Every function below that touches an
" icon or the theme keeps using the classic name even where it looks safely
" deferred (a mapping's RHS, an autocommand): several of them are reachable
" from both an early top-level redraw and a later, genuinely deferred one,
" and the classic name works correctly either way, so one calling
" convention here removes the need to prove which case applies at each call
" site. tests/ui.vim and autoload/chopsticks/health.vim are the only
" callers that go through the g:ChopsticksIcon()-style shim, since both
" only ever run once Vim has fully started. See plugin/chopsticks.vim's own
" comment on ChopsticksIcon() and ChopsticksIconsEnabled() for why sourcing
" that shim early, instead, is not a usable fix.
function! s:WhichKeyGroup(group) abort
    let l:icon = chopsticks#ui#icons#Group(a:group)
    return '+' . (empty(l:icon) ? '' : l:icon . ' ') . a:group
endfunction

function! s:WhichKeySetup() abort
    " Modern which-key treats a group icon and its label as one semantic
    " unit.  The Vim port's stock syntax only accepts ASCII immediately after
    " '+', so teach it to include our optional Nerd Font prefix.
    silent! syntax clear WhichKeyGroup
    syntax match WhichKeyGroup
        \ / +\%(\S\+\s\+\)\?[0-9A-Za-z_\/-]\+\%(\s\+[0-9A-Za-z_\/-]\+\)*/
endfunction

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
let s:fzf_abort_keys = 'esc:abort,ctrl-c:abort,ctrl-g:abort,ctrl-q:abort'
let s:fzf_skip_dirs = [
    \ '.git', '.cache', '.cargo', '.npm', '.pnpm-store', '.rustup',
    \ '.bun', '.codex', 'Library', 'node_modules', 'plugged',
    \ '.venv', 'venv', '__pycache__', 'build', 'dist', 'target', 'vendor',
    \ ]
" See the comment on s:WhichKeyGroup() above: this function runs both from
" this file's own top level immediately below (building g:fzf_vim) and
" later from s:RefreshIconDependents(), when icons are toggled.
function! s:FzfVisualOptions() abort
    return [
        \ '--prompt', chopsticks#ui#icons#Get('search') . ' ',
        \ '--pointer', chopsticks#ui#icons#Get('pointer'),
        \ '--marker', chopsticks#ui#icons#Get('marker'),
        \ ]
endfunction
let g:fzf_vim = {
    \ 'preview_window': s:is_remote ? [] : ['right,55%', 'ctrl-/'],
    \ 'gfiles_options': ['--bind', s:fzf_abort_keys] + s:FzfVisualOptions(),
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
" chopsticks#ui#icons#Get(), not g:ChopsticksIcon(): this file's own script
" top level, before plugin/chopsticks.vim's shim exists. See the comment on
" s:WhichKeyGroup() above.
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

" chopsticks#ui#theme#Apply(), Vim's classic dotted autoload name for
" autoload/chopsticks/ui/theme.vim's exported Apply(): this call is still
" this file's own script top level (after plug#end(), but well before Vim's
" automatic plugin-loading pass sources plugin/chopsticks.vim and defines
" its g:ChopsticksTransparencyEnabled()-style shim), so it cannot go through
" that shim; see s:WhichKeyGroup()'s comment above for the full rationale.
call chopsticks#ui#theme#Apply()

" ── Interface: statusline and buffer tabline ───────────────────────────────

" These wrappers stay in this file rather than moving to
" plugin/chopsticks.vim, which declares every other Chopsticks* global.
" 'statusline' and 'tabline' name two of them, and the `redrawtabline` a few
" lines below evaluates 'tabline' immediately, during this file's own
" execution -- long before Vim's plugin-loading pass has sourced
" plugin/chopsticks.vim. A global that does not exist yet at that moment
" fails startup with E117. The bodies live in
" autoload/chopsticks/ui/statusline.vim and bufferline.vim; these are the
" names Vim and tests/ui.vim know them by.
"
" ChopsticksWritingMode() takes two optional arguments and the rest take one,
" matching the legacy signatures exactly: tests/plugins.vim calls
" ChopsticksDiagnostics() and ChopsticksGitDiff() WITH a buffer argument
" while tests/ui.vim calls ChopsticksWritingMode() with none, so neither a
" fixed arity nor a dropped argument would do.
function! ChopsticksUiDensity() abort
    return chopsticks#ui#statusline#UiDensity()
endfunction

function! ChopsticksStatusline() abort
    return chopsticks#ui#statusline#Render()
endfunction

function! ChopsticksTabline() abort
    return chopsticks#ui#bufferline#Render()
endfunction

function! ChopsticksFileIcon(path) abort
    return chopsticks#ui#icons#FileIcon(a:path)
endfunction

function! ChopsticksMode(...) abort
    return call('chopsticks#ui#statusline#Mode', a:000)
endfunction

function! ChopsticksGitBranch(...) abort
    return call('chopsticks#ui#statusline#GitBranch', a:000)
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

function! ChopsticksBufferFlags(...) abort
    return call('chopsticks#ui#statusline#BufferFlags', a:000)
endfunction

" Stays here because it is the only one of these that needs s:ResolveSwitch(),
" which resolves the 'auto' form of every g:chopsticks_* switch and is still
" this file's own.
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

" icons.vim's own Toggle()/Apply() (see plugin/chopsticks.vim) now own the
" fern/ALE icon variables an icon toggle re-applies. The rest of what a live
" toggle always also refreshed -- fzf's gfiles options, the statusline's
" file-icon cache, a dashboard re-render, and the status/tabline redraw --
" is not an icon concern and stays here, since Vim9 script-local names
" cannot cross files (s:fzf_abort_keys, s:FzfVisualOptions(), and
" s:file_icon_cache are all local to this file; the dashboard re-render
" reaches its own module by the classic dotted name).
" icons.vim's Toggle() fires a guarded `User ChopsticksIconsToggled`
" autocommand right after it applies (see the augroup below) so this still
" runs in the same order it always has, without plugin/chopsticks.vim
" needing a second global just to reach it.
function! s:RefreshIconDependents() abort
    let g:fzf_vim.gfiles_options =
        \ ['--bind', s:fzf_abort_keys] + s:FzfVisualOptions()
    let s:file_icon_cache = {}
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
    " chopsticks#ui#theme#DefineInterfaceColors(), not the g: shim: the
    " `:colorscheme` command chopsticks#ui#theme#Apply() runs above triggers
    " this ColorScheme autocommand synchronously, at this file's own top
    " level, before plugin/chopsticks.vim's shim exists -- the same reason
    " Apply() itself is reached through the classic dotted name (see the
    " comment above it). :ChopsticksTheme and :ChopsticksTransparencyToggle
    " also trigger this event, well after startup, but the classic name
    " works there too, so one call site covers both.
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

function! s:MakeParent(path) abort
    if empty(a:path) || &buftype !=# '' || a:path =~# '^\w\+://'
        return
    endif
    let l:dir = fnamemodify(a:path, ':h')
    if !isdirectory(l:dir)
        silent! call mkdir(l:dir, 'p')
    endif
endfunction

" Project-root resolution, session save/load, and their permission checks now
" live in autoload/chopsticks/session.vim (Vim9 script). ChopsticksProjectRoot()
" and ChopsticksSessionPath() (see plugin/chopsticks.vim) delegate to it, the
" same shim shape ChopsticksIconsEnabled() and friends already use -- a
" Vim9 `:import` statement cannot be used here: vimlint's legacy-script
" parser (vim-vimlparser) does not understand `import autoload` syntax and
" fails to parse this file if one is added.

function! s:FzfFileSource() abort
    if executable('fd') == 1
        let l:parts = ['fd', '--type', 'f', '--hidden', '--color', 'never']
        for l:directory in s:fzf_skip_dirs
            call extend(l:parts, ['--exclude', shellescape(l:directory)])
        endfor
        return join(l:parts, ' ')
    endif
    if executable('rg') == 1
        let l:parts = ['rg', '--files', '--hidden', '--color', 'never']
        for l:directory in s:fzf_skip_dirs
            call extend(l:parts,
                \ ['--glob', shellescape('!**/' . l:directory . '/**')])
        endfor
        return join(l:parts, ' ')
    endif
    return ''
endfunction

function! s:FzfFiles(path, bang) abort
    let l:root = empty(a:path) ? ChopsticksProjectRoot() : expand(a:path)
    let l:root = fnamemodify(l:root, ':p')
    let l:options = [
        \ '--bind', s:fzf_abort_keys,
        \ '--header', chopsticks#ui#icons#Get('quit')
        \     . ' ESC / CTRL-Q close · ENTER open',
        \ ]
    call extend(l:options, s:FzfVisualOptions())
    let l:spec = {'dir': l:root, 'options': l:options}
    let l:source = s:FzfFileSource()
    if !empty(l:source)
        let l:spec.source = l:source
    endif
    call fzf#vim#files(l:root, fzf#vim#with_preview(l:spec), a:bang)
endfunction

function! s:ProjectFzfSpec() abort
    return {'dir': ChopsticksProjectRoot()}
endfunction

function! s:ProjectGrep(query, bang) abort
    if exists(':Rg') != 2 || executable('rg') != 1
        \ || executable('fzf') != 1
        echohl WarningMsg | echom 'chopsticks: project grep needs fzf.vim and rg' | echohl None
        return
    endif
    let l:command = 'rg --column --line-number --no-heading '
        \ . '--color=always --smart-case -- ' . fzf#shellescape(a:query)
    call fzf#vim#grep(
        \ l:command, fzf#vim#with_preview(s:ProjectFzfSpec()), a:bang)
endfunction

command! -bang -nargs=* ChopsticksProjectGrep
    \ call s:ProjectGrep(<q-args>, <bang>0)

function! s:ProjectGitFiles() abort
    if exists(':GFiles') != 2 || executable('git') != 1
        \ || executable('fzf') != 1
        echohl WarningMsg | echom 'chopsticks: Git file search needs Git and fzf.vim' | echohl None
        return
    endif
    let l:root = ChopsticksProjectRoot()
    call system('git -C ' . shellescape(l:root) . ' rev-parse --is-inside-work-tree')
    if v:shell_error != 0
        echohl WarningMsg | echom 'chopsticks: current buffer is outside a Git worktree' | echohl None
        return
    endif
    call fzf#vim#gitfiles(
        \ '', fzf#vim#with_preview(s:ProjectFzfSpec()), 0)
endfunction

function! s:FindFiles() abort
    if executable('fzf') == 1 && exists(':GFiles') == 2
        \ && executable('git') == 1
        let l:root = ChopsticksProjectRoot()
        call system('git -C ' . shellescape(l:root) . ' rev-parse --is-inside-work-tree')
        if v:shell_error == 0
            call s:ProjectGitFiles()
            return
        endif
    endif
    if executable('fzf') == 1 && exists(':Files') == 2
        execute 'Files ' . fnameescape(ChopsticksProjectRoot())
        return
    endif
    execute 'edit ' . fnameescape(ChopsticksProjectRoot())
endfunction

command! ChopsticksFindFiles call s:FindFiles()

function! s:RecentFiles() abort
    if executable('fzf') == 1 && exists(':History') == 2
        History
    elseif !empty(v:oldfiles)
        browse oldfiles
    else
        echohl WarningMsg
        echom 'chopsticks: no recent files yet'
        echohl None
    endif
endfunction

command! ChopsticksRecentFiles call s:RecentFiles()

function! s:DefineFzfCommands() abort
    if executable('fzf') == 1 && exists(':Files') == 2
        command! -bang -nargs=? -complete=dir Files
            \ call s:FzfFiles(<q-args>, <bang>0)
    endif
endfunction
call s:DefineFzfCommands()

function! s:CopyPath(relative) abort
    if empty(expand('%:p'))
        echohl WarningMsg | echom 'chopsticks: current buffer has no file path' | echohl None
        return
    endif
    let l:path = a:relative ? fnamemodify(expand('%:p'), ':.') : expand('%:p')
    if has('clipboard')
        call setreg('+', l:path)
    endif
    call setreg('"', l:path)
    echo 'copied: ' . l:path
endfunction

function! s:ExplorerWindow() abort
    for l:window in getwininfo()
        if l:window.tabnr == tabpagenr()
            \ && index(['fern', 'netrw'],
            \     getbufvar(l:window.bufnr, '&filetype')) >= 0
            return l:window.winid
        endif
    endfor
    return 0
endfunction

function! s:FernAvailable() abort
    return get(g:, 'chopsticks_use_fern', 1)
        \ && exists(':Fern') == 2
endfunction

function! s:PathInside(path, directory) abort
    let l:path = resolve(fnamemodify(a:path, ':p'))
    let l:directory = resolve(fnamemodify(a:directory, ':p'))
    if s:is_windows
        let l:path = substitute(l:path, '\\', '/', 'g')
        let l:directory = substitute(l:directory, '\\', '/', 'g')
        let l:path = substitute(l:path, '/\+$', '', '')
        let l:directory = substitute(l:directory, '/\+$', '', '')
        return l:path ==? l:directory
            \ || stridx(tolower(l:path),
            \     tolower(l:directory . '/')) == 0
    endif
    let l:path = substitute(l:path, '/\+$', '', '')
    let l:directory = substitute(l:directory, '/\+$', '', '')
    return l:path ==# l:directory
        \ || stridx(l:path, l:directory . '/') == 0
endfunction

function! s:ToggleExplorer(directory) abort
    if s:FernAvailable()
        let l:directory = fnamemodify(a:directory, ':p')
        let l:command = 'Fern ' . fnameescape(l:directory)
            \ . ' -drawer -toggle -width=' . g:fern#drawer_width
        let l:current = expand('%:p')
        if filereadable(l:current) && s:PathInside(l:current, l:directory)
            let l:command .= ' -reveal=' . fnameescape(l:current)
        endif
        execute l:command
        return
    endif
    let l:explorer = s:ExplorerWindow()
    if l:explorer
        let l:origin = win_getid()
        if win_gotoid(l:explorer)
            close
        endif
        if l:origin != l:explorer && win_id2win(l:origin) > 0
            call win_gotoid(l:origin)
        endif
        return
    endif
    execute 'Lexplore ' . fnameescape(a:directory)
endfunction

function! s:FernSetup() abort
    setlocal nonumber norelativenumber signcolumn=no winfixwidth cursorline
    " Match the reversible node interaction used by mature file trees: the
    " same key opens a file, expands a closed directory, and collapses an
    " open directory.  expand:stay keeps the cursor on the directory so the
    " second press can close it again.
    nmap <buffer><silent><expr> <Plug>(chopsticks-fern-toggle-node)
        \ fern#smart#leaf(
        \ "\<Plug>(fern-action-open)",
        \ "\<Plug>(fern-action-expand:stay)",
        \ "\<Plug>(fern-action-collapse)")
    nmap <silent><buffer> <CR> <Plug>(chopsticks-fern-toggle-node)
    nmap <silent><buffer> l <Plug>(chopsticks-fern-toggle-node)
    nmap <buffer><silent><expr> <Plug>(chopsticks-fern-parent-or-collapse)
        \ fern#smart#leaf(
        \ "\<Plug>(fern-action-focus:parent)",
        \ "\<Plug>(fern-action-focus:parent)",
        \ "\<Plug>(fern-action-collapse)")
    nmap <silent><buffer> h <Plug>(chopsticks-fern-parent-or-collapse)
    nmap <silent><buffer> o <Plug>(fern-action-open)
    nmap <silent><buffer> s <Plug>(fern-action-open:split)
    nmap <silent><buffer> v <Plug>(fern-action-open:vsplit)
    nmap <silent><buffer> t <Plug>(fern-action-open:tabedit)
    nmap <silent><buffer> N <Plug>(fern-action-new-path)
    nmap <silent><buffer> r <Plug>(fern-action-rename)
    nmap <silent><buffer> x <Plug>(fern-action-mark:toggle)
    nmap <silent><buffer> . <Plug>(fern-action-hidden:toggle)
    nmap <silent><buffer> R <Plug>(fern-action-reload:all)
    nnoremap <silent><buffer> q :close<CR>
    nnoremap <silent><buffer> <Esc> :close<CR>
    if chopsticks#ui#icons#Enabled()
        try
            call glyph_palette#apply()
        catch /^Vim\%((\a\+)\)\=:E117/
        endtry
    endif
endfunction

function! s:ExploreRoot() abort
    call s:ToggleExplorer(ChopsticksProjectRoot())
endfunction

function! s:ExploreHere() abort
    if &filetype ==# 'fern'
        call s:ToggleExplorer(getcwd())
        return
    endif
    let l:directory = empty(expand('%:p')) ? getcwd() : expand('%:p:h')
    call s:ToggleExplorer(l:directory)
endfunction

function! s:MaybeOpenDirectory() abort
    if s:directory_startup_opened || argc() != 1
        \ || !isdirectory(argv(0)) || &modified
        return
    endif
    let l:directory = fnamemodify(argv(0), ':p')
    if !isdirectory(expand('%:p'))
        return
    endif
    let s:directory_startup_opened = 1
    let l:directory_buffer = bufnr('%')
    silent keepalt enew
    execute 'lcd ' . fnameescape(l:directory)
    if l:directory_buffer != bufnr('%') && bufexists(l:directory_buffer)
        execute 'silent! bwipeout ' . l:directory_buffer
    endif
    call s:ToggleExplorer(l:directory)
endfunction

function! s:ToggleQuickfix() abort
    for l:window in getwininfo()
        if get(l:window, 'quickfix', 0) && !get(l:window, 'loclist', 0)
            cclose
            return
        endif
    endfor
    copen
endfunction

function! s:ToggleLocationList() abort
    for l:window in getwininfo()
        if get(l:window, 'quickfix', 0) && get(l:window, 'loclist', 0)
            lclose
            return
        endif
    endfor
    try
        lopen
    catch /^Vim\%((\a\+)\)\=:E776/
        echohl WarningMsg | echom 'chopsticks: location list is empty' | echohl None
    endtry
endfunction

function! s:DeleteOtherBuffers() abort
    let l:current = bufnr('%')
    let l:deleted = 0
    let l:kept = 0
    for l:buffer in getbufinfo({'buflisted': 1})
        if l:buffer.bufnr == l:current
            continue
        endif
        if getbufvar(l:buffer.bufnr, '&modified')
            let l:kept += 1
            continue
        endif
        execute 'silent bdelete ' . l:buffer.bufnr
        let l:deleted += 1
    endfor
    echo printf('buffers: deleted %d, kept %d modified', l:deleted, l:kept)
endfunction

function! s:OpenTerminal(command, position) abort
    if !has('terminal')
        echohl ErrorMsg | echom 'chopsticks: this Vim has no +terminal' | echohl None
        return
    endif
    if a:position ==# 'tab'
        tabnew
    else
        botright 12new
    endif
    if empty(a:command)
        call term_start(&shell, {'curwin': 1})
    else
        call term_start(a:command, {'curwin': 1, 'term_finish': 'close'})
    endif
    startinsert
endfunction

function! s:OpenLazygit() abort
    if executable('lazygit') != 1
        echohl WarningMsg | echom 'chopsticks: lazygit is not installed' | echohl None
        return
    endif
    call s:OpenTerminal(['lazygit', '--path', ChopsticksProjectRoot()], 'tab')
endfunction

function! s:OpenScratch(name, lines) abort
    botright new
    execute 'file ' . fnameescape(a:name)
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nowrap nonumber norelativenumber signcolumn=no
    setlocal modifiable
    silent %delete _
    call setline(1, a:lines)
    setlocal nomodifiable nomodified
    nnoremap <silent><buffer> q :close<CR>
    nnoremap <silent><buffer> <Esc> :close<CR>
    normal! gg
endfunction

" ChopsticksHealthLines()/:ChopsticksHealth now live in
" autoload/chopsticks/health.vim (Vim9 script); see plugin/chopsticks.vim for
" the ChopsticksHealthLines() global and the :ChopsticksHealth command.

let s:key_catalog = []
let s:key_catalog_index = {}
let s:key_group_order = [
    \ 'Essentials', 'Fast find', 'Buffers', 'Windows', 'Files', 'Search', 'Quit',
    \ 'Git', 'Code', 'Diagnostics', 'Run', 'Terminal', 'Tabs', 'Toggles',
    \ 'Editing', 'Navigation', 'Markdown',
    \ ]
let g:which_key_map = {}
let g:which_key_local_map = {'name': s:WhichKeyGroup('Markdown')}

function! s:Catalog(group, mode, keys, description) abort
    let l:id = a:mode . "\n" . a:keys
    let l:entry = {
        \ 'group': a:group,
        \ 'mode': a:mode,
        \ 'keys': a:keys,
        \ 'description': a:description,
        \ }
    if has_key(s:key_catalog_index, l:id)
        let s:key_catalog[s:key_catalog_index[l:id]] = l:entry
    else
        let s:key_catalog_index[l:id] = len(s:key_catalog)
        call add(s:key_catalog, l:entry)
    endif
endfunction

function! s:LeaderLabel(parts) abort
    let l:tokens = []
    for l:token in a:parts
        if l:token ==# '<Space>'
            call add(l:tokens, 'SPC ')
        elseif l:token ==# '<Tab>'
            call add(l:tokens, 'TAB ')
        elseif l:token ==# '<Bar>'
            call add(l:tokens, '|')
        else
            call add(l:tokens, l:token)
        endif
    endfor
    return 'SPC ' . trim(join(l:tokens, ''))
endfunction

function! s:WhichKeyAdd(parts, group, description) abort
    if empty(a:parts)
        return
    endif
    let l:node = g:which_key_map
    if len(a:parts) > 1
        for l:index in range(0, len(a:parts) - 2)
            let l:key = a:parts[l:index]
            if !has_key(l:node, l:key) || type(l:node[l:key]) != type({})
                let l:node[l:key] = {'name': s:WhichKeyGroup(a:group)}
            elseif !has_key(l:node[l:key], 'name')
                let l:node[l:key].name = s:WhichKeyGroup(a:group)
            endif
            let l:node = l:node[l:key]
        endfor
    endif
    let l:node[a:parts[len(a:parts) - 1]] = a:description
endfunction

function! s:LeaderN(parts, rhs, group, description) abort
    execute 'nnoremap <silent> <leader>' . join(a:parts, '') . ' ' . a:rhs
    call s:WhichKeyAdd(a:parts, a:group, a:description)
    call s:Catalog(a:group, 'n', s:LeaderLabel(a:parts), a:description)
endfunction

function! s:LeaderX(parts, rhs, group, description) abort
    execute 'xnoremap <silent> <leader>' . join(a:parts, '') . ' ' . a:rhs
    call s:WhichKeyAdd(a:parts, a:group, a:description)
    call s:Catalog(a:group, 'x', s:LeaderLabel(a:parts), a:description)
endfunction

function! s:DirectN(lhs, rhs, label, group, description) abort
    execute 'nnoremap <silent> ' . a:lhs . ' ' . a:rhs
    call s:Catalog(a:group, 'n', a:label, a:description)
endfunction

function! s:DirectX(lhs, rhs, label, group, description) abort
    execute 'xnoremap <silent> ' . a:lhs . ' ' . a:rhs
    call s:Catalog(a:group, 'x', a:label, a:description)
endfunction

function! ChopsticksKeyLines() abort
    let l:lines = [
        \ 'chopsticks ' . g:chopsticks_version . ' cheatsheet',
        \ '',
        \ 'SPC = Leader   , = Markdown LocalLeader',
        \ 'Pause after SPC or , for the contextual key guide.',
        \ 'Use / to search this sheet, n/N to move, and q to close.',
        \ 'Modes: n normal · x visual · i insert · t terminal · * buffer-local',
        \ ]
    for l:group in s:key_group_order
        let l:entries = filter(copy(s:key_catalog), 'v:val.group ==# l:group')
        if empty(l:entries)
            continue
        endif
        call extend(l:lines, ['', l:group])
        for l:entry in l:entries
            call add(l:lines, printf('  %-15s %-2s  %s',
                \ l:entry.keys, l:entry.mode, l:entry.description))
        endfor
    endfor
    return l:lines
endfunction

function! s:Keys() abort
    call s:OpenScratch('[chopsticks-cheatsheet]', ChopsticksKeyLines())
    setlocal filetype=chopsticks-cheatsheet cursorline
endfunction

command! ChopsticksKeys call s:Keys()
command! ChopsticksCheatsheet call s:Keys()

" ── Markdown and prose ─────────────────────────────────────────────────────

let g:which_key_local_map = {
    \ 'name': s:WhichKeyGroup('Markdown'),
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
        \ 'name': s:WhichKeyGroup('Table'),
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
    call s:Catalog('Markdown', s:markdown_key[0], s:markdown_key[1], s:markdown_key[2])
endfor
unlet s:markdown_key

function! s:MarkdownToggleConceal() abort
    let &l:conceallevel = &l:conceallevel == 0 ? 2 : 0
    echo 'Markdown conceal: ' . (&l:conceallevel ? 'ON' : 'OFF')
endfunction

function! s:MarkdownGlow() abort
    if executable('glow') != 1
        echohl WarningMsg | echom 'chopsticks: install glow for terminal Markdown preview' | echohl None
        return
    endif
    if empty(expand('%:p'))
        echohl WarningMsg | echom 'chopsticks: save the Markdown file before previewing it' | echohl None
        return
    endif
    silent update
    call s:OpenTerminal(['glow', '-p', expand('%:p')], 'split')
endfunction

function! s:MarkdownPasteImage(name) abort
    if executable('pngpaste') != 1
        echohl WarningMsg
        echom 'chopsticks: Markdown image paste needs pngpaste (brew install pngpaste)'
        echohl None
        return
    endif
    if empty(expand('%:p'))
        echohl WarningMsg | echom 'chopsticks: save the Markdown file before pasting an image' | echohl None
        return
    endif
    let l:name = empty(a:name) ? 'image-' . strftime('%Y%m%d-%H%M%S') : a:name
    let l:name = substitute(l:name, '[/\\:[:cntrl:]]', '-', 'g')
    if l:name !~? '\.png$'
        let l:name .= '.png'
    endif
    let l:relative_dir = g:chopsticks_markdown_image_dir
    let l:absolute_dir = expand('%:p:h') . '/' . l:relative_dir
    let l:absolute_path = l:absolute_dir . '/' . l:name
    if filereadable(l:absolute_path)
        echohl ErrorMsg | echom 'chopsticks: image already exists: ' . l:absolute_path | echohl None
        return
    endif
    call mkdir(l:absolute_dir, 'p')
    call system(shellescape(exepath('pngpaste')) . ' ' . shellescape(l:absolute_path))
    if v:shell_error != 0 || !filereadable(l:absolute_path)
        silent! call delete(l:absolute_path)
        echohl ErrorMsg | echom 'chopsticks: clipboard does not contain a PNG image' | echohl None
        return
    endif
    let l:alt = fnamemodify(l:name, ':r')
    let l:link = '![' . l:alt . '](' . l:relative_dir . '/' . l:name . ')'
    if empty(getline('.'))
        call setline('.', l:link)
    else
        call append('.', l:link)
        normal! j
    endif
    echo 'saved: ' . l:relative_dir . '/' . l:name
endfunction

function! s:MarkdownHelp() abort
    call s:OpenScratch('[chopsticks-markdown]', [
        \ 'chopsticks Markdown',
        \ '',
        \ 'Writing',
        \ '  ,z       focus mode (Goyo + Limelight)',
        \ '  ,s       toggle spelling; ]s/[s navigate, z= choose',
        \ '  ,c       toggle syntax conceal',
        \ '  gqap     format paragraph; g<C-g> word count',
        \ '',
        \ 'Structure',
        \ '  ,x       toggle task checkbox (parents follow children)',
        \ '  gN       renumber list',
        \ '  ]] / [[  next / previous heading; ]u parent heading',
        \ '  ,o       heading outline; ,O insert table of contents',
        \ '  ,tt      table mode; ,tr realign; visual ,tc tableize',
        \ '',
        \ 'Links and output',
        \ '  gx / ge  open URL in browser / edit linked Markdown',
        \ '  ,p       live browser preview (Previm)',
        \ '  ,g       terminal preview (Glow)',
        \ '  ,i       paste clipboard PNG into assets/',
        \ '  ,l / ,f  lint now / format with Prettier',
        \ '',
        \ 'Press q to close.',
        \ ])
endfunction

" Vim recomputes the break indent while laying out every wrapped screen line,
" so one very long line degrades far worse than linearly: a 1 MiB single-line
" Markdown file turns a single redraw into tens of seconds. The file-size
" guard below does not catch this, because the cost follows line length rather
" than total bytes. Drop the option on buffers that contain such a line.
" Detection itself has to stay cheap, because this runs for every buffer that
" reaches a window. A virtual-column search is not an option: computing screen
" columns over an enormous line is slower than the problem it looks for.
function! s:HasLongLine() abort
    let l:lines = line('$')
    if l:lines <= 0
        return 0
    endif
    " Constant time, and decisive for the case that actually degrades: a buffer
    " that is mostly one very long line.
    let l:bytes = line2byte(l:lines + 1)
    if l:bytes > 0 && l:bytes / l:lines > g:chopsticks_long_line_threshold
        return 1
    endif
    " Exact, but only for buffers small enough that walking them costs well
    " under a millisecond, so this guard never shows up in a startup budget.
    " Larger buffers keep the constant-time answer above.
    if l:lines > 2000
        return 0
    endif
    return max(map(range(1, l:lines), 'col([v:val, "$"])'))
        \ > g:chopsticks_long_line_threshold
endfunction

function! s:GuardLongLines() abort
    if !exists('+breakindent') || g:chopsticks_long_line_threshold <= 0
        return
    endif
    if s:HasLongLine()
        setlocal nobreakindent
    endif
endfunction

function! s:MarkdownSetup() abort
    setlocal wrap linebreak breakindent textwidth=0 colorcolumn=0
    setlocal norelativenumber nolist signcolumn=auto foldlevel=99
    let &l:conceallevel = g:chopsticks_markdown_conceal ? 2 : 0
    if g:chopsticks_markdown_spell
        setlocal spell spelllang=en_us,cjk
    else
        setlocal nospell
    endif
    if exists(':Pencil') == 2
        call pencil#init({'wrap': 'soft'})
        let &l:conceallevel = g:chopsticks_markdown_conceal ? 2 : 0
    endif

    if !empty(maparg('<Plug>(bullets-newline)', 'i'))
        imap <silent><buffer> <CR> <Plug>(bullets-newline)
        nmap <silent><buffer> o <Plug>(bullets-newline)
        nmap <silent><buffer> gN <Plug>(bullets-renumber)
        xmap <silent><buffer> gN <Plug>(bullets-renumber)
        nmap <silent><buffer> <localleader>x <Plug>(bullets-toggle-checkbox)
    endif
    if exists(':Toc') == 2
        nnoremap <silent><buffer> <localleader>o :Toc<CR>
        nnoremap <silent><buffer> <localleader>O :InsertToc 3<CR>
    endif
    if exists(':TableModeToggle') == 2
        nnoremap <silent><buffer> <localleader>tt :TableModeToggle<CR>
        nnoremap <silent><buffer> <localleader>tr :TableModeRealign<CR>
        xnoremap <silent><buffer> <localleader>tc :Tableize<CR>
    endif
    if exists(':PrevimOpen') == 2
        nnoremap <silent><buffer> <localleader>p :PrevimOpen<CR>
    endif
    if exists(':Goyo') == 2
        nnoremap <silent><buffer> <localleader>z :Goyo<CR>
    endif
    nnoremap <silent><buffer> <localleader>? :call <SID>MarkdownHelp()<CR>
    nnoremap <silent><buffer> <localleader>s :setlocal spell! spell?<CR>
    nnoremap <silent><buffer> <localleader>c :call <SID>MarkdownToggleConceal()<CR>
    nnoremap <silent><buffer> <localleader>g :call <SID>MarkdownGlow()<CR>
    nnoremap <silent><buffer> <localleader>i :MarkdownPasteImage<CR>
    if exists(':WhichKey') == 2
        nnoremap <silent><buffer> <localleader> :<C-u>WhichKey ','<CR>
        xnoremap <silent><buffer> <localleader> :<C-u>WhichKeyVisual ','<CR>
    endif
    if exists(':ALELint') == 2
        nnoremap <silent><buffer> <localleader>l :ALELint<CR>
        nnoremap <silent><buffer> <localleader>f :ALEFix<CR>
    endif
    call s:GuardLongLines()
endfunction

function! s:ProseSetup() abort
    setlocal wrap linebreak breakindent textwidth=0 colorcolumn=0
    setlocal norelativenumber
    if exists(':Pencil') == 2
        call pencil#init({'wrap': 'soft'})
    endif
    if &filetype ==# 'gitcommit' || &filetype ==# 'mail'
        setlocal spell spelllang=en_us,cjk
    endif
    call s:GuardLongLines()
endfunction

function! s:GoyoEnter() abort
    if &filetype =~# '^\%(markdown\|text\|gitcommit\)$' && exists(':Limelight') == 2
        silent Limelight
    endif
    setlocal wrap linebreak
    call chopsticks#ui#bufferline#Refresh()
endfunction

function! s:GoyoLeave() abort
    if exists(':Limelight') == 2
        silent! execute 'Limelight!'
    endif
    call chopsticks#ui#bufferline#Refresh()
endfunction

command! -nargs=? -complete=file MarkdownPasteImage call s:MarkdownPasteImage(<q-args>)
command! MarkdownGlow call s:MarkdownGlow()
command! MarkdownHelp call s:MarkdownHelp()

" ── LSP and completion ─────────────────────────────────────────────────────

function! s:LspMaps() abort
    if !exists('*lsp#complete')
        return
    endif
    setlocal omnifunc=lsp#complete
    nmap <silent><buffer> gd <Plug>(lsp-definition)
    nmap <silent><buffer> gr <Plug>(lsp-references)
    nmap <silent><buffer> gI <Plug>(lsp-implementation)
    nmap <silent><buffer> gy <Plug>(lsp-type-definition)
    nmap <silent><buffer> K <Plug>(lsp-hover)
    nmap <silent><buffer> [d <Plug>(lsp-previous-diagnostic)
    nmap <silent><buffer> ]d <Plug>(lsp-next-diagnostic)
    nmap <silent><buffer> <leader>ca <Plug>(lsp-code-action)
    nmap <silent><buffer> <leader>cr <Plug>(lsp-rename)
    nmap <silent><buffer> <leader>cf <Plug>(lsp-document-format)
    xmap <silent><buffer> <leader>cf <Plug>(lsp-document-range-format)
    nmap <silent><buffer> <leader>co <Plug>(lsp-document-symbol-search)
    nmap <silent><buffer> <leader>cS <Plug>(lsp-workspace-symbol-search)
    nnoremap <silent><buffer> <leader>ci :LspStatus<CR>
    for l:item in [
        \ [['c', 'a'], 'Code action'],
        \ [['c', 'f'], 'Format document'],
        \ [['c', 'i'], 'LSP status'],
        \ [['c', 'o'], 'Document symbols'],
        \ [['c', 'r'], 'Rename symbol'],
        \ [['c', 'S'], 'Workspace symbols'],
        \ ]
        call s:WhichKeyAdd(l:item[0], 'Code', l:item[1])
        call s:Catalog('Code', 'n*', s:LeaderLabel(l:item[0]), l:item[1])
    endfor
    for l:item in [
        \ ['gd', 'Go to definition'], ['gr', 'Find references'],
        \ ['gI', 'Go to implementation'], ['gy', 'Go to type definition'],
        \ ['K', 'Hover documentation'], ['[d / ]d', 'Previous / next LSP diagnostic'],
        \ ]
        call s:Catalog('Code', 'n*', l:item[0], l:item[1])
    endfor
endfunction

function! s:CheckBackspace() abort
    let l:column = col('.') - 1
    return !l:column || getline('.')[l:column - 1] =~# '\s'
endfunction

function! s:CompletionTab() abort
    if pumvisible()
        return "\<C-n>"
    endif
    if s:CheckBackspace() || !exists('*asyncomplete#force_refresh')
        return "\<Tab>"
    endif
    return asyncomplete#force_refresh()
endfunction

function! s:CompletionBackTab() abort
    return pumvisible() ? "\<C-p>" : "\<C-h>"
endfunction

inoremap <silent><expr> <Tab> <SID>CompletionTab()
inoremap <silent><expr> <S-Tab> <SID>CompletionBackTab()

" ── Core mappings ──────────────────────────────────────────────────────────

" Save from any editing mode without moving either hand off the home row.
nnoremap <silent> <C-s> :update<CR>
inoremap <silent> <C-s> <C-o>:update<CR>
xnoremap <silent> <C-s> :<C-u>update<CR>gv
call s:Catalog('Essentials', 'n/i/x', 'Ctrl-s', 'Save file')
call s:LeaderN(['?'], ':ChopsticksCheatsheet<CR>', 'Essentials', 'Full cheatsheet')
call s:LeaderN(['e'], ':call <SID>ExploreRoot()<CR>', 'Files', 'Explore project root')
call s:LeaderN(['E'], ':call <SID>ExploreHere()<CR>', 'Files', 'Explore current file directory')

" Wrapped prose moves by screen line; counts retain physical-line semantics.
nnoremap <silent><expr> j v:count == 0 ? 'gj' : 'j'
nnoremap <silent><expr> k v:count == 0 ? 'gk' : 'k'
xnoremap <silent><expr> j v:count == 0 ? 'gj' : 'j'
xnoremap <silent><expr> k v:count == 0 ? 'gk' : 'k'
nnoremap <silent> <Esc> :nohlsearch<CR><Esc>
call s:Catalog('Navigation', 'n/x', 'j / k', 'Screen line; count uses physical line')
call s:Catalog('Navigation', 'n', 'Esc', 'Clear search highlight')

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
call s:DirectN('se', ':call <SID>ExploreHere()<CR>', 'se', 'Windows', 'Explore current file directory')
call s:DirectN('<C-Up>', ':resize +2<CR>', 'Ctrl-Up', 'Windows', 'Increase height')
call s:DirectN('<C-Down>', ':resize -2<CR>', 'Ctrl-Down', 'Windows', 'Decrease height')
call s:DirectN('<C-Left>', ':vertical resize -2<CR>', 'Ctrl-Left', 'Windows', 'Decrease width')
call s:DirectN('<C-Right>', ':vertical resize +2<CR>', 'Ctrl-Right', 'Windows', 'Increase width')
call s:LeaderN(['-'], '<C-w>s', 'Windows', 'Split below')
nnoremap <silent> <leader><Bar> <C-w>v
call s:WhichKeyAdd(['<Bar>'], 'Windows', 'Split right')
call s:Catalog('Windows', 'n', 'SPC |', 'Split right')
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
call s:Catalog('Editing', 'n/i/x', 'Alt-j / Alt-k', 'Move line or selection')
call s:Catalog('Editing', 'x', '< / >', 'Indent and keep selection')

nnoremap <silent> x "_x
call s:LeaderN(['p'], '"0p', 'Editing', 'Paste without clobbering yank')
call s:LeaderN(['P'], '"0P', 'Editing', 'Paste last yank before cursor')
call s:LeaderX(['p'], '"_dP', 'Editing', 'Paste without replacing yank')
call s:WhichKeyAdd(['p'], 'Editing', 'Paste without clobbering yank')
call s:LeaderN(['v'], '`[v`]', 'Editing', 'Reselect last change')
if has('clipboard')
    call s:LeaderN(['y'], '"+y', 'Editing', 'Yank to system clipboard')
    call s:LeaderX(['y'], '"+y', 'Editing', 'Yank to system clipboard')
    call s:LeaderN(['Y'], '"+Y', 'Editing', 'Yank line to system clipboard')
endif
call s:Catalog('Editing', 'n', 'x', 'Delete character without changing registers')

nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <C-d> <C-d>zz
xnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
xnoremap <C-u> <C-u>zz
call s:Catalog('Navigation', 'n', 'n / N', 'Search result centered')
call s:Catalog('Navigation', 'n/x', 'Ctrl-d / Ctrl-u', 'Half-page centered')

nnoremap <silent> [<Space> :<C-u>put! =repeat(nr2char(10), v:count1)<CR>'[
nnoremap <silent> ]<Space> :<C-u>put =repeat(nr2char(10), v:count1)<CR>
call s:Catalog('Editing', 'n', '[SPC / ]SPC', 'Insert blank line above / below')
call s:LeaderN(['s', 'r'], ':%s/\<<C-r><C-w>\>//g<Left><Left>', 'Search', 'Replace word under cursor')
call s:LeaderX(['s', 'r'], ':s///g<Left><Left><Left>', 'Search', 'Replace in selection')
call s:WhichKeyAdd(['s', 'r'], 'Search', 'Replace text')
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
call s:Catalog('Diagnostics', 'n', '[x / ]x', 'Previous / next conflict marker')
call s:LeaderN(['x', 'q'], ':call <SID>ToggleQuickfix()<CR>', 'Diagnostics', 'Toggle quickfix list')
call s:LeaderN(['x', 'l'], ':call <SID>ToggleLocationList()<CR>', 'Diagnostics', 'Toggle location list')

call s:LeaderN(['b', 'b'], ':buffer #<CR>', 'Buffers', 'Switch to other buffer')
call s:LeaderN(['b', 'd'], ':bdelete<CR>', 'Buffers', 'Delete buffer')
call s:LeaderN(['b', 'n'], ':bnext<CR>', 'Buffers', 'Next buffer')
call s:LeaderN(['b', 'p'], ':bprevious<CR>', 'Buffers', 'Previous buffer')
call s:LeaderN(['b', 'o'], ':call <SID>DeleteOtherBuffers()<CR>', 'Buffers', 'Delete other unmodified buffers')

call s:LeaderN(['f', 'n'], ':enew<CR>', 'Files', 'New file')
call s:LeaderN(['f', 's'], ':update<CR>', 'Files', 'Save file')
call s:LeaderN(['f', 'S'], ':wall<CR>', 'Files', 'Save all files')
call s:LeaderN(['f', 'd'], ':lcd %:p:h<CR>:pwd<CR>', 'Files', 'Use file directory locally')
call s:LeaderN(['f', 'e'], ':call <SID>ExploreRoot()<CR>', 'Files', 'Explore project root')
call s:LeaderN(['f', 'E'], ':call <SID>ExploreHere()<CR>', 'Files', 'Explore current file directory')
call s:LeaderN(['f', 'v'], ':edit $MYVIMRC<CR>', 'Files', 'Edit Vim config')
call s:LeaderN(['f', 'R'], ':source $MYVIMRC<CR>', 'Files', 'Reload Vim config')
call s:LeaderN(['f', 'y'], ':call <SID>CopyPath(1)<CR>', 'Files', 'Copy relative path')
call s:LeaderN(['f', 'Y'], ':call <SID>CopyPath(0)<CR>', 'Files', 'Copy absolute path')

call s:LeaderN(['u', 'h'], ':nohlsearch<CR>', 'Toggles', 'Clear search highlight')
call s:LeaderN(['u', 'n'], ':set number! number?<CR>', 'Toggles', 'Toggle line numbers')
call s:LeaderN(['u', 'r'], ':set relativenumber! relativenumber?<CR>', 'Toggles', 'Toggle relative numbers')
call s:LeaderN(['u', 'l'], ':set list! list?<CR>', 'Toggles', 'Toggle invisible characters')
call s:LeaderN(['u', 'w'], ':set wrap! wrap?<CR>', 'Toggles', 'Toggle wrapping')
call s:LeaderN(['u', 's'], ':set spell! spell?<CR>', 'Toggles', 'Toggle spelling')
call s:LeaderN(['u', 'i'], ':ChopsticksIconsToggle<CR>', 'Toggles', 'Toggle Nerd Font icons')
call s:LeaderN(['u', 'b'], ':ChopsticksTransparencyToggle<CR>', 'Toggles', 'Toggle background transparency')
call s:LeaderN(['u', 'd'], ':ChopsticksUiDensity<CR>', 'Toggles', 'Cycle UI density')

call s:Catalog('Files', 'n*', 'Fern h / l', 'Collapse / open node')
call s:Catalog('Files', 'n*', 'Fern s / v / t', 'Open in split / vsplit / tab')
call s:Catalog('Files', 'n*', 'Fern N / r / x', 'New path / rename / mark')
call s:Catalog('Files', 'n*', 'Fern . / R', 'Toggle hidden files / reload')
call s:Catalog('Files', 'n*', 'Fern q / Esc', 'Close drawer')

call s:LeaderN(['q', 'w'], ':confirm quit<CR>', 'Quit', 'Close window')
call s:LeaderN(['q', 'q'], ':confirm qall<CR>', 'Quit', 'Quit Vim')
call s:LeaderN(['q', 's'], ':ChopsticksSessionSave<CR>', 'Quit', 'Save project session')
call s:LeaderN(['q', 'l'], ':ChopsticksSessionLoad<CR>', 'Quit', 'Restore project session')

if has('terminal')
    call s:LeaderN(['t', 't'], ':call <SID>OpenTerminal([], ''tab'')<CR>', 'Terminal', 'Terminal in new tab')
    call s:LeaderN(['t', 's'], ':call <SID>OpenTerminal([], ''split'')<CR>', 'Terminal', 'Terminal below')
    if !empty(maparg("\<Esc>\<Esc>", 't'))
        execute 'tunmap <Esc><Esc>'
    endif
    call s:Catalog('Terminal', 't', 'Ctrl-w N', 'Leave terminal mode')
endif

call s:LeaderN(['<Tab>', '<Tab>'], ':tabnew<CR>', 'Tabs', 'New tab')
call s:LeaderN(['<Tab>', '['], ':tabprevious<CR>', 'Tabs', 'Previous tab')
call s:LeaderN(['<Tab>', ']'], ':tabnext<CR>', 'Tabs', 'Next tab')
call s:LeaderN(['<Tab>', 'd'], ':tabclose<CR>', 'Tabs', 'Close tab')
call s:LeaderN(['<Tab>', 'o'], ':tabonly<CR>', 'Tabs', 'Close other tabs')
call s:LeaderN(['<Tab>', 'f'], ':tabfirst<CR>', 'Tabs', 'First tab')
call s:LeaderN(['<Tab>', 'l'], ':tablast<CR>', 'Tabs', 'Last tab')

call s:LeaderN(['g', 'g'], ':call <SID>OpenLazygit()<CR>', 'Git', 'Lazygit at project root')

" ── Plugin mappings ────────────────────────────────────────────────────────

function! s:PluginMaps() abort
    if exists(':Files') == 2 && executable('fzf') == 1
        call s:Catalog('Fast find', 't', 'Esc / Ctrl-q', 'Close finder')
        call s:LeaderN(['<Space>'], ':Buffers<CR>', 'Buffers', 'Find open buffers')
        call s:LeaderN([','], ':Buffers<CR>', 'Buffers', 'Find open buffers')
        call s:LeaderN(['f', 'f'], ':call <SID>FindFiles()<CR>', 'Files', 'Find files')
        call s:LeaderN(['f', 'g'], ':call <SID>ProjectGitFiles()<CR>', 'Files', 'Find Git files')
        call s:LeaderN(['f', 'r'], ':History<CR>', 'Files', 'Recent files')
        call s:LeaderN(['/'], ':BLines<CR>', 'Search', 'Search current buffer')
        call s:LeaderN(['s', 'b'], ':BLines<CR>', 'Search', 'Search current buffer')
        call s:LeaderN(['s', 'B'], ':Lines<CR>', 'Search', 'Search open buffers')
        call s:LeaderN(['s', 'c'], ':Commands<CR>', 'Search', 'Search commands')
        call s:LeaderN(['s', 'h'], ':Helptags<CR>', 'Search', 'Search Vim help')
        call s:LeaderN(['s', 'm'], ':Maps<CR>', 'Search', 'Search mappings')
        call s:DirectN('<C-p>', ':call <SID>FindFiles()<CR>', 'Ctrl-p', 'Fast find', 'Find files')
        call s:DirectN(';f', ':call <SID>FindFiles()<CR>', ';f', 'Fast find', 'Find files')
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
        call s:WhichKeyAdd(['j'], 'Navigation', 'Jump to visible target')
        call s:Catalog('Navigation', 'n', 'SPC j', 'Jump to visible target')
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
    call s:DefineFzfCommands()
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
    autocmd BufWritePre * call <SID>MakeParent(expand('<afile>'))
    autocmd BufReadPost * if getfsize(expand('<afile>')) > 10 * 1024 * 1024 |
        \ setlocal syntax= | let b:ale_enabled = 0 | endif
    " 'breakindent' is global, so guard every buffer and not only prose ones.
    " BufWinEnter runs after filetype setup, which is where it gets re-enabled.
    autocmd BufWinEnter * call <SID>GuardLongLines()
    autocmd QuickFixCmdPost [^l]* cwindow
    autocmd QuickFixCmdPost l* lwindow
    autocmd FileType fern call <SID>FernSetup()
    autocmd FileType which_key call <SID>WhichKeySetup()
    autocmd FileType netrw setlocal bufhidden=wipe
    autocmd FileType qf nnoremap <silent><buffer> q :close<CR>
    autocmd BufNewFile,BufRead *.mdx setfiletype markdown
    autocmd FileType markdown call <SID>MarkdownSetup()
    autocmd FileType text,gitcommit,mail call <SID>ProseSetup()
    autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4 textwidth=88
    autocmd FileType javascript,typescript setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2 textwidth=100
    autocmd FileType go setlocal noexpandtab shiftwidth=4 tabstop=4 softtabstop=0 textwidth=120
    autocmd FileType rust setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4 textwidth=100
    autocmd FileType c,cpp setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4 textwidth=80
    autocmd FileType html,css,yaml,json,dockerfile setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2
    autocmd FileType sh setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2 textwidth=80
    autocmd FileType make setlocal noexpandtab shiftwidth=8 tabstop=8 softtabstop=0
    autocmd User lsp_buffer_enabled call <SID>LspMaps()
    autocmd User GoyoEnter nested call <SID>GoyoEnter()
    autocmd User GoyoLeave nested call <SID>GoyoLeave()
augroup END

augroup ChopsticksPlugins
    autocmd!
    autocmd VimEnter * call <SID>PluginsReady()
augroup END

augroup ChopsticksDirectory
    autocmd!
    autocmd BufEnter * nested call <SID>MaybeOpenDirectory()
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
    call s:MarkdownSetup()
endif
