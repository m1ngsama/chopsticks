" ============================================================================
" Vim Configuration - The Ultimate vimrc
" Inspired by the best practices from the Vim community
" ============================================================================

" ============================================================================
" => General Settings
" ============================================================================

" Disable compatibility with vi which can cause unexpected issues
set nocompatible

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

" Highlight cursor line underneath the cursor horizontally
set cursorline

" Set shift width to 4 spaces
set shiftwidth=4

" Set tab width to 4 columns
set tabstop=4

" Use space characters instead of tabs
set expandtab

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

" Show matching words during a search
set showmatch

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

" Better command-line completion
set wildmenu

" Show cursor position
set ruler

" Display line numbers
set number

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

" Turn on the Wild menu for command completion
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

" Always show current position
set ruler

" Height of the command bar
set cmdheight=1

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch

" How many tenths of a second to blink when matching brackets
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

" Turn backup off, since most stuff is in SVN, git etc. anyway
set nobackup
set nowb
set noswapfile

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
Plug 'ctrlpvim/ctrlp.vim'                    " Fuzzy file finder

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
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }  " Go support

" ===== Color Schemes =====
Plug 'morhetz/gruvbox'                       " Gruvbox theme
Plug 'dracula/vim', { 'as': 'dracula' }      " Dracula theme
Plug 'altercation/vim-colors-solarized'      " Solarized theme
Plug 'joshdick/onedark.vim'                  " One Dark theme

" ===== Productivity =====
Plug 'mbbill/undotree'                       " Undo history visualizer
Plug 'preservim/tagbar'                      " Tag browser
Plug 'easymotion/vim-easymotion'             " Easy motion

" ===== Code Intelligence =====
if has('vim9') || has('nvim')
    Plug 'neoclide/coc.nvim', {'branch': 'release'}  " LSP & Completion
endif

" ===== Session Management =====
Plug 'tpope/vim-obsession'                   " Continuous session save
Plug 'dhruvasagar/vim-prosession'            " Better session management

" ===== Additional Utilities =====
Plug 'tpope/vim-unimpaired'                  " Handy bracket mappings
Plug 'wellle/targets.vim'                    " Additional text objects
Plug 'honza/vim-snippets'                    " Snippet collection

call plug#end()

" ============================================================================
" => Colors and Fonts
" ============================================================================

" Enable true colors support
if has('termguicolors')
    set termguicolors
endif

" Set colorscheme
try
    colorscheme gruvbox
    set background=dark
catch
    colorscheme desert
endtry

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

set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines

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

" Close the current buffer
map <leader>bd :Bclose<cr>:tabclose<cr>gT

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
au TabLeave * let g:lasttab = tabpagenr()

" Opens a new tab with the current buffer's path
map <leader>te :tabedit <C-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>

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

" Remove trailing whitespace
nnoremap <leader>w :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" Toggle paste mode
set pastetoggle=<F2>

" Toggle line numbers
nnoremap <F3> :set invnumber<CR>

" Toggle relative line numbers
nnoremap <F4> :set invrelativenumber<CR>

" Enable folding with the spacebar
nnoremap <space> za

" ============================================================================
" => Plugin Settings
" ============================================================================

" --- NERDTree ---
map <C-n> :NERDTreeToggle<CR>
map <leader>n :NERDTreeFind<CR>

" Close vim if the only window left open is a NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Show hidden files
let NERDTreeShowHidden=1

" Ignore files in NERDTree
let NERDTreeIgnore=['\.pyc$', '\~$', '\.swp$', '\.git$', '\.DS_Store', 'node_modules', '__pycache__', '\.egg-info$']

" NERDTree window size
let NERDTreeWinSize=35

" Automatically open NERDTree when vim starts on a directory
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif

" --- FZF ---
map <C-p> :Files<CR>
map <leader>b :Buffers<CR>
map <leader>rg :Rg<CR>
map <leader>t :Tags<CR>

" FZF customization for better project search
let g:fzf_layout = { 'down': '40%' }
let g:fzf_preview_window = ['right:50%', 'ctrl-/']

" Advanced FZF commands
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1,
  \   fzf#vim#with_preview(), <bang>0)

" Search in git files
command! -bang GFiles call fzf#vim#gitfiles('', fzf#vim#with_preview(), <bang>0)

" --- CtrlP ---
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_show_hidden = 1
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(git|hg|svn)$',
  \ 'file': '\v\.(exe|so|dll|pyc)$',
  \ }

" --- Airline ---
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline_powerline_fonts = 1
let g:airline_theme='gruvbox'

" --- GitGutter ---
let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '~'
let g:gitgutter_sign_removed = '-'
let g:gitgutter_sign_removed_first_line = '^'
let g:gitgutter_sign_modified_removed = '~'

