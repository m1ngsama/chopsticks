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
set writebackup

if has('unix')
    let s:swap_dir = expand(get(g:, 'chopsticks_swap_dir', '~/.vim/.swap'))
    let &directory = s:swap_dir . '//,/tmp//'
    silent! call mkdir(s:swap_dir, 'p', 0700)
endif
set swapfile

if has('persistent_undo')
    set undofile
    let &undodir = expand('~/.vim/.undo')
    silent! call mkdir(&undodir, 'p', 0700)
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

let mapleader = ","

" ── Basic Keymaps ───────────────────────────────────────────────────────────

nnoremap <leader>w :w<cr>
nnoremap <leader>q :q<cr>
nnoremap <leader>x :x<cr>

nnoremap <silent> <leader><cr> :noh<cr>

nnoremap <leader>bd :Bclose<cr>
nnoremap <leader>ba :bufdo bd<cr>
nnoremap <leader>l  :bnext<cr>
nnoremap <leader>h  :bprevious<cr>

nnoremap <leader>cd :lcd %:p:h<cr>:pwd<cr>

nnoremap gV `[v`]

cnoremap <C-p> <Up>
cnoremap <C-n> <Down>

nnoremap <M-j> :m .+1<CR>==
nnoremap <M-k> :m .-2<CR>==
vnoremap <M-j> :m '>+1<CR>gv=gv
vnoremap <M-k> :m '<-2<CR>gv=gv

nnoremap <silent> <leader>ss :setlocal spell!<CR>:echo 'Spell: ' . (&spell ? 'ON' : 'OFF')<CR>

nnoremap <silent> <F2> :set paste!<CR>:echo 'Paste: ' . (&paste ? 'ON' : 'OFF')<CR>
nnoremap <silent> <F3> :set invnumber<CR>:echo 'Line numbers: ' . (&number ? 'ON' : 'OFF')<CR>
nnoremap <silent> <F4> :set invrelativenumber<CR>:echo 'Relative numbers: ' . (&relativenumber ? 'ON' : 'OFF')<CR>
nnoremap <silent> <F6> :set list!<CR>:echo 'List chars: ' . (&list ? 'ON' : 'OFF')<CR>

nnoremap <space> za

nnoremap Q <nop>

inoremap jk <Esc>

vnoremap < <gv
vnoremap > >gv

nnoremap n nzzzv
nnoremap N Nzzzv

vnoremap // y/\V<C-r>=escape(@",'/\')<CR><CR>

nnoremap <silent> <C-s> :w<CR>
inoremap <silent> <C-s> <C-o>:w<CR>

nnoremap <C-d> <C-d>zz
vnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
vnoremap <C-u> <C-u>zz

if has('clipboard')
    nnoremap <leader>y "+y
    vnoremap <leader>y "+y
    nnoremap <leader>Y "+Y
    nnoremap <leader>p "+p
    vnoremap <leader>p "+p
    nnoremap <leader>P "+P
    vnoremap <leader>P "+P
endif

nnoremap <leader>qo :copen<CR>
nnoremap <leader>qc :cclose<CR>

augroup ChopstickResize
    autocmd!
    autocmd VimResized * wincmd =
augroup END

" ── Performance ─────────────────────────────────────────────────────────────

set synmaxcol=200
set lazyredraw
set complete-=i

if executable('rg')
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

set exrc
set secure
set sessionoptions=blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal

if has("patch-8.1.0360")
    set diffopt=filler,internal,context:3,algorithm:histogram,indent-heuristic
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
