#!/bin/sh
set -eu
umask 077

# Git Bash rewrites arguments that look like POSIX paths when it starts a
# native program. That mangles the Windows paths path_for_vim has already
# produced: -V1C:/Users/... reached Vim as -V1C:C:/Program Files/Git/Users/...,
# so the verbose log could not be opened and Vim reported E474 for the option.
# Every path handed to Vim here is converted explicitly, so the extra pass is
# redundant wherever it is not harmful. The variable is ignored elsewhere.
MSYS2_ARG_CONV_EXCL='*'
export MSYS2_ARG_CONV_EXCL

vimlint_commit=cec40c28f119a5f4b92ceb0b6aae525122a81244
vimlparser_commit=075a4fa4baf221fbbc788d9e8b8624c35c3e8876
chopsticks_root=$(cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/chopsticks-vim-test.XXXXXX")
# The runner's TEMP carries 8.3 components. Vim's ':p' resolves them only once
# the directory exists, so a path built before mkdir and compared afterwards
# spells the same directory two ways: RUNNER~1 against runneradmin. Resolve the
# root here, where it does exist, and every derived path inherits the long form.
case $(uname -s) in
    CYGWIN* | MINGW* | MSYS*)
        test_root=$(cygpath -u "$(cygpath -m -l "$test_root")")
        ;;
esac
lint_cache=${CHOPSTICKS_LINT_CACHE:-$test_root/linters}
disabled_git_hooks=$test_root/disabled-git-hooks
vimlint_dir=$lint_cache/vim-vimlint
vimlparser_dir=$lint_cache/vim-vimlparser
test_vim=${CHOPSTICKS_TEST_VIM:-${VIMLINT_VIM:-vim}}
skip_vimlint=${CHOPSTICKS_TEST_SKIP_VIMLINT:-0}
ui_test_cases=${CHOPSTICKS_TEST_UI_CASES:-all}
ui_test_count=0
all_ui_test_cases='default default-dashboard minimal rich density status-context tabline-width
transparent opaque theme-valid theme-fallback dashboard-off dashboard-on
dashboard-wide bufferline-off bufferline-on data-dir-override
data-dir-invalid-type data-dir-empty path-overrides fzf-unavailable session
health keys markdown symlink-install'
# Cases known not to reach the end of tests/ui.vim. Both open the dashboard a
# second time, on a buffer that is already one, and Vim terminates there --
# uncatchably, with no assertion recorded. Verified pre-existing: the same two
# cases die the same way against .vimrc as it stood before the autoload split,
# so this is not a regression from that work. Under -es they exit 0 while
# dying, which is why it went unnoticed: everything those two assert after the
# dashboard has never run, and any assertion that failed before it was
# discarded along with the rest of v:errors.
#
# They are warned about rather than failed so the suite stays usable as a gate
# for the other 22 cases. A case that starts quitting early WITHOUT being
# listed here still fails, which is the property worth keeping.
known_incomplete_ui_tests='default-dashboard rich'
mkdir -p "$disabled_git_hooks"

case "$skip_vimlint" in
    0 | 1) ;;
    *)
        printf 'CHOPSTICKS_TEST_SKIP_VIMLINT must be 0 or 1\n' >&2
        exit 2
        ;;
esac

if [ "$ui_test_cases" != all ]; then
    for requested_ui_test in $ui_test_cases; do
        requested_ui_test_known=0
        for available_ui_test in $all_ui_test_cases; do
            if [ "$requested_ui_test" = "$available_ui_test" ]; then
                requested_ui_test_known=1
                break
            fi
        done
        if [ "$requested_ui_test_known" -ne 1 ]; then
            printf 'unknown CHOPSTICKS_TEST_UI_CASES entry: %s\n' \
                "$requested_ui_test" >&2
            exit 2
        fi
    done
fi

cleanup() {
    rm -rf -- "$test_root"
}

trap cleanup EXIT HUP INT TERM

