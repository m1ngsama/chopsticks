" ============================================================================
" Vim Configuration - The Ultimate vimrc
" Inspired by the best practices from the Vim community
" ============================================================================

" ============================================================================
" => General Settings
" ============================================================================

" Disable compatibility with vi which can cause unexpected issues
set nocompatible

" Detect terminal type and capabilities (must be early for conditional configs)
let g:is_tty = ($TERM =~ 'linux' || $TERM =~ 'screen' || &term =~ 'builtin')
let g:has_true_color = ($COLORTERM == 'truecolor' || $COLORTERM == '24bit')

" Enable type file detection. Vim will be able to try to detect the type of file in use
filetype on

" Enable plugins and load plugin for the detected file type
filetype plugin on

" Load an indent file for the detected file type
filetype indent on

" Turn syntax highlighting on
syntax on

" Add numbers to each line on the left-hand side
set number

" Show relative line numbers
set relativenumber

" Highlight cursor line (disabled in TTY for performance)
if !g:is_tty
    set cursorline
endif

" Do not save backup files
set nobackup

" Do not let cursor scroll below or above N number of lines when scrolling
set scrolloff=10

" Do not wrap lines. Allow long lines to extend as far as the line goes
set nowrap

" While searching though a file incrementally highlight matching characters as you type
set incsearch

" Ignore capital letters during search
set ignorecase

" Override the ignorecase option if searching for capital letters
set smartcase

" Show partial command you type in the last line of the screen
set showcmd

" Show the mode you are on the last line
set showmode

" Use highlighting when doing a search
set hlsearch

" Set the commands to save in history default number is 20
set history=1000

" Enable auto completion menu after pressing TAB
set wildmenu

" Make wildmenu behave like similar to Bash completion
set wildmode=list:longest

" There are certain files that we would never want to edit with Vim
" Wildmenu will ignore files with these extensions
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" Enable mouse support
set mouse=a

" Set encoding
set encoding=utf-8

" Enable folding
set foldmethod=indent
set foldlevel=99

" Split window settings
set splitbelow
set splitright

" Better backspace behavior
set backspace=indent,eol,start

" Auto read when file is changed from outside
set autoread

" Height of the command bar
set cmdheight=1

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act (enhanced from earlier basic setting)
set whichwrap+=<,>,h,l

" For regular expressions turn magic on
set magic

" Show matching brackets and how many tenths of a second to blink
set showmatch
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Enable 256 colors palette in Gnome Terminal
if $COLORTERM == 'gnome-terminal'
    set t_Co=256
endif

" Set extra options when running in GUI mode
if has("gui_running")
    set guioptions-=T
    set guioptions-=e
    set t_Co=256
    set guitablabel=%M\ %t
endif

" Use Unix as the standard file type
set ffs=unix,dos,mac

set nowb
set noswapfile

" Persistent undo across sessions
if has('persistent_undo')
    set undofile
    let &undodir = expand('~/.vim/.undo')
    silent! call mkdir(&undodir, 'p', 0700)
endif

" ============================================================================
" => Vim-Plug Plugin Manager
" ============================================================================

" Auto-install vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugin list
call plug#begin('~/.vim/plugged')

" ===== File Navigation & Search =====
Plug 'preservim/nerdtree'                    " File explorer
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'                      " Fuzzy finder

" ===== Git Integration =====
Plug 'tpope/vim-fugitive'                    " Git wrapper
Plug 'airblade/vim-gitgutter'                " Show git diff in gutter

" ===== Status Line & UI =====
Plug 'vim-airline/vim-airline'               " Status bar
Plug 'vim-airline/vim-airline-themes'        " Airline themes

" ===== Code Editing & Completion =====
Plug 'tpope/vim-surround'                    " Surround text objects
Plug 'tpope/vim-commentary'                  " Comment stuff out
Plug 'tpope/vim-repeat'                      " Repeat plugin maps
Plug 'jiangmiao/auto-pairs'                  " Auto close brackets
Plug 'dense-analysis/ale'                    " Async linting engine

" ===== Language Support =====
Plug 'sheerun/vim-polyglot'                  " Language pack
Plug 'fatih/vim-go'                                  " Go support (run :GoUpdateBinaries manually if needed)

" ===== Color Schemes =====
Plug 'morhetz/gruvbox'                       " Gruvbox theme
Plug 'dracula/vim', { 'as': 'dracula' }      " Dracula theme
Plug 'altercation/vim-colors-solarized'      " Solarized theme
Plug 'joshdick/onedark.vim'                  " One Dark theme

" ===== Productivity =====
Plug 'mbbill/undotree'                       " Undo history visualizer
Plug 'preservim/tagbar'                      " Tag browser
Plug 'easymotion/vim-easymotion'             " Easy motion

" ===== Code Intelligence (CoC: requires Vim 8.0.1453+ and Node.js) =====
if (has('nvim') || has('patch-8.0.1453')) && executable('node')
    Plug 'neoclide/coc.nvim', {'branch': 'release'}  " Full LSP + completion via Node.js
endif

" ===== Session Management =====
Plug 'tpope/vim-obsession'                   " Continuous session save
Plug 'dhruvasagar/vim-prosession'            " Better session management

