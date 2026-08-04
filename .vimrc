" chopsticks — a modern, Vim-only development and Markdown writing setup
set nocompatible
scriptencoding utf-8

let s:startup_started_at = reltime()
let g:chopsticks_version = '0.1.0'

if has('nvim')
    echoerr 'chopsticks targets Vim, not Neovim'
    finish
endif
if v:version < 802
    echoerr 'chopsticks requires Vim 8.2 or newer'
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

let mapleader = "\<Space>"
let maplocalleader = ','

let s:is_remote = !empty($SSH_CONNECTION) || !empty($SSH_CLIENT) || !empty($SSH_TTY)
let s:is_rich_terminal = !s:is_remote && has('termguicolors')
    \ && ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')

" Personal switches. Override these before sourcing this file when needed.
let g:chopsticks_markdown_spell = get(g:, 'chopsticks_markdown_spell', 1)
let g:chopsticks_markdown_conceal = get(g:, 'chopsticks_markdown_conceal', 0)
let g:chopsticks_markdown_image_dir = get(g:, 'chopsticks_markdown_image_dir', 'assets')
let g:chopsticks_transparent_background = get(g:, 'chopsticks_transparent_background', 1)

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
let g:fzf_preview_window = s:is_remote ? [] : ['right:55%', 'ctrl-/']
let g:fzf_action = {
    \ 'ctrl-t': 'tab split',
    \ 'ctrl-x': 'split',
    \ 'ctrl-v': 'vsplit',
    \ 'ctrl-o': 'Open',
    \ }
if executable('fzf-preview.sh')
    let s:fzf_preview = executable('viu') && executable('pdftoppm')
        \ ? 'sh -c ''case "$(file -b --mime-type "$1")" in application/pdf) pdftoppm -f 1 -l 1 -singlefile -scale-to 1200 -png "$1" 2>/dev/null ' .
        \ '| viu -b -s -h "${FZF_PREVIEW_LINES:-20}" - ;; image/*) exec viu -b -s -h "${FZF_PREVIEW_LINES:-20}" "$1" ;; *) exec fzf-preview.sh "$1" ;; esac'' _ {}'
        \ : 'fzf-preview.sh {}'
    let g:fzf_vim = {
        \ 'files_options': ['--preview', s:fzf_preview],
        \ 'gfiles_options': ['--preview', s:fzf_preview],
        \ }
endif

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
let g:ale_lint_on_save = 1
let g:ale_lint_on_enter = 1
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_virtualtext_cursor = 'disabled'
let g:ale_echo_msg_format = '%severity%: %s'
let g:ale_sign_error = 'E'
let g:ale_sign_warning = 'W'

let g:lsp_settings_lazyload = 1
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
elseif executable('xdg-open')
    let g:previm_open_cmd = 'xdg-open'
endif

let g:goyo_width = 96
let g:goyo_height = '90%'
let g:goyo_linenr = 0
let g:limelight_default_coefficient = 0.7
let g:limelight_paragraph_span = 1
let g:limelight_priority = -1

let g:startify_disable_at_vimenter = 1
let g:startify_skiplist = [
    \ '/\.git/', '/tmp/', '/\.vim/plugged/',
    \ '/\.codex/auth\.json$', '/\.ssh/',
    \ ]
let g:startify_session_persistence = 1
let g:startify_session_autoload = 1
let g:startify_change_to_vcs_root = 1
let g:startify_enable_special = 0

let s:dashboard_logo = [
    \ '███╗   ███╗ ██╗███╗   ██╗ ██████╗ ███████╗ █████╗ ███╗   ███╗ █████╗',
    \ '████╗ ████║███║████╗  ██║██╔════╝ ██╔════╝██╔══██╗████╗ ████║██╔══██╗',
    \ '██╔████╔██║╚██║██╔██╗ ██║██║  ███╗███████╗███████║██╔████╔██║███████║',
    \ '██║╚██╔╝██║ ██║██║╚██╗██║██║   ██║╚════██║██╔══██║██║╚██╔╝██║██╔══██║',
    \ '██║ ╚═╝ ██║ ██║██║ ╚████║╚██████╔╝███████║██║  ██║██║ ╚═╝ ██║██║  ██║',
    \ '╚═╝     ╚═╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝',
    \ ]
let s:dashboard_compact_logo = [
    \ '╭────────────────────────────────╮',
    \ '│           CHOPSTICKS           │',
    \ '╰────────────────────────────────╯',
    \ ]
let s:dashboard_items = [
    \ {'key': 'f', 'icon': ' ', 'label': 'Find File', 'action': 'Files'},
    \ {'key': 'n', 'icon': ' ', 'label': 'New File', 'action': 'enew | startinsert'},
    \ {'key': 'g', 'icon': ' ', 'label': 'Find Text', 'action': 'Rg'},
    \ {'key': 'r', 'icon': ' ', 'label': 'Recent Files', 'action': 'History'},
    \ {'key': 'c', 'icon': ' ', 'label': 'Config', 'action': 'edit $MYVIMRC'},
    \ {'key': 's', 'icon': ' ', 'label': 'Restore Session', 'action': 'SLoad!'},
    \ {'key': 'x', 'icon': ' ', 'label': 'Plugin Update', 'action': 'PlugUpdate'},
    \ {'key': 'l', 'icon': '󰒲 ', 'label': 'Plugins', 'action': 'PlugStatus'},
    \ {'key': 'q', 'icon': ' ', 'label': 'Quit', 'action': 'qall'},
    \ ]

