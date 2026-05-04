#!/usr/bin/env bash
# Project test runner. CI calls the same groups that maintainers can run locally.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/chopsticks-test-XXXXXX")"
EMPTY_XDG="$TMP_ROOT/xdg-empty"
STARTUP_LIMIT_MS="${STARTUP_LIMIT_MS:-150}"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

cd "$ROOT"
mkdir -p "$EMPTY_XDG"

step() {
    printf '\n==> %s\n' "$1"
}

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing required command: $1" >&2
        exit 1
    }
}

check_shell() {
    step "Shell syntax and lint"
    need bash
    bash -n install.sh
    bash -n get.sh
    bash -n scripts/test.sh
    test -x install.sh
    test -x get.sh
    test -x scripts/test.sh

    need shellcheck
    shellcheck install.sh get.sh scripts/test.sh
}

check_docs() {
    step "Markdown lint"
    need markdownlint
    markdownlint README.md QUICKSTART.md CONTRIBUTING.md CHANGELOG.md
}

check_installer_modes() {
    step "Installer profile-only modes"
    XDG_CONFIG_HOME="$TMP_ROOT/dry" ./install.sh --dry-run --profile=full \
        | tee "$TMP_ROOT/install-dry-run.txt"
    grep -q 'Profile: full' "$TMP_ROOT/install-dry-run.txt"
    test ! -e "$TMP_ROOT/dry/chopsticks.vim"

    XDG_CONFIG_HOME="$TMP_ROOT/config" ./install.sh --configure-only --profile=minimal
    grep -q "let g:chopsticks_profile = 'minimal'" "$TMP_ROOT/config/chopsticks.vim"

    XDG_CONFIG_HOME="$TMP_ROOT/config" ./install.sh --configure-only --profile=full
    grep -q "let g:chopsticks_profile = 'full'" "$TMP_ROOT/config/chopsticks.vim"

    XDG_CONFIG_HOME="$TMP_ROOT/default" ./install.sh --configure-only --yes
    grep -q "let g:chopsticks_profile = 'engineer'" "$TMP_ROOT/default/chopsticks.vim"
}

