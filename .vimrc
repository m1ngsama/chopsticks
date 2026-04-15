" ============================================================================
" chopsticks — vim configuration
" Philosophy: flowing writing on any machine. No Node.js. Solarized palette.
" ============================================================================

" ============================================================================
" => Environment Detection  (must run first)
" ============================================================================

set nocompatible

let g:is_tty       = empty($TERM) || $TERM ==# 'dumb' || $TERM =~# 'linux'
                 \ || $TERM =~# 'screen' || &term =~# 'builtin'
let g:has_true_color = ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')

" ============================================================================
" => General Settings
" ============================================================================

filetype on
filetype plugin on
filetype indent on
syntax on

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
" path+=** removed: hangs on large repos (node_modules); use Ctrl+p (FZF) instead
set mouse=a
set encoding=utf-8
set foldmethod=indent
set foldlevel=99
set splitbelow
set splitright
set backspace=indent,eol,start
set autoread
set cmdheight=1
set hid
set whichwrap+=<,>,h,l
set magic
set showmatch
set mat=2
set noerrorbells
set novisualbell
set t_vb=
set tm=500
set ttimeout
set ttimeoutlen=10

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
set nowb
set noswapfile

if has('persistent_undo')
    set undofile
    let &undodir = expand('~/.vim/.undo')
    silent! call mkdir(&undodir, 'p', 0700)
endif

" ============================================================================
" => vim-plug
" ============================================================================

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
    silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs '
        \ . 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    augroup PlugBootstrap
        autocmd!
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
    augroup END
endif

call plug#begin('~/.vim/plugged')

" ── Navigation & Search ───────────────────────────────────────────────────────
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" ── Git ───────────────────────────────────────────────────────────────────────
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" ── Editing ───────────────────────────────────────────────────────────────────
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-unimpaired'
Plug 'wellle/targets.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'easymotion/vim-easymotion'

" ── Linting & Formatting ──────────────────────────────────────────────────────
Plug 'dense-analysis/ale'

" ── LSP + Completion (no Node.js required) ────────────────────────────────────
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" ── Language Syntax ───────────────────────────────────────────────────────────
Plug 'pangloss/vim-javascript'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'preservim/vim-markdown'
Plug 'fatih/vim-go'

" ── Markdown Preview ──────────────────────────────────────────────────────────
Plug 'previm/previm'

" ── UI ────────────────────────────────────────────────────────────────────────
Plug 'mbbill/undotree'
Plug 'mhinz/vim-startify'
Plug 'altercation/vim-colors-solarized'
if !g:is_tty
    Plug 'Yggdroot/indentLine'
endif

" ── Session ───────────────────────────────────────────────────────────────────
Plug 'tpope/vim-obsession'

" ── tmux ──────────────────────────────────────────────────────────────────────
Plug 'christoomey/vim-tmux-navigator'

call plug#end()

" ============================================================================
" => Colors  (Solarized Dark — matches tmux palette)
" ============================================================================

if g:has_true_color && has('termguicolors') && !g:is_tty
    " Required for true color inside tmux
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
endif

set background=dark

if &t_Co >= 256 && !g:is_tty
    try
        " 256-color approximation — works on any terminal, no palette setup needed
        let g:solarized_termcolors = 256
        colorscheme solarized
    catch
        colorscheme default
    endtry
else
    colorscheme default
endif

if has("gui_running")
    if has("gui_gtk2") || has("gui_gtk3")
        set guifont=Hack\ 12,Source\ Code\ Pro\ 12,Monospace\ 12
    elseif has("gui_win32")
        set guifont=Consolas:h11:cANSI
    endif
endif

" ============================================================================
" => Text, Tab and Indent
" ============================================================================

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
set tw=500
set autoindent
set smartindent

" ============================================================================
" => Key Mappings
" ============================================================================

let mapleader = ","

" Saving / quitting
nnoremap <leader>w :w!<cr>
nnoremap <leader>q :q<cr>
nnoremap <leader>x :x<cr>

" Clear search highlight
nnoremap <silent> <leader><cr> :noh<cr>

" Buffer navigation
nnoremap <leader>bd :Bclose<cr>
nnoremap <leader>ba :bufdo bd<cr>
nnoremap <leader>l  :bnext<cr>
nnoremap <leader>h  :bprevious<cr>

" Tab management
nnoremap <leader>tn :tabnew<cr>
nnoremap <leader>to :tabonly<cr>
nnoremap <leader>tc :tabclose<cr>
nnoremap <leader>tm :tabmove
nnoremap <leader>t<leader> :tabnext<cr>

let g:lasttab = 1
nnoremap <Leader>tl :exe "tabn ".g:lasttab<CR>
augroup ChopstickTabHistory
    autocmd!
    autocmd TabLeave * let g:lasttab = tabpagenr()
augroup END