" vim-plug is optional. Startup never downloads software.
if filereadable(expand('~/.vim/autoload/plug.vim'))
    call plug#begin('~/.vim/plugged')

    " Find and navigate.
    Plug 'junegunn/fzf', {'commit': '0eb2ae9f8bd57fed6242d76d2273df4a1be31cc8', 'do': { -> fzf#install() }}
    Plug 'junegunn/fzf.vim', {'commit': '34a564c81f36047f50e593c1656f4580ff75ccca'}
    Plug 'tpope/vim-vinegar', {'commit': 'bb1bcddf43cfebe05eb565a84ab069b357d0b3d6'}
    Plug 'easymotion/vim-easymotion', {'commit': 'b3cfab2a6302b3b39f53d9fd2cd997e1127d7878', 'on': '<Plug>(easymotion'}

    " Git and project commands.
    Plug 'tpope/vim-fugitive', {'commit': '3b753cf8c6a4dcde6edee8827d464ba9b8c4a6f0'}
    Plug 'tpope/vim-rhubarb', {'commit': '5496d7c94581c4c9ad7430357449bb57fc59f501'}
    Plug 'airblade/vim-gitgutter', {'commit': '21c977e8597c468c7dc76001389b0b430d46a4b0'}
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
    Plug 'dense-analysis/ale', {'commit': 'ba8b9cbab95131e284c5be926642f803b2be0058'}
    Plug 'prabirshrestha/vim-lsp', {'commit': '0c49560e5fbc97876e51bef6b993e48677cc15fc'}
    Plug 'mattn/vim-lsp-settings', {'commit': 'a0ec2ee4e75a14f2471896a1192c1970d7be4258'}
    Plug 'prabirshrestha/asyncomplete.vim', {'commit': '17b654a87a834d4e835fb7467e562b4421ad9310'}
    Plug 'prabirshrestha/asyncomplete-lsp.vim', {'commit': 'da23f4418a6301feac7b99e1728fb79acb243d69'}

    " Markdown and prose.
    Plug 'preservim/vim-markdown', {'commit': '1bc9d0cd8e1cc3e901b0a49c2b50a843f1c89397', 'for': 'markdown'}
    " Pencil defines shared autocommand groups during startup; do not lazy-load it.
    Plug 'preservim/vim-pencil', {'commit': '6d70438a8886eaf933c38a7a43a61adb0a7815ed'}
    Plug 'bullets-vim/bullets.vim', {'commit': '81570b98ca44b4100b3ddcf8d9ca74b9a9b0c884', 'for': ['markdown', 'text', 'gitcommit']}
    Plug 'dhruvasagar/vim-table-mode', {'commit': 'bb025308a45c67c7c8f0763ba37bc2ee3f534df0', 'for': 'markdown'}
    Plug 'previm/previm', {'commit': '2bccb5e2a14e9f344f2656578b815b0da5c37fe3', 'on': 'PrevimOpen'}
    Plug 'junegunn/goyo.vim', {'commit': '9c72fdf2d202914318581f9f0dd09fd102f8504d', 'on': 'Goyo'}
    Plug 'junegunn/limelight.vim', {'commit': '617064e84e896f6f36b5e559f8e6486d632f68ed', 'on': 'Limelight'}

    " Interface.
    Plug 'mhinz/vim-startify', {'commit': '4e089dffdad46f3f5593f34362d530e8fe823dcf'}
    Plug 'liuchengxu/vim-which-key', {'commit': '72a4267b46a76f541b3e9500a7503575575d4f57'}
    Plug 'lifepillar/vim-solarized8', {'commit': '4433b4411de92b2446a4d32f0d8bf1b25c476bf9'}

    call plug#end()
endif

filetype plugin indent on
syntax enable

" ── Vim defaults ────────────────────────────────────────────────────────────

set encoding=utf-8
set number relativenumber cursorline
set scrolloff=10 sidescrolloff=5 nowrap
set incsearch hlsearch ignorecase smartcase
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
if has('popupwin')
    set completeopt+=popup
endif
set pumheight=15
set shortmess+=cI
set signcolumn=yes
set title
set noshowmode noruler
set laststatus=2 showtabline=2
set sessionoptions=blank,buffers,curdir,folds,help,tabpages,winsize,terminal
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

if executable('rg')
    set grepprg=rg\ --vimgrep\ --smart-case
    set grepformat=%f:%l:%c:%m
endif

" Keep all recovery files out of projects.
let s:state_dirs = {
    \ 'backup': expand('~/.vim/.backup'),
    \ 'swap': expand('~/.vim/.swap'),
    \ 'undo': expand('~/.vim/.undo'),
    \ 'view': expand('~/.vim/.view'),
    \ }
for s:state_dir in values(s:state_dirs)
    silent! call mkdir(s:state_dir, 'p', 0700)
endfor
set backup writebackup swapfile
let &backupdir = s:state_dirs.backup . '//'
let &directory = s:state_dirs.swap . '//,/tmp//'
let &viewdir = s:state_dirs.view
if has('persistent_undo')
    let &undodir = s:state_dirs.undo
    set undofile
endif
unlet s:state_dir

set listchars=tab:→\ ,trail:·,extends:›,precedes:‹,nbsp:␣
execute 'set fillchars+=eob:\ '
if s:is_rich_terminal
    set termguicolors
endif
set background=dark
try
    colorscheme solarized8
catch /^Vim\%((\a\+)\)\=:E185/
    colorscheme default
endtry

" ── Interface: statusline and buffer tabline ───────────────────────────────

function! s:DefineInterfaceColors() abort
    highlight ChopStatusNormal  ctermbg=136 ctermfg=234 cterm=bold guibg=#b58900 guifg=#002b36 gui=bold
    highlight ChopStatusInsert  ctermbg=33  ctermfg=234 cterm=bold guibg=#268bd2 guifg=#002b36 gui=bold
    highlight ChopStatusVisual  ctermbg=125 ctermfg=234 cterm=bold guibg=#d33682 guifg=#002b36 gui=bold
    highlight ChopStatusReplace ctermbg=160 ctermfg=234 cterm=bold guibg=#dc322f guifg=#002b36 gui=bold
    highlight ChopStatusCommand ctermbg=37  ctermfg=234 cterm=bold guibg=#2aa198 guifg=#002b36 gui=bold
    highlight ChopStatusBody    ctermbg=235 ctermfg=245 cterm=none guibg=#073642 guifg=#93a1a1
    highlight ChopStatusAccent  ctermbg=235 ctermfg=136 cterm=none guibg=#073642 guifg=#b58900
    highlight ChopStatusGit     ctermbg=235 ctermfg=37  cterm=none guibg=#073642 guifg=#2aa198
    highlight ChopStatusMuted   ctermbg=235 ctermfg=240 cterm=none guibg=#073642 guifg=#586e75
    highlight VertSplit         ctermbg=234 ctermfg=240 cterm=NONE guibg=#002b36 guifg=#586e75 gui=NONE
    highlight CursorLine        ctermbg=235 cterm=NONE guibg=#0c4452 gui=NONE
    highlight CursorLineNr      ctermbg=235 ctermfg=136 cterm=bold guibg=#0c4452 guifg=#b58900 gui=bold
    highlight SignColumn        ctermbg=234 guibg=#002b36
    highlight ChopDashboardLogo   ctermfg=33  cterm=bold guifg=#268bd2 gui=bold
    highlight ChopDashboardItem   ctermfg=37  cterm=none guifg=#2aa198 gui=none
    highlight ChopDashboardKey    ctermfg=166 cterm=none guifg=#cb4b16 gui=none
    highlight ChopDashboardFooter ctermfg=136 cterm=italic guifg=#b58900 gui=italic
    highlight ChopDashboardStatus ctermbg=235 ctermfg=235 guibg=#073642 guifg=#073642
    if g:chopsticks_transparent_background
        highlight Normal ctermbg=NONE guibg=NONE
        highlight NormalNC ctermbg=NONE guibg=NONE
        highlight NonText ctermbg=NONE guibg=NONE
        highlight EndOfBuffer ctermbg=NONE guibg=NONE
        highlight SignColumn ctermbg=NONE guibg=NONE
    endif
endfunction

function! s:DashboardCenter(text) abort
    return repeat(' ', max([0, (&columns - strwidth(a:text)) / 2])) . a:text
endfunction

function! s:DashboardPluginStats() abort
    let l:plugs = get(g:, 'plugs', {})
    let l:runtime = map(split(&runtimepath, ','),
        \ 'resolve(fnamemodify(v:val, ":p"))')
    let l:loaded = 0
    for l:plug in values(l:plugs)
        if index(l:runtime, resolve(fnamemodify(l:plug.dir, ':p'))) >= 0
            let l:loaded += 1
        endif
    endfor
    return [l:loaded, len(l:plugs)]
endfunction

function! s:DashboardFooter() abort
    if !exists('g:chopsticks_startup_ms')
        let g:chopsticks_startup_ms = exists('*reltimefloat')
            \ ? reltimefloat(reltime(s:startup_started_at)) * 1000
            \ : str2float(reltimestr(reltime(s:startup_started_at))) * 1000
    endif
    let [l:loaded, l:total] = s:DashboardPluginStats()
    return l:total > 0
        \ ? printf('⚡ Vim loaded %d/%d plugins in %.2fms',
        \     l:loaded, l:total, g:chopsticks_startup_ms)
        \ : printf('⚡ Vim ready in %.2fms', g:chopsticks_startup_ms)
endfunction

function! s:DashboardEnter() abort
    if !exists('b:chopsticks_dashboard_showtabline')
        let b:chopsticks_dashboard_showtabline = &showtabline
    endif
    set showtabline=0
    setlocal nonumber norelativenumber nolist nocursorline signcolumn=no
    setlocal nowrap nospell foldcolumn=0 colorcolumn=
    let &l:statusline = '%#ChopDashboardStatus#%='
endfunction

function! s:DashboardLeave() abort
    if exists('b:chopsticks_dashboard_showtabline')
        let &showtabline = b:chopsticks_dashboard_showtabline
        unlet b:chopsticks_dashboard_showtabline
    endif
endfunction

function! s:DashboardRender() abort
    if &filetype !=# 'chopsticks-dashboard'
        return
    endif
    let l:logo = &columns >= 100 ? s:dashboard_logo : s:dashboard_compact_logo
    let l:gap = winheight(0) >= 28 ? 1 : 0
    let l:label_width = min([50, max([20, &columns - 10])])
    let l:content_height = len(l:logo) + 2 + len(s:dashboard_items)
        \ + (len(s:dashboard_items) - 1) * l:gap + 2
    let l:top = max([1, (winheight(0) - l:content_height) / 2])
    let l:lines = repeat([''], l:top)
    let l:logo_matches = []
    let l:item_matches = []
    let l:key_matches = []
    let l:item_lines = []
    let l:desc_cols = {}
    let l:actions = {}

    for l:text in l:logo
        let l:line = s:DashboardCenter(l:text)
        call add(l:lines, l:line)
        let l:column = strlen(matchstr(l:line, '^ *')) + 1
        call add(l:logo_matches, [len(l:lines), l:column, strlen(l:text)])
    endfor
    call extend(l:lines, ['', ''])

    for l:index in range(len(s:dashboard_items))
        let l:item = s:dashboard_items[l:index]
        let l:body = l:item.icon . l:item.label
            \ . repeat(' ', max([1, l:label_width - strwidth(l:item.label)]))
            \ . l:item.key
        let l:line = s:DashboardCenter(l:body)
        call add(l:lines, l:line)
        let l:line_number = len(l:lines)
        let l:column = strlen(matchstr(l:line, '^ *')) + 1
        call add(l:item_matches, [l:line_number, l:column, strlen(l:body)])
        call add(l:key_matches,
            \ [l:line_number, strlen(l:line) - strlen(l:item.key) + 1,
            \  strlen(l:item.key)])
        call add(l:item_lines, l:line_number)
        let l:desc_cols[string(l:line_number)] = l:column + strlen(l:item.icon)
        let l:actions[string(l:line_number)] = l:item.key
        if l:gap && l:index + 1 < len(s:dashboard_items)
            call add(l:lines, '')
        endif
    endfor

    call add(l:lines, '')
    let l:footer = s:DashboardFooter()
    let l:footer_line = s:DashboardCenter(l:footer)
    call add(l:lines, l:footer_line)
    let l:footer_column = strlen(matchstr(l:footer_line, '^ *')) + 1

    setlocal modifiable
    silent keepjumps %delete _
    call setline(1, l:lines)
    setlocal nomodified nomodifiable
    call clearmatches()
    call matchaddpos('ChopDashboardLogo', l:logo_matches, 10)
    call matchaddpos('ChopDashboardItem', l:item_matches, 10)
    call matchaddpos('ChopDashboardKey', l:key_matches, 20)
    call matchaddpos('ChopDashboardFooter',
        \ [[len(l:lines), l:footer_column, strlen(l:footer)]], 10)
    let b:chopsticks_dashboard_item_lines = l:item_lines
    let b:chopsticks_dashboard_desc_cols = l:desc_cols
    let b:chopsticks_dashboard_actions = l:actions
    call cursor(l:item_lines[0], l:desc_cols[string(l:item_lines[0])])
endfunction

function! s:DashboardSelectNearest() abort
    let l:lines = get(b:, 'chopsticks_dashboard_item_lines', [])
    if empty(l:lines)
        return
    endif
    let l:current = line('.')
    let l:target = l:lines[0]
    let l:distance = abs(l:target - l:current)
    for l:candidate in l:lines[1:]
        if abs(l:candidate - l:current) < l:distance
            let l:target = l:candidate
            let l:distance = abs(l:candidate - l:current)
        endif
    endfor
    call cursor(l:target, get(b:chopsticks_dashboard_desc_cols,
        \ string(l:target), 1))
endfunction

function! s:DashboardLockCursor() abort
    if &filetype !=# 'chopsticks-dashboard'
        return
    endif
    let l:lines = get(b:, 'chopsticks_dashboard_item_lines', [])
    if index(l:lines, line('.')) < 0
        call s:DashboardSelectNearest()
        return
    endif
    let l:column = get(b:chopsticks_dashboard_desc_cols, string(line('.')), 1)
    if col('.') != l:column
        call cursor(line('.'), l:column)
    endif
endfunction

function! s:DashboardMove(delta) abort
    let l:lines = get(b:, 'chopsticks_dashboard_item_lines', [])
    if empty(l:lines)
        return
    endif
    let l:index = index(l:lines, line('.'))
    if l:index < 0
        call s:DashboardSelectNearest()
        let l:index = index(l:lines, line('.'))
    endif
    let l:index = (l:index + a:delta + len(l:lines)) % len(l:lines)
    let l:target = l:lines[l:index]
    call cursor(l:target, get(b:chopsticks_dashboard_desc_cols,
        \ string(l:target), 1))
endfunction

function! s:DashboardRun(key) abort
    for l:item in s:dashboard_items
        if l:item.key ==# a:key
            try
                execute l:item.action
            catch
                echohl ErrorMsg
                echom 'Dashboard: ' . v:exception
                echohl None
            endtry
            return
        endif
    endfor
endfunction

function! s:DashboardRunCurrent() abort
    let l:key = get(get(b:, 'chopsticks_dashboard_actions', {}),
        \ string(line('.')), '')
    if !empty(l:key)
        call s:DashboardRun(l:key)
    endif
endfunction

function! s:OpenDashboard() abort
    if &filetype !=# 'chopsticks-dashboard'
        silent keepalt enew
        silent file [chopsticks]
        setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
        setfiletype chopsticks-dashboard
    endif
    call s:DashboardEnter()
    for l:item in s:dashboard_items
        execute 'nnoremap <silent><nowait><buffer> ' . l:item.key
            \ . ' :call <SID>DashboardRun(''' . l:item.key . ''')<CR>'
    endfor
    nnoremap <silent><buffer> <CR> :call <SID>DashboardRunCurrent()<CR>
    nnoremap <silent><buffer> j :call <SID>DashboardMove(1)<CR>
    nnoremap <silent><buffer> k :call <SID>DashboardMove(-1)<CR>
    nnoremap <silent><buffer> <Down> :call <SID>DashboardMove(1)<CR>
    nnoremap <silent><buffer> <Up> :call <SID>DashboardMove(-1)<CR>
    nnoremap <silent><buffer> <Tab> :call <SID>DashboardMove(1)<CR>
    nnoremap <silent><buffer> <S-Tab> :call <SID>DashboardMove(-1)<CR>
    nnoremap <silent><nowait><buffer> ? :ChopsticksCheatsheet<CR>
    nnoremap <silent><nowait><buffer> h :ChopsticksHealth<CR>
    call s:DashboardRender()
endfunction

function! s:MaybeOpenDashboard() abort
    if argc() == 0 && bufname('%') ==# '' && &buftype ==# ''
        \ && line('$') == 1 && getline(1) ==# '' && !&modified
        call s:OpenDashboard()
    endif
endfunction

command! ChopsticksDashboard call s:OpenDashboard()

function! ChopsticksMode() abort
    let l:mode = mode(1)
    if l:mode =~# '^i'
        return [' I ', 'ChopStatusInsert']
    elseif l:mode =~# '^[vV\x16]'
        return [' V ', 'ChopStatusVisual']
    elseif l:mode =~# '^R'
        return [' R ', 'ChopStatusReplace']
    elseif l:mode =~# '^[c!t]'
        return [toupper(' ' . l:mode[0] . ' '), 'ChopStatusCommand']
    endif
    return [' N ', 'ChopStatusNormal']
endfunction

function! ChopsticksGitBranch() abort
    if !exists('*FugitiveHead')
        return ''
    endif
    let l:branch = FugitiveHead()
    return empty(l:branch) ? '' : '   ' . substitute(l:branch, '%', '%%', 'g') . ' '
endfunction

function! ChopsticksDiagnostics() abort
    if !exists('*ale#statusline#Count')
        return ''
    endif
    let l:count = ale#statusline#Count(bufnr(''))
    let l:errors = l:count.error + l:count.style_error
    let l:warnings = l:count.warning + l:count.style_warning
    return l:errors == 0 && l:warnings == 0
        \ ? ''
        \ : printf(' E:%d W:%d ', l:errors, l:warnings)
endfunction

function! ChopsticksWritingMode() abort
    let l:parts = []
    if &spell
        call add(l:parts, 'SPELL')
    endif
    if exists('*PencilMode') && !empty(PencilMode())
        call add(l:parts, 'WRAP:' . PencilMode())
    endif
    return empty(l:parts) ? '' : ' ' . join(l:parts, ' ') . ' '
endfunction

function! ChopsticksStatusline() abort
    let [l:label, l:group] = ChopsticksMode()
    let l:line = '%#' . l:group . '#' . l:label
    let l:line .= '%#ChopStatusBody# %<%f '
    let l:line .= '%#ChopStatusAccent#%m%r'
    let l:line .= '%#ChopStatusAccent#' . ChopsticksWritingMode()
    let l:line .= '%#ChopStatusBody#%='
    let l:line .= '%#ChopStatusAccent#' . ChopsticksDiagnostics()
    let l:line .= '%#ChopStatusGit#' . ChopsticksGitBranch()
    let l:line .= '%#ChopStatusMuted# %y  %l:%c  %P '
    return l:line
endfunction

function! ChopsticksTabline() abort
    let l:line = ''
    for l:buffer in getbufinfo({'buflisted': 1})
        if getbufvar(l:buffer.bufnr, '&buftype') !=# ''
            continue
        endif
        let l:line .= l:buffer.bufnr == bufnr('%') ? '%#TabLineSel#' : '%#TabLine#'
        let l:name = fnamemodify(l:buffer.name, ':t')
        let l:name = empty(l:name) ? '[No Name]' : substitute(l:name, '%', '%%', 'g')
        let l:changed = get(l:buffer, 'changed', 0) ? ' +' : ''
        let l:line .= ' ' . l:buffer.bufnr . ' ' . l:name . l:changed . ' '
    endfor
    return l:line . '%#TabLineFill#%='
endfunction

set statusline=%!ChopsticksStatusline()
set tabline=%!ChopsticksTabline()

augroup ChopsticksInterface
    autocmd!
    autocmd ColorScheme * call s:DefineInterfaceColors()
    autocmd BufEnter * if &filetype ==# 'chopsticks-dashboard' | call s:DashboardEnter() | call s:DashboardRender() | endif
    autocmd BufLeave * if &filetype ==# 'chopsticks-dashboard' | call s:DashboardLeave() | endif
    autocmd CursorMoved * if &filetype ==# 'chopsticks-dashboard' | call s:DashboardLockCursor() | endif
    autocmd FocusGained * if &filetype ==# 'chopsticks-dashboard' | call s:DashboardLockCursor() | redraw! | endif
    autocmd VimResized * if &filetype ==# 'chopsticks-dashboard' | call s:DashboardRender() | endif
augroup END
call s:DefineInterfaceColors()

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

function! s:ProjectRoot() abort
    let l:start = empty(expand('%:p')) ? getcwd() : expand('%:p:h')
    let l:marker = finddir('.git', l:start . ';')
    if empty(l:marker)
        let l:marker = findfile('.git', l:start . ';')
    endif
    return empty(l:marker) ? getcwd() : fnamemodify(l:marker, ':h')
endfunction

function! s:FindFiles() abort
    if exists(':GFiles') == 2 && executable('git')
        let l:root = s:ProjectRoot()
        call system('git -C ' . shellescape(l:root) . ' rev-parse --is-inside-work-tree')
        if v:shell_error == 0
            execute 'lcd ' . fnameescape(l:root)
            GFiles
            return
        endif
    endif
    if exists(':Files') == 2
        execute 'Files ' . fnameescape(s:ProjectRoot())
    endif
endfunction

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

function! s:ExploreRoot() abort
    execute 'Lexplore ' . fnameescape(s:ProjectRoot())
endfunction

function! s:ExploreHere() abort
    let l:directory = empty(expand('%:p')) ? getcwd() : expand('%:p:h')
    execute 'Lexplore ' . fnameescape(l:directory)
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
    if !executable('lazygit')
        echohl WarningMsg | echom 'chopsticks: lazygit is not installed' | echohl None
        return
    endif
    call s:OpenTerminal(['lazygit', '--path', s:ProjectRoot()], 'tab')
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

function! ChopsticksHealthLines() abort
    let l:lines = [
        \ 'chopsticks ' . g:chopsticks_version . ' health',
        \ '',
        \ printf('[ok] Vim %d.%d (%s)', v:version / 100, v:version % 100, has('gui_running') ? 'GUI' : 'terminal'),
        \ printf('[%s] +job +channel +timers +popupwin +terminal',
        \     has('job') && has('channel') && has('timers') && has('popupwin') && has('terminal') ? 'ok' : '!!'),
        \ '',
        \ 'Tools',
        \ ]
    for l:tool in ['git', 'rg', 'fzf', 'fd', 'lazygit', 'marksman', 'markdownlint', 'prettier', 'glow', 'pandoc', 'pngpaste']
        call add(l:lines, printf('[%s] %-14s %s',
            \ executable(l:tool) ? 'ok' : '--', l:tool,
            \ executable(l:tool) ? exepath(l:tool) : 'optional / missing'))
    endfor
    call extend(l:lines, ['', 'Plugins'])
    if exists('g:plugs')
        let l:missing = []
        for l:name in sort(keys(g:plugs))
            let l:dir = get(g:plugs[l:name], 'dir', '')
            if empty(l:dir) || !isdirectory(l:dir)
                call add(l:missing, l:name)
            endif
        endfor
        call add(l:lines, empty(l:missing)
            \ ? '[ok] all declared plugins installed'
            \ : '[!!] missing: ' . join(l:missing, ', '))
    else
        call add(l:lines, '[--] vim-plug is not installed')
    endif
    if exists('*ChopsticksInputMethodInfo')
        let l:input_method = ChopsticksInputMethodInfo()
        call extend(l:lines, [
            \ '',
            \ 'Input method',
            \ printf('[%s] %-14s %s',
            \     l:input_method.available ? 'ok' : '--',
            \     'im-select', l:input_method.reason),
            \ ])
    endif
    call extend(l:lines, [
        \ '',
        \ 'Run :PlugInstall for missing plugins.',
        \ 'Run :LspStatus in a source buffer to inspect language servers.',
        \ 'Press q to close.',
        \ ])
    return l:lines
endfunction

function! s:Health() abort
    call s:OpenScratch('[chopsticks-health]', ChopsticksHealthLines())
endfunction

let s:key_catalog = []
let s:key_catalog_index = {}
let s:key_group_order = [
    \ 'Essentials', 'Fast find', 'Buffers', 'Windows', 'Files', 'Search', 'Quit',
    \ 'Git', 'Code', 'Diagnostics', 'Run', 'Terminal', 'Tabs', 'Toggles',
    \ 'Editing', 'Navigation', 'Markdown',
    \ ]
let g:which_key_map = {}
let g:which_key_local_map = {'name': '+Markdown'}

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
                let l:node[l:key] = {'name': '+' . a:group}
            elseif !has_key(l:node[l:key], 'name')
                let l:node[l:key].name = '+' . a:group
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

command! ChopsticksHealth call s:Health()
command! ChopsticksKeys call s:Keys()
command! ChopsticksCheatsheet call s:Keys()

" ── Markdown and prose ─────────────────────────────────────────────────────

let g:which_key_local_map = {
    \ 'name': '+Markdown',
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
        \ 'name': '+Table',
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
    if !executable('glow')
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
    if !executable('pngpaste')
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
endfunction

function! s:GoyoEnter() abort
    if &filetype =~# '^\%(markdown\|text\|gitcommit\)$' && exists(':Limelight') == 2
        silent Limelight
    endif
    setlocal wrap linebreak
endfunction

function! s:GoyoLeave() abort
    if exists(':Limelight') == 2
        silent! Limelight!
    endif
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

call s:LeaderN(['q', 'w'], ':confirm quit<CR>', 'Quit', 'Close window')
call s:LeaderN(['q', 'q'], ':confirm qall<CR>', 'Quit', 'Quit Vim')

if has('terminal')
    call s:LeaderN(['t', 't'], ':call <SID>OpenTerminal([], ''tab'')<CR>', 'Terminal', 'Terminal in new tab')
    call s:LeaderN(['t', 's'], ':call <SID>OpenTerminal([], ''split'')<CR>', 'Terminal', 'Terminal below')
    tnoremap <silent> <Esc><Esc> <C-\><C-n>
    call s:Catalog('Terminal', 't', 'Esc Esc', 'Leave terminal mode')
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
    if exists(':Files') == 2 && executable('fzf')
        call s:LeaderN(['<Space>'], ':Buffers<CR>', 'Buffers', 'Find open buffers')
        call s:LeaderN([','], ':Buffers<CR>', 'Buffers', 'Find open buffers')
        call s:LeaderN(['f', 'f'], ':call <SID>FindFiles()<CR>', 'Files', 'Find files')
        call s:LeaderN(['f', 'g'], ':GFiles<CR>', 'Files', 'Find Git files')
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
    if exists(':Rg') == 2 && executable('rg')
        call s:LeaderN(['s', 'g'], ':Rg<CR>', 'Search', 'Grep project')
        call s:LeaderN(['s', 'w'], ':Rg <C-r><C-w><CR>', 'Search', 'Grep word under cursor')
        call s:DirectN(';r', ':Rg<CR>', ';r', 'Fast find', 'Grep project')
    endif
    if exists(':Git') == 2 && executable('git')
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
    autocmd VimResized * wincmd =
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
    autocmd QuickFixCmdPost [^l]* cwindow
    autocmd QuickFixCmdPost l* lwindow
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

augroup ChopsticksDashboard
    autocmd!
    autocmd VimEnter * call <SID>MaybeOpenDashboard()
augroup END

if v:vim_did_enter
    call s:PluginMaps()
    call s:RegisterWhichKey()
    if &filetype ==# 'markdown'
        call s:MarkdownSetup()
    endif
endif

" ── Input method (final integration) ───────────────────────────────────────

let s:input_method_default_command = executable('im-select') && exists('*exepath')
    \ ? exepath('im-select')
    \ : 'im-select'
let g:chopsticks_input_method_cmd = get(g:, 'chopsticks_input_method_cmd',
    \ s:input_method_default_command)
let g:chopsticks_input_method_default = get(g:, 'chopsticks_input_method_default',
    \ has('macunix') ? 'com.apple.keylayout.ABC' : '')
let g:chopsticks_input_method_restore = get(g:, 'chopsticks_input_method_restore', 1)
let g:chopsticks_input_method_preserve_external = get(g:,
    \ 'chopsticks_input_method_preserve_external', 1)
let g:chopsticks_input_method_disable_on_ssh = get(g:,
    \ 'chopsticks_input_method_disable_on_ssh', 1)
let g:chopsticks_input_method_filetypes = get(g:, 'chopsticks_input_method_filetypes', [])
let g:chopsticks_input_method_ignore_filetypes = get(g:,
    \ 'chopsticks_input_method_ignore_filetypes',
    \ ['chopsticks-dashboard', 'fzf', 'help', 'netrw', 'qf', 'startify'])
let g:chopsticks_enable_input_method = get(g:, 'chopsticks_enable_input_method',
    \ has('macunix') && executable(g:chopsticks_input_method_cmd))
let s:input_method_assumed = ''
if !exists('g:chopsticks_input_method_state')
    \ || type(g:chopsticks_input_method_state) != type({})
    let g:chopsticks_input_method_state = {}
endif
let s:input_method_state = g:chopsticks_input_method_state
let s:input_method_state.active = get(s:input_method_state, 'active', 0)
let s:input_method_state.external = get(s:input_method_state, 'external', '')

function! s:InputMethodList(value) abort
    if type(a:value) == type([])
        return a:value
    endif
    return type(a:value) == type('') && !empty(a:value) ? [a:value] : []
endfunction

function! s:InputMethodBaseInfo() abort
    let l:enabled = get(g:, 'chopsticks_enable_input_method', 0)
    let l:remote_blocked = s:is_remote
        \ && get(g:, 'chopsticks_input_method_disable_on_ssh', 1)
    if !l:enabled
        return {'available': 0, 'reason': 'disabled'}
    elseif l:remote_blocked
        return {'available': 0, 'reason': 'disabled on SSH'}
    elseif empty(g:chopsticks_input_method_cmd)
        return {'available': 0, 'reason': 'command is empty'}
    elseif !executable(g:chopsticks_input_method_cmd)
        return {'available': 0, 'reason': 'missing: ' . g:chopsticks_input_method_cmd}
    elseif empty(g:chopsticks_input_method_default)
        return {'available': 0, 'reason': 'default input source is empty'}
    endif
    return {'available': 1, 'reason': 'ready'}
endfunction

function! s:InputMethodBufferInfo() abort
    let l:base = s:InputMethodBaseInfo()
    if !l:base.available
        return {'enabled': 0, 'reason': l:base.reason}
    elseif &buftype !=# ''
        return {'enabled': 0, 'reason': 'buffer type: ' . &buftype}
    elseif empty(bufname('%')) && empty(&filetype)
        return {'enabled': 0, 'reason': 'unnamed buffer'}
    endif
    let l:allowed = s:InputMethodList(g:chopsticks_input_method_filetypes)
    let l:ignored = s:InputMethodList(g:chopsticks_input_method_ignore_filetypes)
    if !empty(l:allowed) && index(l:allowed, &filetype) < 0
        return {'enabled': 0, 'reason': 'filetype not allowed: ' . &filetype}
    elseif index(l:ignored, &filetype) >= 0
        return {'enabled': 0, 'reason': 'filetype ignored: ' . &filetype}
    endif
    return {'enabled': 1, 'reason': 'ready'}
endfunction

function! ChopsticksInputMethodInfo() abort
    let l:base = s:InputMethodBaseInfo()
    let l:buffer = s:InputMethodBufferInfo()
    return {
        \ 'enabled': get(g:, 'chopsticks_enable_input_method', 0),
        \ 'available': l:base.available,
        \ 'reason': l:base.reason,
        \ 'command': g:chopsticks_input_method_cmd,
        \ 'default': g:chopsticks_input_method_default,
        \ 'restore': get(g:, 'chopsticks_input_method_restore', 1),
        \ 'preserve_external': get(g:,
        \     'chopsticks_input_method_preserve_external', 1),
        \ 'remote': s:is_remote,
        \ 'vim_active': s:input_method_state.active,
        \ 'external': s:input_method_state.external,
        \ 'buffer_enabled': l:buffer.enabled,
        \ 'buffer_reason': l:buffer.reason,
        \ 'saved': get(b:, 'chopsticks_input_method_saved', ''),
        \ 'last': get(b:, 'chopsticks_input_method_last', ''),
        \ }
endfunction

function! s:InputMethodRun(arguments) abort
    let l:command = shellescape(g:chopsticks_input_method_cmd)
    for l:argument in a:arguments
        let l:command .= ' ' . shellescape(l:argument)
    endfor
    let l:output = system(l:command . ' 2>/dev/null')
    return v:shell_error == 0
        \ ? substitute(l:output, '[\r\n]\+$', '', '')
        \ : ''
endfunction

function! s:InputMethodCurrent() abort
    let l:current = s:InputMethodRun([])
    if !empty(l:current)
        let s:input_method_assumed = l:current
    endif
    return l:current
endfunction

function! s:InputMethodSelect(input_source) abort
    if !empty(a:input_source)
        call s:InputMethodRun([a:input_source])
        let s:input_method_assumed = a:input_source
    endif
endfunction

function! s:InputMethodRemember(input_source) abort
    let b:chopsticks_input_method_saved = a:input_source
endfunction

function! s:InputMethodIsInsertLike() abort
    " Replace mode and Insert's one-command Normal mode still accept text with
    " the buffer's Insert preference when control returns to the editor.
    return mode(1) =~# '^\%(i\|R\|ni[IR]\)'
endfunction

" Used when leaving Insert mode. Choosing ABC while inserting is treated as
" an intentional preference change, so the previously saved CJK source clears.
function! s:InputMethodSwitchToDefault() abort
    if !s:input_method_state.active || !s:InputMethodBufferInfo().enabled
        return
    endif
    let l:current = s:InputMethodCurrent()
    if empty(l:current)
        return
    endif
    let b:chopsticks_input_method_last = l:current
    if l:current ==# g:chopsticks_input_method_default
        unlet! b:chopsticks_input_method_saved
        return
    endif
    call s:InputMethodRemember(l:current)
    call s:InputMethodSelect(g:chopsticks_input_method_default)
endfunction

" Used when entering a normal-mode buffer or returning focus to Vim. It keeps
" an existing per-buffer preference when the system is already on ABC.
function! s:InputMethodEnsureDefault() abort
    if !s:input_method_state.active || s:InputMethodIsInsertLike()
        \ || !s:InputMethodBufferInfo().enabled
        return
    endif
    if s:input_method_assumed ==# g:chopsticks_input_method_default
        return
    endif
    let l:current = s:InputMethodCurrent()
    if empty(l:current) || l:current ==# g:chopsticks_input_method_default
        return
    endif
    let b:chopsticks_input_method_last = l:current
    call s:InputMethodRemember(l:current)
    call s:InputMethodSelect(g:chopsticks_input_method_default)
endfunction

function! s:InputMethodRestore() abort
    if !s:input_method_state.active || !s:InputMethodBufferInfo().enabled
        return
    endif
    let l:target = get(b:, 'chopsticks_input_method_saved', '')
    if get(g:, 'chopsticks_input_method_restore', 1)
        \ && !empty(l:target)
        \ && l:target !=# g:chopsticks_input_method_default
        call s:InputMethodSelect(l:target)
    endif
endfunction

" Save the current Insert-mode preference without changing the system source.
" This is important on FocusLost: selecting ABC there would leak Vim's Normal
" mode preference into the application receiving focus.
function! s:InputMethodRememberInsert() abort
    if !s:InputMethodIsInsertLike() || !s:InputMethodBufferInfo().enabled
        return
    endif
    let l:current = s:InputMethodCurrent()
    if empty(l:current)
        return
    endif
    let b:chopsticks_input_method_last = l:current
    if l:current ==# g:chopsticks_input_method_default
        unlet! b:chopsticks_input_method_saved
    else
        call s:InputMethodRemember(l:current)
    endif
endfunction

" im-select changes macOS's process-independent current input source. Emulate
" application-local state by bracketing Vim focus: capture the outside source,
" apply Vim's mode preference, then restore the captured source on focus loss.
function! s:InputMethodActivate() abort
    if s:input_method_state.active || !s:InputMethodBaseInfo().available
        return
    endif
    let l:external = s:InputMethodCurrent()
    if empty(l:external)
        return
    endif
    let s:input_method_state.external = l:external
    let s:input_method_state.active = 1
    if s:InputMethodIsInsertLike()
        call s:InputMethodRestore()
    elseif s:InputMethodBufferInfo().enabled
        \ && l:external !=# g:chopsticks_input_method_default
        call s:InputMethodSelect(g:chopsticks_input_method_default)
    endif
endfunction

function! s:InputMethodDeactivate() abort
    if !s:input_method_state.active
        return
    endif
    call s:InputMethodRememberInsert()
    let l:target = s:input_method_state.external
    let l:current = s:InputMethodCurrent()
    if get(g:, 'chopsticks_input_method_preserve_external', 1)
        \ && !empty(l:target) && l:current !=# l:target
        call s:InputMethodSelect(l:target)
    endif
    let s:input_method_state.active = 0
    let s:input_method_state.external = ''
    let s:input_method_assumed = ''
endfunction

function! s:InputMethodStatus() abort
    let l:info = ChopsticksInputMethodInfo()
    echo 'input method: ' . (l:info.enabled ? 'enabled' : 'disabled')
    echo 'available: ' . (l:info.available ? 'yes' : 'no') . ' (' . l:info.reason . ')'
    echo 'buffer: ' . (l:info.buffer_enabled ? 'enabled' : 'disabled')
        \ . ' (' . l:info.buffer_reason . ')'
    echo 'remote: ' . (l:info.remote ? 'yes' : 'no')
    echo 'Vim focus: ' . (l:info.vim_active ? 'active' : 'inactive')
    echo 'outside source: ' . (empty(l:info.external) ? '(not captured)' : l:info.external)
    echo 'preserve outside: ' . (l:info.preserve_external ? 'yes' : 'no')
    echo 'command: ' . l:info.command
    echo 'default: ' . l:info.default
    echo 'saved: ' . l:info.saved
    echo 'last: ' . l:info.last
endfunction

function! s:InputMethodEnable() abort
    let g:chopsticks_enable_input_method = 1
    let l:info = ChopsticksInputMethodInfo()
    if l:info.available
        call s:InputMethodActivate()
        echo 'chopsticks input method enabled'
    else
        echohl WarningMsg
        echom 'chopsticks input method enabled, but ' . l:info.reason
        echohl None
    endif
endfunction

function! s:InputMethodDisable() abort
    call s:InputMethodDeactivate()
    let g:chopsticks_enable_input_method = 0
    echo 'chopsticks input method disabled'
endfunction

function! s:InputMethodToggle() abort
    if get(g:, 'chopsticks_enable_input_method', 0)
        call s:InputMethodDisable()
    else
        call s:InputMethodEnable()
    endif
endfunction

command! ChopsticksInputMethodStatus call s:InputMethodStatus()
command! ChopsticksInputMethodEnable call s:InputMethodEnable()
command! ChopsticksInputMethodDisable call s:InputMethodDisable()
command! ChopsticksInputMethodToggle call s:InputMethodToggle()

augroup ChopsticksInputMethod
    autocmd!
    autocmd VimEnter * call <SID>InputMethodActivate()
    autocmd BufEnter * call <SID>InputMethodEnsureDefault()
    autocmd InsertLeave * call <SID>InputMethodSwitchToDefault()
    autocmd InsertEnter * call <SID>InputMethodRestore()
    autocmd FocusLost * call <SID>InputMethodDeactivate()
    autocmd FocusGained * call <SID>InputMethodActivate()
    autocmd VimLeavePre * call <SID>InputMethodDeactivate()
augroup END

" :source $MYVIMRC runs after VimEnter. The global state survives reloads so
" the original outside input source is not accidentally replaced with ABC.
if v:vim_did_enter
    call s:InputMethodActivate()
endif
