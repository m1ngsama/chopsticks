#!/usr/bin/env bash
# Install and verify the pinned Vim plugin set used by CI smoke tests.

set -euo pipefail

vim -i NONE -es -u .vimrc -N -c 'PlugInstall --sync' -c 'qa!' 2>&1

required_plugins=(
    fzf
    fzf.vim
    vim-fugitive
    vim-gitgutter
    ale
    vim-lsp
    vim-lsp-settings
    asyncomplete.vim
    asyncomplete-lsp.vim
    vim-markdown
)

for plugin in "${required_plugins[@]}"
do
    if [ ! -d "$HOME/.vim/plugged/$plugin" ]; then
        printf 'FAIL: missing plugin %s\n' "$plugin" >&2
        exit 1
    fi
done
