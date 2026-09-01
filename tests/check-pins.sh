#!/bin/sh
set -eu

repository_root=$(cd -- "$(dirname -- "$0")/.." && pwd)
checker=$repository_root/scripts/check-pins.sh
test_root=$(mktemp -d "${TMPDIR:-/tmp}/chopsticks-pins-test.XXXXXX")
fixture_root=$test_root/'root with spaces'
output=$test_root/check-pins.out

cleanup() {
    rm -rf -- "$test_root"
}

trap cleanup EXIT HUP INT TERM

pin=0123456789abcdef0123456789abcdef01234567
digest=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

write_fixture() {
    action_reference=$1
    docker_reference=$2
    go_reference=$3
    linter_reference=$4
    raw_reference=$5
    plugin_hook=$6

    mkdir -p "$fixture_root/.github/workflows" "$fixture_root/scripts"
    cat >"$fixture_root/.github/workflows/check.yaml" <<EOF
name: pins
on: push
jobs:
  pins:
    runs-on: ubuntu-24.04
    steps:
      - uses: "actions/checkout@$action_reference" # immutable action
      - uses: 'docker://alpine@sha256:$docker_reference' # immutable image
EOF
    cat >"$fixture_root/.vimrc" <<EOF
Plug 'example/plugin', {'commit': '$pin'$plugin_hook}
EOF
    cat >"$fixture_root/package.json" <<EOF
{
  "scripts": {
    "lint:actions": "printf check && go run github.com/example/tool/cmd/tool@$go_reference"
  }
}
EOF
    cat >"$fixture_root/scripts/lint-vim.sh" <<EOF
vimlint_commit=$linter_reference
vimlparser_commit=$pin
EOF
    cat >"$fixture_root/README.md" <<EOF
https://raw.githubusercontent.com/example/tool/$raw_reference/tool.vim
EOF
}

run_checker() {
    CHOPSTICKS_CHECK_PINS_ROOT=$fixture_root sh "$checker"
}

expect_failure() {
    label=$1
    expected=$2
    if run_checker >"$output" 2>&1; then
        printf 'check-pins accepted mutation: %s\n' "$label" >&2
        return 1
    fi
    if ! grep -F "$expected" "$output" >/dev/null 2>&1; then
        printf 'check-pins rejected %s for the wrong reason:\n' "$label" >&2
        sed 's/^/  /' "$output" >&2
        return 1
    fi
}

write_fixture "$pin" "$digest" "$pin" "$pin" "$pin" ''
run_checker

write_fixture "$pin-evil" "$digest" "$pin" "$pin" "$pin" ''
expect_failure 'action suffix' 'remote action must use a full commit SHA'

write_fixture "floating@$pin" "$digest" "$pin" "$pin" "$pin" ''
expect_failure 'multiple action references' \
    'remote action must use exactly one commit reference'

write_fixture "$pin" "$digest-evil" "$pin" "$pin" "$pin" ''
expect_failure 'container suffix' 'container action must use a sha256 digest'

write_fixture "$pin" "$digest@sha256:$digest" "$pin" "$pin" "$pin" ''
expect_failure 'multiple container digests' \
    'container action must use exactly one digest'

write_fixture "$pin" "$digest" "$pin-evil" "$pin" "$pin" ''
expect_failure 'go module suffix' 'go run dependency must use a full commit SHA'

write_fixture "$pin" "$digest" \
    "latest && go run github.com/example/tool/cmd/tool@$pin" \
    "$pin" "$pin" ''
expect_failure 'multiple go dependencies' \
    'use exactly one go run dependency per line'

write_fixture "$pin" "$digest" "$pin" "$pin-evil" "$pin" ''
expect_failure 'shell assignment suffix' 'must use a full commit SHA'

write_fixture "$pin" "$digest" "$pin" "$pin" "$pin-evil" ''
expect_failure 'raw URL suffix' 'raw GitHub URL must use a full commit SHA'

write_fixture "$pin" "$digest" "$pin" "$pin" \
    "main/tool.vim https://raw.githubusercontent.com/example/tool/$pin" ''
expect_failure 'multiple raw URLs' 'use exactly one raw GitHub URL per line'

write_fixture "$pin" "$digest" "$pin" "$pin" "$pin" \
    ", 'do': 'download'"
expect_failure 'plugin post-install hook' \
    'Vim plugin post-install hooks are not allowed'

write_fixture "$pin" "$digest" "$pin" "$pin" "$pin" ''
cat >"$fixture_root/.vimrc" <<EOF
Plug 'example/plugin', {'commit': 'main'} " 'commit': '$pin'
EOF
expect_failure 'plugin comment decoy' \
    'Vim plugin must use a full commit SHA'

write_fixture "$pin" "$digest" "$pin" "$pin" "$pin" ''
cat >"$fixture_root/.vimrc" <<EOF
Plug 'example/plugin', {'commit': '$pin', 'commit': '$pin'}
EOF
expect_failure 'duplicate plugin commit keys' \
    'Vim plugin must declare exactly one commit pin'

write_fixture "$pin" "$digest" "$pin" "$pin" "$pin" ''
cat >"$fixture_root/.vimrc" <<EOF
execute "Plug 'example/plugin', {'commit': '$pin'}"
EOF
expect_failure 'indirect plugin declaration' \
    'indirect Vim plugin declarations are not allowed'

printf 'check-pins mutation tests passed\n'