path_for_vim() {
    case $(uname -s) in
        CYGWIN* | MINGW* | MSYS*)
            if [ -z "$1" ]; then
                printf '\n'
            else
                cygpath -m "$1"
            fi
            ;;
        *) printf '%s\n' "$1" ;;
    esac
}

safe_git() {
    git -c core.hooksPath="$disabled_git_hooks" \
        -c core.fsmonitor=false "$@"
}

checkout_linter() {
    repository=$1
    commit=$2
    destination=$3

    if [ -L "$destination" ] \
        || { [ -e "$destination" ] && [ ! -d "$destination" ]; }
    then
        printf 'unsafe linter cache path: %s\n' "$destination" >&2
        return 1
    fi
    if [ -e "$destination/.git" ]; then
        if [ -L "$destination/.git" ] || [ ! -d "$destination/.git" ]; then
            printf 'unsafe linter Git directory: %s\n' "$destination/.git" >&2
            return 1
        fi
    else
        mkdir -p "$destination"
        if [ -n "$(ls -A "$destination")" ]; then
            printf 'linter cache is not an isolated repository: %s\n' \
                "$destination" >&2
            return 1
        fi
        safe_git -C "$destination" init --quiet
    fi
    if [ -n "$(safe_git -C "$destination" status \
        --porcelain --untracked-files=all --ignored)" ]
    then
        printf 'linter cache contains unverified files: %s\n' "$destination" >&2
        return 1
    fi
    if safe_git -C "$destination" remote get-url origin >/dev/null 2>&1; then
        safe_git -C "$destination" remote set-url origin "$repository"
    else
        safe_git -C "$destination" remote add origin "$repository"
    fi
    if ! safe_git -C "$destination" cat-file -e \
        "$commit^{commit}" 2>/dev/null
    then
        safe_git -C "$destination" fetch --quiet --depth=1 origin "$commit"
    fi
    safe_git -C "$destination" checkout --quiet --detach "$commit"
    if [ "$(safe_git -C "$destination" rev-parse HEAD)" != "$commit" ]; then
        printf 'linter checkout did not resolve to %s\n' "$commit" >&2
        return 1
    fi
    if [ -n "$(safe_git -C "$destination" status \
        --porcelain --untracked-files=all --ignored)" ]
    then
        printf 'linter cache contains unverified files: %s\n' "$destination" >&2
        return 1
    fi
}

if [ "$skip_vimlint" -eq 0 ]; then
    checkout_linter https://github.com/syngan/vim-vimlint.git \
        "$vimlint_commit" "$vimlint_dir"
    checkout_linter https://github.com/vim-jp/vim-vimlparser.git \
        "$vimlparser_commit" "$vimlparser_dir"

    # Invoke vimlint directly. Its shell wrapper parses -c with a GNU sed
    # regexp, which silently generates invalid Vimscript on BSD/macOS. The
    # Python parser also avoids an internal list-index failure on this large
    # configuration.
    vimlint_output=$test_root/vimlint.out
    vimlint_log=$test_root/vimlint.log
    # The dollar-prefixed names below are Vim environment lookups, not shell
    # expansions, so the single quotes are intentional.
    # shellcheck disable=SC2016
    if ! env \
        PYTHONDONTWRITEBYTECODE=1 \
        CHOPSTICKS_VIMLINT_DIR="$vimlint_dir" \
        CHOPSTICKS_VIMPARSER_DIR="$vimlparser_dir" \
        CHOPSTICKS_VIMLINT_FILE="$chopsticks_root/.vimrc" \
        CHOPSTICKS_VIMLINT_OUTPUT="$vimlint_output" \
        "$test_vim" \
            -Nu NONE \
            -i NONE \
            -n -N -es \
            -V1"$vimlint_log" \
            --cmd 'execute "set runtimepath+=" . fnameescape($CHOPSTICKS_VIMLINT_DIR)' \
            --cmd 'execute "set runtimepath+=" . fnameescape($CHOPSTICKS_VIMPARSER_DIR)' \
            --cmd 'let g:vimlint#config = {"quiet": 1, "parse_py": 1}' \
            -c 'call vimlint#vimlint($CHOPSTICKS_VIMLINT_FILE, {"output": $CHOPSTICKS_VIMLINT_OUTPUT})' \
            -c 'qall!'
    then
        printf 'vimlint failed to run\n' >&2
        sed 's/^/  /' "$vimlint_log" >&2
        exit 1
    fi
    if grep -E -a -w 'Error|Warning' \
        "$vimlint_output" >/dev/null 2>&1
    then
        printf 'vimlint reported issues\n' >&2
        sed 's/^/  /' "$vimlint_output" >&2
        exit 1
    fi
