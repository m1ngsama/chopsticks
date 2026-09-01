#!/bin/sh
set -eu

script_root=$(cd -- "$(dirname -- "$0")/.." && pwd)
chopsticks_root=${CHOPSTICKS_CHECK_PINS_ROOT:-$script_root}
status=0
workflow_found=0

check_raw_github_pins() {
    awk '
    /https:\/\/raw\.githubusercontent\.com\// {
        occurrences = $0
        if (gsub(/https:\/\/raw\.githubusercontent\.com\//, "", occurrences) != 1) {
            printf "%s:%d: use exactly one raw GitHub URL per line: %s\n",
                FILENAME, FNR, $0
            invalid = 1
            next
        }
        reference = $0
        sub(/^.*https:\/\/raw\.githubusercontent\.com\/[^\/[:space:]]+\/[^\/[:space:]]+\//,
            "", reference)
        sub(/\/.*$/, "", reference)
        if (length(reference) != 40 || reference !~ /^[0-9a-f]+$/) {
            printf "%s:%d: raw GitHub URL must use a full commit SHA: %s\n",
                FILENAME, FNR, $0
            invalid = 1
        }
    }
    END { exit invalid }
' "$1"
}

for workflow in \
    "$chopsticks_root"/.github/workflows/*.yml \
    "$chopsticks_root"/.github/workflows/*.yaml
do
    [ -f "$workflow" ] || continue
    workflow_found=1
    if ! check_raw_github_pins "$workflow"; then
        status=1
    fi
    if ! awk '
    /^[[:space:]]*(-[[:space:]]*)?uses:/ {
        value = $0
        sub(/^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*/, "", value)
        single_quote = sprintf("%c", 39)
        if (substr(value, 1, 1) == "\"" ||
            substr(value, 1, 1) == single_quote) {
            quote = substr(value, 1, 1)
            value = substr(value, 2)
            closing = index(value, quote)
            trailer = closing ? substr(value, closing + 1) : value
            if (!closing || trailer !~ /^[[:space:]]*(#.*)?$/) {
                printf "%s:%d: malformed quoted uses value: %s\n",
                    FILENAME, FNR, $0
                invalid = 1
                next
            }
            value = substr(value, 1, closing - 1)
        } else {
            sub(/[[:space:]]+#.*$/, "", value)
            sub(/[[:space:]]+$/, "", value)
        }
        if (value ~ /^\.\//) {
            next
        }
        if (value ~ /^docker:\/\//) {
            separators = value
            if (gsub(/@/, "", separators) != 1) {
                printf "%s:%d: container action must use exactly one digest: %s\n",
                    FILENAME, FNR, $0
                invalid = 1
                next
            }
            reference = value
            sub(/^docker:\/\/.*@sha256:/, "", reference)
            if (length(reference) != 64 || reference !~ /^[0-9a-f]+$/) {
                printf "%s:%d: container action must use a sha256 digest: %s\n",
                    FILENAME, FNR, $0
                invalid = 1
            }
            next
        }
        separators = value
        if (gsub(/@/, "", separators) != 1) {
            printf "%s:%d: remote action must use exactly one commit reference: %s\n",
                FILENAME, FNR, $0
            invalid = 1
            next
        }
        reference = value
        sub(/^.*@/, "", reference)
        if (length(reference) != 40 || reference !~ /^[0-9a-f]+$/) {
            printf "%s:%d: remote action must use a full commit SHA: %s\n",
                FILENAME, FNR, $0
            invalid = 1
        }
    }
    END { exit invalid }
' "$workflow"
    then
        status=1
    fi
done

if [ "$workflow_found" -eq 0 ]; then
    printf 'no GitHub Actions workflows found\n' >&2
    status=1
fi

if ! check_raw_github_pins "$chopsticks_root/README.md"; then
    status=1
fi

if ! awk '
    {
        declaration = $0
        if (declaration ~ /^[[:space:]]*"/) {
            next
        }
        if (declaration !~ /^[[:space:]]*Plug[[:space:]]/ &&
                declaration ~ /Plug[[:space:]]+/) {
            printf "%s:%d: indirect Vim plugin declarations are not allowed: %s\n",
                FILENAME, FNR, $0
            invalid = 1
            next
        }
    }
    /^[[:space:]]*Plug[[:space:]]/ {
        declaration = $0
        sub(/[[:space:]]+".*$/, "", declaration)
        if (declaration ~ /'\''do'\''[[:space:]]*:/) {
            printf "%s:%d: Vim plugin post-install hooks are not allowed: %s\n",
                FILENAME, FNR, $0
            invalid = 1
        }
        keys = declaration
        if (gsub(/'\''commit'\''[[:space:]]*:/, "", keys) != 1) {
            printf "%s:%d: Vim plugin must declare exactly one commit pin: %s\n",
                FILENAME, FNR, $0
            invalid = 1
            next
        }
        reference = declaration
        sub(/^.*'\''commit'\'':[[:space:]]*'\''/, "", reference)
        sub(/'\''.*$/, "", reference)
        if (length(reference) != 40 || reference !~ /^[0-9a-f]+$/) {
            printf "%s:%d: Vim plugin must use a full commit SHA: %s\n",
                FILENAME, FNR, $0
            invalid = 1
        }
    }
    END { exit invalid }
' "$chopsticks_root/.vimrc"
then
    status=1
fi

if ! awk '
    /go[[:space:]]+run[[:space:]]+github\.com\// {
        occurrences = $0
        if (gsub(/go[[:space:]]+run[[:space:]]+github\.com\//,
                "", occurrences) != 1) {
            printf "%s:%d: use exactly one go run dependency per line: %s\n",
                FILENAME, FNR, $0
            invalid = 1
            found = 1
            next
        }
        reference = $0
        sub(/^.*go[[:space:]]+run[[:space:]]+github\.com\/[^@"]*@/,
            "", reference)
        sub(/"[[:space:]]*,?[[:space:]]*$/, "", reference)
        if (length(reference) != 40 || reference !~ /^[0-9a-f]+$/) {
            printf "%s:%d: go run dependency must use a full commit SHA: %s\n",
                FILENAME, FNR, $0
            invalid = 1
        }
        found = 1
    }
    END {
        if (!found) {
            printf "%s: no pinned go run dependency found\n", FILENAME
            invalid = 1
        }
        exit invalid
    }
' "$chopsticks_root/package.json"
then
    status=1
fi

if ! awk '
    BEGIN {
        required["vimlint_commit"] = 1
        required["vimlparser_commit"] = 1
    }
    /^[[:space:]]*[A-Za-z0-9_]+_commit=/ {
        name = $0
        sub(/^[[:space:]]*/, "", name)
        sub(/=.*/, "", name)
        reference = $0
        sub(/^[^=]*=[[:space:]]*/, "", reference)
        sub(/[[:space:]]+#.*$/, "", reference)
        sub(/[[:space:]]+$/, "", reference)
        if (length(reference) != 40 || reference !~ /^[0-9a-f]+$/) {
            printf "%s:%d: %s must use a full commit SHA: %s\n",
                FILENAME, FNR, name, $0
            invalid = 1
        }
        seen[name] = 1
    }
    END {
        for (name in required) {
            if (!seen[name]) {
                printf "%s: required pin is missing: %s\n", FILENAME, name
                invalid = 1
            }
        }
        exit invalid
    }
' "$chopsticks_root/scripts/lint-vim.sh"
then
    status=1
fi

exit "$status"
