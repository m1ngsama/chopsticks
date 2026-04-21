" plugins.vim — vim-plug declarations

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

" ── Navigation & Search ──────────────────────────────────────────────────────
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" ── Git ──────────────────────────────────────────────────────────────────────
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" ── Editing ──────────────────────────────────────────────────────────────────
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'
" tpope/vim-unimpaired removed: 2.5ms startup cost, we define our own
" [q/]q (quickfix), [e/]e (ALE), [x/]x (conflict) — unimpaired's [b/]b
" is covered by ,h/,l. Blank line insertion ([<Space>) added below.

Plug 'tpope/vim-sleuth'
Plug 'wellle/targets.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'easymotion/vim-easymotion', { 'on': '<Plug>(easymotion' }

" ── Linting & Formatting ────────────────────────────────────────────────────
Plug 'dense-analysis/ale'

" ── LSP + Completion (no Node.js required) ──────────────────────────────────
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" ── Language Syntax ──────────────────────────────────────────────────────────
Plug 'pangloss/vim-javascript', { 'for': ['javascript', 'javascript.jsx'] }
Plug 'HerringtonDarkholme/yats.vim', { 'for': ['typescript', 'typescript.tsx'] }
Plug 'preservim/vim-markdown', { 'for': 'markdown' }
Plug 'fatih/vim-go', { 'for': 'go' }

" ── Markdown Preview & Writing ───────────────────────────────────────────────
Plug 'previm/previm', { 'on': 'PrevimOpen' }
Plug 'junegunn/goyo.vim', { 'on': 'Goyo' }
Plug 'junegunn/limelight.vim', { 'on': ['Limelight', 'Limelight!'] }

" ── UI ───────────────────────────────────────────────────────────────────────
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }
Plug 'mhinz/vim-startify'
Plug 'lifepillar/vim-solarized8'
if !g:is_tty
    Plug 'Yggdroot/indentLine'
endif

" ── Session & Navigation ────────────────────────────────────────────────────
Plug 'tpope/vim-obsession'
Plug 'christoomey/vim-tmux-navigator'

call plug#end()
