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

usage() {
    cat <<'EOF'
Usage: scripts/test.sh [group...]

Groups:
  quick       shell, docs, installer, and bootstrap checks
  shell       shell syntax, executability, and shellcheck
  docs        markdownlint for project docs
  installer   install.sh dry-run/configure-only profile checks
  bootstrap   get.sh dry-run safety checks
  vim         Vim smoke tests; requires plugins in ~/.vim/plugged
  all         quick plus vim

Options:
  -h, --help  show this help
  list        print group names, one per line
EOF
}

list_groups() {
    printf '%s\n' quick shell docs installer bootstrap vim all
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

    mkdir -p "$TMP_ROOT/no-git-bin"
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        "echo \"brew was called\" >> \"\$BREW_LOG\"" \
        'exit 42' > "$TMP_ROOT/no-git-bin/brew"
    chmod +x "$TMP_ROOT/no-git-bin/brew"
    BREW_LOG="$TMP_ROOT/no-git-brew.log" \
        PATH="$TMP_ROOT/no-git-bin" \
        CHOPSTICKS_DEST="$TMP_ROOT/no-git-bootstrap" \
        /bin/bash ./get.sh --dry-run --profile=full \
        | tee "$TMP_ROOT/get-no-git-dry-run.txt"
    grep -q 'Would require: git' "$TMP_ROOT/get-no-git-dry-run.txt"
    grep -q 'Would clone' "$TMP_ROOT/get-no-git-dry-run.txt"
    test ! -e "$TMP_ROOT/no-git-brew.log"
    test ! -e "$TMP_ROOT/no-git-bootstrap"

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
    grep -Fq 'python  (:LspInstallServer in a python file)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'LSP actions are buffer-local and start after a server attaches.' "$TMP_ROOT/status-default.txt"
    grep -Fq 'Open that filetype and run :LspInstallServer once.' "$TMP_ROOT/status-default.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if maparg("0", "n") !=# "" || maparg("0", "v") !=# "" || maparg("Y", "n") !=# "" || maparg("Q", "n") !=# "" || maparg("<Space>", "n") !=# "" | cquit | endif' \
        -c 'if maparg("jk", "i") !=# "" | cquit | endif' \
        -c 'if maparg("<C-h>", "n") !=# "" || maparg("<C-j>", "n") !=# "" || maparg("<C-k>", "n") !=# "" || maparg("<C-l>", "n") !=# "" | cquit | endif' \
        -c 'if maparg("<C-p>", "n") !=# "" | cquit | endif' \
        -c 'if maparg(",ff", "n") !~# "SmartFiles" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_jk_escape = 1' \
        -c 'source .vimrc' \
        -c 'if maparg("jk", "i") !~# "<Esc>" | cquit | endif' \
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

    vim -u NONE -i NONE -es -N \
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
        -c 'if maparg("gd", "n") !=# "" || maparg("K", "n") !=# "" || maparg("gi", "n") !=# "" || maparg("gr", "n") !=# "" | cquit | endif' \
        -c 'if maparg(",dd", "n") !~# "lsp-definition" | cquit | endif' \
        -c 'if maparg(",dt", "n") !~# "lsp-type-definition" | cquit | endif' \
        -c 'if maparg(",di", "n") !~# "lsp-implementation" | cquit | endif' \
        -c 'if maparg(",dr", "n") !~# "lsp-references" | cquit | endif' \
        -c 'if maparg(",dk", "n") !~# "lsp-hover" | cquit | endif' \
        -c 'if maparg(",dp", "n") !~# "lsp-previous-diagnostic" | cquit | endif' \
        -c 'if maparg(",dn", "n") !~# "lsp-next-diagnostic" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'normal ,?' \
        -c "redir! > $TMP_ROOT/cheat-default.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq ':ChopsticksStatus   check LSP setup' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ',ff       files' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ',dd       definition' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ',dk       hover docs' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ',dp ,dn   LSP diagnostics' "$TMP_ROOT/cheat-default.txt"
    grep -Fq '<C-w>hjkl navigate splits' "$TMP_ROOT/cheat-default.txt"
    if grep -Eq 'Ctrl\\+p    find file|Ctrl\\+hjkl navigate splits|jk        exit insert|gd        definition|K         hover docs|\\[g \\]g     LSP diagnostics' "$TMP_ROOT/cheat-default.txt"; then
        cat "$TMP_ROOT/cheat-default.txt"
        exit 1
    fi

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
        -c 'normal ,cr' \
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

run_group() {
    case "$1" in
        quick)
            check_shell
            check_docs
            check_installer_modes
            check_bootstrap
            ;;
        shell) check_shell ;;
        docs) check_docs ;;
        installer) check_installer_modes ;;
        bootstrap) check_bootstrap ;;
        vim) check_vim ;;
        all)
            run_group quick
            check_vim
            ;;
        list | --list) list_groups ;;
        -h | --help) usage ;;
        *)
            echo "Unknown test group: $1" >&2
            echo >&2
            usage >&2
            exit 1 ;;
    esac
}

if [[ $# -eq 0 ]]; then
    set -- all
fi

for group in "$@"; do
    run_group "$group"
done