nnoremap <leader>te :tabedit <C-r>=expand("%:p:h")<cr>/
nnoremap <leader>cd :lcd %:p:h<cr>:pwd<cr>

" File browser (netrw — built-in, no plugins)
nnoremap <leader>e :Explore<CR>
nnoremap <leader>E :Vexplore<CR>

" Remap 0 to first non-blank (all modes intentional)
noremap 0 ^

" Reselect last paste
nnoremap gV `[v`]

" Command-line history
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>

" Move lines (Alt+j / Alt+k in both normal and visual mode)
nnoremap <M-j> :m .+1<CR>==
nnoremap <M-k> :m .-2<CR>==
vnoremap <M-j> :m '>+1<CR>gv=gv
vnoremap <M-k> :m '<-2<CR>gv=gv

" Spell checking
nnoremap <leader>ss :setlocal spell!<cr>
nnoremap <leader>sn ]s
nnoremap <leader>sp [s
nnoremap <leader>sa zg
nnoremap <leader>s? z=

" Toggle modes
set pastetoggle=<F2>
nnoremap <F3> :set invnumber<CR>
nnoremap <F4> :set invrelativenumber<CR>
nnoremap <F6> :set list!<CR>

" Folding
nnoremap <space> za

" Consistency with D and C
nnoremap Y y$
nnoremap Q <nop>

" Ergonomic escape
inoremap jk <Esc>

" Indent keeps visual selection
vnoremap < <gv
vnoremap > >gv

" Search: centre result on screen
nnoremap n nzzzv
nnoremap N Nzzzv

" Search for visual selection
vnoremap // y/\V<C-r>=escape(@",'/\')<CR><CR>

" Save from any mode
nnoremap <silent> <C-s> :w<CR>
inoremap <silent> <C-s> <Esc>:w<CR>a

" Scroll keeping cursor centred
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

" System clipboard
if has('clipboard')
    nnoremap <leader>y "+y
    vnoremap <leader>y "+y
    nnoremap <leader>Y "+Y
    nnoremap <leader>p "+p
    nnoremap <leader>P "+P
endif

" Quickfix
nnoremap <leader>qo :copen<CR>
nnoremap <leader>qc :cclose<CR>

" Auto-equalise splits on window resize
augroup ChopstickResize
    autocmd!
    autocmd VimResized * wincmd =
augroup END

" ============================================================================
" => netrw  (built-in file browser — replaces NERDTree)
" ============================================================================
"
"  <leader>e   open netrw in current window   (:Explore)
"  <leader>E   open netrw in a vertical split  (:Vexplore)
"  Inside netrw:
"    Enter / o   open file
"    -           go up one directory
"    %           create new file
"    d           create new directory
"    D           delete file/directory
"    R           rename
"    gh          toggle hidden files
"    i           cycle list style  (1=thin, 2=long, 3=tree, 4=wide)

let g:netrw_liststyle    = 3        " tree view by default
let g:netrw_banner       = 0        " no banner
let g:netrw_browse_split = 0        " open in same window
let g:netrw_winsize      = 25       " 25% width when split
let g:netrw_list_hide    = '\(^\|\s\s\)\zs\.\S\+'
let g:netrw_list_hide   .= ',\.pyc$,node_modules,\.git,__pycache__,\.DS_Store'

" ============================================================================
" => FZF
" ============================================================================

" Ctrl+p: git-aware file search (GFiles inside repo, Files outside)
function! s:SmartFiles() abort
    if isdirectory('.git') || finddir('.git', '.;') !=# ''
        GFiles
    else
        Files
    endif
endfunction

if exists('g:plugs["fzf.vim"]')
    nnoremap <C-p>     :call <SID>SmartFiles()<CR>
    nnoremap <leader>b :Buffers<CR>
    nnoremap <leader>rg :Rg<CR>
    nnoremap <leader>rG :RgWord<CR>
    nnoremap <leader>rt :Tags<CR>
    nnoremap <leader>gF :GFiles<CR>
endif

let g:fzf_layout = { 'down': '40%' }

if g:is_tty
    let g:fzf_preview_window = []
else
    let g:fzf_preview_window = ['right:50%', 'ctrl-/']
endif

if g:is_tty
    command! -bang -nargs=* Rg
        \ call fzf#vim#grep(
        \   'rg --column --line-number --no-heading --color=always --smart-case -- '
        \   .shellescape(<q-args>), 1, <bang>0)
    command! -bang GFiles call fzf#vim#gitfiles('', <bang>0)
else
    command! -bang -nargs=* Rg
        \ call fzf#vim#grep(
        \   'rg --column --line-number --no-heading --color=always --smart-case -- '
        \   .shellescape(<q-args>), 1, fzf#vim#with_preview(), <bang>0)
    command! -bang GFiles call fzf#vim#gitfiles('', fzf#vim#with_preview(), <bang>0)
endif

