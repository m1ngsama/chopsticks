#!/bin/sh
set -eu

vimlint_commit=cec40c28f119a5f4b92ceb0b6aae525122a81244
vimlparser_commit=075a4fa4baf221fbbc788d9e8b8624c35c3e8876
chopsticks_root=$(cd -- "$(dirname -- "$0")/.." && pwd)
lint_cache=${CHOPSTICKS_LINT_CACHE:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}/chopsticks-lint}
vimlint_dir=$lint_cache/vim-vimlint
vimlparser_dir=$lint_cache/vim-vimlparser

checkout_linter() {
    repository=$1
    commit=$2
    destination=$3

    if [ ! -d "$destination/.git" ]; then
        mkdir -p "$destination"
        git -C "$destination" init --quiet
    fi
    if git -C "$destination" remote get-url origin >/dev/null 2>&1; then
        git -C "$destination" remote set-url origin "$repository"
    else
        git -C "$destination" remote add origin "$repository"
    fi
    if ! git -C "$destination" cat-file -e "$commit^{commit}" 2>/dev/null; then
        git -C "$destination" fetch --quiet --depth=1 origin "$commit"
    fi
    git -C "$destination" checkout --quiet --detach "$commit"
}

checkout_linter https://github.com/syngan/vim-vimlint.git "$vimlint_commit" "$vimlint_dir"
checkout_linter https://github.com/vim-jp/vim-vimlparser.git "$vimlparser_commit" "$vimlparser_dir"

VIMLINT_VIM=${VIMLINT_VIM:-vim} \
    sh "$vimlint_dir/bin/vimlint.sh" \
        -u \
        -l "$vimlint_dir" \
        -p "$vimlparser_dir" \
        "$chopsticks_root/.vimrc"