" ===== Additional Utilities =====
Plug 'tpope/vim-unimpaired'                  " Handy bracket mappings
Plug 'wellle/targets.vim'                    " Additional text objects
Plug 'honza/vim-snippets'                    " Snippet collection

" ===== Native LSP (vim-lsp: works without Node.js, Vim 8.0+ only) =====
" Used as fallback when CoC/Node.js is unavailable
if !((has('nvim') || has('patch-8.0.1453')) && executable('node'))
    Plug 'prabirshrestha/vim-lsp'                " Pure VimScript LSP client
    Plug 'mattn/vim-lsp-settings'               " Auto-configure language servers
    Plug 'prabirshrestha/asyncomplete.vim'       " Async completion framework
    Plug 'prabirshrestha/asyncomplete-lsp.vim'   " LSP completion source for asyncomplete
endif

" ===== Enhanced UI Experience =====
Plug 'mhinz/vim-startify'                    " Startup screen with recent files
Plug 'liuchengxu/vim-which-key'              " Show keybindings on leader pause
if !g:is_tty
    Plug 'Yggdroot/indentLine'               " Indent guide lines
endif

call plug#end()

" ============================================================================
" => LSP Backend Detection & Completion Settings
" ============================================================================

" Detect which LSP backend is active
" Priority: CoC (full-featured, needs Node.js) > vim-lsp (lightweight fallback)
let g:use_coc = (has('nvim') || has('patch-8.0.1453')) && executable('node') && exists('g:plugs["coc.nvim"]')
let g:use_vimlsp = !g:use_coc && has('patch-8.0.0') && exists('g:plugs["vim-lsp"]')

" Suppress coc.nvim's blocking startup warning on Vim < 9.0.0438
" (the guard above already prevents coc from loading, but the warning
"  fires from the plugin file itself if coc.nvim is in runtimepath)
if !g:use_coc
    let g:coc_start_at_startup     = 0
    let g:coc_disable_startup_warning = 1
endif

" Limit popup menu height (applies to all completion)
set pumheight=15

" ============================================================================
" => Colors and Fonts
" ============================================================================

" Enable true colors support only if terminal supports it
if g:has_true_color && has('termguicolors') && !g:is_tty
    set termguicolors
endif

" Set colorscheme with proper fallbacks
if &t_Co >= 256 && !g:is_tty
    " 256-color terminals
    try
        colorscheme gruvbox
        set background=dark
    catch
        try
            colorscheme desert
        catch
            colorscheme default
        endtry
    endtry
else
    " Basic 16-color terminals (TTY, console)
    colorscheme default
    set background=dark
endif

" Set font for GUI
if has("gui_running")
    if has("gui_gtk2") || has("gui_gtk3")
        set guifont=Hack\ 12,Source\ Code\ Pro\ 12,Monospace\ 12
    elseif has("gui_win32")
        set guifont=Consolas:h11:cANSI
    endif
endif

" ============================================================================
" => Text, Tab and Indent Related
" ============================================================================

" Use spaces instead of tabs
set expandtab

" Be smart when using tabs
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

" Linebreak on 500 characters
set lbr
set tw=500

set autoindent
set smartindent

" ============================================================================
" => Key Mappings
" ============================================================================

" Set leader key to comma
let mapleader = ","

" Fast saving
nmap <leader>w :w!<cr>

" Fast quitting
nmap <leader>q :q<cr>

" Fast save and quit
nmap <leader>x :x<cr>

" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Close the current buffer (Bclose preserves window layout)
map <leader>bd :Bclose<cr>

" Close all the buffers
map <leader>ba :bufdo bd<cr>

" Next buffer
map <leader>l :bnext<cr>

" Previous buffer
map <leader>h :bprevious<cr>

" Useful mappings for managing tabs
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose<cr>
map <leader>tm :tabmove
map <leader>t<leader> :tabnext<cr>

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <Leader>tl :exe "tabn ".g:lasttab<CR>
augroup ChopstickTabHistory
    autocmd!
    autocmd TabLeave * let g:lasttab = tabpagenr()
augroup END

" Opens a new tab with the current buffer's path
map <leader>te :tabedit <C-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
map <leader>wd :cd %:p:h<cr>:pwd<cr>

" Remap VIM 0 to first non-blank character
map 0 ^