" RgWord: fixed-string search for word under cursor (flags before --)
if g:is_tty
    command! -bang -nargs=* RgWord
        \ call fzf#vim#grep(
        \   'rg --column --line-number --no-heading --color=always --smart-case -F -- '
        \   .shellescape(expand('<cword>')), 1, <bang>0)
else
    command! -bang -nargs=* RgWord
        \ call fzf#vim#grep(
        \   'rg --column --line-number --no-heading --color=always --smart-case -F -- '
        \   .shellescape(expand('<cword>')), 1, fzf#vim#with_preview(), <bang>0)
endif

" ============================================================================
" => GitGutter
" ============================================================================

let g:gitgutter_sign_added            = '+'
let g:gitgutter_sign_modified         = '~'
let g:gitgutter_sign_removed          = '-'
let g:gitgutter_sign_removed_first_line = '^'
let g:gitgutter_sign_modified_removed = '~'

" ============================================================================
" => ALE  (async linting + format-on-save)
" ============================================================================

let g:ale_linters = {
\   'python':     ['flake8', 'pylint'],
\   'javascript': ['eslint'],
\   'typescript': ['eslint', 'tsserver'],
\   'go':         ['gopls', 'staticcheck'],
\   'rust':       ['cargo'],
\   'c':          ['cc'],
\   'sh':         ['shellcheck'],
\   'yaml':       ['yamllint'],
\   'dockerfile': ['hadolint'],
\   'css':        ['stylelint'],
\   'scss':       ['stylelint'],
\   'markdown':   ['markdownlint'],
\   'sql':        ['sqlfluff'],
\}

let g:ale_fixers = {
\   '*':          ['remove_trailing_lines', 'trim_whitespace'],
\   'python':     ['black', 'isort'],
\   'javascript': ['prettier', 'eslint'],
\   'typescript': ['prettier', 'eslint'],
\   'go':         ['gofmt', 'goimports'],
\   'rust':       ['rustfmt'],
\   'c':          ['clang-format'],
\   'json':       ['prettier'],
\   'yaml':       ['prettier'],
\   'html':       ['prettier'],
\   'css':        ['prettier'],
\   'scss':       ['prettier'],
\   'less':       ['prettier'],
\   'markdown':   ['prettier'],
\   'sql':        ['sqlfluff'],
\}

let g:ale_fix_on_save          = 1
let g:ale_sign_error           = 'X'
let g:ale_sign_warning         = '!'
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_enter        = 1

if exists('g:plugs["ale"]')
    nnoremap <silent> [e :ALEPrevious<cr>
    nnoremap <silent> ]e :ALENext<cr>
    nnoremap <silent> <leader>aD :ALEDetail<cr>
endif

" ============================================================================
" => vim-go
" ============================================================================

" vim-lsp (gopls) handles all Go intelligence; disable vim-go's own LSP layer
let g:go_gopls_enabled            = 0
let g:go_code_completion_enabled  = 0
let g:go_def_mode                 = 'godef'
let g:go_info_mode                = 'godef'
let g:go_fmt_autosave             = 0  " ALE handles format-on-save
let g:go_imports_autosave         = 0
let g:go_highlight_types          = 1
let g:go_highlight_fields         = 1
let g:go_highlight_functions      = 1
let g:go_highlight_function_calls = 1

" ============================================================================
" => vim-lsp  (primary LSP backend — pure VimScript, no Node.js)
" ============================================================================

let g:lsp_settings_filetype_python     = ['pylsp', 'pyright-langserver']
let g:lsp_settings_filetype_go         = ['gopls']
let g:lsp_settings_filetype_rust       = ['rust-analyzer']
let g:lsp_settings_filetype_typescript = ['typescript-language-server']
let g:lsp_settings_filetype_javascript = ['typescript-language-server']
let g:lsp_settings_filetype_c          = ['clangd']
let g:lsp_settings_filetype_sh         = ['bash-language-server']
let g:lsp_settings_filetype_html       = ['vscode-html-language-server']
let g:lsp_settings_filetype_css        = ['vscode-css-language-server']
let g:lsp_settings_filetype_scss       = ['vscode-css-language-server']
let g:lsp_settings_filetype_json       = ['vscode-json-language-server']
let g:lsp_settings_filetype_yaml       = ['yaml-language-server']
let g:lsp_settings_filetype_markdown   = ['marksman']
let g:lsp_settings_filetype_sql        = ['sqls']

let g:lsp_diagnostics_virtual_text_enabled = !g:is_tty
let g:lsp_diagnostics_highlights_enabled   = !g:is_tty
let g:lsp_document_highlight_enabled       = !g:is_tty
let g:lsp_signs_enabled                    = 1
let g:lsp_diagnostics_echo_cursor          = 1
let g:lsp_completion_documentation_enabled = 1

let g:lsp_signs_error       = {'text': 'X'}
let g:lsp_signs_warning     = {'text': '!'}
let g:lsp_signs_information = {'text': 'i'}
let g:lsp_signs_hint        = {'text': '>'}