" --- ALE (Asynchronous Lint Engine) ---
let g:ale_linters = {
\   'python': ['flake8', 'pylint'],
\   'javascript': ['eslint'],
\   'typescript': ['eslint', 'tsserver'],
\   'go': ['gopls', 'golint'],
\   'rust': ['cargo'],
\   'sh': ['shellcheck'],
\   'yaml': ['yamllint'],
\   'dockerfile': ['hadolint'],
\}

let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'python': ['black', 'isort'],
\   'javascript': ['prettier', 'eslint'],
\   'typescript': ['prettier', 'eslint'],
\   'go': ['gofmt', 'goimports'],
\   'rust': ['rustfmt'],
\   'json': ['prettier'],
\   'yaml': ['prettier'],
\   'html': ['prettier'],
\   'css': ['prettier'],
\   'markdown': ['prettier'],
\}

let g:ale_fix_on_save = 1
let g:ale_sign_error = 'X'
let g:ale_sign_warning = '!'
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_enter = 0

" Navigate between errors
nmap <silent> <leader>aj :ALENext<cr>
nmap <silent> <leader>ak :ALEPrevious<cr>
nmap <silent> <leader>ad :ALEDetail<cr>

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

" --- CoC (Conquer of Completion) ---
if exists('g:plugs["coc.nvim"]')
    " Use tab for trigger completion with characters ahead and navigate
    inoremap <silent><expr> <TAB>
          \ coc#pum#visible() ? coc#pum#next(1) :
          \ CheckBackspace() ? "\<Tab>" :
          \ coc#refresh()
    inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

    " Make <CR> to accept selected completion item
    inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                                  \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

    function! CheckBackspace() abort
      let col = col('.') - 1
      return !col || getline('.')[col - 1]  =~# '\s'
    endfunction

    " Use <c-space> to trigger completion
    inoremap <silent><expr> <c-space> coc#refresh()

    " Use `[g` and `]g` to navigate diagnostics
    nmap <silent> [g <Plug>(coc-diagnostic-prev)
    nmap <silent> ]g <Plug>(coc-diagnostic-next)

    " GoTo code navigation
    nmap <silent> gd <Plug>(coc-definition)
    nmap <silent> gy <Plug>(coc-type-definition)
    nmap <silent> gi <Plug>(coc-implementation)
    nmap <silent> gr <Plug>(coc-references)

    " Use K to show documentation in preview window
    nnoremap <silent> K :call ShowDocumentation()<CR>

    function! ShowDocumentation()
      if CocAction('hasProvider', 'hover')
        call CocActionAsync('doHover')
      else
        call feedkeys('K', 'in')
      endif
    endfunction

    " Highlight the symbol and its references when holding the cursor
    autocmd CursorHold * silent call CocActionAsync('highlight')

    " Symbol renaming
    nmap <leader>rn <Plug>(coc-rename)

    " Formatting selected code
    xmap <leader>f  <Plug>(coc-format-selected)
    nmap <leader>f  <Plug>(coc-format-selected)
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

if has("autocmd")
    autocmd BufWritePre *.txt,*.js,*.py,*.wiki,*.sh,*.coffee :call CleanExtraSpaces()
endif

" ============================================================================
" => Auto Commands
" ============================================================================

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
autocmd FileType markdown setlocal wrap linebreak spell

" Shell script settings
autocmd FileType sh setlocal expandtab shiftwidth=2 tabstop=2

" Makefile settings (must use tabs)
autocmd FileType make setlocal noexpandtab shiftwidth=8 tabstop=8

" JSON specific settings
autocmd FileType json setlocal expandtab shiftwidth=2 tabstop=2

" Docker specific settings
autocmd BufNewFile,BufRead Dockerfile* setlocal filetype=dockerfile
autocmd FileType dockerfile setlocal expandtab shiftwidth=2 tabstop=2

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

" Quickly open a buffer for scribble
map <leader>q :e ~/buffer<cr>

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

" Always show the signcolumn
if has("patch-8.1.1564")
  set signcolumn=number
else
  set signcolumn=yes
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

" Toggle between source and header files (for C/C++)
nnoremap <leader>a :A<CR>

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
    autocmd BufWritePre * :call s:MkNonExDir(expand('<afile>'), +expand('<abuf>'))
augroup END

" ============================================================================
" => Debugging Helpers
" ============================================================================

" Show syntax highlighting groups for word under cursor
nmap <leader>sp :call <SID>SynStack()<CR>
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
    tnoremap <Esc> <C-\><C-n>
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
    autocmd BufReadPre * let f=getfsize(expand("<afile>")) | if f > g:LargeFile || f == -2 | call LargeFileSettings() | endif
augroup END

function! LargeFileSettings()
    setlocal bufhidden=unload
    setlocal undolevels=-1
    setlocal eventignore+=FileType
    setlocal noswapfile
    setlocal buftype=nowrite
    echo "Large file detected. Some features disabled for performance."
endfunction

" ============================================================================
" End of Configuration
" ============================================================================