" Move a line of text using ALT+[jk] or Command+[jk] on mac
nmap <M-j> mz:m+<cr>`z
nmap <M-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z

" Pressing ,ss will toggle and untoggle spell checking
map <leader>ss :setlocal spell!<cr>

" Shortcuts using <leader>
map <leader>sn ]s
map <leader>sp [s
map <leader>sa zg
map <leader>s? z=

" Toggle paste mode
set pastetoggle=<F2>

" Toggle line numbers
nnoremap <F3> :set invnumber<CR>

" Toggle relative line numbers
nnoremap <F4> :set invrelativenumber<CR>

" Enable folding with the spacebar
nnoremap <space> za

" Y yanks to end of line (consistent with D, C)
nnoremap Y y$

" Disable accidental Ex mode
nnoremap Q <nop>

" Keep visual selection after indent
vnoremap < <gv
vnoremap > >gv

" Center cursor when jumping through search results
nnoremap n nzzzv
nnoremap N Nzzzv

" Center cursor after half-page scroll
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

" System clipboard yank (conditional: requires clipboard provider)
if has('clipboard')
    nnoremap <leader>y "+y
    vnoremap <leader>y "+y
    nnoremap <leader>Y "+Y
endif

" Quickfix list shortcuts ([q/]q from vim-unimpaired handles navigation)
nnoremap <leader>qo :copen<CR>
nnoremap <leader>qc :cclose<CR>

" Auto-equalize splits when terminal window is resized
augroup ChopstickResize
    autocmd!
    autocmd VimResized * wincmd =
augroup END

" ============================================================================
" => Plugin Settings
" ============================================================================

" --- NERDTree ---
map <C-n> :NERDTreeToggle<CR>
map <leader>n :NERDTreeFind<CR>

" Close vim if the only window left open is a NERDTree
augroup NERDTreeAutoClose
    autocmd!
    autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
augroup END

" Show hidden files
let NERDTreeShowHidden=1

" Ignore files in NERDTree
let NERDTreeIgnore=['\.pyc$', '\~$', '\.swp$', '\.git$', '\.DS_Store', 'node_modules', '__pycache__', '\.egg-info$']

" NERDTree window size
let NERDTreeWinSize=35

" Track stdin reads so startup autocmds can skip pipe/heredoc input
augroup ChopstickStdin
    autocmd!
    autocmd StdinReadPre * let s:std_in=1
augroup END

" Startup layout (non-TTY only — keeps TTY startup instant)
if !g:is_tty
    augroup ChopstickStartup
        autocmd!
        " vim <dir>  →  NERDTree on left + Startify (or blank buffer) on right
        autocmd VimEnter *
            \ if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') |
            \     exe 'NERDTree ' . fnameescape(argv()[0]) |
            \     exe 'cd ' . fnameescape(argv()[0]) |
            \     wincmd p |
            \     if exists(':Startify') == 2 | Startify | else | enew | endif |
            \ endif
        " vim (no args)  →  Startify renders first; open NERDTree alongside it
        autocmd User Startified
            \ if argc() == 0 && !exists('s:std_in') |
            \     NERDTree |
            \     wincmd p |
            \ endif
    augroup END
endif

" --- FZF ---
" Smart file search: use GFiles (respects .gitignore) inside git repos, Files elsewhere
function! s:SmartFiles() abort
    if !empty(system('git rev-parse --show-toplevel 2>/dev/null'))
        GFiles
    else
        Files
    endif
endfunction
map <C-p> :call <SID>SmartFiles()<CR>
map <leader>b :Buffers<CR>
map <leader>rg :Rg<CR>
map <leader>rt :Tags<CR>
map <leader>gF :GFiles<CR>

" FZF customization for better project search
let g:fzf_layout = { 'down': '40%' }

" Disable preview in TTY for better performance
if g:is_tty
    let g:fzf_preview_window = []
else
    let g:fzf_preview_window = ['right:50%', 'ctrl-/']
endif

" Advanced FZF commands
" Conditionally enable preview based on terminal type
if g:is_tty
    command! -bang -nargs=* Rg
      \ call fzf#vim#grep(
      \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1,
      \   <bang>0)

    command! -bang GFiles call fzf#vim#gitfiles('', <bang>0)
else
    command! -bang -nargs=* Rg
      \ call fzf#vim#grep(
      \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1,
      \   fzf#vim#with_preview(), <bang>0)

    command! -bang GFiles call fzf#vim#gitfiles('', fzf#vim#with_preview(), <bang>0)
endif


" --- Airline ---
" Disable powerline fonts in TTY for compatibility
if g:is_tty
    let g:airline_powerline_fonts = 0
    let g:airline_left_sep = ''
    let g:airline_right_sep = ''
    let g:airline#extensions#tabline#left_sep = ' '
    let g:airline#extensions#tabline#left_alt_sep = '|'
else
    let g:airline_powerline_fonts = 1
endif

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

" Set theme based on terminal capabilities
if &t_Co >= 256 && !g:is_tty
    let g:airline_theme='gruvbox'
else
    let g:airline_theme='dark'
endif

" --- GitGutter ---
let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '~'
let g:gitgutter_sign_removed = '-'
let g:gitgutter_sign_removed_first_line = '^'
let g:gitgutter_sign_modified_removed = '~'

" --- ALE (Asynchronous Lint Engine) ---
let g:ale_linters = {
\   'python':     ['flake8', 'pylint'],
\   'javascript': ['eslint'],
\   'typescript': ['eslint', 'tsserver'],
\   'go':         ['gopls', 'staticcheck'],
\   'rust':       ['cargo'],
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
\   'json':       ['prettier'],
\   'yaml':       ['prettier'],
\   'html':       ['prettier'],
\   'css':        ['prettier'],
\   'scss':       ['prettier'],
\   'less':       ['prettier'],
\   'markdown':   ['prettier'],
\   'sql':        ['sqlfluff'],
\}

" Don't fix on save if LSP is handling formatting (avoids double-format)
let g:ale_fix_on_save = !g:use_vimlsp
let g:ale_sign_error = 'X'
let g:ale_sign_warning = '!'
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_enter = 0

" --- vim-go: disable built-in LSP/gopls — CoC (coc-go) handles all Go intelligence ---
" vim-go's gopls conflicts with coc-go and causes E495 errors on startup
" (BufWinEnter afile expand fails for non-file buffers like NERDTree/Startify)
let g:go_gopls_enabled           = 0  " disable vim-go's own gopls — coc-go handles LSP
let g:go_code_completion_enabled = 0  " let CoC handle completion
" Use godef as fallback for jump-to-def when CoC unavailable; gopls+disabled = error
let g:go_def_mode               = g:use_coc ? 'gopls' : 'godef'
let g:go_info_mode              = g:use_coc ? 'gopls' : 'godef'
let g:go_fmt_autosave           = 0  " CoC/ALE handle format-on-save
let g:go_imports_autosave       = 0
let g:go_highlight_types        = 1  " keep syntax features
let g:go_highlight_fields       = 1
let g:go_highlight_functions    = 1
let g:go_highlight_function_calls = 1

" Navigate between errors: [e/]e (unimpaired style), <leader>aD for detail
nmap <silent> [e :ALENext<cr>
nmap <silent> ]e :ALEPrevious<cr>
nmap <silent> <leader>aD :ALEDetail<cr>

" --- Tagbar ---
nmap <F8> :TagbarToggle<CR>

" --- UndoTree ---
nnoremap <F5> :UndotreeToggle<CR>

" --- EasyMotion ---
let g:EasyMotion_do_mapping = 0 " Disable default mappings

" Jump to anywhere you want with minimal keystrokes
nmap s <Plug>(easymotion-overwin-f2)

" Turn on case-insensitive feature
let g:EasyMotion_smartcase = 1

" JK motions: Line motions
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)

" --- CoC (Conquer of Completion) - Full LSP via Node.js ---
if g:use_coc
    " Tab for trigger completion / navigate popup
    inoremap <silent><expr> <TAB>
          \ coc#pum#visible() ? coc#pum#next(1) :
          \ CheckBackspace() ? "\<Tab>" :
          \ coc#refresh()
    inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

    " CR to confirm selected completion item
    inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                                  \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

    function! CheckBackspace() abort
      let col = col('.') - 1
      return !col || getline('.')[col - 1]  =~# '\s'
    endfunction

    " <C-Space> to trigger completion manually
    inoremap <silent><expr> <c-space> coc#refresh()

    " Diagnostic navigation
    nmap <silent> [g <Plug>(coc-diagnostic-prev)
    nmap <silent> ]g <Plug>(coc-diagnostic-next)
    nmap <silent> <leader>ad :CocDiagnostics<CR>

    " GoTo code navigation
    nmap <silent> gd <Plug>(coc-definition)
    nmap <silent> gy <Plug>(coc-type-definition)
    nmap <silent> gi <Plug>(coc-implementation)
    nmap <silent> gr <Plug>(coc-references)

    " Hover documentation
    nnoremap <silent> K :call ShowDocumentation()<CR>
    function! ShowDocumentation()
      if CocAction('hasProvider', 'hover')
        call CocActionAsync('doHover')
      else
        call feedkeys('K', 'in')
      endif
    endfunction

    " Highlight symbol and its references on cursor hold
    augroup CocHighlight
        autocmd!
        autocmd CursorHold * silent call CocActionAsync('highlight')
    augroup END

    " Symbol renaming
    nmap <leader>rn <Plug>(coc-rename)

    " Format selected code
    xmap <leader>f  <Plug>(coc-format-selected)
    nmap <leader>f  <Plug>(coc-format-selected)

    " Code actions (cursor, file, selected range)
    nmap <leader>ca  <Plug>(coc-codeaction-cursor)
    nmap <leader>cA  <Plug>(coc-codeaction-source)
    xmap <leader>ca  <Plug>(coc-codeaction-selected)

    " Apply auto-fix for current line
    nmap <leader>qf  <Plug>(coc-fix-current)

    " Run code lens action on current line
    nmap <leader>cl  <Plug>(coc-codelens-action)

    " Workspace symbols and outline
    nnoremap <silent> <leader>ws :CocList -I symbols<CR>
    nnoremap <silent> <leader>o  :CocList outline<CR>

    " Search recently used commands
    nnoremap <silent> <leader>cc :CocList commands<CR>

    " Resume latest CoC list
    nnoremap <silent> <leader>cr :CocListResume<CR>

    " Show all diagnostics
    nnoremap <silent> <leader>cD :CocList diagnostics<CR>

    " Text object for function/class (requires language server support)
    xmap if <Plug>(coc-funcobj-i)
    omap if <Plug>(coc-funcobj-i)
    xmap af <Plug>(coc-funcobj-a)
    omap af <Plug>(coc-funcobj-a)
    xmap ic <Plug>(coc-classobj-i)
    omap ic <Plug>(coc-classobj-i)
    xmap ac <Plug>(coc-classobj-a)
    omap ac <Plug>(coc-classobj-a)

    " Scroll float windows
    if has('nvim-0.4.0') || has('patch-8.2.0750')
        nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
        nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
        inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
        inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
    endif

    " Status line integration
    set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
endif

" --- vim-lsp (Native VimScript LSP - fallback when Node.js unavailable) ---
if g:use_vimlsp
    " Auto-configure language servers via vim-lsp-settings
    let g:lsp_settings_filetype_python     = ['pylsp', 'pyright-langserver']
    let g:lsp_settings_filetype_go         = ['gopls']
    let g:lsp_settings_filetype_rust       = ['rust-analyzer']
    let g:lsp_settings_filetype_typescript = ['typescript-language-server']
    let g:lsp_settings_filetype_javascript = ['typescript-language-server']
    let g:lsp_settings_filetype_sh         = ['bash-language-server']
    let g:lsp_settings_filetype_html       = ['vscode-html-language-server']
    let g:lsp_settings_filetype_css        = ['vscode-css-language-server']
    let g:lsp_settings_filetype_scss       = ['vscode-css-language-server']
    let g:lsp_settings_filetype_json       = ['vscode-json-language-server']
    let g:lsp_settings_filetype_yaml       = ['yaml-language-server']
    let g:lsp_settings_filetype_markdown   = ['marksman']
    let g:lsp_settings_filetype_sql        = ['sqls']

    " Performance: disable virtual text diagnostics in TTY
    let g:lsp_diagnostics_virtual_text_enabled = !g:is_tty
    let g:lsp_diagnostics_highlights_enabled   = !g:is_tty
    let g:lsp_document_highlight_enabled       = !g:is_tty
    let g:lsp_signs_enabled                    = 1
    let g:lsp_diagnostics_echo_cursor          = 1
    let g:lsp_completion_documentation_enabled = 1

    " Diagnostic signs (ASCII, KISS)
    let g:lsp_signs_error         = {'text': 'X'}
    let g:lsp_signs_warning       = {'text': '!'}
    let g:lsp_signs_information   = {'text': 'i'}
    let g:lsp_signs_hint          = {'text': '>'}

    " asyncomplete manages completeopt for vim-lsp mode
    set completeopt=menuone,noinsert,noselect
    let g:asyncomplete_auto_popup = 1
    let g:asyncomplete_auto_completeopt = 1
    let g:asyncomplete_popup_delay = 200

    " Tab to navigate completion popup (mirrors CoC behavior)
    inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
    inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
    inoremap <expr> <CR>    pumvisible() ? asyncomplete#close_popup() : "\<CR>"

    " Key mappings (mirror CoC's gd/gy/gi/gr/K/<leader>rn layout)
    function! s:on_lsp_buffer_enabled() abort
        setlocal omnifunc=lsp#complete
        setlocal signcolumn=yes

        " Navigation
        nmap <buffer> gd           <plug>(lsp-definition)
        nmap <buffer> gy           <plug>(lsp-type-definition)
        nmap <buffer> gi           <plug>(lsp-implementation)
        nmap <buffer> gr           <plug>(lsp-references)
        nmap <buffer> [g           <plug>(lsp-previous-diagnostic)
        nmap <buffer> ]g           <plug>(lsp-next-diagnostic)

        " Hover documentation
        nmap <buffer> K            <plug>(lsp-hover)

        " Refactoring
        nmap <buffer> <leader>rn   <plug>(lsp-rename)
        nmap <buffer> <leader>ca   <plug>(lsp-code-action)
        nmap <buffer> <leader>f    <plug>(lsp-document-format)

        " Workspace
        nmap <buffer> <leader>ws   <plug>(lsp-workspace-symbol-search)
        nmap <buffer> <leader>o    <plug>(lsp-document-symbol-search)
        nmap <buffer> <leader>cD   <plug>(lsp-document-diagnostics)

        " Enable auto-format on save for filetypes with reliable LSP formatters
        if index(['python', 'go', 'rust', 'typescript', 'javascript', 'sh'], &filetype) >= 0
            autocmd BufWritePre <buffer> LspDocumentFormatSync
        endif
    endfunction

    augroup lsp_install
        autocmd!
        autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
    augroup END
endif

" ============================================================================
" => Helper Functions
" ============================================================================

" Returns true if paste mode is enabled
function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    endif
    return ''
endfunction

" Don't close window, when deleting a buffer
command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
    let l:currentBufNum = bufnr("%")
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
        execute("bdelete! ".l:currentBufNum)
    endif
endfunction

" Delete trailing white space on save
fun! CleanExtraSpaces()
    let save_cursor = getpos(".")
    let old_query = getreg('/')
    silent! %s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfun

augroup ChopstickCleanup
    autocmd!
    " Run for real files only; skip special buffers (NERDTree, Startify, terminal, etc.)
    autocmd BufWritePre * if empty(&buftype) && !empty(expand('<afile>')) | call CleanExtraSpaces() | endif
augroup END

" ============================================================================
" => Auto Commands
" ============================================================================

augroup ChopstickFiletype
    autocmd!
    " Return to last edit position when opening files
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

    " Set specific file types
    autocmd BufNewFile,BufRead *.json setlocal filetype=json
    autocmd BufNewFile,BufRead *.md setlocal filetype=markdown
    autocmd BufNewFile,BufRead *.jsx setlocal filetype=javascript.jsx
    autocmd BufNewFile,BufRead *.tsx setlocal filetype=typescript.tsx

    " Python specific settings
    autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=4 colorcolumn=88

    " JavaScript specific settings
    autocmd FileType javascript,typescript setlocal expandtab shiftwidth=2 tabstop=2

    " Go specific settings
    autocmd FileType go setlocal noexpandtab shiftwidth=4 tabstop=4

    " HTML/CSS specific settings
    autocmd FileType html,css setlocal expandtab shiftwidth=2 tabstop=2

    " YAML specific settings
    autocmd FileType yaml setlocal expandtab shiftwidth=2 tabstop=2

    " Markdown specific settings
    autocmd FileType markdown setlocal wrap linebreak spell tw=0

    " Shell script settings
    autocmd FileType sh setlocal expandtab shiftwidth=2 tabstop=2

    " Makefile settings (must use tabs)
    autocmd FileType make setlocal noexpandtab shiftwidth=8 tabstop=8

    " JSON specific settings
    autocmd FileType json setlocal expandtab shiftwidth=2 tabstop=2

    " Docker specific settings
    autocmd BufNewFile,BufRead Dockerfile* setlocal filetype=dockerfile
    autocmd FileType dockerfile setlocal expandtab shiftwidth=2 tabstop=2
augroup END

" ============================================================================
" => Status Line
" ============================================================================

" Always show the status line
set laststatus=2

" Format the status line (if not using airline)
" set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c

" ============================================================================
" => Misc
" ============================================================================

" Quickly open a markdown buffer for scribble
map <leader>m :e ~/buffer.md<cr>

" Toggle between number and relativenumber
function! ToggleNumber()
    if(&relativenumber == 1)
        set norelativenumber
        set number
    else
        set relativenumber
    endif
endfunc

" Toggle paste mode
map <leader>pp :setlocal paste!<cr>

" ============================================================================
" => Performance Optimization
" ============================================================================

" Optimize for large files
set synmaxcol=200
set ttyfast

" Reduce updatetime for better user experience
set updatetime=300

" Don't pass messages to |ins-completion-menu|
set shortmess+=c

" Always show the signcolumn (simplified for TTY)
if g:is_tty
    " In TTY, only show signcolumn when there are signs
    set signcolumn=auto
else
    if has("patch-8.1.1564")
        set signcolumn=number
    else
        set signcolumn=yes
    endif
endif

" ============================================================================
" => Project-Specific Settings
" ============================================================================

" Load project-specific vimrc if it exists
" This allows per-project customization
set exrc
set secure

" ============================================================================
" => Additional Engineering Utilities
" ============================================================================

" Quick format entire file
nnoremap <leader>F gg=G``

" Quick save all buffers
nnoremap <leader>wa :wa<CR>

" Easier window resizing
nnoremap <silent> <Leader>= :exe "resize " . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize " . (winheight(0) * 2/3)<CR>
nnoremap <silent> <Leader>+ :exe "vertical resize " . (winwidth(0) * 3/2)<CR>
nnoremap <silent> <Leader>_ :exe "vertical resize " . (winwidth(0) * 2/3)<CR>

" Quick switch between last two files
nnoremap <leader><leader> <c-^>

" Clear whitespace on empty lines
nnoremap <leader>W :%s/\s\+$//<CR>:let @/=''<CR>

" Source current file
nnoremap <leader>so :source %<CR>

" Edit vimrc quickly
nnoremap <leader>ev :edit $MYVIMRC<CR>

" Reload vimrc
nnoremap <leader>sv :source $MYVIMRC<CR>

" Search and replace word under cursor
nnoremap <leader>* :%s/\<<C-r><C-w>\>//g<Left><Left>

" Copy file path to clipboard
nnoremap <leader>cp :let @+ = expand("%:p")<CR>:echo "Copied path: " . expand("%:p")<CR>
nnoremap <leader>cf :let @+ = expand("%:t")<CR>:echo "Copied filename: " . expand("%:t")<CR>

" Create parent directories on save if they don't exist
function! s:MkNonExDir(file, buf)
    if empty(getbufvar(a:buf, '&buftype')) && a:file!~#'\v^\w+\:\/'
        let dir=fnamemodify(a:file, ':h')
        if !isdirectory(dir)
            call mkdir(dir, 'p')
        endif
    endif
endfunction
augroup BWCCreateDir
    autocmd!
    " Guard: <afile> is empty for special buffers (NERDTree, Startify, etc.)
    autocmd BufWritePre * if !empty(expand('<afile>')) | call s:MkNonExDir(expand('<afile>'), +expand('<abuf>')) | endif
augroup END

" ============================================================================
" => Debugging Helpers
" ============================================================================

" Show syntax highlighting groups for word under cursor
nmap <leader>sh :call <SID>SynStack()<CR>
function! <SID>SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

" ============================================================================
" => Git Workflow Enhancements
" ============================================================================

" Git shortcuts
nnoremap <leader>gs :Git status<CR>
nnoremap <leader>gc :Git commit<CR>
nnoremap <leader>gp :Git push<CR>
nnoremap <leader>gl :Git pull<CR>
nnoremap <leader>gd :Gdiff<CR>
nnoremap <leader>gb :Git blame<CR>

" ============================================================================
" => Terminal Integration
" ============================================================================

" Better terminal navigation
if has('terminal')
    " Open terminal in split
    nnoremap <leader>tv :terminal<CR>
    nnoremap <leader>th :terminal ++rows=10<CR>

    " Terminal mode mappings
    " Double-Esc to exit terminal mode (single Esc passes through to the running program)
    tnoremap <Esc><Esc> <C-\><C-n>
    tnoremap <C-h> <C-\><C-n><C-w>h
    tnoremap <C-j> <C-\><C-n><C-w>j
    tnoremap <C-k> <C-\><C-n><C-w>k
    tnoremap <C-l> <C-\><C-n><C-w>l
endif

" ============================================================================
" => Large File Handling
" ============================================================================

" Disable syntax highlighting and other features for large files (>10MB)
let g:LargeFile = 1024 * 1024 * 10
augroup LargeFile
    autocmd!
    " Guard: <afile> is empty for special buffers
    autocmd BufReadPre * if !empty(expand('<afile>')) | let f=getfsize(expand('<afile>')) | if f > g:LargeFile || f == -2 | call LargeFileSettings() | endif | endif
augroup END

function! LargeFileSettings()
    setlocal bufhidden=unload
    setlocal undolevels=-1
    setlocal eventignore+=FileType
    setlocal noswapfile
    setlocal syntax=OFF
    echo "Large file (>10MB): syntax and undo disabled for performance."
endfunction

" ============================================================================
" => TTY and Basic Terminal Optimizations
" ============================================================================

" Additional optimizations for TTY/basic terminals
if g:is_tty
    " Disable syntax highlighting for very large files in TTY
    augroup ChopstickTTYLargeFile
        autocmd!
        autocmd BufReadPre * if !empty(expand('<afile>')) && getfsize(expand('<afile>')) > 512000 | setlocal syntax=OFF | endif
    augroup END

    " Simpler status line for TTY
    set statusline=%f\ %h%w%m%r\ %=%(%l,%c%V\ %=\ %P%)

    " Reduce syntax highlighting complexity in TTY (global is 200, lower here)
    set synmaxcol=120

    " lazyredraw is safe in TTY; avoid globally as it causes CoC float flicker
    set lazyredraw
endif

" Provide helpful message on first run in TTY
if g:is_tty && !exists("g:tty_message_shown")
    augroup TTYMessage
        autocmd!
        autocmd VimEnter * echom "Running in TTY mode - some features disabled for performance"
    augroup END
    let g:tty_message_shown = 1
endif

" ============================================================================
" => Which-Key: Keybinding Hints
" ============================================================================

" Show available bindings after <leader> with a 500ms pause
set timeoutlen=500

if exists('g:plugs["vim-which-key"]')
    " Register after plugins are loaded (autoload functions available at VimEnter)
    augroup ChopstickWhichKey
        autocmd!
        autocmd VimEnter * call which_key#register(',', 'g:which_key_map')
    augroup END

    nnoremap <silent> <leader> :<C-u>WhichKey ','<CR>
    vnoremap <silent> <leader> :<C-u>WhichKeyVisual ','<CR>

    " Top-level single-key bindings (w and q also have sub-groups below)
    let g:which_key_map = {}
    let g:which_key_map['x']  = 'save-and-quit'
    let g:which_key_map['F']  = 'format-file'
    let g:which_key_map['W']  = 'strip-trailing-whitespace'
    let g:which_key_map['m']  = 'scratch-markdown'
    let g:which_key_map['n']  = 'nerdtree-find'
    let g:which_key_map['o']  = 'outline'
    let g:which_key_map['b']  = 'buffers'
    let g:which_key_map['h']  = 'prev-buffer'
    let g:which_key_map['l']  = 'next-buffer'
    let g:which_key_map['*']  = 'search-replace-word'
    let g:which_key_map[',']  = 'last-file'
    let g:which_key_map['y']  = 'clipboard-yank'
    let g:which_key_map['Y']  = 'clipboard-yank-line'

    " [a]LE lint group  ([e/]e navigate; <leader>aD for detail; <leader>ad for diagnostics)
    let g:which_key_map['a'] = {
        \ 'name': '+ale-lint',
        \ 'D': 'ale-detail',
        \ 'd': 'diagnostics',
        \ }

    " [c]ode / [c]opy group
    let g:which_key_map['c'] = {
        \ 'name': '+code/copy',
        \ 'a': 'code-action-cursor',
        \ 'A': 'code-action-source',
        \ 'c': 'coc-commands',
        \ 'D': 'diagnostics-list',
        \ 'l': 'code-lens',
        \ 'r': 'coc-list-resume',
        \ 'p': 'copy-filepath',
        \ 'f': 'copy-filename',
        \ }

    " [e]dit group
    let g:which_key_map['e'] = {
        \ 'name': '+edit',
        \ 'v': 'edit-vimrc',
        \ }

    " [g]it group
    let g:which_key_map['g'] = {
        \ 'name': '+git',
        \ 's': 'status',
        \ 'c': 'commit',
        \ 'p': 'push',
        \ 'l': 'pull',
        \ 'd': 'diff',
        \ 'b': 'blame',
        \ 'F': 'git-files-fzf',
        \ }

    " [q]uickfix group  (also: <leader>q = fast quit)
    let g:which_key_map['q'] = {
        \ 'name': '+quickfix',
        \ 'f': 'lsp-fix-current',
        \ 'o': 'open-quickfix',
        \ 'c': 'close-quickfix',
        \ }

    " [r]efactor / [r]ipgrep / [r]eplace group
    let g:which_key_map['r'] = {
        \ 'name': '+search/refactor',
        \ 'n': 'rename',
        \ 'g': 'ripgrep',
        \ 't': 'tags-search',
        \ }

    " [s]pell / [s]ource group
    let g:which_key_map['s'] = {
        \ 'name': '+spell/source',
        \ 's': 'toggle-spell',
        \ 'n': 'next-spell',
        \ 'p': 'prev-spell',
        \ 'a': 'add-word',
        \ '?': 'suggest',
        \ 'v': 'source-vimrc',
        \ 'o': 'source-file',
        \ 'h': 'syntax-highlight-stack',
        \ }

    " [t]ab / [t]erminal group
    let g:which_key_map['t'] = {
        \ 'name': '+tab/terminal',
        \ 'n': 'new-tab',
        \ 'o': 'tab-only',
        \ 'c': 'close-tab',
        \ 'm': 'move-tab',
        \ 'l': 'last-tab',
        \ 'e': 'edit-in-tab',
        \ 'v': 'terminal-vertical',
        \ 'h': 'terminal-horizontal',
        \ }

    " [w]orkspace / [w]indow / save group  (also: <leader>w = fast save)
    let g:which_key_map['w'] = {
        \ 'name': '+save/window',
        \ 'a': 'save-all',
        \ 's': 'workspace-symbols',
        \ 'd': 'change-dir',
        \ }
endif

" ============================================================================
" => Startify: Startup Screen
" ============================================================================

if exists('g:plugs["vim-startify"]')
    " Dynamic header: config name, vim version, current dir, git branch, key tips
    function! StartifyHeader() abort
        let l:ver = 'Vim ' . (v:version / 100) . '.' . printf('%02d', v:version % 100)
        let l:cwd = fnamemodify(getcwd(), ':t')
        let l:git = ''
        if executable('git')
            let l:branch = system('git -C ' . shellescape(getcwd()) .
                \ ' rev-parse --abbrev-ref HEAD 2>/dev/null')
            if v:shell_error == 0
                let l:git = '  [' . substitute(l:branch, '\n\+$', '', '') . ']'
            endif
        endif
        return [
            \ '  chopsticks  |  ' . l:ver . '  |  ' . l:cwd . l:git,
            \ '  , = leader  |  , + pause = key hints  |  Ctrl-p = files  |  ,rg = search',
            \ '',
            \ ]
    endfunction
    let g:startify_custom_header = 'StartifyHeader()'

    " Sessions first: restores full project state; dir + recent files below
    let g:startify_lists = [
        \ { 'type': 'sessions',  'header': ['   Sessions']                    },
        \ { 'type': 'dir',       'header': ['   Directory: ' . getcwd()]      },
        \ { 'type': 'files',     'header': ['   Recent Files']                },
        \ { 'type': 'bookmarks', 'header': ['   Bookmarks']                   },
        \ ]

    " Quick-access bookmarks for common config files
    let g:startify_bookmarks = [
        \ {'v': '~/.vimrc'},
        \ {'z': '~/.zshrc'},
        \ {'b': '~/.bashrc'},
        \ ]

    " Session integration
    let g:startify_session_persistence    = 1   " Auto-save session on quit
    let g:startify_session_autoload       = 1   " Auto-load Session.vim if present
    let g:startify_change_to_vcs_root     = 1   " cd to git root on open
    let g:startify_fortune_use_unicode    = 0   " ASCII only (KISS)
    let g:startify_enable_special         = 0   " Hide <empty> / <quit> clutter

    " Limit recent files shown
    let g:startify_files_number = 10

    " Required for NERDTree compatibility (prevents buftype conflicts)
    augroup ChopstickStartify
        autocmd!
        autocmd User Startified setlocal buftype=
    augroup END
endif

" ============================================================================
" => IndentLine: Indent Guide Lines (non-TTY only)
" ============================================================================

if !g:is_tty && exists('g:plugs["indentLine"]')
    " Use simple ASCII bar as indent guide
    let g:indentLine_char            = '|'
    let g:indentLine_first_char      = '|'
    let g:indentLine_showFirstIndentLevel = 1

    " Disable in certain filetypes where it causes issues
    let g:indentLine_fileTypeExclude = ['text', 'help', 'startify', 'nerdtree', 'markdown']
    let g:indentLine_bufTypeExclude  = ['help', 'terminal', 'nofile']

    " Conceal level settings (prevent hiding quotes in JSON/markdown)
    let g:indentLine_setConceal      = 2
    let g:indentLine_concealcursor   = ''
endif

" ============================================================================
" End of Configuration
" ============================================================================