if has('patch-8.1.1517')
    set completeopt=menuone,noinsert,noselect,popup
else
    set completeopt=menuone,noinsert,noselect
endif
set pumheight=15
let g:asyncomplete_auto_popup       = 1
let g:asyncomplete_auto_completeopt = 1
let g:asyncomplete_popup_delay      = 200

" Completion popup navigation
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>    pumvisible() ? asyncomplete#close_popup() : "\<CR>"

function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes

    " Navigation
    nmap <buffer> gd          <plug>(lsp-definition)
    nmap <buffer> gy          <plug>(lsp-type-definition)
    nmap <buffer> gi          <plug>(lsp-implementation)
    nmap <buffer> gr          <plug>(lsp-references)
    nmap <buffer> [g          <plug>(lsp-previous-diagnostic)
    nmap <buffer> ]g          <plug>(lsp-next-diagnostic)

    " Documentation
    nmap <buffer> K           <plug>(lsp-hover)

    " Refactoring
    nmap <buffer> <leader>rn  <plug>(lsp-rename)
    nmap <buffer> <leader>ca  <plug>(lsp-code-action)
    nmap <buffer> <leader>f   <plug>(lsp-document-format)
    xmap <buffer> <leader>f   <plug>(lsp-document-range-format)

    " Workspace
    nmap <buffer> <leader>o   <plug>(lsp-document-symbol-search)
    nmap <buffer> <leader>ws  <plug>(lsp-workspace-symbol-search)
    nmap <buffer> <leader>cD  <plug>(lsp-document-diagnostics)
endfunction

augroup lsp_install
    autocmd!
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

" ============================================================================
" => vim-markdown
" ============================================================================

" Concealment: hides syntax markers, renders formatting inline
" (cursor moving to a line temporarily reveals the raw syntax)
let g:vim_markdown_conceal             = 1
let g:vim_markdown_conceal_code_blocks = 0   " keep fenced code readable
let g:vim_markdown_folding_disabled    = 0
let g:vim_markdown_folding_level       = 2
let g:vim_markdown_frontmatter        = 1    " YAML front matter
let g:vim_markdown_toml_frontmatter   = 1
let g:vim_markdown_json_frontmatter   = 1
let g:vim_markdown_follow_anchor      = 1
let g:vim_markdown_new_list_item_indent = 2
let g:vim_markdown_strikethrough      = 1

" Table of contents (side window)
if exists('g:plugs["vim-markdown"]')
    nnoremap <leader>mt :Toc<CR>
endif

" ============================================================================
" => previm  (Markdown browser preview)
" ============================================================================

" <leader>mp   open live-reloading preview in browser
if exists('g:plugs["previm"]')
    nnoremap <leader>mp :PrevimOpen<CR>
endif
let g:previm_enable_realtime = 1

" ============================================================================
" => EasyMotion
" ============================================================================

let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase  = 1

if exists('g:plugs["vim-easymotion"]')
    " s + two chars: jump anywhere on screen
    nmap s <Plug>(easymotion-overwin-f2)
    " Line motions
    nmap <Leader>j <Plug>(easymotion-j)
    nmap <Leader>k <Plug>(easymotion-k)
endif

" ============================================================================
" => UndoTree
" ============================================================================

if exists('g:plugs["undotree"]')
    nnoremap <F5>       :UndotreeToggle<CR>
    nnoremap <leader>u  :UndotreeToggle<CR>
endif

" ============================================================================
" => IndentLine  (non-TTY only)
" ============================================================================

if !g:is_tty && exists('g:plugs["indentLine"]')
    let g:indentLine_char                 = '|'
    let g:indentLine_first_char           = '|'
    let g:indentLine_showFirstIndentLevel = 1
    " Exclude filetypes where concealment causes display issues
    let g:indentLine_fileTypeExclude      = ['text', 'help', 'startify', 'markdown']
    let g:indentLine_bufTypeExclude       = ['help', 'terminal', 'nofile']
    " Let indentLine manage conceallevel (reverts on excluded types)
    let g:indentLine_setConceal           = 2
    let g:indentLine_concealcursor        = ''
endif

" ============================================================================
" => Startify  (startup screen + session management)
" ============================================================================

