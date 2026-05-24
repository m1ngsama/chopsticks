#!/usr/bin/env bash
# Vim smoke tests. Requires plugins in ~/.vim/plugged.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/test-common.sh
source "$SCRIPT_DIR/test-common.sh"

check_plugin_dirs() {
    step "Plugin directories"
    for plugin in \
        fzf fzf.vim vim-fugitive vim-gitgutter ale vim-lsp vim-lsp-settings \
        asyncomplete.vim asyncomplete-lsp.vim vim-markdown
    do
        test -d "$HOME/.vim/plugged/$plugin" || {
            echo "Missing plugin directory: $plugin" >&2
            exit 1
        }
    done
}

check_vim() {
    step "Vim smoke tests"
    need vim
    check_plugin_dirs

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -c 'qa!' 2>&1
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N -c 'qa!' 2>&1
    if [ -x /usr/bin/vim ] && [ "$(command -v vim)" != "/usr/bin/vim" ]; then
        XDG_CONFIG_HOME="$EMPTY_XDG" /usr/bin/vim -u .vimrc -i NONE -es -N -c 'qa!' 2>&1
    fi

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c "redir! > $TMP_ROOT/plugs.txt" \
        -c 'silent echo len(g:plugs)' \
        -c 'redir END' \
        -c 'qa!' 2>/dev/null
    PLUGS="$(tr -d '[:space:]' < "$TMP_ROOT/plugs.txt")"
    echo "Plugins registered: $PLUGS"
    if [ "$PLUGS" -lt 20 ]; then
        echo "Expected 20+ plugins, got $PLUGS" >&2
        exit 1
    fi

    mkdir -p "$TMP_ROOT/chopsticks path/modules"
    mkdir -p "$TMP_ROOT/chopsticks path/doc"
    cp .vimrc "$TMP_ROOT/chopsticks path/.vimrc"
    cp modules/*.vim "$TMP_ROOT/chopsticks path/modules/"
    cp doc/*.txt "$TMP_ROOT/chopsticks path/doc/"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u "$TMP_ROOT/chopsticks path/.vimrc" \
        -i NONE -es -N -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u "$TMP_ROOT/chopsticks path/.vimrc" -i NONE -es -N \
        -c 'ChopsticksHelp' \
        -c 'if expand("%:t") !=# "chopsticks.txt" | cquit | endif' \
        -c 'if search("chopsticks-v3-space", "n") == 0 | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_profile = "minimal"' \
        -c 'source .vimrc' \
        -c 'if has_key(g:plugs, "ale") || has_key(g:plugs, "vim-lsp") || has_key(g:plugs, "vim-lsp-settings") || has_key(g:plugs, "asyncomplete.vim") || has_key(g:plugs, "auto-pairs") | cquit | endif' \
        -c 'qa!' 2>&1

    mkdir -p "$TMP_ROOT/local"
    printf "%s\n" "let g:chopsticks_profile = 'minimal'" > "$TMP_ROOT/local/config.vim"
    vim -u NONE -i NONE -es -N \
        -c "let g:chopsticks_local_config = '$TMP_ROOT/local/config.vim'" \
        -c 'source .vimrc' \
        -c 'if g:chopsticks_resolved_local_config !~# "config.vim$" || g:chopsticks_profile !=# "minimal" || has_key(g:plugs, "ale") || has_key(g:plugs, "vim-lsp") || has_key(g:plugs, "auto-pairs") | cquit | endif' \
        -c 'qa!' 2>&1

    mkdir -p "$TMP_ROOT/xdg"
    printf "%s\n" "let g:chopsticks_profile = 'minimal'" > "$TMP_ROOT/xdg/chopsticks.vim"
    XDG_CONFIG_HOME="$TMP_ROOT/xdg" vim -u NONE -i NONE -es -N \
        -c 'source .vimrc' \
        -c 'if g:chopsticks_resolved_local_config !~# "chopsticks.vim$" || g:chopsticks_profile !=# "minimal" || has_key(g:plugs, "ale") || has_key(g:plugs, "vim-lsp") || has_key(g:plugs, "auto-pairs") | cquit | endif' \
        -c 'qa!' 2>&1

    local_config_cmd="$TMP_ROOT/config command/chopsticks.vim"
    vim -u NONE -i NONE -es -N \
        -c "let g:chopsticks_local_config = '$local_config_cmd'" \
        -c 'source .vimrc' \
        -c 'ChopsticksConfig' \
        -c 'if expand("%:p") !=# g:chopsticks_resolved_local_config || &l:filetype !=# "vim" | cquit | endif' \
        -c 'if getline(1) !~# "chopsticks local preferences" || &modified | cquit | endif' \
        -c 'qa!' 2>&1
    test -d "$(dirname "$local_config_cmd")"
    test ! -e "$local_config_cmd"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-default.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    if grep -Fq 'vim-lsp not loaded' "$TMP_ROOT/status-default.txt"; then
        cat "$TMP_ROOT/status-default.txt"
        exit 1
    fi
    grep -Fq 'OK  vim-lsp stack  (installed)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'help       :ChopsticksHelp  :ChopsticksTutor  SPC ?' "$TMP_ROOT/status-default.txt"
    grep -Fq 'commands   :ChopsticksConfig  :ChopsticksReload' "$TMP_ROOT/status-default.txt"
    grep -Fq 'candidate  3.0.0-beta.1' "$TMP_ROOT/status-default.txt"
    grep -Fq 'keymap     space' "$TMP_ROOT/status-default.txt"
    grep -Fq 'commands   :ChopsticksBeta  :ChopsticksBetaLog' "$TMP_ROOT/status-default.txt"
    grep -Fq ':ChopsticksBetaSession' "$TMP_ROOT/status-default.txt"
    grep -Fq 'chopsticks-beta.md' "$TMP_ROOT/status-default.txt"
    grep -Fq 'python  (:LspInstallServer in a python file)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'LSP actions are buffer-local and start after a server attaches.' "$TMP_ROOT/status-default.txt"
    grep -Fq 'Open that filetype and run :LspInstallServer once.' "$TMP_ROOT/status-default.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let last_change_map = nr2char(96) . "[v" . nr2char(96) . "]"' \
        -c 'if maparg("0", "n") !=# "" || maparg("0", "v") !=# "" || maparg("Y", "n") !=# "" || maparg("Q", "n") !=# "" || maparg("<Space>", "n") !=# "" || maparg("//", "v") !=# "" || maparg("gV", "n") !=# "" || maparg("jk", "i") !=# "" || maparg("<C-s>", "n") !=# "" || maparg("<C-s>", "i") !=# "" || maparg("<C-p>", "n") !=# "" || maparg("<C-p>", "c") !=# "" || maparg("<C-n>", "c") !=# "" || maparg("w!!", "c") !=# "" | cquit | endif' \
        -c 'if maparg("<C-h>", "n") !~# "NavigateWindow" || maparg("<C-j>", "n") !~# "NavigateWindow" || maparg("<C-k>", "n") !~# "NavigateWindow" || maparg("<C-l>", "n") !~# "NavigateWindow" | cquit | endif' \
        -c 'if has_key(g:plugs, "auto-pairs") || maparg("<Tab>", "i") =~# "pumvisible" || maparg("<S-Tab>", "i") =~# "pumvisible" || maparg("<CR>", "i") =~# "asyncomplete#close_popup" || maparg("<CR>", "i") =~# "AutoPairs" | cquit | endif' \
        -c 'if maparg("<Esc><Esc>", "t") !=# "" || maparg("<C-h>", "t") !=# "" || maparg("<C-j>", "t") !=# "" || maparg("<C-k>", "t") !=# "" || maparg("<C-l>", "t") !=# "" | cquit | endif' \
        -c 'if maparg("s", "n") !~# "easymotion-overwin-f2" | cquit | endif' \
        -c 'if maparg("<Space>/", "v") !~# "escape" || maparg("<Space>v", "n") !=# last_change_map || maparg("<Space><Space>", "n") !~# "SmartFiles" | cquit | endif' \
        -c 'if maparg(",/", "v") !=# "" || maparg(",v", "n") !=# "" || maparg(",ff", "n") !=# "" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "classic"' \
        -c 'source .vimrc' \
        -c 'let last_change_map = nr2char(96) . "[v" . nr2char(96) . "]"' \
        -c 'if mapleader !=# "," || maparg("s", "n") !=# "" || maparg(",/", "v") !~# "escape" || maparg(",v", "n") !=# last_change_map || maparg(",ff", "n") !~# "SmartFiles" | cquit | endif' \
        -c 'if maparg("<C-h>", "n") !~# "NavigateWindow" || maparg("<C-j>", "n") !~# "NavigateWindow" || maparg("<C-k>", "n") !~# "NavigateWindow" || maparg("<C-l>", "n") !~# "NavigateWindow" | cquit | endif' \
        -c 'if maparg(",ec", "n") !~# "ChopsticksConfig" || maparg(",sv", "n") !~# "ChopsticksReload" | cquit | endif' \
        -c 'if maparg(",gp", "n") !=# "" || maparg(",gl", "n") !=# "" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_jk_escape = 1' \
        -c 'source .vimrc' \
        -c 'if maparg("jk", "i") !~# "<Esc>" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_ctrl_s_save = 1' \
        -c 'let g:chopsticks_enable_sudo_save_bang = 1' \
        -c 'let g:chopsticks_enable_completion_keymaps = 1' \
        -c 'source .vimrc' \
        -c 'if maparg("<C-s>", "n") !~# ":w" || maparg("<C-s>", "i") !~# ":w" || maparg("w!!", "c") !~# "sudo tee" | cquit | endif' \
        -c 'if maparg("<Tab>", "i") !~# "pumvisible" || maparg("<S-Tab>", "i") !~# "pumvisible" || maparg("<CR>", "i") !~# "asyncomplete#close_popup" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_auto_pairs = 1' \
        -c 'source .vimrc' \
        -c 'if !has_key(g:plugs, "auto-pairs") | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_terminal_keymaps = 1' \
        -c 'source .vimrc' \
        -c 'if has("terminal") && (maparg("<Esc><Esc>", "t") !~# "<C-\\\\><C-N>" || maparg("<C-h>", "t") !~# "NavigateWindow" || maparg("<C-j>", "t") !~# "NavigateWindow" || maparg("<C-k>", "t") !~# "NavigateWindow" || maparg("<C-l>", "t") !~# "NavigateWindow") | cquit | endif' \
        -c 'qa!' 2>&1

    TMUX=/tmp/chopsticks-test XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if has_key(g:plugs, "vim-tmux-navigator") | cquit | endif' \
        -c 'qa!' 2>&1

    TMUX=/tmp/chopsticks-test XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_tmux_navigator = 1' \
        -c 'source .vimrc' \
        -c 'if !has_key(g:plugs, "vim-tmux-navigator") | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'setfiletype netrw' \
        -c 'if &filetype !=# "netrw" | cquit | endif' \
        -c 'if !maparg("<C-l>", "n", 0, 1).buffer | cquit | endif' \
        -c 'if maparg("<C-h>", "n") !~# "NavigateWindow" || maparg("<C-l>", "n") !~# "NavigateWindow" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if &exrc || &secure | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_exrc = 1' \
        -c 'source .vimrc' \
        -c 'if !&exrc || !&secure | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if maparg("<Space>c=", "n") !=# "" | cquit | endif' \
        -c 'if maparg("<Space>=", "v") !~# "=" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_reindent_file = 1' \
        -c 'source .vimrc' \
        -c 'if maparg("<Space>c=", "n") !~# "gg=G" | cquit | endif' \
        -c 'qa!' 2>&1

    TERM=xterm-256color XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if g:is_tty || &ttimeoutlen != 10 | cquit | endif' \
        -c 'qa!' 2>&1

    TERM=linux XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !g:is_tty || &ttimeoutlen != 50 | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("loaded_gzip") || !exists("loaded_logiPat") || !exists("loaded_rrhelper") || !exists("loaded_spellfile_plugin") | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! delcommand LspStatus' \
        -c 'silent! delcommand LspInstallServer' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-lsp-not-loaded.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'OK  vim-lsp stack  (installed; not loaded yet)' "$TMP_ROOT/status-lsp-not-loaded.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_profile = "minimal"' \
        -c 'source .vimrc' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-minimal.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'off vim-lsp stack  (LSP disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off python  (LSP disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    if grep -Fq 'LSP actions are buffer-local' "$TMP_ROOT/status-minimal.txt"; then
        cat "$TMP_ROOT/status-minimal.txt"
        exit 1
    fi

    mkdir -p "$TMP_ROOT/missing-home/.vim/autoload"
    cp "$HOME/.vim/autoload/plug.vim" "$TMP_ROOT/missing-home/.vim/autoload/plug.vim"
    HOME="$TMP_ROOT/missing-home" XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u .vimrc -i NONE -es -N \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-missing-plugin.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'vim-lsp not installed; run :PlugInstall' "$TMP_ROOT/status-missing-plugin.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'doautocmd User lsp_buffer_enabled' \
        -c 'if maparg("gd", "n") !~# "lsp-definition" || maparg("gr", "n") !~# "lsp-references" || maparg("gI", "n") !~# "lsp-implementation" || maparg("gy", "n") !~# "lsp-type-definition" || maparg("K", "n") !~# "lsp-hover" | cquit | endif' \
        -c 'if maparg("[d", "n") !~# "lsp-previous-diagnostic" || maparg("]d", "n") !~# "lsp-next-diagnostic" | cquit | endif' \
        -c 'if maparg("<Space>ca", "n") !~# "lsp-code-action" || maparg("<Space>cr", "n") !~# "lsp-rename" || maparg("<Space>cf", "n") !~# "lsp-document-format" | cquit | endif' \
        -c 'if maparg("<Space>ci", "n") !~# "LspStatus" || maparg("<Space>co", "n") !~# "lsp-document-symbol-search" | cquit | endif' \
        -c 'if maparg("<Space>cd", "n") !=# "" || maparg("<Space>ck", "n") !=# "" || maparg("<Space>cp", "n") !=# "" || maparg("<Space>cn", "n") !=# "" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "classic"' \
        -c 'source .vimrc' \
        -c 'doautocmd User lsp_buffer_enabled' \
        -c 'if maparg("gd", "n") !=# "" || maparg("K", "n") !=# "" || maparg("gI", "n") !=# "" || maparg("gr", "n") !=# "" | cquit | endif' \
        -c 'if maparg(",dd", "n") !~# "lsp-definition" || maparg(",dt", "n") !~# "lsp-type-definition" || maparg(",di", "n") !~# "lsp-implementation" || maparg(",dr", "n") !~# "lsp-references" || maparg(",dk", "n") !~# "lsp-hover" | cquit | endif' \
        -c 'if maparg(",dp", "n") !~# "lsp-previous-diagnostic" | cquit | endif' \
        -c 'if maparg(",dn", "n") !~# "lsp-next-diagnostic" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "space"' \
        -c 'source .vimrc' \
        -c 'if mapleader !=# "\<Space>" || maplocalleader !=# "," | cquit | endif' \
        -c 'if maparg(",ff", "n") !=# "" || maparg(",w", "n") !=# "" || maparg(",mt", "n") !=# "" || maparg(",gp", "n") !=# "" || maparg("<Space>gp", "n") !=# "" | cquit | endif' \
        -c 'if maparg("<Space>f", "n") !=# "" || maparg("<Space>q", "n") !=# "" || maparg("<Space>u", "n") !=# "" || maparg("<Space>c", "n") !=# "" || maparg("<Space>x", "n") !=# "" || maparg("<Space>wm", "n") !=# "" || maparg("<Space>w+", "n") !=# "" || maparg("<Space>w-", "n") !=# "" | cquit | endif' \
        -c 'if maparg("<Space><Space>", "n") !~# "SmartFiles" || maparg("<Space>ff", "n") !~# "SmartFiles" || maparg("<Space>,", "n") !~# "Buffers" || maparg("<Space>bd", "n") !~# "Bclose" | cquit | endif' \
        -c 'if maparg("<Space>w", "n") !~# ":w" || maparg("<Space>W", "n") !~# ":wa" || maparg("<Space>qq", "n") !~# ":q" || maparg("<Space>qx", "n") !~# ":x" || maparg("<Space>fc", "n") !~# "ChopsticksConfig" || maparg("<Space>fV", "n") !~# "ChopsticksReload" || maparg("<Space>U", "n") !~# "UndotreeToggle" || maparg("<Space>fs", "n") !=# "" || maparg("<Space>bu", "n") !=# "" | cquit | endif' \
        -c 'if maparg("<Space>gl", "n") !~# "Git log" || maparg("<Space>gC", "n") !~# "Commits" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "space"' \
        -c 'source .vimrc' \
        -c 'doautocmd User lsp_buffer_enabled' \
        -c 'if maparg("<Space>cf", "n") !~# "lsp-document-format" | cquit | endif' \
        -c 'if maparg("gd", "n") !~# "lsp-definition" || maparg("gr", "n") !~# "lsp-references" || maparg("K", "n") !~# "lsp-hover" | cquit | endif' \
        -c 'if maparg("<Space>cd", "n") !=# "" || maparg("<Space>ck", "n") !=# "" | cquit | endif' \
        -c 'if maparg("<Space>f", "n") !=# "" || maparg("<Space>c", "n") !=# "" | cquit | endif' \
        -c 'if maparg(",f", "n") !=# "" || maparg(",dd", "n") !=# "" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'call feedkeys("\<Space>?", "xt")' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 42 | cquit | endif' \
        -c "redir! > $TMP_ROOT/cheat-default.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq ':ChopsticksStatus   check LSP setup' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'trained loop:' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'files → s jump → gd/K' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'run → grep → git' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC SPC   files' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'gd        definition' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'K         hover docs' "$TMP_ROOT/cheat-default.txt"
    grep -Fq '[d ]d     LSP diagnostics' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'Ctrl-hjkl windows' "$TMP_ROOT/cheat-default.txt"
    grep -Fq '<C-w>hjkl native fallback' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC w     save' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC fc    edit local config' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 's+2ch     easymotion jump' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'cl / cc   native s / S substitute' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksHelp    full help' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksConfig  local config' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksReload  reload config' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksTutor   practice' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksBeta    beta test guide' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksBetaLog beta notes' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksBetaSession new beta note' "$TMP_ROOT/cheat-default.txt"
    if grep -Eq 'Ctrl\\+p    find file|Ctrl\\+hjkl navigate splits|Ctrl\\+s    save|jk        exit insert|SPC fs    save|SPC cd    definition|SPC ck    hover|SPC wm|SPC w\\+/-|\\[g \\]g     LSP diagnostics' "$TMP_ROOT/cheat-default.txt"; then
        cat "$TMP_ROOT/cheat-default.txt"
        exit 1
    fi

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'ChopsticksCheatSheet' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 42 | cquit | endif' \
        -c "redir! > $TMP_ROOT/cheat-command.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'SPC SPC   files' "$TMP_ROOT/cheat-command.txt"
    grep -Fq ':ChopsticksTutor   practice' "$TMP_ROOT/cheat-command.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "classic"' \
        -c 'source .vimrc' \
        -c 'normal ,?' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 42 | cquit | endif' \
        -c "redir! > $TMP_ROOT/cheat-classic.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq ',ff       files' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq 'trained loop:' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq 'files → jump → inspect' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq 'run → grep → git' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',dd       definition' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',dk       hover docs' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',dp ,dn   LSP diagnostics' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',ec       edit local config' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ':ChopsticksConfig  local config' "$TMP_ROOT/cheat-classic.txt"
    if grep -Eq ',gp       push|,gl       pull' "$TMP_ROOT/cheat-classic.txt"; then
        cat "$TMP_ROOT/cheat-classic.txt"
        exit 1
    fi

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_profile = "minimal"' \
        -c 'source .vimrc' \
        -c 'call feedkeys("\<Space>?", "xt")' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 42 | cquit | endif' \
        -c "redir! > $TMP_ROOT/cheat.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    if grep -Eq 'definition|LspInstallServer|ALE errors|undo tree|markdown preview' "$TMP_ROOT/cheat.txt"; then
        cat "$TMP_ROOT/cheat.txt"
        exit 1
    fi
    grep -q 'SPC rr    run file' "$TMP_ROOT/cheat.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "space"' \
        -c 'source .vimrc' \
        -c 'call feedkeys("\<Space>?", "xt")' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 42 | cquit | endif' \
        -c "redir! > $TMP_ROOT/cheat-space.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'SPC w     save' "$TMP_ROOT/cheat-space.txt"
    grep -Fq 'gd        definition' "$TMP_ROOT/cheat-space.txt"
    grep -Fq 'SPC gl    log graph' "$TMP_ROOT/cheat-space.txt"
    grep -Fq 'SPC fc    edit local config' "$TMP_ROOT/cheat-space.txt"
    grep -Fq 's+2ch     easymotion jump' "$TMP_ROOT/cheat-space.txt"
    if grep -Eq ',w        save|,gp       push|SPC gp    push|SPC gl    pull|SPC fs    save|SPC cd    definition|SPC f     format' "$TMP_ROOT/cheat-space.txt"; then
        cat "$TMP_ROOT/cheat-space.txt"
        exit 1
    fi

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'ChopsticksTutor' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 78 | cquit | endif' \
        -c "redir! > $TMP_ROOT/tutor-default.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'chopsticks tutor' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'Goal: train one long-term project loop around Vim.' "$TMP_ROOT/tutor-default.txt"
    grep -Fq '1. trained loop' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'SPC ?      active cheat sheet' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'SPC fc     edit local config' "$TMP_ROOT/tutor-default.txt"
    grep -Fq ':ChopsticksHelp    full help' "$TMP_ROOT/tutor-default.txt"
    grep -Fq ':ChopsticksConfig  local config' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'Ctrl-h/j/k/l split navigation' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'SPC e, Ctrl-h/l  enter/leave sidebar' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 's + 2 chars  visible jump' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'cl / cc      native s / S substitute' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'gd / gr / K  definition / refs / docs' "$TMP_ROOT/tutor-default.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "classic"' \
        -c 'source .vimrc' \
        -c 'ChopsticksTutor' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 78 | cquit | endif' \
        -c "redir! > $TMP_ROOT/tutor-classic.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'classic layout' "$TMP_ROOT/tutor-classic.txt"
    grep -Fq 'Goal: train one long-term project loop around Vim.' "$TMP_ROOT/tutor-classic.txt"
    grep -Fq ',?         active cheat sheet' "$TMP_ROOT/tutor-classic.txt"
    grep -Fq ',ec       edit local config' "$TMP_ROOT/tutor-classic.txt"
    grep -Fq 'Ctrl-h/j/k/l  split navigation' "$TMP_ROOT/tutor-classic.txt"
    grep -Fq ',S + 2 chars  EasyMotion jump' "$TMP_ROOT/tutor-classic.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'ChopsticksBeta' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 78 | cquit | endif' \
        -c "redir! > $TMP_ROOT/beta-guide.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'chopsticks beta' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'Prove this can be a long-term project loop.' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'Record real editing friction, not abstract taste.' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'no private wiki is needed to remember the daily loop' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'window/sidebar navigation beats native <C-w> only' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'SPC ?     active cheat sheet' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'BETA.md        full beta checklist and rollback' "$TMP_ROOT/beta-guide.txt"
    grep -Fq ':ChopsticksBetaLog      editable local beta notes' "$TMP_ROOT/beta-guide.txt"
    grep -Fq ':ChopsticksBetaSession  append a new session block' "$TMP_ROOT/beta-guide.txt"

    beta_log="$TMP_ROOT/beta log/chopsticks-beta.md"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c "let g:chopsticks_beta_log = '$beta_log'" \
        -c 'source .vimrc' \
        -c 'ChopsticksBetaLog' \
        -c 'if expand("%:p") !~# "chopsticks-beta.md" || &l:filetype !=# "markdown" | cquit | endif' \
        -c 'qa!' 2>&1
    grep -Fq '# chopsticks beta log' "$beta_log"
    grep -Fq 'First key tried when stuck:' "$beta_log"
    printf '%s\n' '- keep-existing-note' >> "$beta_log"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c "let g:chopsticks_beta_log = '$beta_log'" \
        -c 'source .vimrc' \
        -c 'ChopsticksBetaLog' \
        -c 'qa!' 2>&1
    grep -Fq -- '- keep-existing-note' "$beta_log"
    before_sessions="$(grep -c '^## ' "$beta_log")"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c "let g:chopsticks_beta_log = '$beta_log'" \
        -c 'source .vimrc' \
        -c 'ChopsticksBetaSession' \
        -c 'qa!' 2>&1
    after_sessions="$(grep -c '^## ' "$beta_log")"
    test "$after_sessions" -eq $((before_sessions + 1))
    grep -Fq -- '- keep-existing-note' "$beta_log"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N README.md \
        -c 'let g:chopsticks_keymap_style = "space"' \
        -c 'source .vimrc' \
        -c 'set filetype=markdown' \
        -c 'if maparg(",mt", "n") !~# "Toc" || maparg(",mp", "n") !~# "PrevimOpen" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N README.md \
        -c 'set filetype=markdown' \
        -c 'if &l:spell || &l:conceallevel != 0 || &l:signcolumn !=# "no" || exists("g:lsp_settings_filetype_markdown") | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if maparg("s", "n") !~# "easymotion-overwin-f2" | cquit | endif' \
        -c 'if maparg("<Space>w", "n") =~# "!" | cquit | endif' \
        -c 'if !&swapfile || !&writebackup || &directory !~# "\.vim/.swap" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:ale_fix_on_save = 0' \
        -c 'source .vimrc' \
        -c 'if g:ale_fix_on_save != 0 | cquit | endif' \
        -c 'qa!' 2>&1

    truncate -s 11000000 "$TMP_ROOT/large.py"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N "$TMP_ROOT/large.py" \
        -c 'set filetype=python' \
        -c 'if &l:syntax !=# "" || &l:undolevels != -1 || &l:swapfile || get(b:, "ale_enabled", 1) != 0 | cquit | endif' \
        -c 'qa!' 2>&1

    mkdir -p "$TMP_ROOT/fake-bin" "$TMP_ROOT/c runner"
    cat > "$TMP_ROOT/fake-bin/gcc" <<'GCCEOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$@" > "$GCC_ARGS"
out=""
while [ "$#" -gt 0 ]; do
    if [ "$1" = "-o" ]; then
        shift
        out="$1"
    fi
    shift || true
done
test -n "$out"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$out"
chmod +x "$out"
GCCEOF
    chmod +x "$TMP_ROOT/fake-bin/gcc"
    c_file="$TMP_ROOT/c runner/main.c"
    c_file_real="$(cd "$TMP_ROOT/c runner" && pwd -P)/main.c"
    printf '%s\n' 'int main(void) { return 0; }' > "$c_file"
    GCC_ARGS="$TMP_ROOT/gcc-args.txt" \
        PATH="$TMP_ROOT/fake-bin:$PATH" \
        XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u .vimrc -i NONE -es -N "$c_file" \
        -c 'set filetype=c' \
        -c 'call feedkeys("\<Space>rr", "xt")' \
        -c 'qa!' 2>&1
    c_out="$(sed -n '2p' "$TMP_ROOT/gcc-args.txt")"
    test -n "$c_out"
    test "$c_out" != "/tmp/a.out"
    test ! -e "$c_out"
    grep -Fxq "$c_file_real" "$TMP_ROOT/gcc-args.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE --startuptime "$TMP_ROOT/startup.log" \
        -es -N -c 'qa!' 2>/dev/null
    tail -1 "$TMP_ROOT/startup.log"
    STARTUP_MS="$(awk 'END { print $1 }' "$TMP_ROOT/startup.log")"
    awk -v ms="$STARTUP_MS" -v limit="$STARTUP_LIMIT_MS" \
        'BEGIN { if (ms > limit) exit 1 }'
}

check_vim