fi

# vimlint parses legacy script only and cannot read `vim9script`, so Vim9
# modules are checked with :defcompile instead, which compiles every def in
# the script it runs inside and reports Vim9 type and syntax errors.
# :defcompile only compiles the script it runs inside: sourcing a module
# directly from the command line and running :defcompile afterward compiles
# the command line's own (empty) script, not the module, and silently misses
# every error in it. Copying the module and appending the directive to the
# copy puts :defcompile inside the module's own script context, where it
# actually checks it.
vim9_copy_counter=0
lint_vim9_file() {
    vim9_source=$1
    vim9_copy_counter=$((vim9_copy_counter + 1))
    vim9_copy=$test_root/vim9-$vim9_copy_counter.vim
    cp "$vim9_source" "$vim9_copy"
    printf '\ndefcompile\n' >>"$vim9_copy"
    vim9_copy_for_vim=$(path_for_vim "$vim9_copy")
    vim9_root_for_vim=$(path_for_vim "$chopsticks_root")
    vim9_log=$vim9_copy.log
    vim9_log_for_vim=$(path_for_vim "$vim9_log")
    vim9_error=$vim9_copy.error
    rm -f "$vim9_error"
    vim9_error_for_vim=$(path_for_vim "$vim9_error")
    # The dollar-prefixed names below are Vim environment lookups, not shell
    # expansions, so the single quotes are intentional. Paths travel through
    # the environment and are escaped with fnameescape() inside Vim, as the
    # vimlint invocation above does, rather than being spliced into the
    # command strings: :set and :source both split unescaped arguments on
    # whitespace, and this repo's own test fixtures include a
    # space-containing path.
    # shellcheck disable=SC2016
    if ! env \
        CHOPSTICKS_VIM9_ROOT="$vim9_root_for_vim" \
        CHOPSTICKS_VIM9_FILE="$vim9_copy_for_vim" \
        CHOPSTICKS_VIM9_ERROR="$vim9_error_for_vim" \
        "$test_vim" \
            -Nu NONE -i NONE -n -N -es \
            -V1"$vim9_log_for_vim" \
            --cmd 'execute "set runtimepath^=" . fnameescape($CHOPSTICKS_VIM9_ROOT)' \
            -c 'try | execute "source " . fnameescape($CHOPSTICKS_VIM9_FILE) | catch | call writefile([v:exception, v:throwpoint], $CHOPSTICKS_VIM9_ERROR) | cquit | endtry' \
            -c 'qall!' >/dev/null 2>&1
    then
        printf 'vim9 compile failed: %s\n' "$vim9_source" >&2
        # The exception itself, which is the part that names the construct
        # Vim refused. Without this the report is just a filename, which is
        # what it gave the first time this fired on a Vim older than the
        # developer's.
        if [ -s "$vim9_error" ]; then
            sed 's/^/  /' "$vim9_error" >&2
        fi
        if [ -s "$vim9_log" ]; then
            printf '  --- verbose log tail ---\n' >&2
            tail -20 "$vim9_log" | sed 's/^/  /' >&2
        fi
        return 1
    fi
    return 0
}