if exists('g:plugs["vim-startify"]')
    let g:startify_custom_header = [
        \ '         ██████╗██╗  ██╗ ██████╗ ██████╗ ███████╗████████╗██╗ ██████╗██╗  ██╗███████╗',
        \ '        ██╔════╝██║  ██║██╔═══██╗██╔══██╗██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝██╔════╝',
        \ '        ██║     ███████║██║   ██║██████╔╝███████╗   ██║   ██║██║     █████╔╝ ███████╗',
        \ '        ██║     ██╔══██║██║   ██║██╔═══╝ ╚════██║   ██║   ██║██║     ██╔═██╗ ╚════██║',
        \ '        ╚██████╗██║  ██║╚██████╔╝██║     ███████║   ██║   ██║╚██████╗██║  ██╗███████║',
        \ '         ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝',
        \ '',
        \ ]

    let g:startify_lists = [
        \ { 'type': 'sessions',  'header': ['   Sessions']     },
        \ { 'type': 'files',     'header': ['   Recent Files'] },
        \ { 'type': 'dir',       'header': ['   Current Dir']  },
        \ { 'type': 'bookmarks', 'header': ['   Bookmarks']    },
        \ ]

    let g:startify_bookmarks = [{'v': '~/.vimrc'}]
    if filereadable(expand('~/.zshrc'))
        call add(g:startify_bookmarks, {'z': '~/.zshrc'})
    endif
    if filereadable(expand('~/.bashrc'))
        call add(g:startify_bookmarks, {'b': '~/.bashrc'})
    endif
    if filereadable(expand('~/.config/fish/config.fish'))
        call add(g:startify_bookmarks, {'f': '~/.config/fish/config.fish'})
    endif

    let g:startify_session_persistence = 1
    let g:startify_session_autoload    = 1
    let g:startify_change_to_vcs_root  = 1
    let g:startify_fortune_use_unicode = 0
    let g:startify_enable_special      = 0
    let g:startify_files_number        = 8
    let g:startify_padding_left        = 4

    " vim <dir>: cd to it and show Startify (no auto file-tree)
    if !g:is_tty
        augroup ChopstickStartup
            autocmd!
            autocmd StdinReadPre * let s:std_in = 1
            autocmd VimEnter *
                \ if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') |
                \     exe 'cd ' . fnameescape(argv()[0]) |
                \     if exists(':Startify') == 2 | Startify | else | enew | endif |
                \ endif
        augroup END
    endif

    augroup ChopstickStartify
        autocmd!
        autocmd User Startified setlocal buftype=
    augroup END
endif

" ============================================================================
" => Status Line  (native — Solarized palette, seamless with tmux bar)
" ============================================================================
"
"  Palette reference (Solarized 256 approximations):
"    base03=234  base02=235  base01=240  base0=244  base1=245
"    yellow=136  blue=33     cyan=37     green=64    red=160
"    orange=166  magenta=125
"
"  The statusline bg (base02=235 / #073642) intentionally matches the tmux
"  status bar bg (#002b36 ≈ base03), so the two bars read as one continuous
"  band at the bottom of the screen.

set laststatus=2
set noshowmode   " mode is shown in the statusline block, not the echo line

function! s:SLDefineColors() abort
    hi SLNormal  ctermbg=136 ctermfg=234 cterm=bold guibg=#b58900 guifg=#002b36 gui=bold
    hi SLInsert  ctermbg=33  ctermfg=234 cterm=bold guibg=#268bd2 guifg=#002b36 gui=bold
    hi SLVisual  ctermbg=125 ctermfg=234 cterm=bold guibg=#d33682 guifg=#002b36 gui=bold
    hi SLReplace ctermbg=160 ctermfg=234 cterm=bold guibg=#dc322f guifg=#002b36 gui=bold
    hi SLCommand ctermbg=37  ctermfg=234 cterm=bold guibg=#2aa198 guifg=#002b36 gui=bold
    hi SLBody    ctermbg=235 ctermfg=245 cterm=none guibg=#073642 guifg=#93a1a1
    hi SLFlag    ctermbg=235 ctermfg=136 cterm=none guibg=#073642 guifg=#b58900
    hi SLRight   ctermbg=235 ctermfg=240 cterm=none guibg=#073642 guifg=#586e75
    hi SLGit     ctermbg=235 ctermfg=37  cterm=none guibg=#073642 guifg=#2aa198
    hi SLFtype   ctermbg=235 ctermfg=244 cterm=none guibg=#073642 guifg=#839496
endfunction

augroup SLColors
    autocmd!
    autocmd ColorScheme * call s:SLDefineColors()
augroup END

" Current mode → [label, highlight-group]
function! SLMode() abort
    let l:m = mode()
    if     l:m ==# 'n'                          | return [' N ', 'SLNormal' ]
    elseif l:m ==# 'i'                          | return [' I ', 'SLInsert' ]
    elseif l:m =~# '[vV]' || l:m ==# "\<C-v>"  | return [' V ', 'SLVisual' ]
    elseif l:m ==# 'R'                          | return [' R ', 'SLReplace']
    elseif l:m ==# 'c'                          | return [' C ', 'SLCommand']
    elseif l:m ==# 't'                          | return [' T ', 'SLInsert' ]
    else                                        | return [' ' . l:m . ' ', 'SLNormal']
    endif
endfunction

" Git branch via vim-fugitive (already installed — zero extra cost)
function! SLGit() abort
    if !exists('*FugitiveHead') | return '' | endif
    let l:b = FugitiveHead()
    return empty(l:b) ? '' : '  ' . l:b . ' '
