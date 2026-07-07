#!/usr/bin/env bash
# Install and verify the pinned Vim plugin set used by release smoke tests.

set -euo pipefail

TMUX=/tmp/chopsticks-ci vim \
    --cmd 'let g:chopsticks_enable_auto_pairs = 1' \
    --cmd 'let g:chopsticks_enable_tmux_navigator = 1' \
    -i NONE -es -u .vimrc -N \
    -c 'PlugInstall --sync' \
    -c 'qa!' 2>&1

required_plugins=(
    ale
    asyncomplete-lsp.vim
    asyncomplete.vim
    auto-pairs
    fzf
    fzf.vim
    previm
    targets.vim
    undotree
    vim-commentary
    vim-easymotion
    vim-fugitive
    vim-gitgutter
    vim-go
    vim-javascript
    vim-lsp
    vim-lsp-settings
    vim-markdown
    vim-repeat
    vim-sleuth
    vim-solarized8
    vim-startify
    vim-surround
    vim-tmux-navigator
    yats.vim
)

for plugin in "${required_plugins[@]}"
do
    if [ ! -d "$HOME/.vim/plugged/$plugin" ]; then
        printf 'FAIL: missing plugin %s\n' "$plugin" >&2
        exit 1
    fi
done
