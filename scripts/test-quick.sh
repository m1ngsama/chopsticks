#!/usr/bin/env bash
# Shell, docs, installer, and bootstrap checks.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/test-common.sh
source "$SCRIPT_DIR/test-common.sh"

check_shell() {
    step "Shell syntax and lint"
    need bash
    bash -n install.sh
    bash -n get.sh
    bash -n scripts/test.sh
    bash -n scripts/test-common.sh
    bash -n scripts/test-quick.sh
    bash -n scripts/test-vim.sh
    test -x install.sh
    test -x get.sh
    test -x scripts/test.sh

    need shellcheck
    shellcheck install.sh get.sh scripts/test.sh \
        scripts/test-common.sh scripts/test-quick.sh scripts/test-vim.sh
}

check_docs() {
    step "Markdown lint"
    need markdownlint
    markdownlint README.md QUICKSTART.md CONTRIBUTING.md CHANGELOG.md BETA.md

    step "Documentation consistency"
    for command in ChopsticksBeta ChopsticksBetaLog ChopsticksBetaSession; do
        for file in README.md BETA.md modules/beta.vim modules/cheatsheet.vim \
            modules/tutor.vim modules/status.vim
        do
            grep -Fq "$command" "$file" || {
                echo "Missing $command in $file" >&2
                exit 1
            }
        done
    done

    if command -v vhs >/dev/null 2>&1; then
        vhs validate .github/demo.tape
    else
        echo "Skipping VHS tape validation: vhs not installed"
    fi
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

run_quick_group() {
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
        *)
            echo "Unknown quick test group: $1" >&2
            exit 1 ;;
    esac
}

if [[ $# -eq 0 ]]; then
    set -- quick
fi

for group in "$@"; do
    run_quick_group "$group"
done