endfunction

" Assemble the statusline on every redraw
function! SLBuild() abort
    let [l:label, l:hl] = SLMode()
    let l:s  = '%#' . l:hl . '#' . l:label
    let l:s .= '%#SLBody# %f '
    let l:s .= '%#SLFlag#%m%r'
    let l:s .= '%#SLBody#%='
    let l:s .= '%#SLGit#'  . SLGit()
    let l:s .= '%#SLFtype# %y '
    let l:s .= '%#SLRight# %l:%c  %P '
    return l:s
endfunction

set statusline=%!SLBuild()

" TTY: simpler fallback (no colour, no function call overhead)
if g:is_tty
    set statusline=%f\ %h%w%m%r\ %=%(%l,%c%V\ %=\ %P%)
endif

" ============================================================================
" => Helper Functions
" ============================================================================

function! HasPaste()
    if &paste | return 'PASTE MODE  ' | endif
    return ''
endfunction

" Close buffer without closing the window
command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
    let l:currentBufNum   = bufnr("%")
    let l:alternateBufNum = bufnr("#")
    if buflisted(l:alternateBufNum)
        buffer #
    else
        bnext
    endif
    if bufnr("%") == l:currentBufNum
        new
    endif
    if buflisted(l:currentBufNum)
        execute("bdelete! " . l:currentBufNum)
    endif
endfunction

" Strip trailing whitespace without moving cursor
fun! CleanExtraSpaces()
    let save_cursor = getpos(".")
    let old_query   = getreg('/')
    silent! %s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfun

" Toggle between absolute and relative numbers
function! ToggleNumber()
    if(&relativenumber == 1)
        set norelativenumber
        set number
    else
        set relativenumber
    endif
endfunc

" ============================================================================
" => Auto Commands
" ============================================================================

" Suppress comment continuation on Enter / o / O
augroup ChopstickFormatOptions
    autocmd!
    autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
augroup END

" Auto-disable paste mode on leaving insert
augroup ChopstickPaste
    autocmd!
    autocmd InsertLeave * set nopaste
augroup END

augroup ChopstickFiletype
    autocmd!

    " Restore cursor to last known position
    autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

    " Filetype detection for common extensions
    autocmd BufNewFile,BufRead *.json      setlocal filetype=json
    autocmd BufNewFile,BufRead *.md        setlocal filetype=markdown
    autocmd BufNewFile,BufRead *.jsx       setlocal filetype=javascript.jsx
    autocmd BufNewFile,BufRead *.tsx       setlocal filetype=typescript.tsx
    autocmd BufNewFile,BufRead Dockerfile* setlocal filetype=dockerfile

    " Per-filetype formatting
    autocmd FileType python
        \ setlocal expandtab shiftwidth=4 tabstop=4 textwidth=88 colorcolumn=+1
    autocmd FileType javascript,typescript
        \ setlocal expandtab shiftwidth=2 tabstop=2 textwidth=100 colorcolumn=+1
    autocmd FileType go
        \ setlocal noexpandtab shiftwidth=4 tabstop=4 textwidth=120 colorcolumn=+1
    autocmd FileType rust
        \ setlocal expandtab shiftwidth=4 tabstop=4 textwidth=100 colorcolumn=+1
    autocmd FileType c,cpp
        \ setlocal expandtab shiftwidth=4 tabstop=4 textwidth=80 colorcolumn=+1
    autocmd FileType html,css
        \ setlocal expandtab shiftwidth=2 tabstop=2
    autocmd FileType yaml
        \ setlocal expandtab shiftwidth=2 tabstop=2
    autocmd FileType markdown
        \ setlocal wrap linebreak spell textwidth=0 colorcolumn=0 conceallevel=2
    autocmd FileType sh
        \ setlocal expandtab shiftwidth=2 tabstop=2 textwidth=80 colorcolumn=+1
    autocmd FileType make
        \ setlocal noexpandtab shiftwidth=8 tabstop=8
    autocmd FileType json
        \ setlocal expandtab shiftwidth=2 tabstop=2
    autocmd FileType dockerfile
        \ setlocal expandtab shiftwidth=2 tabstop=2
augroup END

" ============================================================================
" => Performance
" ============================================================================

set synmaxcol=200
set ttyfast
set complete-=i   " don't scan included files — makes Ctrl+n/p much faster
set updatetime=300
set shortmess+=c

if g:is_tty
    set signcolumn=auto
    set synmaxcol=120
    set lazyredraw
else
    if has("patch-8.1.1564")
        set signcolumn=number
    else
        set signcolumn=yes
    endif
endif

" ============================================================================
" => Project-Local Config
" ============================================================================

set exrc
set secure
set sessionoptions=blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal

" ============================================================================
" => Additional Utilities
" ============================================================================