check_bootstrap() {
    step "Bootstrap dry-run safety"
    CHOPSTICKS_DEST="$TMP_ROOT/bootstrap" ./get.sh --dry-run --profile=minimal \
        | tee "$TMP_ROOT/get-dry-run.txt"
    grep -q 'Would clone' "$TMP_ROOT/get-dry-run.txt"
    test ! -e "$TMP_ROOT/bootstrap"

    mkdir -p "$TMP_ROOT/not-chopsticks"
    git -c init.defaultBranch=main init "$TMP_ROOT/not-chopsticks" >/dev/null
    git -C "$TMP_ROOT/not-chopsticks" remote add origin https://github.com/example/not-chopsticks.git
    if CHOPSTICKS_DEST="$TMP_ROOT/not-chopsticks" ./get.sh --dry-run; then
        echo "Expected get.sh to reject non-chopsticks repo" >&2
        exit 1
    fi

    mkdir -p "$TMP_ROOT/chopsticks-existing"
    git -c init.defaultBranch=main init "$TMP_ROOT/chopsticks-existing" >/dev/null
    git -C "$TMP_ROOT/chopsticks-existing" remote add origin https://github.com/m1ngsama/chopsticks.git
    touch "$TMP_ROOT/chopsticks-existing/install.sh" "$TMP_ROOT/chopsticks-existing/.vimrc"
    CHOPSTICKS_DEST="$TMP_ROOT/chopsticks-existing" ./get.sh --dry-run --yes \
        | tee "$TMP_ROOT/get-existing.txt"
    grep -q 'Would update existing chopsticks repo' "$TMP_ROOT/get-existing.txt"
}

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

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N -c 'qa!' 2>&1

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
    cp .vimrc "$TMP_ROOT/chopsticks path/.vimrc"
    cp modules/*.vim "$TMP_ROOT/chopsticks path/modules/"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u "$TMP_ROOT/chopsticks path/.vimrc" \
        -i NONE -es -N -c 'qa!' 2>&1

    vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_profile = "minimal"' \
        -c 'source .vimrc' \
        -c 'if has_key(g:plugs, "ale") || has_key(g:plugs, "vim-lsp") || has_key(g:plugs, "vim-lsp-settings") || has_key(g:plugs, "asyncomplete.vim") | cquit | endif' \
        -c 'qa!' 2>&1

    mkdir -p "$TMP_ROOT/local"
    printf "%s\n" "let g:chopsticks_profile = 'minimal'" > "$TMP_ROOT/local/config.vim"
    vim -u NONE -i NONE -es -N \
        -c "let g:chopsticks_local_config = '$TMP_ROOT/local/config.vim'" \
        -c 'source .vimrc' \
        -c 'if g:chopsticks_profile !=# "minimal" || has_key(g:plugs, "ale") || has_key(g:plugs, "vim-lsp") | cquit | endif' \
        -c 'qa!' 2>&1

    mkdir -p "$TMP_ROOT/xdg"
    printf "%s\n" "let g:chopsticks_profile = 'minimal'" > "$TMP_ROOT/xdg/chopsticks.vim"
    XDG_CONFIG_HOME="$TMP_ROOT/xdg" vim -u NONE -i NONE -es -N \
        -c 'source .vimrc' \
        -c 'if g:chopsticks_profile !=# "minimal" || has_key(g:plugs, "ale") || has_key(g:plugs, "vim-lsp") | cquit | endif' \
        -c 'qa!' 2>&1

    vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_profile = "minimal"' \
        -c 'source .vimrc' \
        -c 'normal ,?' \
        -c "redir! > $TMP_ROOT/cheat.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    if grep -Eq 'definition|LspInstallServer|ALE errors|undo tree|markdown preview' "$TMP_ROOT/cheat.txt"; then
        cat "$TMP_ROOT/cheat.txt"
        exit 1
    fi
    grep -q ',cr       run file' "$TMP_ROOT/cheat.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N README.md \
        -c 'set filetype=markdown' \
        -c 'if &l:spell || &l:conceallevel != 0 || &l:signcolumn !=# "no" || exists("g:lsp_settings_filetype_markdown") | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if maparg("s", "n") !=# "" | cquit | endif' \
        -c 'if maparg(",w", "n") =~# "!" | cquit | endif' \
        -c 'if !&swapfile || !&writebackup || &directory !~# "\.vim/.swap" | cquit | endif' \
        -c 'qa!' 2>&1

    vim -u NONE -i NONE -es -N \
        -c 'let g:ale_fix_on_save = 0' \
        -c 'source .vimrc' \
        -c 'if g:ale_fix_on_save != 0 | cquit | endif' \
        -c 'qa!' 2>&1

    truncate -s 11000000 "$TMP_ROOT/large.py"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N "$TMP_ROOT/large.py" \
        -c 'set filetype=python' \
        -c 'if &l:syntax !=# "" || &l:undolevels != -1 || &l:swapfile || get(b:, "ale_enabled", 1) != 0 | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE --startuptime "$TMP_ROOT/startup.log" \
        -es -N -c 'qa!' 2>/dev/null
    tail -1 "$TMP_ROOT/startup.log"
    STARTUP_MS="$(awk 'END { print $1 }' "$TMP_ROOT/startup.log")"
    awk -v ms="$STARTUP_MS" -v limit="$STARTUP_LIMIT_MS" \
        'BEGIN { if (ms > limit) exit 1 }'
}

run_group() {
    case "$1" in
        shell) check_shell ;;
        docs) check_docs ;;
        installer) check_installer_modes ;;
        bootstrap) check_bootstrap ;;
        vim) check_vim ;;
        all)
            check_shell
            check_docs
            check_installer_modes
            check_bootstrap
            check_vim
            ;;
        *)
            echo "Usage: scripts/test.sh [shell|docs|installer|bootstrap|vim|all]..." >&2
            exit 1 ;;
    esac
}

if [[ $# -eq 0 ]]; then
    set -- all
fi

for group in "$@"; do
    run_group "$group"
done
