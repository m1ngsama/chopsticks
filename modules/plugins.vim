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
Plug 'tpope/vim-sleuth'
Plug 'wellle/targets.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'easymotion/vim-easymotion', { 'on': '<Plug>(easymotion' }

" ── Linting & Formatting ────────────────────────────────────────────────────
Plug 'dense-analysis/ale'

" ── LSP + Completion ─────────────────────────────────────────────────────────
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" ── Language Syntax ──────────────────────────────────────────────────────────
Plug 'pangloss/vim-javascript', { 'for': ['javascript', 'javascript.jsx'] }
Plug 'HerringtonDarkholme/yats.vim', { 'for': ['typescript', 'typescript.tsx'] }
Plug 'preservim/vim-markdown', { 'for': 'markdown' }
Plug 'previm/previm', { 'on': 'PrevimOpen' }
Plug 'fatih/vim-go', { 'for': 'go' }

" ── UI ───────────────────────────────────────────────────────────────────────
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }
Plug 'mhinz/vim-startify'
Plug 'lifepillar/vim-solarized8'
if !empty($TMUX)
    Plug 'christoomey/vim-tmux-navigator'
endif

call plug#end()