" Quick re-indent entire file
nnoremap <leader>F gg=G``

" Save all open buffers
nnoremap <leader>wa :wa<CR>

" Window resizing
nnoremap <silent> <Leader>= :exe "resize "          . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize "          . (winheight(0) * 2/3)<CR>
nnoremap <silent> <Leader>+ :exe "vertical resize " . (winwidth(0)  * 3/2)<CR>
nnoremap <silent> <Leader>_ :exe "vertical resize " . (winwidth(0)  * 2/3)<CR>

" Quick-switch between last two files
nnoremap <leader><leader> <c-^>

" Strip trailing whitespace (manual, no auto-save)
nnoremap <leader>W :%s/\s\+$//<CR>:let @/=''<CR>

" Source helpers
nnoremap <leader>so :if &filetype ==# 'vim' <Bar> source % <Bar> echo "Sourced " . expand('%') <Bar> else <Bar> echo "Not a vim file" <Bar> endif<CR>
nnoremap <leader>ev :edit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>:echo "vimrc reloaded"<CR>

" Search and replace word under cursor
nnoremap <leader>* :%s/\<<C-r><C-w>\>//g<Left><Left>

" Copy path / filename to clipboard
if has('clipboard')
    nnoremap <leader>cp :let @+ = expand("%:p")<CR>:echo "Copied: " . expand("%:p")<CR>
    nnoremap <leader>cf :let @+ = expand("%:t")<CR>:echo "Copied: " . expand("%:t")<CR>
endif

" Scratch markdown buffer
nnoremap <leader>ms :e ~/buffer.md<cr>

" Auto-create parent directories on save
function! s:MkNonExDir(file, buf)
    if empty(getbufvar(a:buf, '&buftype')) && a:file !~# '\v^\w+\:\/'
        let dir = fnamemodify(a:file, ':h')
        if !isdirectory(dir)
            call mkdir(dir, 'p')
        endif
    endif
endfunction
augroup BWCCreateDir
    autocmd!
    autocmd BufWritePre *
        \ if !empty(expand('<afile>')) |
        \     call s:MkNonExDir(expand('<afile>'), +expand('<abuf>')) |
        \ endif
augroup END

" ============================================================================
" => Git Shortcuts
" ============================================================================

if exists('g:plugs["vim-fugitive"]')
    nnoremap <leader>gs :Git status<CR>
    nnoremap <leader>gc :Git commit<CR>
    nnoremap <leader>gp :Git push<CR>
    nnoremap <leader>gl :Git pull<CR>
    nnoremap <leader>gd :Gdiffsplit<CR>
    nnoremap <leader>gb :Git blame<CR>
endif

" ============================================================================
" => Terminal Integration
" ============================================================================

if has('terminal')
    nnoremap <leader>tv :terminal<CR>
    nnoremap <leader>th :terminal ++rows=10<CR>
    " Double-Esc exits terminal mode (single Esc passes through to the program)
    tnoremap <Esc><Esc> <C-\><C-n>
    tnoremap <C-h> <C-\><C-n><C-w>h
    tnoremap <C-j> <C-\><C-n><C-w>j
    tnoremap <C-k> <C-\><C-n><C-w>k
    tnoremap <C-l> <C-\><C-n><C-w>l
endif

" ============================================================================
" => Large File Handling  (>10 MB)
" ============================================================================

let g:LargeFile = 1024 * 1024 * 10
augroup LargeFile
    autocmd!
    autocmd BufReadPre *
        \ if !empty(expand('<afile>')) |
        \     let f = getfsize(expand('<afile>')) |
        \     if f > g:LargeFile || f == -2 | call LargeFileSettings() | endif |
        \ endif
augroup END

function! LargeFileSettings()
    setlocal bufhidden=unload
    setlocal undolevels=-1
    setlocal noswapfile
    setlocal syntax=
    let b:ale_enabled = 0
    echo "Large file (>10 MB): syntax, undo, and linting disabled."
endfunction

if g:is_tty
    augroup ChopstickTTYLargeFile
        autocmd!
        autocmd BufReadPre *
            \ if !empty(expand('<afile>')) && getfsize(expand('<afile>')) > 512000 |
            \     setlocal syntax= |
            \ endif
    augroup END

    if !exists("g:tty_message_shown")
        augroup TTYMessage
            autocmd!
            autocmd VimEnter * echom "TTY mode — visual features disabled"
        augroup END
        let g:tty_message_shown = 1
    endif
endif

" ============================================================================
" => Cheat Sheet  (,?)
" ============================================================================

set timeoutlen=500

