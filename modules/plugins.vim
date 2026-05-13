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
Plug 'easymotion/vim-easymotion', { 'on': '<Plug>(easymotion' }

if g:chopsticks_enable_auto_pairs
    Plug 'jiangmiao/auto-pairs'
endif

if g:chopsticks_enable_lint
    " ── Linting & Formatting ────────────────────────────────────────────────
    Plug 'dense-analysis/ale'
endif

if g:chopsticks_enable_lsp
    " ── LSP + Completion ─────────────────────────────────────────────────────
    Plug 'prabirshrestha/vim-lsp'
    Plug 'mattn/vim-lsp-settings'
    Plug 'prabirshrestha/asyncomplete.vim'
    Plug 'prabirshrestha/asyncomplete-lsp.vim'
endif

" ── Language Syntax ──────────────────────────────────────────────────────────
Plug 'preservim/vim-markdown', { 'for': 'markdown' }
if g:chopsticks_enable_markdown_preview
    Plug 'previm/previm', { 'on': 'PrevimOpen' }
endif
if g:chopsticks_enable_extra_languages
    Plug 'pangloss/vim-javascript', { 'for': ['javascript', 'javascript.jsx'] }
    Plug 'HerringtonDarkholme/yats.vim', { 'for': ['typescript', 'typescript.tsx'] }
    Plug 'fatih/vim-go', { 'for': 'go' }
endif

" ── UI ───────────────────────────────────────────────────────────────────────
if g:chopsticks_enable_ui_extras
    Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }
    Plug 'mhinz/vim-startify'
endif
Plug 'lifepillar/vim-solarized8'
if !empty($TMUX)
    Plug 'christoomey/vim-tmux-navigator'
endif

call plug#end()