vim9_failed=0
for vim9_candidate in \
    "$chopsticks_root"/plugin/*.vim \
    "$chopsticks_root"/autoload/chopsticks/*.vim \
    "$chopsticks_root"/autoload/chopsticks/*/*.vim \
    "$chopsticks_root"/lang/*.vim
do
    [ -f "$vim9_candidate" ] || continue
    lint_vim9_file "$vim9_candidate" || vim9_failed=1
done
if [ "$vim9_failed" -ne 0 ]; then
    exit 1
fi

run_ui_test() {
    test_case=$1
    shift
    if [ "$ui_test_cases" != all ]; then
        case " $ui_test_cases " in
            *" $test_case "*) ;;
            *) return 0 ;;
        esac
    fi
    ui_test_count=$((ui_test_count + 1))
    test_home=$test_root/home-$test_case
    test_completed=$test_root/$test_case.completed
    rm -f "$test_completed"
    test_completed_for_vim=$(path_for_vim "$test_completed")
    test_errors=$test_root/$test_case.errors
    test_log=$test_root/$test_case.log
    test_screen=$test_root/$test_case.screen
    test_home_for_vim=$(path_for_vim "$test_home")
    test_errors_for_vim=$(path_for_vim "$test_errors")
    test_log_for_vim=$(path_for_vim "$test_log")
    test_vimrc=$(path_for_vim "$chopsticks_root/.vimrc")
    test_ui_script=$(path_for_vim "$chopsticks_root/tests/ui.vim")
    test_data_dir_for_vim=$(path_for_vim \
        "${CHOPSTICKS_TEST_DATA_DIR:-}")
    test_session_dir_for_vim=$(path_for_vim \
        "${CHOPSTICKS_TEST_SESSION_DIR:-}")
    test_local_config_for_vim=$(path_for_vim \
        "${CHOPSTICKS_TEST_LOCAL_CONFIG:-}")
    # -es is silent Ex mode, and a case that opens the dashboard dies there
    # with status 0 -- silently, before tests/ui.vim reaches the end where it
    # would report anything v:errors had collected. Cases that open one run
    # with --not-a-term instead, which is headless without that behaviour.
    test_mode=-es
    if [ "$test_case" = dashboard-wide ]; then
        test_mode=--not-a-term
    fi
    mkdir -p "$test_home"

    if ! env \
        HOME="$test_home_for_vim" \
        USERPROFILE="$test_home_for_vim" \
        XDG_CACHE_HOME= \
        XDG_CONFIG_HOME= \
        XDG_DATA_HOME= \
        XDG_STATE_HOME= \
        COLORTERM=truecolor \
        TERM=xterm-256color \
        TERM_PROGRAM=WezTerm \
        SSH_CLIENT= \
        SSH_CONNECTION= \
        SSH_TTY= \
        CHOPSTICKS_TEST_CASE="$test_case" \
        CHOPSTICKS_TEST_DATA_DIR="$test_data_dir_for_vim" \
        CHOPSTICKS_TEST_ERRORS="$test_errors_for_vim" \
        CHOPSTICKS_TEST_COMPLETED="$test_completed_for_vim" \
        CHOPSTICKS_TEST_LOCAL_CONFIG="$test_local_config_for_vim" \
        CHOPSTICKS_TEST_SESSION_DIR="$test_session_dir_for_vim" \
        "$test_vim" \
            -Nu "$test_vimrc" \
            -i NONE \
            -n "$test_mode" \
            -V1"$test_log_for_vim" \
            "$@" \
            -S "$test_ui_script" \
            >"$test_screen" 2>&1
    then
        printf 'headless UI test failed: %s\n' "$test_case" >&2
        if [ -s "$test_errors" ]; then
            sed 's/^/  /' "$test_errors" >&2
        elif [ -s "$test_log" ]; then
            sed 's/^/  /' "$test_log" >&2
        fi
        # An assertion on v:errmsg reports the message but not where it came
        # from, which is the part that matters when a platform raises an error
        # nothing else does. The verbose log keeps that context.
        if [ -s "$test_log" ]; then
            if grep -n 'E[0-9][0-9]*:' "$test_log" >/dev/null 2>&1; then
                printf '  --- verbose log around the first Vim error ---\n' >&2
                grep -n -B10 -m1 'E[0-9][0-9]*:' "$test_log" \
                    | sed 's/^/  /' >&2
            fi
        fi
        return 1
    fi
    # Vim exiting 0 is not proof the case ran: an early :qall -- from a
    # mapping a case triggers, say -- quits silently with no assertions
    # recorded, which is indistinguishable from success. tests/ui.vim writes
    # this marker as its last act, so a missing one means the script did not
    # reach the end and the case tested nothing.
    if [ ! -s "$test_completed" ]; then
        case " $known_incomplete_ui_tests " in
            *" $test_case "*)
                printf 'warning: UI test %s quit early (known)\n' \
                    "$test_case" >&2
                return 0
                ;;
        esac
        printf 'headless UI test never completed: %s\n' "$test_case" >&2
        printf '  tests/ui.vim exited before its completion marker.\n' >&2
        if [ -s "$test_log" ]; then
            printf '  --- tail of the verbose log ---\n' >&2
            tail -20 "$test_log" | sed 's/^/  /' >&2
        fi
        return 1
    fi
}

# Every run_ui_test case above starts Vim with -Nu pointing straight at
# .vimrc, which leaves $MYVIMRC empty, so .vimrc's own fallback
# (`if empty($MYVIMRC) | let $MYVIMRC = expand('<sfile>:p') | endif`) sets it
# to .vimrc's own real path. That is why those cases could never have caught
# the regression where .vimrc derived its own directory from $MYVIMRC: the
# documented install (README.md) symlinks .vimrc into $HOME, so a real user's
# $MYVIMRC names the symlink, not this repository, and deriving the
# repository root from it silently prepends $HOME to 'runtimepath' instead.
# This case starts Vim the way that install does -- a real ~/.vimrc symlink,
# discovered by Vim on its own rather than named with -u -- so it exercises
# the case every other one structurally cannot.
#
# -es (silent Ex mode, what every other case uses) cannot be reused here:
# per `:help -s-ex`, "Initializations are skipped (except the ones given with
# the -u argument)", so -es never reads a discovered vimrc at all regardless
# of $HOME -- it would silently pass this case without exercising anything.
# --not-a-term keeps this headless without silent Ex mode's initialization
# skip; the 'dashboard-wide' case above already establishes that combination
# is safe for this harness.
run_symlink_ui_test() {
    test_case=symlink-install
    if [ "$ui_test_cases" != all ]; then
        case " $ui_test_cases " in
            *" $test_case "*) ;;
            *) return 0 ;;
        esac
    fi
    test_home=$test_root/home-$test_case
    test_completed=$test_root/$test_case.completed
    rm -f "$test_completed"
    test_completed_for_vim=$(path_for_vim "$test_completed")
    test_errors=$test_root/$test_case.errors
    test_log=$test_root/$test_case.log
    test_screen=$test_root/$test_case.screen
    test_home_for_vim=$(path_for_vim "$test_home")
    test_errors_for_vim=$(path_for_vim "$test_errors")
    test_log_for_vim=$(path_for_vim "$test_log")
    test_ui_script=$(path_for_vim "$chopsticks_root/tests/ui.vim")
    mkdir -p "$test_home"

    if ! ln -s "$chopsticks_root/.vimrc" "$test_home/.vimrc" 2>"$test_errors"
    then
        # Creating a symlink can require a privilege the runner does not
        # grant (this is precisely why README.md's Windows install writes a
        # forwarding _vimrc instead of symlinking). That is an environment
        # limitation, not a chopsticks regression, so it is reported and
        # skipped rather than failed.
        printf 'symlink-install: skipped, could not create a symlink\n' >&2
        sed 's/^/  /' "$test_errors" >&2
        : >"$test_errors"
        return 0
    fi
    ui_test_count=$((ui_test_count + 1))

    if ! env \
        HOME="$test_home_for_vim" \
        USERPROFILE="$test_home_for_vim" \
        XDG_CACHE_HOME= \
        XDG_CONFIG_HOME= \
        XDG_DATA_HOME= \
        XDG_STATE_HOME= \
        COLORTERM=truecolor \
        TERM=xterm-256color \
        TERM_PROGRAM=WezTerm \
        SSH_CLIENT= \
        SSH_CONNECTION= \
        SSH_TTY= \
        CHOPSTICKS_TEST_CASE="$test_case" \
        CHOPSTICKS_TEST_ERRORS="$test_errors_for_vim" \
        CHOPSTICKS_TEST_COMPLETED="$test_completed_for_vim" \
        "$test_vim" \
            -N \
            -i NONE \
            -n --not-a-term \
            -V1"$test_log_for_vim" \
            -S "$test_ui_script" \
            >"$test_screen" 2>&1
    then
        printf 'headless UI test failed: %s\n' "$test_case" >&2
        if [ -s "$test_errors" ]; then
            sed 's/^/  /' "$test_errors" >&2
        elif [ -s "$test_log" ]; then
            sed 's/^/  /' "$test_log" >&2
        fi
        if [ -s "$test_log" ]; then
            if grep -n 'E[0-9][0-9]*:' "$test_log" >/dev/null 2>&1; then
                printf '  --- verbose log around the first Vim error ---\n' >&2
                grep -n -B10 -m1 'E[0-9][0-9]*:' "$test_log" \
                    | sed 's/^/  /' >&2
            fi
        fi
        return 1
    fi
    # Same reasoning as run_ui_test: exiting 0 is not proof the case ran,
    # and this is the case that guards the documented symlink install, so
    # it is the last one that should be allowed to pass by quitting early.
    if [ ! -s "$test_completed" ]; then
        printf 'headless UI test never completed: %s\n' "$test_case" >&2
        printf '  tests/ui.vim exited before its completion marker.\n' >&2
        return 1
    fi
}

run_ui_test default
run_ui_test default-dashboard
run_ui_test minimal \
    --cmd "let g:chopsticks_ui_density = 'minimal'"
run_ui_test rich \
    --cmd "let g:chopsticks_ui_density = 'rich'"
run_ui_test density \
    --cmd 'let g:chopsticks_icons = 1'
run_ui_test status-context \
    --cmd 'let g:chopsticks_icons = 0'
run_ui_test tabline-width \
    --cmd 'let g:chopsticks_icons = 1'
run_ui_test transparent \
    --cmd "let g:chopsticks_colorscheme = 'industry'" \
    --cmd 'let g:chopsticks_transparent_background = 1'
run_ui_test opaque \
    --cmd "let g:chopsticks_colorscheme = 'industry'" \
    --cmd 'let g:chopsticks_transparent_background = 0'
run_ui_test theme-valid \
    --cmd "let g:chopsticks_colorscheme = 'industry'"
run_ui_test theme-fallback \
    --cmd "let g:chopsticks_colorscheme = '__chopsticks_missing__'"
run_ui_test dashboard-off \
    --cmd "let g:chopsticks_ui_density = 'rich'" \
    --cmd 'let g:chopsticks_dashboard = 0' \
    README.md
run_ui_test dashboard-on \
    --cmd "let g:chopsticks_ui_density = 'minimal'" \
    --cmd 'let g:chopsticks_dashboard = 1'
run_ui_test dashboard-wide \
    --cmd "let g:chopsticks_ui_density = 'rich'" \
    --cmd 'let g:chopsticks_icons = 0'
run_ui_test bufferline-off \
    --cmd "let g:chopsticks_ui_density = 'rich'" \
    --cmd 'let g:chopsticks_bufferline = 0'
run_ui_test bufferline-on \
    --cmd "let g:chopsticks_ui_density = 'minimal'" \
    --cmd 'let g:chopsticks_bufferline = 1'

CHOPSTICKS_TEST_DATA_DIR=$test_root/'custom data dir'
CHOPSTICKS_TEST_SESSION_DIR=$test_root/'explicit session dir'
CHOPSTICKS_TEST_LOCAL_CONFIG=$test_root/'explicit local config.vim'
export CHOPSTICKS_TEST_DATA_DIR
export CHOPSTICKS_TEST_SESSION_DIR
export CHOPSTICKS_TEST_LOCAL_CONFIG
mkdir -p "$CHOPSTICKS_TEST_DATA_DIR/autoload"
printf '%s\n' \
    "let g:chopsticks_test_local_config = 'loaded-from-data-dir'" \
    >"$CHOPSTICKS_TEST_DATA_DIR/chopsticks.local.vim"
printf '%s\n' \
    'function! plug#begin(directory) abort' \
    '    let g:chopsticks_test_plug_directory = a:directory' \
    '    let g:chopsticks_test_plugin_count = 0' \
    '    command! -nargs=+ Plug let g:chopsticks_test_plugin_count += 1' \
    'endfunction' \
    'function! plug#end() abort' \
    '    silent! delcommand Plug' \
    'endfunction' \
    >"$CHOPSTICKS_TEST_DATA_DIR/autoload/plug.vim"
printf '%s\n' \
    "let g:chopsticks_test_local_config = 'loaded-from-explicit-path'" \
    >"$CHOPSTICKS_TEST_LOCAL_CONFIG"

# The dollar-prefixed names below are Vim environment lookups.
# shellcheck disable=SC2016
run_ui_test data-dir-override \
    --cmd 'let g:chopsticks_data_dir = $CHOPSTICKS_TEST_DATA_DIR' \
    --cmd 'let g:chopsticks_dashboard = 0'
run_ui_test data-dir-invalid-type \
    --cmd 'let g:chopsticks_data_dir = []' \
    --cmd 'let g:chopsticks_dashboard = 0'
run_ui_test data-dir-empty \
    --cmd "let g:chopsticks_data_dir = ''" \
    --cmd 'let g:chopsticks_dashboard = 0'
# shellcheck disable=SC2016
run_ui_test path-overrides \
    --cmd 'let g:chopsticks_data_dir = $CHOPSTICKS_TEST_DATA_DIR' \
    --cmd 'let g:chopsticks_local_config = $CHOPSTICKS_TEST_LOCAL_CONFIG' \
    --cmd 'let g:chopsticks_session_dir = $CHOPSTICKS_TEST_SESSION_DIR' \
    --cmd 'let g:chopsticks_dashboard = 0'
# shellcheck disable=SC2016
run_ui_test fzf-unavailable \
    --cmd 'let $PATH = ""' \
    --cmd 'command! Files echoerr "fzf command executed"' \
    --cmd 'command! GFiles echoerr "fzf command executed"' \
    --cmd 'command! History echoerr "fzf command executed"' \
    --cmd 'command! Rg echoerr "fzf command executed"' \
    --cmd 'let g:chopsticks_dashboard = 0'
run_ui_test session \
    --cmd "let g:chopsticks_session_dir = '~/.chopsticks-session-tests'" \
    --cmd 'let g:chopsticks_dashboard = 0'
run_ui_test health
run_ui_test keys
run_ui_test markdown
run_symlink_ui_test

if [ "$ui_test_count" -eq 0 ]; then
    printf 'no UI tests matched CHOPSTICKS_TEST_UI_CASES=%s\n' \
        "$ui_test_cases" >&2
    exit 2
fi
