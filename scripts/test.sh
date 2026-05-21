#!/usr/bin/env bash
# Project test runner. CI calls the same groups maintainers can run locally.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

run_group() {
    case "$1" in
        quick | shell | docs | installer | bootstrap)
            bash "$SCRIPT_DIR/test-quick.sh" "$1"
            ;;
        vim)
            bash "$SCRIPT_DIR/test-vim.sh"
            ;;
        all)
            bash "$SCRIPT_DIR/test-quick.sh" quick
            bash "$SCRIPT_DIR/test-vim.sh"
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