function! s:CheatSheet() abort
    let l:name = '__ChopsticksCheatSheet__'
    if bufwinnr(l:name) > 0
        execute bufwinnr(l:name) . 'wincmd w'
        return
    endif
    execute 'botright new ' . l:name
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    call setline(1, [
        \ '=== chopsticks — Quick Reference ===',
        \ '',
        \ 'MODES',
        \ '  Normal    Default. Navigate and run commands.',
        \ '  Insert    Type text.  Enter: i/a/o   Leave: Esc or jk',
        \ '  Visual    Select.     Enter: v/V      Leave: Esc',
        \ '',
        \ 'SURVIVAL',
        \ '  Esc / jk      Exit insert or visual mode',
        \ '  :q! + Enter   Quit without saving',
        \ '  ,x            Save and quit  |  ,w  Save',
        \ '  Ctrl+s        Save (normal + insert mode)',
        \ '',
        \ 'FILES & NAVIGATION',
        \ '  Ctrl+p        Fuzzy find file (git-aware, FZF)',
        \ '  ,e            Open netrw file browser',
        \ '  ,E            Open netrw in vertical split',
        \ '  ,b            Search open buffers (FZF)',
        \ '  ,rg           Search project contents (ripgrep)',
        \ '  ,rG           Ripgrep word under cursor',
        \ '  ,,            Switch to last file (Ctrl+^)',
        \ '  Ctrl+o / i    Jump back / forward in history',
        \ '',
        \ 'CODE INTELLIGENCE (vim-lsp)',
        \ '  gd            Go to definition',
        \ '  gy            Go to type definition',
        \ '  gi            Go to implementation',
        \ '  gr            Show references',
        \ '  K             Hover documentation',
        \ '  [g / ]g       Prev / next LSP diagnostic',
        \ '  [e / ]e       Prev / next ALE error',
        \ '  ,ca           Code action',
        \ '  ,rn           Rename symbol',
        \ '  ,f            Format buffer (or visual selection)',
        \ '  ,o            File outline (symbols)',
        \ '  ,ws           Workspace symbols',
        \ '',
        \ 'MARKDOWN',
        \ '  ,mp           Open live browser preview (previm)',
        \ '  ,mt           Table of contents',
        \ '  zr            Unfold all headings',
        \ '  zm            Fold all headings',
        \ '',
        \ 'EDITING',
        \ '  gc            Toggle comment (visual mode too)',
        \ '  s + 2 chars   EasyMotion — jump anywhere on screen',
        \ '  ,j / ,k       EasyMotion — line motions',
        \ '  ,u / F5       Undo tree (visual branch history)',
        \ '  ,y / ,Y       Yank / yank line to system clipboard',
        \ '  ,p / ,P       Paste from system clipboard',
        \ '  Alt+j / Alt+k Move line down / up (also visual mode)',
        \ '  ,F            Re-indent entire file',
        \ '  ,W            Strip trailing whitespace',
        \ '  ,*            Search and replace word under cursor',
        \ '',
        \ 'SPELLING',
        \ '  ,ss           Toggle spell checking',
        \ '  ,sn / ,sp     Next / prev misspelling',
        \ '  ,sa           Add word to dictionary',
        \ '  ,s?           Suggest corrections',
        \ '',
        \ 'GIT',
        \ '  ,gs  Status   ,gd  Diff   ,gb  Blame',
        \ '  ,gc  Commit   ,gp  Push   ,gl  Pull',
        \ '',
        \ 'WINDOWS & PANES',
        \ '  Ctrl+h/j/k/l  Navigate Vim splits and tmux panes',
        \ '  ,h / ,l       Prev / next buffer',
        \ '  ,bd            Close buffer (keep layout)',
        \ '  ,tn / ,tc     New tab / close tab  |  ,tl  Last tab',
        \ '  ,tv / ,th     Open terminal (vertical / horizontal)',
        \ '  Esc Esc       Exit terminal mode',
        \ '  ,= / ,-       Resize height (grow / shrink)',
        \ '  ,+ / ,_       Resize width  (grow / shrink)',
        \ '',
        \ 'UTILITIES',
        \ '  ,ev / ,sv     Edit / reload ~/.vimrc',
        \ '  ,cp / ,cf     Copy file path / filename to clipboard',
        \ '  ,ms           Open scratch markdown buffer',
        \ '  ,cd           Change CWD to current file directory',
        \ '  F2  Paste   F3  Line#   F4  Relative#   F6  Invisible',
        \ '',
        \ 'SESSION',
        \ '  :Obsess       Start tracking session',
        \ '  :Obsess!      Stop tracking',
        \ '',
        \ '(press q to close)',
        \ ])
    setlocal nomodifiable readonly
    nnoremap <buffer> <silent> q :bd<CR>
endfunction
nnoremap <silent> <leader>? :call <SID>CheatSheet()<CR>

" ============================================================================
" => Debug Helpers
" ============================================================================

" Show syntax highlight stack for word under cursor
nnoremap <leader>sh :call <SID>SynStack()<CR>
function! <SID>SynStack()
    if !exists("*synstack") | return | endif
    echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

" ============================================================================
" End of Configuration
" ============================================================================
