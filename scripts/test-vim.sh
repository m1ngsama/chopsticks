#!/usr/bin/env bash
# Vim smoke tests. Requires plugins in ~/.vim/plugged.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/test-common.sh
source "$SCRIPT_DIR/test-common.sh"
set -E

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

has_chopsticks_truecolor_env() {
    [ "${COLORTERM:-}" = "truecolor" ] || [ "${COLORTERM:-}" = "24bit" ]
}

dump_vim_status_diagnostics() {
    local status_file="$TMP_ROOT/status-default.txt"
    local diag_file="$TMP_ROOT/status-diagnostics.txt"

    echo "Status/info diagnostics:" >&2
    echo "TERM=${TERM:-} COLORTERM=${COLORTERM:-}" >&2
    vim --version | sed -n '1,80p' >&2 || true

    if [ -s "$status_file" ]; then
        echo "--- status-default.txt ---" >&2
        cat "$status_file" >&2
    fi

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c "redir! > $diag_file" \
        -c 'silent echo "features terminal=" . has("terminal") . " job=" . has("job") . " timers=" . has("timers") . " popupwin=" . (has("popupwin") || has("patch-8.1.1517")) . " clipboard=" . has("clipboard") . " termguicolors=" . exists("&termguicolors")' \
        -c 'silent echo "runtime=" . string(ChopsticksRuntimeInfo().items)' \
        -c 'silent echo "ui=" . string(ChopsticksUiInfo().items)' \
        -c 'silent echo "completion=" . string(ChopsticksCompletionInfo().items)' \
        -c 'silent echo "lsp_stack=" . string(ChopsticksLspInfo().stack)' \
        -c 'silent echo "health=" . string(ChopsticksHealthInfo().summary_line)' \
        -c 'redir END' \
        -c 'qa!' 2>&1 || true

    if [ -s "$diag_file" ]; then
        echo "--- status-diagnostics.txt ---" >&2
        cat "$diag_file" >&2
    fi
}

dump_vim_keymap_diagnostics() {
    local diag_script="$TMP_ROOT/keymap-diagnostics.vim"
    local diag_file="$TMP_ROOT/keymap-diagnostics.txt"

    echo "Keymap diagnostics:" >&2
    echo "Keymap phase=${CHOPSTICKS_TEST_KEYMAP_PHASE:-unknown}" >&2
    echo "TERM=${TERM:-} COLORTERM=${COLORTERM:-}" >&2
    vim --version | sed -n '1,80p' >&2 || true

    local keymap_file
    for keymap_file in \
        "$TMP_ROOT/status-keymap-audit.txt" \
        "$TMP_ROOT/status-keymap-audit-broken.txt"
    do
        if [ -s "$keymap_file" ]; then
            echo "--- $(basename "$keymap_file") ---" >&2
            cat "$keymap_file" >&2
        fi
    done

    cat > "$diag_script" <<'VIM'
execute 'redir! > ' . fnameescape(g:chopsticks_diag_file)
silent echo 'features terminal=' . has('terminal') . ' clipboard=' . has('clipboard') . ' termguicolors=' . exists('&termguicolors')
silent echo 'leaders mapleader=' . string(exists('mapleader') ? mapleader : '<unset>') . ' maplocalleader=' . string(exists('maplocalleader') ? maplocalleader : '<unset>')
silent echo 'auto-pairs registered=' . has_key(get(g:, 'plugs', {}), 'auto-pairs')
let s:last_change_map = nr2char(96) . '[v' . nr2char(96) . ']'
let s:checks = [
    \ ['reserved n 0 empty', maparg('0', 'n') ==# ''],
    \ ['reserved v 0 empty', maparg('0', 'v') ==# ''],
    \ ['reserved n Y empty', maparg('Y', 'n') ==# ''],
    \ ['reserved n Q empty', maparg('Q', 'n') ==# ''],
    \ ['reserved n Space empty', maparg('<Space>', 'n') ==# ''],
    \ ['reserved v // empty', maparg('//', 'v') ==# ''],
    \ ['reserved n gV empty', maparg('gV', 'n') ==# ''],
    \ ['opt-in i jk empty', maparg('jk', 'i') ==# ''],
    \ ['opt-in n C-s empty', maparg('<C-s>', 'n') ==# ''],
    \ ['opt-in i C-s empty', maparg('<C-s>', 'i') ==# ''],
    \ ['opt-in n C-p empty', maparg('<C-p>', 'n') ==# ''],
    \ ['opt-in c C-p empty', maparg('<C-p>', 'c') ==# ''],
    \ ['opt-in c C-n empty', maparg('<C-n>', 'c') ==# ''],
    \ ['opt-in c w!! empty', maparg('w!!', 'c') ==# ''],
    \ ['window n C-h NavigateWindow', maparg('<C-h>', 'n') =~# 'NavigateWindow'],
    \ ['window n C-j NavigateWindow', maparg('<C-j>', 'n') =~# 'NavigateWindow'],
    \ ['window n C-k NavigateWindow', maparg('<C-k>', 'n') =~# 'NavigateWindow'],
    \ ['window n C-l NavigateWindow', maparg('<C-l>', 'n') =~# 'NavigateWindow'],
    \ ['no auto-pairs plugin', !has_key(get(g:, 'plugs', {}), 'auto-pairs')],
    \ ['default i Tab no completion', maparg('<Tab>', 'i') !~# 'pumvisible'],
    \ ['default i S-Tab no completion', maparg('<S-Tab>', 'i') !~# 'pumvisible'],
    \ ['default i CR no asyncomplete', maparg('<CR>', 'i') !~# 'asyncomplete#close_popup'],
    \ ['default i CR no AutoPairs', maparg('<CR>', 'i') !~# 'AutoPairs'],
    \ ['default t EscEsc empty', maparg('<Esc><Esc>', 't') ==# ''],
    \ ['default t C-h empty', maparg('<C-h>', 't') ==# ''],
    \ ['default t C-j empty', maparg('<C-j>', 't') ==# ''],
    \ ['default t C-k empty', maparg('<C-k>', 't') ==# ''],
    \ ['default t C-l empty', maparg('<C-l>', 't') ==# ''],
    \ ['jump n s easymotion', maparg('s', 'n') =~# 'easymotion-overwin-f2'],
    \ ['space v / escape', maparg('<Space>/', 'v') =~# 'escape'],
    \ ['space n v last visual change', maparg('<Space>v', 'n') ==# s:last_change_map],
    \ ['space n SpaceSpace files', maparg('<Space><Space>', 'n') =~# 'SmartFiles'],
    \ ['space n SpaceTab alternate', maparg('<Space><Tab>', 'n') =~# 'Balternate'],
    \ ['space n z maximize', maparg('<Space>z', 'n') =~# 'ToggleMaximize'],
    \ ['classic v ,/ empty', maparg(',/', 'v') ==# ''],
    \ ['classic n ,v empty', maparg(',v', 'n') ==# ''],
    \ ['classic n ,ff empty', maparg(',ff', 'n') ==# ''],
    \ ]
for s:check in s:checks
    silent echo 'check ' . (s:check[1] ? 'OK   ' : 'FAIL ') . s:check[0]
endfor
let s:maps = [
    \ ['n', '0'], ['v', '0'], ['n', 'Y'], ['n', 'Q'],
    \ ['n', '<Space>'], ['v', '//'], ['n', 'gV'], ['i', 'jk'],
    \ ['n', '<C-s>'], ['i', '<C-s>'], ['n', '<C-p>'],
    \ ['c', '<C-p>'], ['c', '<C-n>'], ['c', 'w!!'],
    \ ['n', '<C-h>'], ['n', '<C-j>'], ['n', '<C-k>'], ['n', '<C-l>'],
    \ ['i', '<Tab>'], ['i', '<S-Tab>'], ['i', '<CR>'],
    \ ['t', '<Esc><Esc>'], ['t', '<C-h>'], ['t', '<C-j>'], ['t', '<C-k>'], ['t', '<C-l>'],
    \ ['n', 's'], ['v', '<Space>/'], ['n', '<Space>v'],
    \ ['n', '<Space><Space>'], ['n', '<Space><Tab>'], ['n', '<Space>z'],
    \ ['v', ',/'], ['n', ',v'], ['n', ',ff'],
    \ ]
for s:item in s:maps
    silent echo 'map ' . s:item[0] . ' ' . s:item[1] . ' rhs=' . string(maparg(s:item[1], s:item[0])) . ' dict=' . string(maparg(s:item[1], s:item[0], 0, 1))
endfor
silent echo 'contract project files=' . string(ChopsticksKeymapContractKeys('project_files'))
silent echo 'contract visible jump=' . string(ChopsticksKeymapContractKeys('visible_jump_summary'))
silent echo 'audit issues=' . string(ChopsticksKeymapAuditIssues())
silent echo 'audit info=' . string(ChopsticksKeymapAuditInfo())
redir END
qa!
VIM

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c "let g:chopsticks_diag_file = '$diag_file'" \
        -S "$diag_script" 2>&1 || true

    if [ -s "$diag_file" ]; then
        echo "--- keymap-diagnostics.txt ---" >&2
        cat "$diag_file" >&2
    fi
}

on_error() {
    local status=$?
    case "${CHOPSTICKS_TEST_STEP:-}" in
        status_info)
            CHOPSTICKS_TEST_STEP=
            dump_vim_status_diagnostics || true
            ;;
        keymap)
            CHOPSTICKS_TEST_STEP=
            dump_vim_keymap_diagnostics || true
            ;;
    esac
    exit "$status"
}
trap on_error ERR

check_vim() {
    step "Vim smoke tests"
    need vim
    check_plugin_dirs

    step "Startup and plugin reproducibility"
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

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksPluginInfo") || !get(g:, "chopsticks_pin_plugins", 0) | cquit | endif' \
        -c 'if get(g:, "chopsticks_plugin_lock_count", 0) < 20 | cquit | endif' \
        -c 'let g:plugin_info = ChopsticksPluginInfo() | if get(g:plugin_info, "title", "") !=# "plugin reproducibility" || !ChopsticksInfoShapeIssue(g:plugin_info, "ChopsticksPluginInfo()").ok || g:plugin_info.declared_count < 20 || g:plugin_info.lock_count < 20 | cquit | endif' \
        -c 'if !g:plugin_info.all_active_locked || !g:plugin_info.all_active_pinned || len(get(g:plugin_info, "details", [])) != 2 || len(get(g:plugin_info, "items", [])) != 3 | cquit | endif' \
        -c 'if get(g:plugin_info.items[0], "label", "") !=# "lock coverage" || get(g:plugin_info.items[0], "severity", "") !=# "attention" || get(g:plugin_info.items[0], "action", "") !~# "plugin_locks" || get(g:plugin_info.items[1], "label", "") !=# "applied pins" || get(g:plugin_info.items[1], "severity", "") !=# "attention" || get(g:plugin_info.items[1], "action", "") !~# "ChopsticksLockedPlugOpts" || get(g:plugin_info.items[2], "label", "") !=# "installed plugins" || get(g:plugin_info.items[2], "severity", "") !=# "setup" || get(g:plugin_info.items[2], "action", "") !=# ":PlugInstall" | cquit | endif' \
        -c 'if get(g:plugs["fzf"], "commit", "") ==# "" | cquit | endif' \
        -c 'if get(g:plugs["vim-lsp"], "commit", "") ==# "" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_pin_plugins = 0' \
        -c 'source .vimrc' \
        -c 'let g:plugin_info = ChopsticksPluginInfo() | let g:profile_info = ChopsticksProfileInfo() | if g:plugin_info.pinning_enabled || g:plugin_info.all_active_pinned || get(g:plugin_info.items[1], "state", "") !=# "off" || get(g:plugin_info.items[1], "diagnostic", 1) || len(get(g:profile_info, "items", [])) != 1 || get(g:profile_info.items[0], "label", "") !=# "plugin locks" || get(g:profile_info.items[0], "severity", "") !=# "info" || get(g:profile_info.items[0], "action", "") !~# "pin_plugins" | cquit | endif' \
        -c 'if get(g:plugs["fzf"], "commit", "") !=# "" | cquit | endif' \
        -c 'if get(g:plugs["vim-lsp"], "commit", "") !=# "" | cquit | endif' \
        -c 'qa!' 2>&1

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
        -c 'if search("chopsticks-space", "n") == 0 | cquit | endif' \
        -c 'qa!' 2>&1

    step "Profiles and local config"
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
        -c 'let g:local_config = ChopsticksLocalConfigInfo() | if !g:local_config.ok || !g:local_config.loaded || g:local_config.source !=# "override" | cquit | endif' \
        -c 'if len(get(g:local_config, "details", [])) != 3 || len(get(g:local_config, "items", [])) != 1 || get(g:local_config.items[0], "label", "") !=# "local config" || get(g:local_config.items[0], "state", "") !=# "ready" || get(g:local_config.items[0], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    mkdir -p "$TMP_ROOT/xdg"
    printf "%s\n" "let g:chopsticks_profile = 'minimal'" > "$TMP_ROOT/xdg/chopsticks.vim"
    XDG_CONFIG_HOME="$TMP_ROOT/xdg" vim -u NONE -i NONE -es -N \
        -c 'source .vimrc' \
        -c 'if g:chopsticks_resolved_local_config !~# "chopsticks.vim$" || g:chopsticks_profile !=# "minimal" || has_key(g:plugs, "ale") || has_key(g:plugs, "vim-lsp") || has_key(g:plugs, "auto-pairs") | cquit | endif' \
        -c 'let g:local_config = ChopsticksLocalConfigInfo() | if !g:local_config.ok || !g:local_config.loaded || g:local_config.source !=# "xdg" | cquit | endif' \
        -c 'if len(get(g:local_config, "details", [])) != 3 || get(g:local_config.items[0], "state", "") !=# "ready" | cquit | endif' \
        -c 'qa!' 2>&1

    mkdir -p "$TMP_ROOT/bad-local"
    printf "%s\n" "let g:chopsticks_profile = 'minimal'" \
        "throw 'broken local config'" > "$TMP_ROOT/bad-local/chopsticks.vim"
    XDG_CONFIG_HOME="$TMP_ROOT/bad-local" vim -u NONE -i NONE -es -N \
        -c 'source .vimrc' \
        -c 'let g:local_config = ChopsticksLocalConfigInfo() | if g:local_config.ok || g:local_config.loaded | cquit | endif' \
        -c 'if g:local_config.error !~# "broken local config" || len(get(g:local_config, "details", [])) != 4 || get(g:local_config.items[0], "state", "") !=# "missing" || !get(g:local_config.items[0], "diagnostic", 0) || get(g:local_config.items[0], "severity", "") !=# "attention" || get(g:local_config.items[0], "action", "") !=# ":ChopsticksConfig" | cquit | endif' \
        -c 'if ChopsticksHealthInfo().summary.attention < 1 | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-bad-local.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq '── local preferences ──' "$TMP_ROOT/status-bad-local.txt"
    grep -Fq 'broken local config' "$TMP_ROOT/status-bad-local.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_profile = "bad-profile"' \
        -c 'let g:chopsticks_keymap_style = "bad-keymap"' \
        -c 'source .vimrc' \
        -c 'let g:profile_info = ChopsticksProfileInfo() | if g:profile_info.profile !=# "engineer" || g:profile_info.keymap !=# "space" | cquit | endif' \
        -c 'if g:profile_info.profile_valid || g:profile_info.keymap_valid || len(get(g:profile_info, "details", [])) != 7 || len(get(g:profile_info, "items", [])) != 2 || get(g:profile_info.items[0], "label", "") !=# "requested profile" || get(g:profile_info.items[0], "value", "") !=# "bad-profile" || get(g:profile_info.items[0], "severity", "") !=# "attention" || get(g:profile_info.items[0], "issue_label", "") !=# "profile value" || get(g:profile_info.items[0], "action", "") !~# "chopsticks_profile" || get(g:profile_info.items[1], "label", "") !=# "requested keymap" || get(g:profile_info.items[1], "issue_label", "") !=# "keymap value" || get(g:profile_info.items[1], "action", "") !~# "keymap_style" | cquit | endif' \
        -c 'if ChopsticksHealthInfo().summary.attention < 2 | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-invalid-profile.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq 'requested profile  bad-profile  (using engineer)' \
        "$TMP_ROOT/status-invalid-profile.txt"
    grep -Fq 'requested keymap  bad-keymap  (using space)' \
        "$TMP_ROOT/status-invalid-profile.txt"

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

    step "Core project loop surfaces"
    step "Runner surface"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksRunnerInfo") | cquit | endif' \
        -c 'let g:run_keys = ChopsticksKeymapContractKeys("project_run") | let g:runner = ChopsticksRunnerInfo() | if join(g:run_keys, "/") !=# "SPC rr" || get(g:runner, "title", "") !=# "run file" || !ChopsticksInfoShapeIssue(g:runner, "ChopsticksRunnerInfo()").ok || get(g:runner, "keymap", "") !=# "SPC rr" || get(g:runner.details[0], "value", "") !=# "SPC rr" || !empty(get(g:runner, "missing_maps", [])) || len(get(g:runner, "details", [])) != 3 || len(get(g:runner, "items", [])) != 1 || get(g:runner.items[0], "state", "") !=# "off" || get(g:runner.items[0], "reason", "") !=# "no filetype" || get(g:runner.items[0], "diagnostic", 1) || get(g:runner, "supported", "") !~# "python" || get(g:runner, "supported", "") !~# "c" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! nunmap <Space>rr' \
        -c 'let g:runner = ChopsticksRunnerInfo() | let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if get(g:runner.items[0], "state", "") !=# "missing" || stridx(get(g:runner.items[0], "detail", ""), "SPC rr") < 0 || g:keymap.ok || empty(filter(copy(g:health.issues), "v:val.code ==# \"runner.run-keymap\" && stridx(v:val.detail, \"SPC rr\") >= 0")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim --cmd 'let g:chopsticks_keymap_style = "classic"' \
        -u .vimrc -i NONE -es -N \
        -c 'let g:run_keys = ChopsticksKeymapContractKeys("project_run") | let g:runner = ChopsticksRunnerInfo() | if join(g:run_keys, "/") !=# ",cr" || get(g:runner, "keymap", "") !=# ",cr" || get(g:runner.details[0], "value", "") !=# ",cr" || !empty(get(g:runner, "missing_maps", [])) | cquit | endif' \
        -c 'qa!' 2>&1

    step "Editing assist surface"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksEditingInfo") | cquit | endif' \
        -c 'let g:visible_jump_keys = ChopsticksKeymapContractKeys("visible_jump_summary") | let g:cleanup_keys = ChopsticksKeymapContractKeys("edit_cleanup_summary") | let g:blank_line_keys = ChopsticksKeymapContractKeys("blank_lines") | let g:undo_keys = ChopsticksKeymapContractKeys("undo_tree") | if join(g:visible_jump_keys, " / ") !=# "s / SPC S" || join(g:cleanup_keys, "/") !=# "SPC cW/SPC sr/SPC =" || join(g:blank_line_keys, " ") !=# "[<Space> ]<Space>" || join(g:undo_keys, "/") !=# "SPC U" | cquit | endif' \
        -c 'let g:editing = ChopsticksEditingInfo() | if get(g:editing, "title", "") !=# "editing" || !ChopsticksInfoShapeIssue(g:editing, "ChopsticksEditingInfo()").ok || len(get(g:editing, "details", [])) != 3 || len(get(g:editing, "items", [])) != 5 || get(g:editing, "layout", "") !=# "space" | cquit | endif' \
        -c 'if get(g:editing.items[0], "label", "") !=# "visible jump" || get(g:editing.items[0], "state", "") !=# "ready" || get(g:editing.items[0], "reason", "") !=# "s / SPC S" || get(g:editing.items[0], "diagnostic", 1) | cquit | endif' \
        -c 'if get(g:editing.items[1], "label", "") !=# "undo tree" || get(g:editing.items[1], "state", "") !=# "ready" || get(g:editing.items[1], "reason", "") !=# "SPC U" || get(g:editing.items[1], "diagnostic", 1) | cquit | endif' \
        -c 'if get(g:editing.items[2], "label", "") !=# "edit cleanup" || get(g:editing.items[2], "state", "") !=# "ready" || get(g:editing.items[2], "reason", "") !=# "SPC cW/SPC sr/SPC =" || get(g:editing.items[2], "diagnostic", 1) | cquit | endif' \
        -c 'if get(g:editing.items[3], "label", "") !=# "blank lines" || get(g:editing.items[3], "state", "") !=# "ready" || get(g:editing.items[3], "diagnostic", 1) || get(g:editing.items[4], "label", "") !=# "full-file reindent" || get(g:editing.items[4], "state", "") !=# "off" || get(g:editing.items[4], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    step "Buffer lifecycle surface"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksBufferInfo") | cquit | endif' \
        -c 'let g:buffer_close_keys = ChopsticksKeymapContractKeys("buffer_close") | let g:buffer_navigation_keys = ChopsticksKeymapContractKeys("buffer_navigation") | let g:buffer_alternate_keys = ChopsticksKeymapContractKeys("buffer_alternate") | if join(g:buffer_close_keys, "/") !=# "SPC bd" || join(g:buffer_navigation_keys, "/") !=# "SPC bn/SPC bp" || join(g:buffer_alternate_keys, "/") !=# "SPC Tab" | cquit | endif' \
        -c 'let g:buffers = ChopsticksBufferInfo() | if get(g:buffers, "title", "") !=# "buffers" || !ChopsticksInfoShapeIssue(g:buffers, "ChopsticksBufferInfo()").ok || len(get(g:buffers, "details", [])) != 3 || len(get(g:buffers, "items", [])) != 3 || get(g:buffers, "listed_count", -1) < 1 || get(g:buffers, "alternate_buffer", 0) != -1 | cquit | endif' \
        -c 'if get(g:buffers.items[0], "label", "") !=# "buffer close" || get(g:buffers.items[0], "state", "") !=# "ready" || get(g:buffers.items[0], "diagnostic", 1) || get(g:buffers.items[1], "label", "") !=# "buffer navigation" || get(g:buffers.items[1], "state", "") !=# "ready" || get(g:buffers.items[1], "reason", "") !=# "SPC bn/SPC bp" || get(g:buffers.items[1], "diagnostic", 1) | cquit | endif' \
        -c 'if get(g:buffers.items[2], "label", "") !=# "alternate buffer" || get(g:buffers.items[2], "state", "") !=# "ready" || get(g:buffers.items[2], "reason", "") !=# "SPC Tab" || get(g:buffers.items[2], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    printf '%s\n' 'changed' > "$TMP_ROOT/bclose-safe.txt"
    step "Buffer close behavior"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        "$TMP_ROOT/bclose-safe.txt" \
        -c 'let g:bclose_buf = bufnr("%")' \
        -c 'call setline(1, "unsaved")' \
        -c 'Bclose' \
        -c 'if !buflisted(g:bclose_buf) || !getbufvar(g:bclose_buf, "&modified") | cquit | endif' \
        -c 'qa!' 2>&1

    printf '%s\n' 'first' > "$TMP_ROOT/bclose-first.txt"
    printf '%s\n' 'second' > "$TMP_ROOT/bclose-second.txt"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        "$TMP_ROOT/bclose-first.txt" \
        -c "edit $TMP_ROOT/bclose-second.txt" \
        -c 'let g:bclose_buf = bufnr("%")' \
        -c 'Bclose' \
        -c 'if buflisted(g:bclose_buf) || expand("%:t") !=# "bclose-first.txt" | cquit | endif' \
        -c 'qa!' 2>&1

    step "Quickfix and file safety surfaces"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksQuickfixInfo") | cquit | endif' \
        -c 'let g:quickfix_keys = ChopsticksKeymapContractKeys("quickfix_navigation") | let g:loclist_keys = ChopsticksKeymapContractKeys("loclist_navigation") | let g:qf = ChopsticksQuickfixInfo() | if join(g:quickfix_keys, " ") !=# "[q ]q" || join(g:loclist_keys, " ") !=# "[l ]l" || get(g:qf, "title", "") !=# "quickfix" || !ChopsticksInfoShapeIssue(g:qf, "ChopsticksQuickfixInfo()").ok || len(get(g:qf, "details", [])) != 3 || len(get(g:qf, "items", [])) != 4 || get(g:qf, "quickfix_count", -1) != 0 || get(g:qf, "loclist_count", -1) != 0 || !empty(get(g:qf, "missing_maps", [])) || !empty(get(g:qf, "missing_loc_maps", [])) || get(g:qf.items[0], "label", "") !=# "quickfix window" || get(g:qf.items[0], "state", "") !=# "ready" || get(g:qf.items[1], "label", "") !=# "location window" || get(g:qf.items[1], "state", "") !=# "ready" || get(g:qf.items[2], "label", "") !=# "quickfix navigation" || get(g:qf.items[2], "state", "") !=# "ready" || get(g:qf.items[2], "reason", "") !=# "[q ]q" || get(g:qf.items[2], "diagnostic", 1) || get(g:qf.items[3], "label", "") !=# "location navigation" || get(g:qf.items[3], "state", "") !=# "ready" || get(g:qf.items[3], "reason", "") !=# "[l ]l" || get(g:qf.items[3], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! nunmap [q' \
        -c 'let g:qf = ChopsticksQuickfixInfo() | let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if get(g:qf.items[2], "state", "") !=# "missing" || stridx(get(g:qf.items[2], "detail", ""), "[q") < 0 || g:keymap.ok || empty(filter(copy(g:health.issues), "v:val.code ==# \"quickfix.quickfix-navigation\" && stridx(v:val.detail, \"[q\") >= 0")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! nunmap ]l' \
        -c 'let g:qf = ChopsticksQuickfixInfo() | let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if get(g:qf.items[3], "state", "") !=# "missing" || stridx(get(g:qf.items[3], "detail", ""), "]l") < 0 || g:keymap.ok || empty(filter(copy(g:health.issues), "v:val.code ==# \"quickfix.location-navigation\" && stridx(v:val.detail, \"]l\") >= 0")) | cquit | endif' \
        -c 'qa!' 2>&1

    step "File safety surface"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksFileSafetyInfo") | cquit | endif' \
        -c 'let g:files = ChopsticksFileSafetyInfo() | if get(g:files, "title", "") !=# "file safety" || !ChopsticksInfoShapeIssue(g:files, "ChopsticksFileSafetyInfo()").ok || len(get(g:files, "details", [])) != 3 || len(get(g:files, "items", [])) != 3 || get(g:files.items[0], "label", "") !=# "write directory guard" || get(g:files.items[0], "state", "") !=# "ready" || get(g:files.items[1], "label", "") !=# "large file guard" || get(g:files.items[1], "state", "") !=# "ready" || get(g:files.items[1], "diagnostic", 1) || get(g:files.items[2], "label", "") !=# "current buffer" || get(g:files.items[2], "state", "") !=# "off" || get(g:files.items[2], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    step "Git and editor core surfaces"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksGitInfo") | cquit | endif' \
        -c 'let g:git_keys = ChopsticksKeymapContractKeys("git_keymaps") | let g:git_status_keys = ChopsticksKeymapContractKeys("git_status") | let g:git_commit_keys = ChopsticksKeymapContractKeys("git_commit") | let g:git_diff_keys = ChopsticksKeymapContractKeys("git_diff") | let g:git_blame_keys = ChopsticksKeymapContractKeys("git_blame") | let g:git_log_keys = ChopsticksKeymapContractKeys("git_log") | let g:git_conflict_keys = ChopsticksKeymapContractKeys("git_conflict_navigation") | if join(g:git_keys, "/") !=# "SPC gs/SPC gc/SPC gd/SPC gb/SPC gl" || join(g:git_status_keys, "/") !=# "SPC gs" || join(g:git_commit_keys, "/") !=# "SPC gc" || join(g:git_diff_keys, "/") !=# "SPC gd" || join(g:git_blame_keys, "/") !=# "SPC gb" || join(g:git_log_keys, "/") !=# "SPC gl" || join(g:git_conflict_keys, " ") !=# "[x ]x" | cquit | endif' \
        -c 'let g:git_commit_picker_keys = ChopsticksKeymapContractKeys("git_commit_picker") | let g:git_buffer_commit_picker_keys = ChopsticksKeymapContractKeys("git_buffer_commit_picker") | if join(g:git_commit_picker_keys, "/") !=# "SPC gC" || join(g:git_buffer_commit_picker_keys, "/") !=# "SPC gB" | cquit | endif' \
        -c 'let g:git = ChopsticksGitInfo() | if get(g:git, "title", "") !=# "git" || !ChopsticksInfoShapeIssue(g:git, "ChopsticksGitInfo()").ok || len(get(g:git, "details", [])) != 3 || len(get(g:git, "items", [])) != 5 || get(g:git.details[0], "value", "") !=# "SPC gs" || get(g:git.details[1], "value", "") !=# "SPC gl" || get(g:git.details[2], "value", "") ==# "none" || !empty(get(g:git, "missing_maps", [])) || !empty(get(g:git, "missing_conflict_maps", [])) || get(g:git.items[0], "label", "") !=# "git command" || get(g:git.items[0], "state", "") !=# "ready" || get(g:git.items[1], "label", "") !=# "fugitive" || get(g:git.items[1], "state", "") !=# "ready" || get(g:git.items[2], "label", "") !=# "gitgutter" || get(g:git.items[2], "state", "") !=# "ready" || get(g:git.items[3], "label", "") !=# "git keymaps" || get(g:git.items[3], "state", "") !=# "ready" || get(g:git.items[3], "reason", "") !=# "SPC gs" || get(g:git.items[4], "label", "") !=# "conflict navigation" || get(g:git.items[4], "state", "") !=# "ready" || get(g:git.items[4], "reason", "") !=# "[x ]x" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! nunmap <Space>gd' \
        -c 'let g:git = ChopsticksGitInfo() | let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if get(g:git.items[3], "state", "") !=# "missing" || stridx(get(g:git.items[3], "detail", ""), "SPC gd") < 0 || g:keymap.ok || empty(filter(copy(g:health.issues), "v:val.code ==# \"git.git-keymaps\" && stridx(v:val.detail, \"SPC gd\") >= 0")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! nunmap [x' \
        -c 'let g:git = ChopsticksGitInfo() | let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if get(g:git.items[4], "state", "") !=# "missing" || stridx(get(g:git.items[4], "detail", ""), "[x") < 0 || g:keymap.ok || empty(filter(copy(g:health.issues), "v:val.code ==# \"git.conflict-navigation\" && stridx(v:val.detail, \"[x\") >= 0")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksCoreInfo") | cquit | endif' \
        -c 'let g:expected_timing = g:is_tty ? "timeout=500 ttimeout=50ms" : "timeout=500 ttimeout=10ms" | let g:expected_performance = g:is_tty ? "TTY timing" : "rich timing"' \
        -c 'let g:core = ChopsticksCoreInfo() | if get(g:core, "title", "") !=# "editor core" || !ChopsticksInfoShapeIssue(g:core, "ChopsticksCoreInfo()").ok || len(get(g:core, "details", [])) != 3 || len(get(g:core, "items", [])) != 8 || get(g:core, "layout", "") !=# "space" || get(g:core.details[1], "value", "") !=# g:expected_timing || get(g:core.details[2], "value", "") !=# "rg" | cquit | endif' \
        -c 'if get(g:core.items[0], "label", "") !=# "editor defaults" || get(g:core.items[0], "state", "") !=# "ready" || get(g:core.items[1], "label", "") !=# "survival maps" || get(g:core.items[1], "reason", "") !=# "SPC w/SPC W/SPC q/SPC uh/SPC fd" || get(g:core.items[2], "label", "") !=# "search motion" || get(g:core.items[2], "state", "") !=# "ready" || get(g:core.items[3], "label", "") !=# "core toggles" || get(g:core.items[3], "reason", "") !=# "F2/F3/F4/F6 + SPC us" | cquit | endif' \
        -c 'if get(g:core.items[4], "label", "") !=# "persistence" || get(g:core.items[4], "state", "") !=# "ready" || get(g:core.items[5], "label", "") !=# "performance" || get(g:core.items[5], "reason", "") !=# g:expected_performance || get(g:core.items[6], "label", "") !=# "autocmd hygiene" || get(g:core.items[6], "state", "") !=# "ready" || get(g:core.items[7], "label", "") !=# "project-local config" || get(g:core.items[7], "state", "") !=# "off" || get(g:core.items[7], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let g:toggle_keys = ChopsticksKeymapContractKeys("core_toggles") | if join(g:toggle_keys, "/") !=# "F2/F3/F4/F6/SPC us" | cquit | endif' \
        -c 'silent! nunmap <F2>' \
        -c 'let g:core = ChopsticksCoreInfo() | let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if get(g:core.items[3], "state", "") !=# "missing" || stridx(get(g:core.items[3], "detail", ""), "F2") < 0 || g:keymap.ok || empty(filter(copy(g:health.issues), "v:val.code ==# \"core.core-toggles\" && stridx(v:val.detail, \"F2\") >= 0")) || empty(filter(copy(g:health.issues), "v:val.code ==# \"keymap.ergonomic-contract\" && stridx(v:val.detail, \"missing nmap <F2>\") >= 0")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let g:line_move_keys = ChopsticksKeymapContractKeys("line_move_summary") | let g:clipboard_keys = ChopsticksKeymapContractKeys("clipboard_summary") | if join(g:line_move_keys, "/") !=# "Alt+j/Alt+k" || (has("clipboard") && join(g:clipboard_keys, "/") !=# "SPC y/SPC p") || (!has("clipboard") && !empty(g:clipboard_keys)) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! nunmap <M-j>' \
        -c 'let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if g:keymap.ok || empty(filter(copy(g:health.issues), "v:val.code ==# \"keymap.ergonomic-contract\" && stridx(v:val.detail, \"missing nmap <M-j>\") >= 0")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let g:clipboard_case = has("clipboard")' \
        -c 'silent! nunmap <Space>y' \
        -c 'let g:keymap = ChopsticksKeymapAuditInfo() | let g:issue_text = join(ChopsticksKeymapAuditIssues(), "\n")' \
        -c 'if g:clipboard_case && (g:keymap.ok || stridx(g:issue_text, "missing nmap <Space>y") < 0) | cquit | endif' \
        -c 'qa!' 2>&1

    step "Help and command adapters"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksHelpInfo") | cquit | endif' \
        -c 'let g:help = ChopsticksHelpInfo() | if get(g:help, "title", "") !=# "help surface" || !ChopsticksInfoShapeIssue(g:help, "ChopsticksHelpInfo()").ok || !get(g:help, "ok", 0) || len(get(g:help, "details", [])) != 3 || len(get(g:help, "items", [])) != 3 || get(g:help.details[0], "value", "") !=# ":ChopsticksHelp" || get(g:help.details[1], "value", "") !~# "doc/chopsticks.txt" | cquit | endif' \
        -c 'if get(g:help.items[0], "label", "") !=# "help command" || get(g:help.items[0], "state", "") !=# "ready" || get(g:help.items[1], "label", "") !=# "help document" || get(g:help.items[1], "state", "") !=# "ready" || get(g:help.items[2], "label", "") !=# "help tags" || get(g:help.items[2], "state", "") !=# "ready" || get(g:help.items[2], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksCommandHeader") || !exists("*ChopsticksCommandLines") | cquit | endif' \
        -c 'if ChopsticksCommandHeader("help", "") !=# ":ChopsticksHelp  :ChopsticksTutor" || ChopsticksCommandHeader("config", "") !=# ":ChopsticksConfig  :ChopsticksReload" | cquit | endif' \
        -c 'let g:survival_commands = ChopsticksCommandLines("survival") | if len(g:survival_commands) != 10 || g:survival_commands[0] !=# "  :ChopsticksHelp        full help" || g:survival_commands[-1] !=# "  :ChopsticksBetaSession new release note" || max(map(copy(g:survival_commands), "strdisplaywidth(v:val)")) > 42 | cquit | endif' \
        -c 'let g:beta_command_lines = ChopsticksCommandLines("beta", "     ") | if len(g:beta_command_lines) != 3 || g:beta_command_lines[0] !=# "     :ChopsticksBeta        release checklist" || g:beta_command_lines[-1] !=# "     :ChopsticksBetaSession new release note" | cquit | endif' \
        -c 'let g:beta_commands = ChopsticksCommandNames("beta") | if len(g:beta_commands) != 3 || g:beta_commands[0] !=# "ChopsticksBeta" || g:beta_commands[1] !=# "ChopsticksBetaLog" || g:beta_commands[2] !=# "ChopsticksBetaSession" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'source modules/env.vim' \
        -c 'source modules/info.vim' \
        -c 'if exists("*ChopsticksKeymapContractKeys") || ChopsticksStatusHeaderInfo().details[0].value !=# ":ChopsticksHelp  :ChopsticksTutor  SPC ?" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "classic"' \
        -c 'source modules/env.vim' \
        -c 'source modules/info.vim' \
        -c 'if exists("*ChopsticksKeymapContractKeys") || ChopsticksStatusHeaderInfo().details[0].value !=# ":ChopsticksHelp  :ChopsticksTutor  ,?" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'source modules/env.vim' \
        -c 'source modules/info.vim' \
        -c 'function! ChopsticksKeymapContractKeys(group, fallback) abort' \
        -c 'return a:group ==# "learning_entrypoint" ? ["CONTRACT ?"] : a:fallback' \
        -c 'endfunction' \
        -c 'if ChopsticksStatusHeaderInfo().details[0].value !=# ":ChopsticksHelp  :ChopsticksTutor  CONTRACT ?" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'source modules/env.vim' \
        -c 'source modules/info.vim' \
        -c 'function! ChopsticksLearningEntrypointInfo() abort' \
        -c 'return {"key": "INFO ?"}' \
        -c 'endfunction' \
        -c 'function! ChopsticksKeymapContractKeys(group, fallback) abort' \
        -c 'return a:group ==# "learning_entrypoint" ? ["CONTRACT ?"] : a:fallback' \
        -c 'endfunction' \
        -c 'if ChopsticksStatusHeaderInfo().details[0].value !=# ":ChopsticksHelp  :ChopsticksTutor  INFO ?" | cquit | endif' \
        -c 'qa!' 2>&1

    status_header_fallback_vim="$TMP_ROOT/status-header-fallback.vim"
    cat > "$status_header_fallback_vim" <<VIMEOF
source modules/env.vim
source modules/info.vim
function! ChopsticksLearningEntrypointInfo() abort
    return {'key': 'INFO ?'}
endfunction
function! ChopsticksStatusHeaderInfo() abort
    throw 'header broke'
endfunction
function! ChopsticksCommandHeader(group, fallback) abort
    return a:group ==# 'help' ? 'HELP HEAD' : 'CONFIG HEAD'
endfunction
source modules/status.vim
ChopsticksStatus
redir! > $TMP_ROOT/status-header-fallback.txt
silent %print
redir END
qa!
VIMEOF
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N -S "$status_header_fallback_vim" 2>&1
    grep -Fq 'help       HELP HEAD  INFO ?' \
        "$TMP_ROOT/status-header-fallback.txt"
    grep -Fq 'commands   CONFIG HEAD' \
        "$TMP_ROOT/status-header-fallback.txt"

    step "Info and status adapters"
    info_call_vim="$TMP_ROOT/info-call.vim"
    cat > "$info_call_vim" <<'VIMEOF'
source modules/env.vim
source modules/info.vim
function! GoodInfo() abort
    return ChopsticksInfoSection('good', {
        \ 'items': [ChopsticksInfoItem('good item', 'ready', 'ok')],
        \ })
endfunction
function! ThrowInfo() abort
    throw 'loader boom'
endfunction
function! BadTypeInfo() abort
    return 'bad'
endfunction
function! BadShapeInfo() abort
    return {'title': 'bad', 'items': 'bad'}
endfunction
let g:ready = ChopsticksInfoCall('GoodInfo')
let g:missing = ChopsticksInfoCall('MissingInfo')
let g:thrown = ChopsticksInfoCall('ThrowInfo')
let g:bad_type = ChopsticksInfoCall('BadTypeInfo')
let g:bad_shape = ChopsticksInfoCall('BadShapeInfo')
if !get(g:ready, 'ok', 0) || get(g:ready, 'status', '') !=# 'ready'
    cquit
endif
if get(g:ready.info, 'title', '') !=# 'good'
    cquit
endif
if get(g:missing, 'status', '') !=# 'missing'
    cquit
endif
if get(g:thrown, 'status', '') !=# 'thrown'
    cquit
endif
if get(g:thrown, 'exception', '') !=# 'loader boom'
    cquit
endif
if get(g:bad_type, 'status', '') !=# 'invalid-type'
    cquit
endif
if get(g:bad_shape, 'status', '') !=# 'invalid-shape'
    cquit
endif
if get(g:bad_shape.shape, 'detail', '') !=# 'BadShapeInfo().items is not a List'
    cquit
endif
let g:surface_specs = ChopsticksInfoSurfaceSpecs()
let g:status_specs = ChopsticksInfoSurfaceSpecsFor('status')
let g:health_specs = ChopsticksInfoSurfaceSpecsFor('health')
let g:toolchain_surface = ChopsticksInfoSurfaceSpec('toolchain')
let g:keymap_surface = ChopsticksInfoSurfaceSpec('keymap')
if len(g:surface_specs) < 25
    cquit
endif
if get(g:status_specs[0], 'name', '') !=# 'health'
    \ || get(g:status_specs[1], 'name', '') !=# 'keymap'
    \ || get(g:status_specs[-1], 'name', '') !=# 'lsp'
    cquit
endif
if get(g:health_specs[0], 'name', '') !=# 'runtime'
    \ || get(g:health_specs[12], 'name', '') !=# 'keymap'
    \ || get(g:health_specs[-1], 'name', '') !=# 'input-method'
    cquit
endif
if get(g:toolchain_surface, 'function', '') !=# 'ChopsticksToolchainInfo'
    \ || get(get(g:toolchain_surface, 'health_options', {}),
    \     'check_sections', 0) != 1
    cquit
endif
if get(g:keymap_surface, 'health_kind', '') !=# 'function'
    \ || get(g:keymap_surface, 'health_function', '') !=# 's:CheckKeymap'
    cquit
endif
qa!
VIMEOF
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N -S "$info_call_vim" 2>&1

    command_adapter_vim="$TMP_ROOT/command-adapter.vim"
    cat > "$command_adapter_vim" <<'VIMEOF'
source modules/env.vim
if !ChopsticksCommandAvailable('edit')
    cquit
endif
if !ChopsticksCommandAvailable(':edit')
    cquit
endif
if ChopsticksCommandAvailable('')
    cquit
endif
if ChopsticksCommandAvailable('__ChopsticksMissingCommand')
    cquit
endif
if join(ChopsticksMissingCommands(['edit', ':__ChopsticksMissingCommand']),
    \ '/') !=# ':__ChopsticksMissingCommand'
    cquit
endif
if get(ChopsticksCommandNamesOr('beta', ['Fallback']), 0, '') !=# 'ChopsticksBeta'
    cquit
endif
if join(ChopsticksCommandNamesOr('missing', ['Fallback']), '/') !=# 'Fallback'
    cquit
endif
if join(ChopsticksCommandLinesOr('beta', '  ', ['fallback']), "\n") !~# ':ChopsticksBeta'
    cquit
endif
if join(ChopsticksCommandLinesOr('missing', '  ', ['fallback']), "\n") !=# 'fallback'
    cquit
endif
if ChopsticksCommandHeaderOr('help', 'fallback') !~# ':ChopsticksHelp'
    cquit
endif
if ChopsticksCommandHeaderOr('missing', 'fallback') !=# 'fallback'
    cquit
endif
delfunction ChopsticksCommandNames
delfunction ChopsticksCommandLines
delfunction ChopsticksCommandHeader
if join(ChopsticksCommandNamesOr('beta', ['Fallback']), '/') !=# 'Fallback'
    cquit
endif
if join(ChopsticksCommandLinesOr('beta', '  ', ['fallback']), "\n") !=# 'fallback'
    cquit
endif
if ChopsticksCommandHeaderOr('help', 'fallback') !=# 'fallback'
    cquit
endif
qa!
VIMEOF
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N -S "$command_adapter_vim" 2>&1

    plugin_state_vim="$TMP_ROOT/plugin-state.vim"
    cat > "$plugin_state_vim" <<'VIMEOF'
source modules/env.vim
if ChopsticksPluginDeclared('missing')
    cquit
endif
if !empty(ChopsticksPluginSpec('missing'))
    cquit
endif
if !empty(ChopsticksPluginDir('missing'))
    cquit
endif
if ChopsticksPluginInstalled('missing')
    cquit
endif
let g:plugin_dir = tempname()
let g:plugs = {
    \ 'declared-only': {'dir': g:plugin_dir . '-missing'},
    \ 'installed': {'dir': g:plugin_dir},
    \ }
call mkdir(g:plugin_dir, 'p')
let g:spec = ChopsticksPluginSpec('installed')
let g:spec.dir = 'mutated'
if !ChopsticksPluginDeclared('declared-only')
    cquit
endif
if ChopsticksPluginInstalled('declared-only')
    cquit
endif
if !ChopsticksPluginDeclared('installed')
    cquit
endif
if !ChopsticksPluginInstalled('installed')
    cquit
endif
if ChopsticksPluginDir('installed') !=# fnamemodify(g:plugin_dir, ':p')
    cquit
endif
if get(g:plugs.installed, 'dir', '') ==# 'mutated'
    cquit
endif
qa!
VIMEOF
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N -S "$plugin_state_vim" 2>&1

    tool_availability_vim="$TMP_ROOT/tool-availability.vim"
    cat > "$tool_availability_vim" <<'VIMEOF'
source modules/env.vim
if ChopsticksToolAvailable('')
    cquit
endif
if ChopsticksToolAvailable('__chopsticks_missing_tool__')
    cquit
endif
if index(ChopsticksMissingTools(['__chopsticks_missing_tool__']),
    \ '__chopsticks_missing_tool__') < 0
    cquit
endif
if index(ChopsticksMissingTools(['sh']), 'sh') >= 0
    cquit
endif
let g:ready_tool = ChopsticksToolState('shell', 'sh', 0, 'shell command')
if get(g:ready_tool, 'state', '') !=# 'ready'
    \ || !get(g:ready_tool, 'available', 0)
    \ || !get(g:ready_tool, 'enabled', 0)
    cquit
endif
let g:missing_tool = ChopsticksToolState('missing',
    \ '__chopsticks_missing_tool__', 0, 'required command')
if get(g:missing_tool, 'state', '') !=# 'missing'
    \ || get(g:missing_tool, 'available', 1)
    \ || get(g:missing_tool, 'optional', 1)
    cquit
endif
let g:optional_tool = ChopsticksToolState('optional',
    \ '__chopsticks_missing_tool__', 1, 'optional command')
if get(g:optional_tool, 'state', '') !=# 'optional'
    \ || !get(g:optional_tool, 'optional', 0)
    cquit
endif
let g:off_tool = ChopsticksToolOffState('disabled', 'disabled by profile')
if get(g:off_tool, 'state', '') !=# 'off'
    \ || get(g:off_tool, 'enabled', 1)
    \ || get(g:off_tool, 'reason', '') !=# 'disabled by profile'
    cquit
endif
qa!
VIMEOF
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N -S "$tool_availability_vim" 2>&1

    info_fallback_vim="$TMP_ROOT/info-fallback.vim"
    cat > "$info_fallback_vim" <<'VIMEOF'
source modules/env.vim
source modules/info.vim
let g:fallback = {'key': 'fallback'}
if get(ChopsticksInfoOr('ChopsticksMissingInfo', g:fallback),
    \ 'key', '') !=# 'fallback'
    cquit
endif
function! ChopsticksEmptyInfo() abort
    return {}
endfunction
if get(ChopsticksInfoOr('ChopsticksEmptyInfo', g:fallback),
    \ 'key', '') !=# 'fallback'
    cquit
endif
function! ChopsticksThrownInfo() abort
    throw 'fallback boom'
endfunction
if get(ChopsticksInfoOr('ChopsticksThrownInfo', g:fallback),
    \ 'key', '') !=# 'fallback'
    cquit
endif
function! ChopsticksReadyInfo() abort
    return {'key': 'ready', 'items': []}
endfunction
let g:ready = ChopsticksInfoOr('ChopsticksReadyInfo', g:fallback)
let g:ready.key = 'mutated'
if get(ChopsticksInfoOr('ChopsticksReadyInfo', g:fallback),
    \ 'key', '') !=# 'ready'
    cquit
endif
if ChopsticksLspLearningEnabledOr(0)
    cquit
endif
if !ChopsticksLspLearningEnabledOr(1)
    cquit
endif
let g:lsp_info = {'enabled': 1, 'stack': {'state': 'ready'}}
function! ChopsticksLspInfo() abort
    return g:lsp_info
endfunction
if !ChopsticksLspLearningEnabledOr(0)
    cquit
endif
let g:lsp_info = {'enabled': 1, 'stack': {'state': 'off'}}
if ChopsticksLspLearningEnabledOr(1)
    cquit
endif
function! ChopsticksLspLearningEnabled() abort
    return 0
endfunction
let g:lsp_info = {'enabled': 1, 'stack': {'state': 'ready'}}
if ChopsticksLspLearningEnabledOr(1)
    cquit
endif
qa!
VIMEOF
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N -S "$info_fallback_vim" 2>&1

    step "Keymap and file adapters"
    keymap_ready_vim="$TMP_ROOT/keymap-ready.vim"
    cat > "$keymap_ready_vim" <<'VIMEOF'
source modules/env.vim
let g:mapleader = "\<Space>"
nnoremap <Space>zz :ChopsticksReady<CR>
cnoremap w!! w !sudo tee %
inoremap <buffer> <CR> AutoPairsReturn()
let g:normal_ready = {
    \ 'mode': 'n',
    \ 'lhs': '<Space>zz',
    \ 'key': 'SPC zz',
    \ 'text': 'ChopsticksReady',
    \ }
let g:cmd_ready = {
    \ 'mode': 'c',
    \ 'lhs': 'w!!',
    \ 'key': 'w!!',
    \ 'text': 'sudo tee',
    \ }
let g:auto_ready = {
    \ 'kind': 'auto_pairs_map',
    \ 'lhs': '<CR>',
    \ 'key': 'CR',
    \ 'text': 'AutoPairsReturn',
    \ }
let g:missing_spec = {
    \ 'mode': 'n',
    \ 'lhs': '<Space>missing',
    \ 'key': 'missing key',
    \ 'text': 'Nope',
    \ }
if !ChopsticksKeymapSpecReady({'kind': 'leader', 'var': 'mapleader',
    \ 'expected': "\<Space>", 'message': 'leader mismatch'})
    cquit
endif
if !ChopsticksKeymapSpecReady(g:normal_ready)
    cquit
endif
if !ChopsticksKeymapSpecReady(g:cmd_ready)
    cquit
endif
if !ChopsticksKeymapSpecReady(g:auto_ready)
    cquit
endif
if ChopsticksKeymapSpecReady({'kind': 'no_map', 'mode': 'n',
    \ 'lhs': '<Space>zz', 'key': 'SPC zz'})
    cquit
endif
if ChopsticksKeymapSpecIssue({'kind': 'no_map', 'mode': 'n',
    \ 'lhs': '<Space>zz', 'key': 'SPC zz'}) !~# 'unexpected nmap <Space>zz'
    cquit
endif
let g:missing = ChopsticksKeymapMissingKeys([g:normal_ready, g:missing_spec])
if join(g:missing, ',') !=# 'missing key'
    cquit
endif
qa!
VIMEOF
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N -S "$keymap_ready_vim" 2>&1

    keymap_contract_adapter_vim="$TMP_ROOT/keymap-contract-adapter.vim"
    cat > "$keymap_contract_adapter_vim" <<'VIMEOF'
source modules/env.vim
let g:fallback_specs = [{'lhs': '<Space>x', 'key': 'fallback'}]
if get(ChopsticksKeymapContractSpecsOr('missing',
    \ g:fallback_specs)[0], 'key', '') !=# 'fallback'
    cquit
endif
function! ChopsticksKeymapContractSpecsFor(group, fallback) abort
    return a:group ==# 'ready'
        \ ? [{'lhs': '<Space>r', 'key': 'ready'}]
        \ : []
endfunction
function! ChopsticksKeymapContractKeys(group, fallback) abort
    return a:group ==# 'ready' ? ['READY'] : []
endfunction
function! ChopsticksKeymapContractLines(group, indent, width) abort
    return a:group ==# 'ready' ? [a:indent . 'READY'] : []
endfunction
if get(ChopsticksKeymapContractSpecsOr('ready',
    \ g:fallback_specs)[0], 'key', '') !=# 'ready'
    cquit
endif
if get(ChopsticksKeymapContractFirstSpecOr('ready',
    \ {'key': 'fallback'}), 'key', '') !=# 'ready'
    cquit
endif
if join(ChopsticksKeymapContractKeysOr('ready', ['fallback']), '/') !=# 'READY'
    cquit
endif
if join(ChopsticksKeymapContractLinesOr('ready', '  ', 8,
    \ ['fallback']), "\n") !=# '  READY'
    cquit
endif
if join(ChopsticksKeymapContractLinesOr('empty', '  ', 8,
    \ ['fallback']), "\n") !=# 'fallback'
    cquit
endif
qa!
VIMEOF
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N -S "$keymap_contract_adapter_vim" 2>&1

    managed_file_adapter_vim="$TMP_ROOT/managed-file-adapter.vim"
    cat > "$managed_file_adapter_vim" <<VIMEOF
source modules/env.vim
let s:dir = '$TMP_ROOT/managed/nested'
if !ChopsticksEnsureDir(s:dir) || !isdirectory(s:dir)
    cquit
endif
let s:file = s:dir . '/note.txt'
if !ChopsticksEnsureManagedFile(s:file, ['one']) || readfile(s:file) !=# ['one']
    cquit
endif
if !ChopsticksAppendManagedFile(s:file, ['two']) || readfile(s:file) !=# ['one', 'two']
    cquit
endif
let s:buffer_file = '$TMP_ROOT/managed-buffer/chopsticks.vim'
let s:opened = ChopsticksOpenManagedFile(s:buffer_file, {
    \ 'filetype': 'vim',
    \ 'buffer_seed_lines': ['" seeded local preferences'],
    \ 'mark_unmodified': 1,
    \ })
if !get(s:opened, 'new_file', 0) || !get(s:opened, 'dir_ready', 0)
    cquit
endif
if &l:filetype !=# 'vim' || getline(1) !=# '" seeded local preferences'
    cquit
endif
if &modified || filereadable(s:buffer_file)
    cquit
endif
qa!
VIMEOF
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N -S "$managed_file_adapter_vim" 2>&1

    scratch_surface_adapter_vim="$TMP_ROOT/scratch-surface-adapter.vim"
    cat > "$scratch_surface_adapter_vim" <<VIMEOF
source modules/env.vim
let s:opened = ChopsticksOpenScratchBuffer('__ChopsticksScratchTest__', ['one', 'two'], {
    \ 'height': 7,
    \ 'mappings': [{'lhs': '?', 'rhs': ':echo "help"<CR>'}],
    \ })
if !get(s:opened, 'opened', 0) || get(s:opened, 'closed_existing', 1)
    cquit
endif
if getline(1, '$') !=# ['one', 'two']
    cquit
endif
if &l:buftype !=# 'nofile' || &l:bufhidden !=# 'wipe'
    cquit
endif
if &l:buflisted || &l:swapfile || &l:wrap || &l:number
    cquit
endif
if &l:relativenumber || &l:modifiable || !&l:readonly
    cquit
endif
if maparg('q', 'n') !~# ':bd' || maparg('?', 'n') !~# ':echo "help"'
    cquit
endif
let s:closed = ChopsticksOpenScratchBuffer('__ChopsticksScratchTest__', ['ignored'], {
    \ 'height': 7,
    \ })
if get(s:closed, 'opened', 1) || !get(s:closed, 'closed_existing', 0)
    cquit
endif
if bufwinnr('__ChopsticksScratchTest__') != -1
    cquit
endif
let s:side = ChopsticksOpenScratchBuffer('__ChopsticksScratchSide__', ['side'], {
    \ 'split': 'vertical botright new',
    \ 'width': 12,
    \ 'winfixwidth': 1,
    \ })
if !get(s:side, 'opened', 0) || !&l:winfixwidth
    cquit
endif
let s:refreshed = ChopsticksOpenScratchBuffer('__ChopsticksScratchSide__', ['fresh'], {
    \ 'split': 'vertical botright new',
    \ 'width': 12,
    \ 'winfixwidth': 1,
    \ 'toggle': 0,
    \ })
if !get(s:refreshed, 'opened', 0) || !get(s:refreshed, 'closed_existing', 0)
    cquit
endif
if getline(1) !=# 'fresh'
    cquit
endif
qa!
VIMEOF
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N -S "$scratch_surface_adapter_vim" 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'source modules/env.vim' \
        -c 'source modules/info.vim' \
        -c 'let g:shape = ChopsticksInfoShapeIssue({"sections": [{"title": "outer", "sections": [{"title": "inner", "items": "bad"}]}]}, "ShapeInfo()")' \
        -c 'if get(g:shape, "ok", 1) || get(g:shape, "detail", "") !=# "ShapeInfo().sections[0].sections[0].items is not a List" || get(g:shape, "action", "") !=# "return a List from ShapeInfo().sections[0].sections[0].items" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'source modules/env.vim' \
        -c 'source modules/info.vim' \
        -c 'let g:shape = ChopsticksInfoShapeIssue({"sections": [{"title": "outer", "footers": [{}]}]}, "ShapeInfo()")' \
        -c 'if get(g:shape, "ok", 1) || get(g:shape, "detail", "") !=# "ShapeInfo().sections[0].footers[0] is not a String" || get(g:shape, "action", "") !=# "return String entries from ShapeInfo().sections[0].footers" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'source modules/env.vim' \
        -c 'source modules/info.vim' \
        -c 'let g:detail = ChopsticksInfoDetail("key", "value") | let g:item = ChopsticksInfoItem("thing", "ready", "ok", {"diagnostic": 0})' \
        -c 'let g:issue = ChopsticksInfoDiagnosticItem("bad thing", "missing", "nope", "bad label", "fix it", {"severity": "setup", "detail": "broken"})' \
        -c 'let g:section = ChopsticksInfoSection("section", {"title": "old", "details": [g:detail], "items": [g:item], "footers": ["done"]})' \
        -c 'if get(g:detail, "label", "") !=# "key" || get(g:detail, "value", "") !=# "value" || get(g:detail, "reason", "x") !=# "" | cquit | endif' \
        -c 'if get(g:item, "label", "") !=# "thing" || get(g:item, "state", "") !=# "ready" || get(g:item, "reason", "") !=# "ok" || get(g:item, "diagnostic", 1) | cquit | endif' \
        -c 'if !get(g:issue, "diagnostic", 0) || get(g:issue, "severity", "") !=# "setup" || get(g:issue, "issue_label", "") !=# "bad label" || get(g:issue, "detail", "") !=# "broken" || get(g:issue, "action", "") !=# "fix it" | cquit | endif' \
        -c 'if get(g:section, "title", "") !=# "section" || len(get(g:section, "details", [])) != 1 || len(get(g:section, "items", [])) != 1 || !ChopsticksInfoShapeIssue(g:section, "SectionInfo()").ok | cquit | endif' \
        -c 'qa!' 2>&1

    display_adapter_vim="$TMP_ROOT/display-adapter.vim"
    cat > "$display_adapter_vim" <<'VIMEOF'
source modules/env.vim
source modules/info.vim
function! StatusReadyInfo() abort
    return ChopsticksInfoSection('ready section', {
        \ 'items': [
        \   ChopsticksInfoItem('ready item', 'ready', 'ok'),
        \ ],
        \ })
endfunction
function! StatusThrownInfo() abort
    throw 'boom'
endfunction
function! StatusInvalidShapeInfo() abort
    return {'items': 'bad'}
endfunction
let g:ready_status_info = ChopsticksStatusInfoFromSpec({
    \ 'function': 'StatusReadyInfo',
    \ 'section_title': 'status',
    \ 'label': 'status',
    \ 'reason': 'missing',
    \ })
if get(g:ready_status_info, 'title', '') !=# 'ready section'
    \ || get(g:ready_status_info.items[0], 'label', '') !=# 'ready item'
    cquit
endif
let g:fallback_status = ChopsticksInfoSection('fallback section', {
    \ 'items': [],
    \ })
let g:missing_status_info = ChopsticksStatusInfoFromSpec({
    \ 'function': 'StatusMissingInfo',
    \ 'section_title': 'status',
    \ 'label': 'status',
    \ 'reason': 'not loaded',
    \ 'fallback': g:fallback_status,
    \ })
if get(g:missing_status_info, 'title', '') !=# 'fallback section'
    cquit
endif
let g:thrown_status_info = ChopsticksStatusInfoFromSpec({
    \ 'function': 'StatusThrownInfo',
    \ 'section_title': 'broken section',
    \ 'label': 'broken label',
    \ 'reason': 'not loaded',
    \ })
if get(g:thrown_status_info, 'title', '') !=# 'broken section'
    \ || get(g:thrown_status_info.items[0], 'label', '') !=# 'broken label'
    \ || get(g:thrown_status_info.items[0], 'state', '') !=# 'missing'
    \ || get(g:thrown_status_info.items[0], 'reason', '') !~# 'StatusThrownInfo() failed'
    cquit
endif
let g:invalid_status_info = ChopsticksStatusInfoFromSpec({
    \ 'function': 'StatusInvalidShapeInfo',
    \ 'section_title': 'invalid section',
    \ 'label': 'invalid label',
    \ 'reason': 'not loaded',
    \ })
if get(g:invalid_status_info, 'title', '') !=# 'invalid section'
    \ || get(g:invalid_status_info.items[0], 'reason', '') !=# 'StatusInvalidShapeInfo().items is not a List'
    cquit
endif
if ChopsticksDisplayKeyLine('>', 4, 'ab', 'cd') !=# '>ab   cd'
    cquit
endif
let g:header = ChopsticksInfoSection('status header', {
    \ 'details': [ChopsticksInfoDetail('help', ':Help')],
    \ })
let g:ready = ChopsticksInfoItemValue('ready item', 'value', 'ready', 'ok', {
    \ 'diagnostic': 0,
    \ })
let g:optional = ChopsticksInfoItem('optional item', 'optional',
    \ 'nice-to-have')
let g:off = ChopsticksInfoItem('off item', 'off', 'disabled')
let g:missing = ChopsticksInfoItem('missing item', 'missing', 'not loaded')
let g:inner = ChopsticksInfoSection('inner', {'items': [g:missing]})
let g:outer = ChopsticksInfoSection('outer', {
    \ 'details': [ChopsticksInfoDetail('path', '/tmp/x')],
    \ 'items': [g:ready, g:optional, g:off],
    \ 'notes': ['read the note'],
    \ 'sections': [g:inner],
    \ 'footers': ['tail'],
    \ })
let g:display = ChopsticksStatusDisplay(g:header, [g:outer])
if get(g:display.counts, 'ready', -1) != 1
    \ || get(g:display.counts, 'missing', -1) != 1
    \ || get(g:display.counts, 'optional', -1) != 1
    cquit
endif
if index(g:display.lines, 'chopsticks status') < 0
    \ || index(g:display.lines, '── outer ──') < 0
    \ || index(g:display.lines, '── inner ──') < 0
    cquit
endif
if index(g:display.lines, '  help       :Help') < 0
    \ || index(g:display.lines, '  OK  ready item  value  (ok)') < 0
    \ || index(g:display.lines, '  opt optional item  (nice-to-have)') < 0
    \ || index(g:display.lines, '  off off item  (disabled)') < 0
    \ || index(g:display.lines, '  --  missing item  (not loaded)') < 0
    cquit
endif
if index(g:display.lines, '  1 ready, 1 missing, 1 optional') < 0
    \ || index(g:display.lines, '  tail') < 0
    cquit
endif
let g:learning_rows = ChopsticksLearningRowLines([
    \ {'key': 'aa', 'label': 'alpha'},
    \ {'line': 'preformatted'},
    \ {'key': 'bb', 'gap': '    ', 'label': 'beta'},
    \ ], {'indent': '>', 'key_width': 4})
if g:learning_rows !=# ['>aa   alpha', 'preformatted', '>bb    beta']
    cquit
endif
let g:fallback_learning_rows = ChopsticksLearningRowLinesOr([], {
    \ 'indent': '>',
    \ 'key_width': 4,
    \ }, ['fallback'])
if g:fallback_learning_rows !=# ['fallback']
    cquit
endif
if ChopsticksLearningTaskLine({'tasks': ['one', 'two']}, '  ', ['fallback'])
    \ !=# '  task: one, two'
    cquit
endif
if ChopsticksLearningTaskLine({}, '  ', ['fallback'])
    \ !=# '  task: fallback'
    cquit
endif
if ChopsticksLearningDrillLine({'drill_steps': ['a', 'b']}, ['x'])
    \ !=# 'Repeat: a, b.'
    cquit
endif
if ChopsticksLearningDrillLine({}, ['x', 'y']) !=# 'Repeat: x, y.'
    cquit
endif
let g:info_learning_rows = ChopsticksLearningInfoRowLinesOr({
    \ 'rows': [{'key': 'cc', 'label': 'gamma'}],
    \ }, 'rows', {'indent': '>', 'key_width': 4}, ['fallback'])
if g:info_learning_rows !=# ['>cc   gamma']
    cquit
endif
if ChopsticksLearningInfoRowLinesOr({}, 'rows', {
    \ 'indent': '>',
    \ 'key_width': 4,
    \ }, ['fallback']) !=# ['fallback']
    cquit
endif
if ChopsticksLearningLoopEnabled({'lsp_enabled': 0}, {'enabled': 1}, 0) != 1
    cquit
endif
if ChopsticksLearningLoopEnabled({'lsp_enabled': 0}, {}, 1) != 0
    cquit
endif
if ChopsticksLearningKey({'keys': {'hover': 'K'}}, 'hover', ',dk') !=# 'K'
    cquit
endif
if ChopsticksLearningKey({}, 'hover', ',dk') !=# ',dk'
    cquit
endif
qa!
VIMEOF
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N -S "$display_adapter_vim" 2>&1

    step "Status and info surfaces"
    CHOPSTICKS_TEST_STEP=status_info
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksRuntimeInfo") || !exists("*ChopsticksRuntimeFeatureSpec") || !exists("*ChopsticksRuntimeFeatureAvailable") || !exists("*ChopsticksDisplayKeyLine") || !exists("*ChopsticksStatusDisplay") || !exists("*ChopsticksStatusInfoFromSpec") || !exists("*ChopsticksInfoSurfaceSpecs") || !exists("*ChopsticksInfoSurfaceSpec") || !exists("*ChopsticksInfoSurfaceSpecsFor") || !exists("*ChopsticksLearningRowLines") || !exists("*ChopsticksLearningRowLinesOr") || !exists("*ChopsticksLearningTaskLine") || !exists("*ChopsticksLearningDrillLine") || !exists("*ChopsticksLearningLoopEnabled") || !exists("*ChopsticksLearningKey") || !exists("*ChopsticksLearningInfoRowLinesOr") || !exists("*ChopsticksOpenScratchBuffer") || !exists("*ChopsticksModuleInfo") || !exists("*ChopsticksCoreInfo") || !exists("*ChopsticksCommandInfo") || !exists("*ChopsticksCommandLines") || !exists("*ChopsticksUtilityInfo") || !exists("*ChopsticksLearningInfo") || !exists("*ChopsticksLearningDailyLoopInfo") || !exists("*ChopsticksLearningLspLoopInfo") || !exists("*ChopsticksHelpInfo") || !exists("*ChopsticksUiInfo") || !exists("*ChopsticksLanguageInfo") || !exists("*ChopsticksLintInfo") || !exists("*ChopsticksCompletionInfo") || !exists("*ChopsticksEditingInfo") || !exists("*ChopsticksBufferInfo") || !exists("*ChopsticksQuickfixInfo") || !exists("*ChopsticksFileSafetyInfo") || !exists("*ChopsticksGitInfo") || !exists("*ChopsticksRunnerInfo") || !exists("*ChopsticksToolchainInfo") || !exists("*ChopsticksLspInfo") || !exists("*ChopsticksLspLearningEnabled") || !exists("*ChopsticksProfileInfo") || !exists("*ChopsticksHealthInfo") || !exists("*ChopsticksKeymapContractSpecs") || !exists("*ChopsticksKeymapContractSpecsFor") || !exists("*ChopsticksKeymapContractKeys") || !exists("*ChopsticksKeymapContractLines") || !exists("*ChopsticksKeymapAuditInfo") || !exists("*ChopsticksBetaInfo") || !exists("*ChopsticksStatusHeaderInfo") | cquit | endif' \
        -c 'let g:runtime_info = ChopsticksRuntimeInfo() | let g:module_info = ChopsticksModuleInfo() | let g:clipboard_feature = ChopsticksRuntimeFeatureSpec("clipboard") | if get(g:runtime_info, "title", "") !=# "runtime" || g:runtime_info.editor !=# "vim" || !g:runtime_info.compatible || len(get(g:runtime_info, "details", [])) != 3 || len(get(g:runtime_info, "items", [])) != len(g:runtime_info.features) + 1 || get(g:runtime_info.items[0], "label", "") !=# "runtime gate" || get(g:runtime_info.items[0], "state", "") !=# "ready" || get(g:runtime_info.items[0], "diagnostic", 1) || get(g:module_info, "title", "") !=# "modules" || !g:module_info.ok || !g:module_info.inventory_ok || get(g:clipboard_feature, "label", "") !=# "clipboard" || get(g:clipboard_feature, "available", -1) != has("clipboard") || ChopsticksRuntimeFeatureAvailable("+terminal") != has("terminal") || ChopsticksRuntimeFeatureAvailable("popupwin") != (has("popupwin") || has("patch-8.1.1517")) | cquit | endif | let g:runtime_items = get(g:runtime_info, "items", [])[1:] | if len(g:runtime_items) != len(g:runtime_info.features) | cquit | endif | for g:i in range(0, len(g:runtime_info.features) - 1) | let g:feature = g:runtime_info.features[g:i] | let g:item = g:runtime_items[g:i] | let g:available = get(g:feature, "available", 0) | if get(g:item, "label", "") !=# "+" . get(g:feature, "label", "") || get(g:item, "state", "") !=# (g:available ? "ready" : "missing") || get(g:item, "diagnostic", 0) != !g:available | cquit | endif | endfor' \
        -c 'let g:command_info = ChopsticksCommandInfo() | if g:module_info.loaded_count != g:module_info.declared_count || g:module_info.file_count != g:module_info.declared_count || len(get(g:module_info, "details", [])) != 3 || len(get(g:module_info, "items", [])) != 2 || get(g:module_info.items[0], "label", "") !=# "module inventory" || get(g:module_info.items[1], "label", "") !=# "module load" || get(g:module_info.items[0], "diagnostic", 1) || get(g:module_info.items[1], "diagnostic", 1) || get(g:command_info, "title", "") !=# "command surface" || !g:command_info.ok || g:command_info.declared_count != 15 || g:command_info.available_count != 15 || g:command_info.discovered_count != 15 || !empty(get(g:command_info, "unlisted", [])) | cquit | endif' \
        -c 'let g:local_config = ChopsticksLocalConfigInfo() | let g:header = ChopsticksStatusHeaderInfo() | if len(get(g:command_info, "details", [])) != 2 || get(g:command_info.details[1], "label", "") !=# "defined" || len(get(g:command_info, "items", [])) != 1 || get(g:command_info.items[0], "label", "") !=# "command surface" || get(g:command_info.items[0], "state", "") !=# "ready" || get(g:command_info.items[0], "reason", "") !=# "catalog matches Vim commands" || get(g:command_info.items[0], "diagnostic", 1) || len(filter(copy(g:command_info.commands), "get(v:val, \"header\", \"\") ==# \"help\"")) != 2 || len(filter(copy(g:command_info.commands), "get(v:val, \"header\", \"\") ==# \"config\"")) != 2 || get(g:local_config, "title", "") !=# "local preferences" || len(get(g:local_config, "details", [])) != 3 || get(g:local_config.details[2], "value", "") !=# ":ChopsticksConfig  :ChopsticksReload" || len(get(g:local_config, "items", [])) != 1 || get(g:local_config.items[0], "state", "") !=# "off" || get(g:local_config.items[0], "diagnostic", 1) || get(g:header, "title", "") !=# "status header" || len(get(g:header, "details", [])) != 3 || get(g:header.details[0], "value", "") !=# ":ChopsticksHelp  :ChopsticksTutor  SPC ?" || get(g:header.details[2], "value", "") !=# ":ChopsticksConfig  :ChopsticksReload" | cquit | endif' \
        -c 'let g:profile_info = ChopsticksProfileInfo() | let g:lsp = ChopsticksLspInfo() | let g:daily_loop = ChopsticksLearningDailyLoopInfo() | let g:lsp_loop = ChopsticksLearningLspLoopInfo() | if get(g:profile_info, "title", "") !=# "profile" || g:profile_info.profile !=# "engineer" || g:profile_info.keymap !=# "space" || len(get(g:profile_info, "details", [])) != 7 || len(get(g:profile_info, "items", [])) != 0 || get(g:profile_info.details[4], "label", "") !=# "features" || g:lsp.stack.state !=# "ready" || !ChopsticksInfoShapeIssue(g:lsp, "ChopsticksLspInfo()").ok || !ChopsticksLspLearningEnabled() || !get(g:daily_loop, "lsp_enabled", 0) || !get(g:lsp_loop, "enabled", 0) || get(g:lsp_loop.keys, "definition_references_docs", "") !=# "gd / gr / K" || get(g:lsp_loop.tutor_rows[0], "key", "") !=# "gd / gr / K" || get(g:lsp_loop.beta_rows[2], "key", "") !=# "SPC cf" || len(get(g:lsp_loop, "cheat_rows", [])) != 12 || get(g:lsp_loop.cheat_rows[0], "key", "") !=# "gd" || get(g:lsp_loop.cheat_rows[11], "key", "") !=# "SPC cS" || get(g:lsp_loop.cheat_command_lines, 2, "") !=# "  :ChopsticksDoctor   health issues" || get(g:daily_loop.summary_lines, 0, "") !=# "files → s jump → gd/K" || join(get(g:daily_loop, "drill_steps", []), ", ") !=# "SPC SPC, s, gd/K, edit, SPC rr, SPC /, SPC gs" || join(get(g:daily_loop, "tasks", []), ", ") !=# "project navigation, code, grep, git, LSP, Markdown, SSH" || len(get(g:daily_loop, "tutor_rows", [])) != 6 || get(g:daily_loop.tutor_rows[0], "key", "") !=# "SPC SPC" || get(g:daily_loop.tutor_rows[1], "label", "") !=# "jump to visible text" || get(g:daily_loop.tutor_rows[2], "key", "") !=# "gd / gr / K" || get(g:daily_loop.tutor_rows[-1], "label", "") !=# "check git status" || get(get(g:daily_loop, "visible_jump", {}), "primary_key", "") !=# "s" || len(get(get(g:daily_loop, "visible_jump", {}), "cheat_rows", [])) != 2 || len(get(get(g:daily_loop, "visible_jump", {}), "tutor_lines", [])) != 2 || len(get(g:daily_loop, "beta_rows", [])) != 8 || get(g:daily_loop.beta_rows[0], "key", "") !=# "SPC SPC" || get(g:daily_loop.beta_rows[2], "key", "") !=# "gd / gr" || get(g:daily_loop.beta_rows[-1], "key", "") !=# "SPC cf" || len(get(g:lsp, "items", [])) != len(g:lsp.servers) + 1 || get(g:lsp.items[0], "label", "") !=# "vim-lsp stack" || get(g:lsp.items[0], "severity", "") !=# "setup" || get(g:lsp.items[0], "action", "") !=# ":PlugInstall" || get(g:lsp.items[1], "severity", "") !=# "optional" || get(g:lsp.items[1], "action", "") !=# ":LspInstallServer" || get(g:lsp.items[1], "issue_label", "") !=# "python language server" || get(g:lsp, "title", "") !=# "lsp servers" || get(g:lsp, "suffix", "") !~# ":LspInstallServer" || len(get(g:lsp, "notes", [])) != 2 || len(get(g:lsp, "footers", [])) != 1 || ChopsticksHealthInfo().summary.attention != 0 | cquit | endif' \
        -c 'let g:health = ChopsticksHealthInfo() | let g:toolchain = ChopsticksToolchainInfo() | if get(g:health, "title", "") !=# "health" || !ChopsticksInfoShapeIssue(g:health, "ChopsticksHealthInfo()").ok || get(g:health, "summary_line", "") !~# "^attention=0 setup=" || get(g:health, "summary_line", "") !~# " info=" || len(get(g:health, "details", [])) != 2 || get(g:health.details[0], "label", "") !=# "doctor" || get(g:health.details[1], "label", "") !=# "command" || get(g:toolchain, "title", "") !=# "toolchain" || !ChopsticksInfoShapeIssue(g:toolchain, "ChopsticksToolchainInfo()").ok || len(get(g:toolchain, "sections", [])) != 4 || get(g:toolchain.sections[0], "title", "") !=# "project loop tools" || get(g:toolchain.sections[3], "suffix", "") !~# "format-on-save" || len(get(g:toolchain, "footers", [])) != 1 || get(g:toolchain.sections[0], "severity", "") !=# "setup" || get(g:toolchain.sections[1], "severity", "") !=# "optional" || get(g:toolchain.sections[0].items[1], "cmd", "") !=# "rg" || get(g:toolchain.sections[0].items[1], "detail", "") !=# "project grep" || get(g:toolchain.sections[0].items[1], "diagnostic", 1) || get(g:toolchain.sections[1].items[0], "action", "") !=# "install: node" || !has_key(g:toolchain.sections[1].items[0], "diagnostic") | cquit | endif' \
        -c 'let g:beta = ChopsticksBetaInfo() | if !g:beta.enabled || get(g:beta, "title", "") !=# "release guide" || !ChopsticksInfoShapeIssue(g:beta, "ChopsticksBetaInfo()").ok || get(g:beta, "label", "") !=# "2.3.0" || get(g:beta, "log_path", "") !~# "chopsticks-2.3.0.md" || len(get(g:beta, "details", [])) != 5 || get(g:beta.details[0], "label", "") !=# "release" || get(g:beta.details[3], "value", "") !=# ":ChopsticksBeta  :ChopsticksBetaLog" || get(g:beta.details[4], "value", "") !=# ":ChopsticksBetaSession" || len(get(g:health, "summary_rows", [])) != 4 || get(g:health.summary_rows[0], "severity", "") !=# "attention" || get(g:health.summary_rows[3], "severity", "") !=# "info" | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-default.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    if grep -Fq 'vim-lsp not loaded' "$TMP_ROOT/status-default.txt"; then
        cat "$TMP_ROOT/status-default.txt"
        exit 1
    fi
    grep -Fq 'OK  vim-lsp stack  (installed)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'help       :ChopsticksHelp  :ChopsticksTutor  SPC ?' "$TMP_ROOT/status-default.txt"
    grep -Fq 'commands   :ChopsticksConfig  :ChopsticksReload' "$TMP_ROOT/status-default.txt"
    grep -Fq 'doctor    ' "$TMP_ROOT/status-default.txt"
    grep -Fq 'attention=0' "$TMP_ROOT/status-default.txt"
    grep -Fq ' info=' "$TMP_ROOT/status-default.txt"
    grep -Fq 'command   :ChopsticksDoctor' "$TMP_ROOT/status-default.txt"
    grep -Fq '── help surface ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'command   :ChopsticksHelp' "$TMP_ROOT/status-default.txt"
    grep -Fq 'doc       doc/chopsticks.txt' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  help command  (:ChopsticksHelp)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  help document  (doc/chopsticks.txt)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  help tags' "$TMP_ROOT/status-default.txt"
    grep -Fq '── learning ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'layout    space' "$TMP_ROOT/status-default.txt"
    grep -Fq 'cheat     SPC ?' "$TMP_ROOT/status-default.txt"
    grep -Fq 'help      :ChopsticksHelp' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  active cheat sheet  (SPC ?)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  guided tutor  (:ChopsticksTutor)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  native help  (:help chopsticks)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  release guide  (:ChopsticksBeta)' "$TMP_ROOT/status-default.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let g:entry = ChopsticksLearningEntrypointInfo() | if get(g:entry, "key", "") !=# "SPC ?" || get(g:entry, "lhs", "") !=# "<Space>?" || get(g:entry, "open_lhs", "") !=# "<Space>?" || get(g:entry, "close_lhs", "") !=# "<Space>?" || get(g:entry, "cheat_title", "") !=# "  chopsticks         SPC ? close" || get(g:entry.guide_lines, 0, "") !=# "     SPC ?     active cheat sheet" || get(g:entry.tutor_lines, 0, "") !=# "     SPC ?      active cheat sheet" || get(g:entry, "feedback_line", "") !=# "     whether SPC ?, :ChopsticksTutor, or :ChopsticksStatus answered it" || get(g:entry, "session_prompt", "") !=# "- Did SPC ?, :ChopsticksTutor, or :ChopsticksStatus answer it:" | cquit | endif' \
        -c 'if maparg("<Space>?", "n") !~# "ChopsticksCheatSheet" | cquit | endif' \
        -c 'qa!' 2>&1

    grep -Fq '── runtime ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'session   local' "$TMP_ROOT/status-default.txt"
    grep -Fq 'minimum=8.2' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  runtime gate  (Vim 8.2/9.x)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── modules ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  module inventory  (manifest matches modules/*.vim)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  module load  (all modules loaded)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── editor core ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'timing    timeout=500 ttimeout=10ms' "$TMP_ROOT/status-default.txt"
    grep -Fq 'grep      rg' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  editor defaults  (numbers/splits/buffers)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  survival maps  (SPC w/SPC W/SPC q/SPC uh/SPC fd)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  search motion  (centered search/scroll)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  core toggles  (F2/F3/F4/F6 + SPC us)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  persistence  (swap/writebackup/undo)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  performance  (rich timing)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  autocmd hygiene  (resize/format/paste)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off project-local config  (disabled by default)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── command surface ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'defined   15' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  command surface  (catalog matches Vim commands)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── local preferences ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off local config  (not created yet)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── utilities ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'config    SPC fc/SPC fv/SPC fV' "$TMP_ROOT/status-default.txt"
    grep -Fq 'sudo      disabled' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  config actions  (SPC fc/SPC fv/SPC fV)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off classic save all  (space layout uses SPC W)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off sudo save  (disabled by default)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── profile ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'profile   engineer' "$TMP_ROOT/status-default.txt"
    grep -Fq 'keymap    space' "$TMP_ROOT/status-default.txt"
    grep -Fq 'plugins   pinned' "$TMP_ROOT/status-default.txt"
    grep -Fq '── ui ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'terminal  rich terminal' "$TMP_ROOT/status-default.txt"
    grep -Fq 'colors    solarized8' "$TMP_ROOT/status-default.txt"
    grep -Fq 'status    custom' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  color palette  (solarized8)' "$TMP_ROOT/status-default.txt"
    if has_chopsticks_truecolor_env; then
        grep -Eq 'OK  truecolor  \(termguicolors\)|opt truecolor  \(Vim lacks termguicolors\)' "$TMP_ROOT/status-default.txt"
    else
        grep -Fq 'opt truecolor  (COLORTERM not truecolor)' "$TMP_ROOT/status-default.txt"
    fi
    grep -Fq 'OK  statusline  (SLBuild)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  tabline  (TLBuild)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  layout stability  (signcolumn=yes; stable separators)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  start screen  (vim-startify)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── languages ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'markdown  quiet defaults' "$TMP_ROOT/status-default.txt"
    grep -Fq 'preview   PrevimOpen' "$TMP_ROOT/status-default.txt"
    grep -Fq 'current   none' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  markdown syntax  (vim-markdown)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  markdown writing mode  (quiet defaults)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  markdown maps  (buffer-local on markdown)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  markdown preview  (PrevimOpen)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  go syntax  (syntax only; LSP owns intelligence)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  filetype defaults  (indent + markdown defaults)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── plugin reproducibility ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'mode      pinned' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  lock coverage  (all active plugins locked)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  applied pins  (all active plugins pinned)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  installed plugins  (all active plugin dirs exist)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── lint ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'engine    ALE' "$TMP_ROOT/status-default.txt"
    grep -Fq 'format    ON' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  ALE stack  (installed)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  lint keymaps  (SPC xd/SPC uf/[e ]e)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  format on save  (ON)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off markdown lint  (quiet defaults)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── completion ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'engine    asyncomplete' "$TMP_ROOT/status-default.txt"
    grep -Fq 'source    vim-lsp' "$TMP_ROOT/status-default.txt"
    grep -Fq 'keys      off' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  completion engine  (asyncomplete.vim)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  vim-lsp completion source  (asyncomplete-lsp.vim)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  auto popup  (delay=50)' "$TMP_ROOT/status-default.txt"
    grep -Eq 'OK  popup menu  \(.*pumheight=15\)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off completion keymaps  (disabled by default)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'features  LSP, ALE, extra languages, UI extras, Markdown preview' "$TMP_ROOT/status-default.txt"
    grep -Fq 'opt-ins   none' "$TMP_ROOT/status-default.txt"
    grep -Fq 'markdown  quiet defaults' "$TMP_ROOT/status-default.txt"
    grep -Fq '── editing ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'jump      s / SPC S' "$TMP_ROOT/status-default.txt"
    grep -Fq 'cleanup   SPC cW/SPC sr/SPC =' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  visible jump  (s / SPC S)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  undo tree  (SPC U)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  edit cleanup  (SPC cW/SPC sr/SPC =)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  blank lines  ([<Space> ]<Space>)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off full-file reindent  (disabled by default)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  project search  (SPC SPC/SPC /)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  file sidebar  (SPC e/SPC E)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  window navigation  (vim splits)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  window layout  (SPC z)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off terminal navigation  (disabled by default)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off tmux navigator  (disabled by default)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── buffers ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'listed    1 buffers' "$TMP_ROOT/status-default.txt"
    grep -Fq 'alternate none' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  buffer close  (:Bclose)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  buffer navigation  (SPC bn/SPC bp)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  alternate buffer  (SPC Tab)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── quickfix ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'quickfix  0 entries' "$TMP_ROOT/status-default.txt"
    grep -Fq 'loclist   0 entries' "$TMP_ROOT/status-default.txt"
    grep -Fq 'maps      [q ]q / [l ]l' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  quickfix window  (cwindow)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  location window  (lwindow)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  quickfix navigation  ([q ]q)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  location navigation  ([l ]l)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── file safety ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'write     auto mkdir' "$TMP_ROOT/status-default.txt"
    grep -Fq 'large     10485760 bytes' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  write directory guard  (BufWritePre mkdir -p)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  large file guard  (threshold=10485760)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off current buffer  (no file)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── git ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'status    SPC gs' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  git command  (git)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  fugitive  (:Git)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  gitgutter  (:GitGutter)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  git keymaps  (SPC gs)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'OK  conflict navigation  ([x ]x)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── run file ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'keymap    SPC rr' "$TMP_ROOT/status-default.txt"
    grep -Fq 'current   none' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off run file  (no filetype)' "$TMP_ROOT/status-default.txt"
    grep -Fq '── project loop tools ──' "$TMP_ROOT/status-default.txt"
    grep -Fq '── optional language runtimes ──' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off markdownlint (md)  (disabled by default)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off prettier (md)  (disabled by default)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'Install optional tools with ./install.sh --install-tools' "$TMP_ROOT/status-default.txt"
    grep -Fq 'release   2.3.0' "$TMP_ROOT/status-default.txt"
    grep -Fq 'commands  :ChopsticksBeta  :ChopsticksBetaLog' "$TMP_ROOT/status-default.txt"
    grep -Fq ':ChopsticksBetaSession' "$TMP_ROOT/status-default.txt"
    grep -Fq 'chopsticks-2.3.0.md' "$TMP_ROOT/status-default.txt"
    grep -Fq 'python  (:LspInstallServer in a python file)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'off markdown  (disabled by default)' "$TMP_ROOT/status-default.txt"
    grep -Fq 'LSP actions are buffer-local and start after a server attaches.' "$TMP_ROOT/status-default.txt"
    grep -Fq 'Open that filetype and run :LspInstallServer once.' "$TMP_ROOT/status-default.txt"

    printf '%s\n' \
        'function! ChopsticksCoreInfo() abort' \
        'throw "status core boom"' \
        'endfunction' \
        > "$TMP_ROOT/status-core-throw.vim"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -S "$TMP_ROOT/status-core-throw.vim" \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-core-throw.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq '── editor core ──' "$TMP_ROOT/status-core-throw.txt"
    grep -Fq 'ChopsticksCoreInfo() failed: status core boom' \
        "$TMP_ROOT/status-core-throw.txt"

    printf '%s\n' \
        'function! ChopsticksUtilityInfo() abort' \
        'return "bad"' \
        'endfunction' \
        > "$TMP_ROOT/status-utility-invalid.vim"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -S "$TMP_ROOT/status-utility-invalid.vim" \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-utility-invalid.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq '── utilities ──' "$TMP_ROOT/status-utility-invalid.txt"
    grep -Fq 'ChopsticksUtilityInfo() returned invalid status info' \
        "$TMP_ROOT/status-utility-invalid.txt"

    printf '%s\n' \
        'function! ChopsticksHelpInfo() abort' \
        'return {"title": "help surface", "items": "bad"}' \
        'endfunction' \
        > "$TMP_ROOT/status-help-malformed.vim"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -S "$TMP_ROOT/status-help-malformed.vim" \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-help-malformed.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq '── help surface ──' "$TMP_ROOT/status-help-malformed.txt"
    grep -Fq 'ChopsticksHelpInfo().items is not a List' \
        "$TMP_ROOT/status-help-malformed.txt"

    printf '%s\n' \
        'function! ChopsticksToolchainInfo() abort' \
        'return {"sections": [{"title": "outer tools", "items": [{"label": "outer tool", "state": "ready", "reason": "ok"}], "sections": [{"title": "inner tools", "items": [{"label": "inner tool", "state": "missing", "reason": "nested"}]}]}], "footers": []}' \
        'endfunction' \
        > "$TMP_ROOT/status-nested-section.vim"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -S "$TMP_ROOT/status-nested-section.vim" \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-nested-section.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq '── outer tools ──' "$TMP_ROOT/status-nested-section.txt"
    grep -Fq 'OK  outer tool  (ok)' "$TMP_ROOT/status-nested-section.txt"
    grep -Fq '── inner tools ──' "$TMP_ROOT/status-nested-section.txt"
    grep -Fq -- '--  inner tool  (nested)' "$TMP_ROOT/status-nested-section.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksLearningInfo") | cquit | endif' \
        -c 'let g:learning_keys = ChopsticksKeymapContractKeys("learning_entrypoint") | let g:learning = ChopsticksLearningInfo() | let g:commands = ChopsticksCommandInfo() | if join(g:learning_keys, "/") !=# "SPC ?" || get(g:learning, "title", "") !=# "learning" || !ChopsticksInfoShapeIssue(g:learning, "ChopsticksLearningInfo()").ok || len(get(g:learning, "details", [])) != 3 || get(g:learning.details[1], "value", "") !=# "SPC ?" || len(get(g:learning, "items", [])) != 4 || len(filter(copy(g:commands.commands), "get(v:val, \"owner\", \"\") ==# \"tutor\"")) != 1 || len(filter(copy(g:commands.commands), "get(v:val, \"owner\", \"\") ==# \"beta\"")) != 3 || get(g:learning.items[0], "label", "") !=# "active cheat sheet" || get(g:learning.items[0], "state", "") !=# "ready" || get(g:learning.items[0], "reason", "") !=# "SPC ?" || get(g:learning.items[1], "label", "") !=# "guided tutor" || get(g:learning.items[1], "state", "") !=# "ready" || get(g:learning.items[1], "reason", "") !=# ":ChopsticksTutor" | cquit | endif' \
        -c 'if get(g:learning.items[2], "label", "") !=# "native help" || get(g:learning.items[2], "state", "") !=# "ready" || get(g:learning.items[2], "diagnostic", 1) || get(g:learning.items[3], "label", "") !=# "release guide" || get(g:learning.items[3], "state", "") !=# "ready" || get(g:learning.items[3], "reason", "") !=# ":ChopsticksBeta" || get(g:learning.items[3], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! nunmap <Space>?' \
        -c 'let g:learning = ChopsticksLearningInfo() | let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if get(g:learning.items[0], "state", "") !=# "missing" || stridx(get(g:learning.items[0], "detail", ""), "SPC ?") < 0 || g:keymap.ok || empty(filter(copy(g:health.issues), "v:val.code ==# \"learning.active-cheat-sheet\" && stridx(v:val.detail, \"SPC ?\") >= 0")) || empty(filter(copy(g:health.issues), "v:val.code ==# \"keymap.ergonomic-contract\" && stridx(v:val.detail, \"missing nmap <Space>?\") >= 0")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksLintInfo") | cquit | endif' \
        -c 'let g:lint_keys = ChopsticksKeymapContractKeys("lint_keymaps") | let g:lint = ChopsticksLintInfo() | if join(g:lint_keys[0:1], "/") . "/" . join(g:lint_keys[2:], " ") !=# "SPC xd/SPC uf/[e ]e" || get(g:lint, "title", "") !=# "lint" || !ChopsticksInfoShapeIssue(g:lint, "ChopsticksLintInfo()").ok || len(get(g:lint, "details", [])) != 3 || len(get(g:lint, "items", [])) != 4 || get(g:lint.details[0], "value", "") !=# "ALE" || get(g:lint.details[1], "value", "") !=# "ON" | cquit | endif' \
        -c 'if get(g:lint.items[0], "label", "") !=# "ALE stack" || get(g:lint.items[0], "state", "") !=# "ready" || get(g:lint.items[0], "reason", "") !=# "installed" || get(g:lint.items[1], "label", "") !=# "lint keymaps" || get(g:lint.items[1], "state", "") !=# "ready" || get(g:lint.items[1], "reason", "") !=# "SPC xd/SPC uf/[e ]e" || get(g:lint.items[1], "diagnostic", 1) | cquit | endif' \
        -c 'if get(g:lint.items[2], "label", "") !=# "format on save" || get(g:lint.items[2], "state", "") !=# "ready" || get(g:lint.items[2], "reason", "") !=# "ON" || get(g:lint.items[3], "label", "") !=# "markdown lint" || get(g:lint.items[3], "state", "") !=# "off" || get(g:lint.items[3], "reason", "") !=# "quiet defaults" || get(g:lint.items[3], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! nunmap <Space>xd' \
        -c 'let g:lint = ChopsticksLintInfo() | let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if get(g:lint.items[1], "state", "") !=# "missing" || stridx(get(g:lint.items[1], "detail", ""), "SPC xd") < 0 || g:keymap.ok || empty(filter(copy(g:health.issues), "v:val.code ==# \"lint.lint-keymaps\" && stridx(v:val.detail, \"SPC xd\") >= 0")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim --cmd 'let g:chopsticks_keymap_style = "classic"' \
        -u .vimrc -i NONE -es -N \
        -c 'let g:lint_keys = ChopsticksKeymapContractKeys("lint_keymaps") | let g:lint = ChopsticksLintInfo() | if join(g:lint_keys[0:1], "/") . "/" . join(g:lint_keys[2:], " ") !=# ",aD/,af/[e ]e" || get(g:lint.items[1], "reason", "") !=# ",aD/,af/[e ]e" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksUiInfo") | cquit | endif' \
        -c 'let g:ui = ChopsticksUiInfo() | if get(g:ui, "title", "") !=# "ui" || !ChopsticksInfoShapeIssue(g:ui, "ChopsticksUiInfo()").ok || len(get(g:ui, "details", [])) != 3 || len(get(g:ui, "items", [])) != 6 || get(g:ui.details[0], "value", "") !=# "rich terminal" || get(g:ui.details[1], "value", "") !=# "solarized8" || get(g:ui.details[2], "value", "") !=# "custom" | cquit | endif' \
        -c 'if get(g:ui.items[0], "label", "") !=# "color palette" || get(g:ui.items[0], "state", "") !=# "ready" || get(g:ui.items[0], "reason", "") !=# "solarized8" || get(g:ui.items[1], "label", "") !=# "truecolor" | cquit | endif' \
        -c 'if g:has_true_color && exists("&termguicolors") && &termguicolors && (get(g:ui.items[1], "state", "") !=# "ready" || get(g:ui.items[1], "reason", "") !=# "termguicolors") | cquit | endif' \
        -c 'if g:has_true_color && !exists("&termguicolors") && (get(g:ui.items[1], "state", "") !=# "optional" || get(g:ui.items[1], "reason", "") !=# "Vim lacks termguicolors" || get(g:ui.items[1], "severity", "") !=# "setup") | cquit | endif' \
        -c 'if !g:has_true_color && (get(g:ui.items[1], "state", "") !=# "optional" || get(g:ui.items[1], "reason", "") !=# "COLORTERM not truecolor" || get(g:ui.items[1], "severity", "") !=# "setup") | cquit | endif' \
        -c 'if get(g:ui.items[2], "label", "") !=# "statusline" || get(g:ui.items[2], "state", "") !=# "ready" || get(g:ui.items[2], "reason", "") !=# "SLBuild" || get(g:ui.items[3], "label", "") !=# "tabline" || get(g:ui.items[3], "state", "") !=# "ready" || get(g:ui.items[4], "label", "") !=# "layout stability" || get(g:ui.items[4], "state", "") !=# "ready" || get(g:ui.items[5], "label", "") !=# "start screen" || get(g:ui.items[5], "state", "") !=# "ready" || get(g:ui.items[5], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksLanguageInfo") | cquit | endif' \
        -c 'let g:language = ChopsticksLanguageInfo() | if get(g:language, "title", "") !=# "languages" || !ChopsticksInfoShapeIssue(g:language, "ChopsticksLanguageInfo()").ok || len(get(g:language, "details", [])) != 3 || len(get(g:language, "items", [])) != 6 || get(g:language.details[0], "value", "") !=# "quiet defaults" || get(g:language.details[1], "value", "") !=# "PrevimOpen" || get(g:language.details[2], "value", "") !=# "none" | cquit | endif' \
        -c 'if get(g:language.items[0], "label", "") !=# "markdown syntax" || get(g:language.items[0], "state", "") !=# "ready" || get(g:language.items[1], "label", "") !=# "markdown writing mode" || get(g:language.items[1], "state", "") !=# "ready" || get(g:language.items[2], "label", "") !=# "markdown maps" || get(g:language.items[2], "reason", "") !=# "buffer-local on markdown" | cquit | endif' \
        -c 'if get(g:language.items[3], "label", "") !=# "markdown preview" || get(g:language.items[3], "state", "") !=# "ready" || get(g:language.items[3], "reason", "") !=# "PrevimOpen" || get(g:language.items[4], "label", "") !=# "go syntax" || get(g:language.items[4], "state", "") !=# "ready" || get(g:language.items[4], "reason", "") !=# "syntax only; LSP owns intelligence" || get(g:language.items[5], "label", "") !=# "filetype defaults" || get(g:language.items[5], "state", "") !=# "ready" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !empty(ChopsticksKeymapContractKeys("markdown_maps")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksCompletionInfo") | cquit | endif' \
        -c 'let g:completion = ChopsticksCompletionInfo() | if !empty(ChopsticksKeymapContractKeys("completion_keymaps")) || get(g:completion, "title", "") !=# "completion" || !ChopsticksInfoShapeIssue(g:completion, "ChopsticksCompletionInfo()").ok || len(get(g:completion, "details", [])) != 3 || len(get(g:completion, "items", [])) != 5 || get(g:completion.details[0], "value", "") !=# "asyncomplete" || get(g:completion.details[1], "value", "") !=# "vim-lsp" || get(g:completion.details[2], "value", "") !=# "off" | cquit | endif' \
        -c 'if get(g:completion.items[0], "label", "") !=# "completion engine" || get(g:completion.items[0], "state", "") !=# "ready" || get(g:completion.items[0], "reason", "") !=# "asyncomplete.vim" || get(g:completion.items[1], "label", "") !=# "vim-lsp completion source" || get(g:completion.items[1], "state", "") !=# "ready" || get(g:completion.items[1], "reason", "") !=# "asyncomplete-lsp.vim" | cquit | endif' \
        -c 'if get(g:completion.items[2], "label", "") !=# "auto popup" || get(g:completion.items[2], "state", "") !=# "ready" || get(g:completion.items[2], "reason", "") !=# "delay=50" || get(g:completion.items[3], "label", "") !=# "popup menu" || get(g:completion.items[3], "state", "") !=# "ready" || get(g:completion.items[3], "reason", "") !~# "pumheight=15" || get(g:completion.items[4], "label", "") !=# "completion keymaps" || get(g:completion.items[4], "state", "") !=# "off" || get(g:completion.items[4], "reason", "") !=# "disabled by default" || get(g:completion.items[4], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("*ChopsticksUtilityInfo") | cquit | endif' \
        -c 'let g:utility_config_keys = ChopsticksKeymapContractKeys("utility_config") | let g:utility_path_keys = ChopsticksKeymapContractKeys("utility_path_copy") | if join(g:utility_config_keys, "/") !=# "SPC fc/SPC fv/SPC fV" || (has("clipboard") && join(g:utility_path_keys, "/") !=# "SPC fp/SPC fn") | cquit | endif' \
        -c 'let g:utility = ChopsticksUtilityInfo() | if get(g:utility, "title", "") !=# "utilities" || !ChopsticksInfoShapeIssue(g:utility, "ChopsticksUtilityInfo()").ok || len(get(g:utility, "details", [])) != 3 || len(get(g:utility, "items", [])) != 4 || get(g:utility.items[0], "label", "") !=# "config actions" || get(g:utility.items[0], "state", "") !=# "ready" || get(g:utility.items[0], "reason", "") !=# "SPC fc/SPC fv/SPC fV" || get(g:utility.items[2], "state", "") !=# "off" || get(g:utility.items[2], "reason", "") !=# "space layout uses SPC W" || get(g:utility.items[3], "state", "") !=# "off" || get(g:utility.items[3], "diagnostic", 1) | cquit | endif' \
        -c 'if has("clipboard") && (get(g:utility.items[1], "state", "") !=# "ready" || get(g:utility.items[1], "reason", "") !=# "SPC fp/SPC fn" || get(g:utility.items[1], "diagnostic", 1)) | cquit | endif' \
        -c 'if !has("clipboard") && (get(g:utility.items[1], "state", "") !=# "off" || get(g:utility.items[1], "diagnostic", 1)) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let g:nav = ChopsticksNavigationInfo()' \
        -c 'let g:project_search_keys = ChopsticksKeymapContractKeys("project_search") | let g:sidebar_keys = ChopsticksKeymapContractKeys("file_sidebar") | let g:window_navigation_keys = ChopsticksKeymapContractKeys("window_navigation") | let g:layout_keys = ChopsticksKeymapContractKeys("window_layout") | if join(g:project_search_keys[0:1], "/") !=# "SPC SPC/SPC /" || join(g:sidebar_keys, "/") !=# "SPC e/SPC E" || join(g:window_navigation_keys, "/") !=# "<C-h>/<C-j>/<C-k>/<C-l>" || join(g:layout_keys, "/") !=# "SPC z" | cquit | endif' \
        -c 'let g:project_files_keys = ChopsticksKeymapContractKeys("project_files") | let g:project_buffers_keys = ChopsticksKeymapContractKeys("project_buffers") | let g:project_grep_keys = ChopsticksKeymapContractKeys("project_grep") | if join(g:project_files_keys, "/") !=# "SPC SPC" || join(g:project_buffers_keys, "/") !=# "SPC ," || join(g:project_grep_keys, "/") !=# "SPC /" | cquit | endif' \
        -c 'if get(g:nav, "title", "") !=# "navigation" || !ChopsticksInfoShapeIssue(g:nav, "ChopsticksNavigationInfo()").ok || len(get(g:nav, "items", [])) != 6 | cquit | endif' \
        -c 'if get(g:nav.items[0], "label", "") !=# "project search" || get(g:nav.items[0], "state", "") !=# "ready" || get(g:nav.items[0], "reason", "") !=# "SPC SPC/SPC /" || !empty(get(g:nav, "missing_search_maps", [])) || !empty(get(g:nav, "missing_search_commands", [])) || !empty(get(g:nav, "missing_search_tools", [])) | cquit | endif' \
        -c 'if get(g:nav.items[1], "label", "") !=# "file sidebar" || get(g:nav.items[1], "state", "") !=# "ready" || get(g:nav.items[1], "reason", "") !=# "SPC e/SPC E" || !empty(get(g:nav, "missing_sidebar_maps", [])) || !empty(get(g:nav, "missing_sidebar_commands", [])) | cquit | endif' \
        -c 'if get(g:nav.items[2], "label", "") !=# "window navigation" || get(g:nav.items[2], "state", "") !=# "ready" || get(g:nav.items[2], "reason", "") !=# "vim splits" || !empty(get(g:nav, "missing_window_maps", [])) | cquit | endif' \
        -c 'if get(g:nav.items[3], "label", "") !=# "window layout" || get(g:nav.items[3], "state", "") !=# "ready" || get(g:nav.items[3], "reason", "") !=# "SPC z" || !empty(get(g:nav, "missing_layout_maps", [])) || get(g:nav.items[4], "label", "") !=# "terminal navigation" || get(g:nav.items[4], "state", "") !=# "off" || get(g:nav.items[5], "label", "") !=# "tmux navigator" || get(g:nav.items[5], "state", "") !=# "off" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let g:file_picker_keys = ChopsticksKeymapContractKeys("project_files_picker") | let g:buffer_picker_keys = ChopsticksKeymapContractKeys("project_buffers_picker") | let g:git_file_keys = ChopsticksKeymapContractKeys("project_git_files") | let g:recent_file_keys = ChopsticksKeymapContractKeys("project_recent_files") | let g:buffer_line_keys = ChopsticksKeymapContractKeys("project_buffer_lines") | if join(g:file_picker_keys, "/") !=# "SPC ff" || join(g:buffer_picker_keys, "/") !=# "SPC fb" || join(g:git_file_keys, "/") !=# "SPC fg" || join(g:recent_file_keys, "/") !=# "SPC fr" || join(g:buffer_line_keys, "/") !=# "SPC fl" | cquit | endif' \
        -c 'let g:command_keys = ChopsticksKeymapContractKeys("project_commands") | let g:mark_keys = ChopsticksKeymapContractKeys("project_marks") | let g:search_history_keys = ChopsticksKeymapContractKeys("project_search_history") | let g:command_history_keys = ChopsticksKeymapContractKeys("project_command_history") | let g:grep_picker_keys = ChopsticksKeymapContractKeys("project_grep_picker") | let g:grep_word_keys = ChopsticksKeymapContractKeys("project_grep_word") | let g:tag_keys = ChopsticksKeymapContractKeys("project_tags") | if join(g:command_keys, "/") !=# "SPC sc" || join(g:mark_keys, "/") !=# "SPC sm" || join(g:search_history_keys, "/") !=# "SPC s/" || join(g:command_history_keys, "/") !=# "SPC s:" || join(g:grep_picker_keys, "/") !=# "SPC sg" || join(g:grep_word_keys, "/") !=# "SPC sw" || join(g:tag_keys, "/") !=# "SPC st" | cquit | endif' \
        -c 'let g:close_other_keys = ChopsticksKeymapContractKeys("buffer_close_others") | let g:quickfix_window_keys = ChopsticksKeymapContractKeys("quickfix_window") | let g:loclist_window_keys = ChopsticksKeymapContractKeys("loclist_window") | let g:quickfix_nav_keys = ChopsticksKeymapContractKeys("quickfix_navigation") | let g:loclist_nav_keys = ChopsticksKeymapContractKeys("loclist_navigation") | let g:terminal_keys = ChopsticksKeymapContractKeys("terminal_entry") | if join(g:close_other_keys, "/") !=# "SPC bo" || join(g:quickfix_window_keys, "/") !=# "SPC xq/SPC xQ" || join(g:loclist_window_keys, "/") !=# "SPC xl/SPC xL" || join(g:quickfix_nav_keys, "/") !=# "[q/]q" || join(g:loclist_nav_keys, "/") !=# "[l/]l" || (has("terminal") && join(g:terminal_keys, "/") !=# "SPC tt/SPC th") | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! nunmap <Space>/' \
        -c 'let g:nav = ChopsticksNavigationInfo() | let g:health = ChopsticksHealthInfo() | if get(g:nav.items[0], "label", "") !=# "project search" || get(g:nav.items[0], "state", "") !=# "missing" || get(g:nav.items[0], "detail", "") !~# "SPC /" || empty(filter(copy(g:health.issues), "v:val.code ==# \"navigation.project-search\" && v:val.detail =~# \"SPC /\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksRuntimeInfo() abort' \
        -c 'return {"title": "runtime", "items": [{"label": "runtime item", "state": "ready", "reason": "custom", "diagnostic": 1, "severity": "info", "issue_label": "custom runtime", "detail": "from runtime items", "action": "custom action"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"runtime.custom-runtime\" && v:val.detail ==# \"from runtime items\" && v:val.action ==# \"custom action\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksRuntimeInfo() abort' \
        -c 'return {"title": "runtime", "items": [{"label": "runtime info", "diagnostic": 1, "severity": "info", "issue_label": "runtime info", "detail": "runtime info first by module", "action": "runtime action"}]}' \
        -c 'endfunction' \
        -c 'function! ChopsticksCoreInfo() abort' \
        -c 'return {"title": "editor core", "items": [{"label": "core attention", "diagnostic": 1, "severity": "attention", "issue_label": "core attention", "detail": "core attention second by module", "action": "core action"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if len(g:health.issues) < 2 || get(g:health.issues[0], "code", "") !=# "core.core-attention" || get(g:health.issues[-1], "code", "") !=# "runtime.runtime-info" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksCoreInfo() abort' \
        -c 'return {"title": "editor core", "items": [{"label": "editor defaults", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom core", "detail": "from core item", "action": "fix core"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"core.custom-core\" && v:val.detail ==# \"from core item\" && v:val.action ==# \"fix core\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksCoreInfo() abort' \
        -c 'return {"title": "editor core", "items": [{"label": "bad severity", "diagnostic": 1, "severity": "urgent", "issue_label": "bad severity", "detail": "bad severity item", "action": "fix severity"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"core.bad-severity\" && v:val.severity ==# \"attention\" && v:val.detail ==# \"bad severity item\"")) || get(g:health.summary, "urgent", 0) != 0 || get(g:health.summary, "attention", 0) != 1 || g:health.state !=# "attention" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'delfunction ChopsticksCoreInfo' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"core.editor-core-interface\" && v:val.detail ==# \"ChopsticksCoreInfo() is not loaded\" && v:val.action ==# \"reload chopsticks\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksCoreInfo() abort' \
        -c 'return {"title": "editor core"}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"core.editor-core-interface\" && v:val.detail ==# \"ChopsticksCoreInfo() returned no diagnostic items\" && v:val.action ==# \"return an items list from ChopsticksCoreInfo()\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksCoreInfo() abort' \
        -c 'return "bad"' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"core.editor-core-interface\" && v:val.detail ==# \"ChopsticksCoreInfo() returned invalid diagnostic info\" && v:val.action ==# \"return a Dictionary from ChopsticksCoreInfo()\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksCoreInfo() abort' \
        -c 'return {"title": "editor core", "items": "bad"}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"core.editor-core-interface\" && v:val.detail ==# \"ChopsticksCoreInfo().items is not a List\" && v:val.action ==# \"return a List from ChopsticksCoreInfo().items\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksCoreInfo() abort' \
        -c 'return {"title": "editor core", "items": ["bad"]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"core.editor-core-interface\" && v:val.detail ==# \"ChopsticksCoreInfo().items[0] is not a Dictionary\" && v:val.action ==# \"return Dictionary entries from ChopsticksCoreInfo().items\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksCoreInfo() abort' \
        -c 'throw "boom"' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"core.editor-core-interface\" && v:val.detail =~# \"ChopsticksCoreInfo() failed:\" && v:val.action ==# \"fix ChopsticksCoreInfo() and reload chopsticks\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksHelpInfo() abort' \
        -c 'return {"title": "help surface", "items": [{"label": "help document", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom help", "detail": "from help item", "action": "fix help"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"help.custom-help\" && v:val.detail ==# \"from help item\" && v:val.action ==# \"fix help\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksToolchainInfo() abort' \
        -c 'return {"sections": [{"title": "custom tools", "severity": "setup", "items": [{"label": "custom tool", "state": "missing", "diagnostic": 1, "severity": "optional", "issue_label": "custom tool", "detail": "from toolchain item", "action": "install custom"}, {"label": "section default tool", "state": "missing", "diagnostic": 1, "issue_label": "section default", "detail": "from section default", "action": "install section default"}]}], "footers": []}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"toolchain.custom-tool\" && v:val.severity ==# \"optional\" && v:val.detail ==# \"from toolchain item\" && v:val.action ==# \"install custom\"")) || empty(filter(copy(g:health.issues), "v:val.code ==# \"toolchain.section-default\" && v:val.severity ==# \"setup\" && v:val.detail ==# \"from section default\" && v:val.action ==# \"install section default\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksToolchainInfo() abort' \
        -c 'return {"sections": [{"title": "bad section", "severity": "urgent", "items": [{"label": "section default", "state": "missing", "diagnostic": 1, "issue_label": "section severity", "detail": "bad section severity", "action": "fix section severity"}]}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"toolchain.section-severity\" && v:val.severity ==# \"attention\" && v:val.detail ==# \"bad section severity\"")) || get(g:health.summary, "urgent", 0) != 0 || get(g:health.summary, "attention", 0) != 1 || g:health.state !=# "attention" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksToolchainInfo() abort' \
        -c 'return {"sections": "bad"}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"toolchain.toolchain-interface\" && v:val.detail ==# \"ChopsticksToolchainInfo().sections is not a List\" && v:val.action ==# \"return a List from ChopsticksToolchainInfo().sections\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksToolchainInfo() abort' \
        -c 'return {"sections": ["bad"]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"toolchain.toolchain-interface\" && v:val.detail ==# \"ChopsticksToolchainInfo().sections[0] is not a Dictionary\" && v:val.action ==# \"return Dictionary entries from ChopsticksToolchainInfo().sections\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksToolchainInfo() abort' \
        -c 'return {"sections": [{"title": "bad", "items": "bad"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"toolchain.toolchain-interface\" && v:val.detail ==# \"ChopsticksToolchainInfo().sections[0].items is not a List\" && v:val.action ==# \"return a List from ChopsticksToolchainInfo().sections[0].items\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksToolchainInfo() abort' \
        -c 'return {"sections": [{"title": "bad", "items": ["bad"]}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"toolchain.toolchain-interface\" && v:val.detail ==# \"ChopsticksToolchainInfo().sections[0].items[0] is not a Dictionary\" && v:val.action ==# \"return Dictionary entries from ChopsticksToolchainInfo().sections[0].items\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    printf '%s\n' \
        'function! ChopsticksToolchainInfo() abort' \
        'return {"sections": [], "footers": "bad"}' \
        'endfunction' \
        > "$TMP_ROOT/health-toolchain-footers.vim"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -S "$TMP_ROOT/health-toolchain-footers.vim" \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"toolchain.toolchain-interface\" && v:val.detail ==# \"ChopsticksToolchainInfo().footers is not a List\" && v:val.action ==# \"return a List from ChopsticksToolchainInfo().footers\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    printf '%s\n' \
        'function! ChopsticksToolchainInfo() abort' \
        'return {"sections": [], "footers": [{}]}' \
        'endfunction' \
        > "$TMP_ROOT/health-toolchain-footer-entry.vim"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -S "$TMP_ROOT/health-toolchain-footer-entry.vim" \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"toolchain.toolchain-interface\" && v:val.detail ==# \"ChopsticksToolchainInfo().footers[0] is not a String\" && v:val.action ==# \"return String entries from ChopsticksToolchainInfo().footers\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    printf '%s\n' \
        'function! ChopsticksToolchainInfo() abort' \
        'return {"sections": [{"title": "outer", "sections": [{"title": "inner", "items": "bad"}]}]}' \
        'endfunction' \
        > "$TMP_ROOT/health-toolchain-nested-bad.vim"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -S "$TMP_ROOT/health-toolchain-nested-bad.vim" \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"toolchain.toolchain-interface\" && v:val.detail ==# \"ChopsticksToolchainInfo().sections[0].sections[0].items is not a List\" && v:val.action ==# \"return a List from ChopsticksToolchainInfo().sections[0].sections[0].items\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    printf '%s\n' \
        'function! ChopsticksToolchainInfo() abort' \
        'return {"sections": [{"title": "outer", "severity": "setup", "sections": [{"title": "inner", "items": [{"label": "nested tool", "state": "missing", "diagnostic": 1, "issue_label": "nested tool", "detail": "from nested tool", "action": "install nested"}]}]}]}' \
        'endfunction' \
        > "$TMP_ROOT/health-toolchain-nested-issue.vim"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -S "$TMP_ROOT/health-toolchain-nested-issue.vim" \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"toolchain.nested-tool\" && v:val.severity ==# \"setup\" && v:val.detail ==# \"from nested tool\" && v:val.action ==# \"install nested\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksLspInfo() abort' \
        -c 'return {"title": "lsp servers", "stack": {"state": "ready"}, "servers": []}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"lsp.lsp-interface\" && v:val.detail ==# \"ChopsticksLspInfo() returned no diagnostic items\" && v:val.action ==# \"return an items list from ChopsticksLspInfo()\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksLspInfo() abort' \
        -c 'return {"title": "lsp servers", "items": ["bad"]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"lsp.lsp-interface\" && v:val.detail ==# \"ChopsticksLspInfo().items[0] is not a Dictionary\" && v:val.action ==# \"return Dictionary entries from ChopsticksLspInfo().items\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksUiInfo() abort' \
        -c 'return {"title": "ui", "items": [{"label": "color palette", "state": "missing", "diagnostic": 1, "severity": "setup", "issue_label": "custom ui", "detail": "from ui item", "action": "fix ui"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"ui.custom-ui\" && v:val.detail ==# \"from ui item\" && v:val.action ==# \"fix ui\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksLanguageInfo() abort' \
        -c 'return {"title": "languages", "items": [{"label": "markdown syntax", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom language", "detail": "from language item", "action": "fix language"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"languages.custom-language\" && v:val.detail ==# \"from language item\" && v:val.action ==# \"fix language\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksLintInfo() abort' \
        -c 'return {"title": "lint", "items": [{"label": "ALE stack", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom lint", "detail": "from lint item", "action": "fix lint"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"lint.custom-lint\" && v:val.detail ==# \"from lint item\" && v:val.action ==# \"fix lint\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksCompletionInfo() abort' \
        -c 'return {"title": "completion", "items": [{"label": "popup menu", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom completion", "detail": "from completion item", "action": "fix completion"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"completion.custom-completion\" && v:val.detail ==# \"from completion item\" && v:val.action ==# \"fix completion\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksEditingInfo() abort' \
        -c 'return {"title": "editing", "items": [{"label": "editing assist", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom editing", "detail": "from editing item", "action": "fix editing"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"editing.custom-editing\" && v:val.detail ==# \"from editing item\" && v:val.action ==# \"fix editing\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksBufferInfo() abort' \
        -c 'return {"title": "buffers", "items": [{"label": "buffer lifecycle", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom buffer", "detail": "from buffer item", "action": "fix buffers"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"buffers.custom-buffer\" && v:val.detail ==# \"from buffer item\" && v:val.action ==# \"fix buffers\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksQuickfixInfo() abort' \
        -c 'return {"title": "quickfix", "items": [{"label": "quickfix", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom quickfix", "detail": "from quickfix item", "action": "fix quickfix"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"quickfix.custom-quickfix\" && v:val.detail ==# \"from quickfix item\" && v:val.action ==# \"fix quickfix\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksNavigationInfo() abort' \
        -c 'return {"title": "navigation", "items": [{"label": "window layout", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom navigation", "detail": "from navigation item", "action": "fix navigation"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"navigation.custom-navigation\" && v:val.detail ==# \"from navigation item\" && v:val.action ==# \"fix navigation\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksUtilityInfo() abort' \
        -c 'return {"title": "utilities", "items": [{"label": "config actions", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom utility", "detail": "from utility item", "action": "fix utilities"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"utilities.custom-utility\" && v:val.detail ==# \"from utility item\" && v:val.action ==# \"fix utilities\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksLearningInfo() abort' \
        -c 'return {"title": "learning", "items": [{"label": "active cheat sheet", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom learning", "detail": "from learning item", "action": "fix learning"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"learning.custom-learning\" && v:val.detail ==# \"from learning item\" && v:val.action ==# \"fix learning\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksFileSafetyInfo() abort' \
        -c 'return {"title": "file safety", "items": [{"label": "file safety", "state": "missing", "diagnostic": 1, "severity": "attention", "issue_label": "custom file safety", "detail": "from file safety item", "action": "set file safety"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"file-safety.custom-file-safety\" && v:val.detail ==# \"from file safety item\" && v:val.action ==# \"set file safety\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksGitInfo() abort' \
        -c 'return {"title": "git", "items": [{"label": "git loop", "state": "missing", "diagnostic": 1, "severity": "setup", "issue_label": "custom git", "detail": "from git item", "action": "install git loop"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"git.custom-git\" && v:val.detail ==# \"from git item\" && v:val.action ==# \"install git loop\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'function! ChopsticksRunnerInfo() abort' \
        -c 'return {"title": "run file", "items": [{"label": "run file", "state": "missing", "diagnostic": 1, "severity": "setup", "issue_label": "custom runner", "detail": "from runner item", "action": "install runner"}]}' \
        -c 'endfunction' \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"runner.custom-runner\" && v:val.detail ==# \"from runner item\" && v:val.action ==# \"install runner\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let g:chopsticks_module_loads = filter(copy(g:chopsticks_module_loads), "get(v:val, \"name\", \"\") !=# \"status\"")' \
        -c 'let g:modules = ChopsticksModuleInfo() | let g:health = ChopsticksHealthInfo() | if g:modules.ok || empty(get(g:modules, "missing", [])) || get(g:modules.items[-1], "label", "") !=# "missing" || !get(g:modules.items[-1], "diagnostic", 0) || get(g:modules.items[-1], "issue_label", "") !=# "module manifest" || get(g:modules.items[-1], "detail", "") !~# "not loaded:" || g:health.summary.attention != 1 || empty(filter(copy(g:health.issues), "v:val.code ==# \"modules.module-manifest\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    printf '%s\n' \
        'function! ChopsticksRuntimeInfo() abort' \
        'return {"title": "runtime", "remote": 1, "remote_source": "legacy"}' \
        'endfunction' \
        'function! ChopsticksLocalConfigInfo() abort' \
        'return {"title": "local preferences", "exists": 1, "ok": 0, "error": "legacy local error"}' \
        'endfunction' \
        'function! ChopsticksModuleInfo() abort' \
        'return {"title": "modules", "missing": ["legacy-module"]}' \
        'endfunction' \
        'function! ChopsticksPluginInfo() abort' \
        'return {"title": "plugin reproducibility", "missing_locks": ["legacy-plugin"], "missing_installs": ["legacy-plugin"]}' \
        'endfunction' \
        > "$TMP_ROOT/health-side-fields-no-items.vim"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -S "$TMP_ROOT/health-side-fields-no-items.vim" \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"runtime.runtime-interface\" && v:val.detail ==# \"ChopsticksRuntimeInfo() returned no diagnostic items\"")) || empty(filter(copy(g:health.issues), "v:val.code ==# \"local-config.local-config-interface\" && v:val.detail ==# \"ChopsticksLocalConfigInfo() returned no diagnostic items\"")) | cquit | endif' \
        -c 'if empty(filter(copy(g:health.issues), "v:val.code ==# \"modules.module-interface\" && v:val.detail ==# \"ChopsticksModuleInfo() returned no diagnostic items\"")) || empty(filter(copy(g:health.issues), "v:val.code ==# \"plugins.plugin-interface\" && v:val.detail ==# \"ChopsticksPluginInfo() returned no diagnostic items\"")) | cquit | endif' \
        -c 'if !empty(filter(copy(g:health.issues), "v:val.code ==# \"runtime.remote-session\" || v:val.code ==# \"local-config.local-preferences\" || v:val.code ==# \"modules.module-manifest\" || v:val.code ==# \"plugins.plugin-locks\" || v:val.code ==# \"plugins.plugin-install\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! delcommand ChopsticksTutor' \
        -c 'let g:commands = ChopsticksCommandInfo() | let g:learning = ChopsticksLearningInfo() | let g:health = ChopsticksHealthInfo() | if g:commands.ok || len(get(g:commands, "missing", [])) != 1 || len(get(g:commands, "items", [])) != 1 || get(g:commands.items[0], "label", "") !=# ":ChopsticksTutor" || get(g:commands.items[0], "state", "") !=# "missing" || get(g:commands.items[0], "reason", "") !=# "tutor" || !get(g:commands.items[0], "diagnostic", 0) || get(g:commands.items[0], "issue_label", "") !=# "ChopsticksTutor" || get(g:commands.items[0], "detail", "") !=# "missing public command from tutor" || get(g:commands.items[0], "action", "") !=# "check module load and command definition" || get(g:learning.items[1], "state", "") !=# "missing" || g:health.summary.attention != 2 || empty(filter(copy(g:health.issues), "v:val.code ==# \"commands.chopstickstutor\"")) || empty(filter(copy(g:health.issues), "v:val.code ==# \"learning.guided-tutor\"")) | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-missing-command.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq -- '--  :ChopsticksTutor  (tutor)' \
        "$TMP_ROOT/status-missing-command.txt"
    grep -Fq -- '--  guided tutor  (missing: :ChopsticksTutor)' \
        "$TMP_ROOT/status-missing-command.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! delcommand ChopsticksBetaLog' \
        -c 'let g:commands = ChopsticksCommandInfo() | let g:learning = ChopsticksLearningInfo() | let g:health = ChopsticksHealthInfo() | if g:commands.ok || len(get(g:commands, "missing", [])) != 1 || get(g:commands.missing[0], "name", "") !=# "ChopsticksBetaLog" || get(g:learning.items[3], "label", "") !=# "release guide" || get(g:learning.items[3], "state", "") !=# "missing" || get(g:learning.items[3], "reason", "") !~# ":ChopsticksBetaLog" || g:health.summary.attention != 2 || empty(filter(copy(g:health.issues), "v:val.code ==# \"commands.chopsticksbetalog\"")) || empty(filter(copy(g:health.issues), "v:val.code ==# \"learning.release-guide\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'command! ChopsticksScratch echo "scratch"' \
        -c 'let g:commands = ChopsticksCommandInfo() | let g:health = ChopsticksHealthInfo() | if g:commands.ok || len(get(g:commands, "unlisted", [])) != 1 || get(g:commands.unlisted, 0, "") !=# "ChopsticksScratch" || get(g:commands.items[-1], "label", "") !=# ":ChopsticksScratch" || get(g:commands.items[-1], "reason", "") !=# "unlisted" || get(g:commands.items[-1], "detail", "") !~# "missing from command catalog" || g:health.summary.attention != 1 || empty(filter(copy(g:health.issues), "v:val.code ==# \"commands.chopsticksscratch\" && v:val.detail =~# \"missing from command catalog\"")) | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-unlisted-command.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq -- '--  :ChopsticksScratch  (unlisted)' \
        "$TMP_ROOT/status-unlisted-command.txt"

    printf '%s\n' \
        'function! ChopsticksCommandInfo() abort' \
        'return {"title": "command surface", "missing": [{"name": "ChopsticksLegacy", "owner": "legacy"}]}' \
        'endfunction' \
        > "$TMP_ROOT/health-command-no-items.vim"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -S "$TMP_ROOT/health-command-no-items.vim" \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"commands.command-interface\" && v:val.detail ==# \"ChopsticksCommandInfo() returned no diagnostic items\" && v:val.action ==# \"return an items list from ChopsticksCommandInfo()\"")) || !empty(filter(copy(g:health.issues), "v:val.code ==# \"commands.chopstickslegacy\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if exists(":ChopsticksDoctor") != 2 | cquit | endif' \
        -c 'if ChopsticksHealthInfo().summary.attention != 0 | cquit | endif' \
        -c 'ChopsticksDoctor' \
        -c "redir! > $TMP_ROOT/doctor-default.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'chopsticks doctor' "$TMP_ROOT/doctor-default.txt"
    grep -Fq 'attention 0' "$TMP_ROOT/doctor-default.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_profile = "bad-profile"' \
        -c 'let g:chopsticks_keymap_style = "bad-keymap"' \
        -c 'source .vimrc' \
        -c 'ChopsticksDoctor' \
        -c "redir! > $TMP_ROOT/doctor-invalid-profile.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq '[profile.profile-value]' "$TMP_ROOT/doctor-invalid-profile.txt"
    grep -Fq '[profile.keymap-value]' "$TMP_ROOT/doctor-invalid-profile.txt"

    printf '%s\n' \
        'function! ChopsticksProfileInfo() abort' \
        'return {"title": "profile", "items": [{"label": "custom profile", "state": "missing", "diagnostic": 1, "severity": "setup", "issue_label": "custom profile", "detail": "from profile item", "action": "fix profile"}]}' \
        'endfunction' \
        > "$TMP_ROOT/health-profile-custom-item.vim"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -S "$TMP_ROOT/health-profile-custom-item.vim" \
        -c 'let g:health = ChopsticksHealthInfo() | if empty(filter(copy(g:health.issues), "v:val.code ==# \"profile.custom-profile\" && v:val.severity ==# \"setup\" && v:val.detail ==# \"from profile item\" && v:val.action ==# \"fix profile\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_STEP=keymap
    step "Keymap contract and opt-ins"
    CHOPSTICKS_TEST_KEYMAP_PHASE="default space contract"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let last_change_map = nr2char(96) . "[v" . nr2char(96) . "]"' \
        -c 'if maparg("0", "n") !=# "" || maparg("0", "v") !=# "" || maparg("Y", "n") !=# "" || maparg("Q", "n") !=# "" || maparg("<Space>", "n") !=# "" || maparg("//", "v") !=# "" || maparg("gV", "n") !=# "" || maparg("jk", "i") !=# "" || maparg("<C-s>", "n") !=# "" || maparg("<C-s>", "i") !=# "" || maparg("<C-p>", "n") !=# "" || maparg("<C-p>", "c") !=# "" || maparg("<C-n>", "c") !=# "" || maparg("w!!", "c") !=# "" | cquit | endif' \
        -c 'if maparg("<C-h>", "n") !~# "NavigateWindow" || maparg("<C-j>", "n") !~# "NavigateWindow" || maparg("<C-k>", "n") !~# "NavigateWindow" || maparg("<C-l>", "n") !~# "NavigateWindow" | cquit | endif' \
        -c 'if has_key(g:plugs, "auto-pairs") || maparg("<Tab>", "i") =~# "pumvisible" || maparg("<S-Tab>", "i") =~# "pumvisible" || maparg("<CR>", "i") =~# "asyncomplete#close_popup" || maparg("<CR>", "i") =~# "AutoPairs" | cquit | endif' \
        -c 'if maparg("<Esc><Esc>", "t") !=# "" || maparg("<C-h>", "t") !=# "" || maparg("<C-j>", "t") !=# "" || maparg("<C-k>", "t") !=# "" || maparg("<C-l>", "t") !=# "" | cquit | endif' \
        -c 'if maparg("s", "n") !~# "easymotion-overwin-f2" | cquit | endif' \
        -c 'if maparg("<Space>/", "v") !~# "escape" || maparg("<Space>v", "n") !=# last_change_map || maparg("<Space><Space>", "n") !~# "SmartFiles" || maparg("<Space><Tab>", "n") !~# "Balternate" || maparg("<Space>z", "n") !~# "ToggleMaximize" | cquit | endif' \
        -c 'if maparg(",/", "v") !=# "" || maparg(",v", "n") !=# "" || maparg(",ff", "n") !=# "" | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_KEYMAP_PHASE="keymap audit surface"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if exists(":ChopsticksKeymapAudit") != 2 || !exists("*ChopsticksKeymapContractSpecs") || !exists("*ChopsticksKeymapContractSpecsFor") || !exists("*ChopsticksKeymapContractKeys") || !exists("*ChopsticksKeymapContractLines") || !exists("*ChopsticksKeymapAuditIssues") || !exists("*ChopsticksKeymapAuditInfo") | cquit | endif' \
        -c 'let g:contract = ChopsticksKeymapContractSpecs() | let g:contract_leader = !empty(filter(copy(g:contract.specs), "get(v:val, \"kind\", \"\") ==# \"leader\" && get(v:val, \"var\", \"\") ==# \"mapleader\"")) | let g:contract_save = !empty(filter(copy(g:contract.specs), "get(v:val, \"kind\", \"\") ==# \"map\" && get(v:val, \"lhs\", \"\") ==# \"<Space>w\" && get(v:val, \"text\", \"\") ==# \":w\"")) | let g:contract_no_push = !empty(filter(copy(g:contract.specs), "get(v:val, \"kind\", \"\") ==# \"no_map\" && get(v:val, \"lhs\", \"\") ==# \"<Space>gp\"")) | let g:learning_entrypoint_lines = ChopsticksKeymapContractLines("learning_entrypoint", "  ", 9) | let g:learning_entrypoint_keys = ChopsticksKeymapContractKeys("learning_entrypoint") | let g:survival_key_lines = ChopsticksKeymapContractLines("survival_core", "  ", 9) | let g:survival_config_lines = ChopsticksKeymapContractLines("survival_config", "  ", 9) | let g:core_survival_specs = ChopsticksKeymapContractSpecsFor("core_survival") | let g:core_survival_keys = ChopsticksKeymapContractKeys("core_survival")' \
        -c 'let g:project_files_keys = ChopsticksKeymapContractKeys("project_files") | let g:project_buffers_keys = ChopsticksKeymapContractKeys("project_buffers") | let g:project_grep_keys = ChopsticksKeymapContractKeys("project_grep") | let g:project_tags_keys = ChopsticksKeymapContractKeys("project_tags")' \
        -c 'if get(g:contract, "title", "") !=# "keymap contract" || !ChopsticksInfoShapeIssue(g:contract, "ChopsticksKeymapContractSpecs()").ok || get(g:contract, "layout", "") !=# "space" || len(get(g:contract, "specs", [])) < 50 || !g:contract_leader || !g:contract_save || !g:contract_no_push || len(g:learning_entrypoint_lines) != 1 || g:learning_entrypoint_lines[0] !=# "  SPC ?     active cheat sheet" || join(g:learning_entrypoint_keys, "/") !=# "SPC ?" || join(g:project_files_keys, "/") !=# "SPC SPC" || join(g:project_buffers_keys, "/") !=# "SPC ," || join(g:project_grep_keys, "/") !=# "SPC /" || join(g:project_tags_keys, "/") !=# "SPC st" || len(g:survival_key_lines) != 3 || g:survival_key_lines[0] !=# "  SPC w     save" || g:survival_key_lines[-1] !=# "  SPC q     quit" || len(g:survival_config_lines) != 3 || g:survival_config_lines[0] !=# "  SPC fc    edit local config" || len(g:core_survival_specs) != 5 || join(g:core_survival_keys, "/") !=# "SPC w/SPC W/SPC q/SPC uh/SPC fd" | cquit | endif' \
        -c 'let g:keymap = ChopsticksKeymapAuditInfo() | if get(g:keymap, "title", "") !=# "keymap audit" || !ChopsticksInfoShapeIssue(g:keymap, "ChopsticksKeymapAuditInfo()").ok || !g:keymap.ok || g:keymap.issue_count != 0 || len(get(g:keymap, "details", [])) != 2 || len(get(g:keymap, "items", [])) != 1 || get(g:keymap.items[0], "state", "") !=# "ready" || get(g:keymap.items[0], "reason", "") !=# ":ChopsticksKeymapAudit" || get(g:keymap.items[0], "diagnostic", 1) || !empty(get(g:keymap.items[0], "diagnostics", [])) | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-keymap-audit.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'OK  keymap audit  (:ChopsticksKeymapAudit)' "$TMP_ROOT/status-keymap-audit.txt"

    CHOPSTICKS_TEST_KEYMAP_PHASE="keymap audit missing map"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! nunmap <Space>w' \
        -c 'let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if g:keymap.ok || g:keymap.issue_count < 1 || get(g:keymap.items[0], "state", "") !=# "missing" || !get(g:keymap.items[0], "diagnostic", 0) || len(get(g:keymap.items[0], "diagnostics", [])) != g:keymap.issue_count || get(g:keymap.items[0].diagnostics[0], "issue_label", "") !=# "ergonomic contract" || get(g:keymap.items[0].diagnostics[0], "action", "") !=# ":ChopsticksKeymapAudit" || empty(filter(copy(g:health.issues), "v:val.code ==# \"keymap.ergonomic-contract\" && v:val.detail =~# \"missing nmap <Space>w\"")) | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-keymap-audit-broken.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq -- '--  keymap audit  (' \
        "$TMP_ROOT/status-keymap-audit-broken.txt"

    CHOPSTICKS_TEST_KEYMAP_PHASE="classic summary keys"
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim --cmd 'let g:chopsticks_keymap_style = "classic"' \
        -u .vimrc -i NONE -es -N \
        -c 'let g:line_move_keys = ChopsticksKeymapContractKeys("line_move_summary") | let g:clipboard_keys = ChopsticksKeymapContractKeys("clipboard_summary") | if join(g:line_move_keys, "/") !=# "Alt+j/Alt+k" || (has("clipboard") && join(g:clipboard_keys, "/") !=# ",y/,p") || (!has("clipboard") && !empty(g:clipboard_keys)) | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_KEYMAP_PHASE="classic core maps"
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim --cmd 'let g:chopsticks_keymap_style = "classic"' \
        -u .vimrc -i NONE -es -N \
        -c 'let last_change_map = nr2char(96) . "[v" . nr2char(96) . "]"' \
        -c 'if mapleader !=# "," || maparg("s", "n") !=# "" || maparg(",/", "v") !~# "escape" || maparg(",v", "n") !=# last_change_map || maparg(",ff", "n") !~# "SmartFiles" || maparg(",,", "n") !~# "Balternate" | cquit | endif' \
        -c 'if maparg(",e", "n") !~# "ToggleSidebar" || maparg(",E", "n") !~# "ToggleSidebar" || maparg(",b", "n") !~# "Buffers" || maparg(",rg", "n") !~# "Rg" || maparg(",rG", "n") !~# "RgWord" || maparg(",rt", "n") !~# "Tags" | cquit | endif' \
        -c 'if maparg("<C-h>", "n") !~# "NavigateWindow" || maparg("<C-j>", "n") !~# "NavigateWindow" || maparg("<C-k>", "n") !~# "NavigateWindow" || maparg("<C-l>", "n") !~# "NavigateWindow" | cquit | endif' \
        -c 'if maparg(",ec", "n") !~# "ChopsticksConfig" || maparg(",ev", "n") !~# "[$]MYVIMRC" || maparg(",sv", "n") !~# "ChopsticksReload" || maparg(",wa", "n") !~# ":wa" || maparg(",z", "n") !~# "ToggleMaximize" || maparg(",=", "n") !~# "resize" || maparg(",-", "n") !~# "resize" | cquit | endif' \
        -c 'let g:classic_project_search_keys = ChopsticksKeymapContractKeys("project_search") | let g:classic_project_files_keys = ChopsticksKeymapContractKeys("project_files") | let g:classic_project_buffers_keys = ChopsticksKeymapContractKeys("project_buffers") | let g:classic_project_grep_keys = ChopsticksKeymapContractKeys("project_grep") | let g:classic_sidebar_keys = ChopsticksKeymapContractKeys("file_sidebar") | let g:classic_layout_keys = ChopsticksKeymapContractKeys("window_layout") | let g:nav = ChopsticksNavigationInfo() | if join(g:classic_project_search_keys[0:1], "/") !=# ",ff/,rg" || join(g:classic_project_files_keys, "/") !=# ",ff" || join(g:classic_project_buffers_keys, "/") !=# ",b" || join(g:classic_project_grep_keys, "/") !=# ",rg" || join(g:classic_sidebar_keys, "/") !=# ",e/,E" || join(g:classic_layout_keys, "/") !=# ",z/,=/,-" || get(g:nav.items[0], "reason", "") !=# ",ff/,rg" || get(g:nav.items[1], "reason", "") !=# ",e/,E" || get(g:nav.items[3], "label", "") !=# "window layout" || get(g:nav.items[3], "reason", "") !=# ",z/,=/,-" || !empty(get(g:nav, "missing_layout_maps", [])) | cquit | endif' \
        -c 'let g:core = ChopsticksCoreInfo() | if get(g:core, "layout", "") !=# "classic" || get(g:core.details[0], "value", "") !=# "classic" || get(g:core.items[1], "reason", "") !=# ",w/,q/,x/,<CR>/,cd" || get(g:core.items[3], "reason", "") !=# "F2/F3/F4/F6 + ,ss" | cquit | endif' \
        -c 'if maparg(",gp", "n") !=# "" || maparg(",gl", "n") !=# "" | cquit | endif' \
        -c 'let g:classic_core_lines = ChopsticksKeymapContractLines("survival_core", "  ", 9) | let g:classic_config_lines = ChopsticksKeymapContractLines("survival_config", "  ", 9) | let g:classic_core_keys = ChopsticksKeymapContractKeys("core_survival") | let g:classic_learning_keys = ChopsticksKeymapContractKeys("learning_entrypoint") | let g:classic_learning = ChopsticksLearningInfo() | if len(ChopsticksKeymapAuditIssues()) != 0 || get(ChopsticksStatusHeaderInfo().details[0], "value", "") !=# ":ChopsticksHelp  :ChopsticksTutor  ,?" || join(g:classic_learning_keys, "/") !=# ",?" || get(g:classic_learning.details[1], "value", "") !=# ",?" || get(g:classic_learning.items[0], "reason", "") !=# ",?" || g:classic_core_lines[0] !=# "  ,w        save" || g:classic_core_lines[-1] !=# "  ,x        save + quit" || g:classic_config_lines[0] !=# "  ,ec       edit local config" || join(g:classic_core_keys, "/") !=# ",w/,q/,x/,<CR>/,cd" | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_KEYMAP_PHASE="classic learning entrypoint"
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim --cmd 'let g:chopsticks_keymap_style = "classic"' \
        -u .vimrc -i NONE -es -N \
        -c 'let g:entry = ChopsticksLearningEntrypointInfo() | if get(g:entry, "key", "") !=# ",?" || get(g:entry, "lhs", "") !=# ",?" || get(g:entry, "open_lhs", "") !=# ",?" || get(g:entry, "close_lhs", "") !=# ",?" || get(g:entry, "cheat_title", "") !=# "  chopsticks         ,? close" || get(g:entry.guide_lines, 0, "") !=# "     ,?        active cheat sheet" || get(g:entry.tutor_lines, 0, "") !=# "     ,?         active cheat sheet" || get(g:entry, "feedback_line", "") !=# "     whether ,?, :ChopsticksTutor, or :ChopsticksStatus answered it" || get(g:entry, "session_prompt", "") !=# "- Did ,?, :ChopsticksTutor, or :ChopsticksStatus answer it:" | cquit | endif' \
        -c 'if maparg(",?", "n") !~# "ChopsticksCheatSheet" | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_KEYMAP_PHASE="classic picker and quickfix keys"
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim --cmd 'let g:chopsticks_keymap_style = "classic"' \
        -u .vimrc -i NONE -es -N \
        -c 'let g:classic_grep_word_keys = ChopsticksKeymapContractKeys("project_grep_word") | let g:classic_tag_keys = ChopsticksKeymapContractKeys("project_tags") | let g:classic_recent_keys = ChopsticksKeymapContractKeys("project_recent_files") | let g:classic_buffer_line_keys = ChopsticksKeymapContractKeys("project_buffer_lines") | let g:classic_command_keys = ChopsticksKeymapContractKeys("project_commands") | let g:classic_mark_keys = ChopsticksKeymapContractKeys("project_marks") | if join(g:classic_grep_word_keys, "/") !=# ",rG" || join(g:classic_tag_keys, "/") !=# ",rt" || join(g:classic_recent_keys, "/") !=# ",fh" || join(g:classic_buffer_line_keys, "/") !=# ",fl" || join(g:classic_command_keys, "/") !=# ",fc" || join(g:classic_mark_keys, "/") !=# ",fm" | cquit | endif' \
        -c 'let g:classic_quickfix_window_keys = ChopsticksKeymapContractKeys("quickfix_window") | let g:classic_quickfix_nav_keys = ChopsticksKeymapContractKeys("quickfix_navigation") | let g:classic_loclist_nav_keys = ChopsticksKeymapContractKeys("loclist_navigation") | let g:classic_terminal_keys = ChopsticksKeymapContractKeys("terminal_entry") | if join(g:classic_quickfix_window_keys, "/") !=# ",qo/,qc" || join(g:classic_quickfix_nav_keys, "/") !=# "[q/]q" || join(g:classic_loclist_nav_keys, "/") !=# "[l/]l" || (has("terminal") && join(g:classic_terminal_keys, "/") !=# ",tv/,th") | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_KEYMAP_PHASE="classic git keys"
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim --cmd 'let g:chopsticks_keymap_style = "classic"' \
        -u .vimrc -i NONE -es -N \
        -c 'let g:git_keys = ChopsticksKeymapContractKeys("git_keymaps") | let g:git_status_keys = ChopsticksKeymapContractKeys("git_status") | let g:git_commit_keys = ChopsticksKeymapContractKeys("git_commit") | let g:git_diff_keys = ChopsticksKeymapContractKeys("git_diff") | let g:git_blame_keys = ChopsticksKeymapContractKeys("git_blame") | let g:git_log_keys = ChopsticksKeymapContractKeys("git_log") | let g:git_conflict_keys = ChopsticksKeymapContractKeys("git_conflict_navigation") | let g:git = ChopsticksGitInfo() | if join(g:git_keys, "/") !=# ",gs/,gc/,gd/,gb/,gL" || join(g:git_status_keys, "/") !=# ",gs" || join(g:git_commit_keys, "/") !=# ",gc" || join(g:git_diff_keys, "/") !=# ",gd" || join(g:git_blame_keys, "/") !=# ",gb" || join(g:git_log_keys, "/") !=# ",gL" || join(g:git_conflict_keys, " ") !=# "[x ]x" || get(g:git.details[0], "value", "") !=# ",gs" || get(g:git.details[1], "value", "") !=# ",gL" || get(g:git.items[3], "reason", "") !=# ",gs" || get(g:git.items[4], "reason", "") !=# "[x ]x" | cquit | endif' \
        -c 'let g:git_commit_picker_keys = ChopsticksKeymapContractKeys("git_commit_picker") | let g:git_buffer_commit_picker_keys = ChopsticksKeymapContractKeys("git_buffer_commit_picker") | if join(g:git_commit_picker_keys, "/") !=# ",gC" || join(g:git_buffer_commit_picker_keys, "/") !=# ",gB" | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_KEYMAP_PHASE="classic editing keys"
    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim --cmd 'let g:chopsticks_keymap_style = "classic"' \
        -u .vimrc -i NONE -es -N \
        -c 'let g:classic_visible_jump_keys = ChopsticksKeymapContractKeys("visible_jump_summary") | let g:classic_cleanup_keys = ChopsticksKeymapContractKeys("edit_cleanup_summary") | let g:blank_line_keys = ChopsticksKeymapContractKeys("blank_lines") | let g:undo_keys = ChopsticksKeymapContractKeys("undo_tree") | let g:editing = ChopsticksEditingInfo() | if join(g:classic_visible_jump_keys, " / ") !=# ",S" || join(g:classic_cleanup_keys, "/") !=# ",W/,*/,F" || join(g:blank_line_keys, " ") !=# "[<Space> ]<Space>" || join(g:undo_keys, "/") !=# ",u" || get(g:editing.items[0], "reason", "") !=# ",S" || get(g:editing.items[2], "reason", "") !=# ",W/,*/,F" | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_KEYMAP_PHASE="jk escape opt-in"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_jk_escape = 1' \
        -c 'source .vimrc' \
        -c 'if maparg("jk", "i") !~# "<Esc>" | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_KEYMAP_PHASE="utility and completion opt-ins"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_ctrl_s_save = 1' \
        -c 'let g:chopsticks_enable_sudo_save_bang = 1' \
        -c 'let g:chopsticks_enable_completion_keymaps = 1' \
        -c 'source .vimrc' \
        -c 'if ChopsticksProfileInfo().opt_ins[1].enabled != 1 || ChopsticksProfileInfo().opt_ins[2].enabled != 1 || ChopsticksProfileInfo().opt_ins[3].enabled != 1 | cquit | endif' \
        -c 'if maparg("<C-s>", "n") !~# ":w" || maparg("<C-s>", "i") !~# ":w" || maparg("w!!", "c") !~# "sudo tee" | cquit | endif' \
        -c 'let g:utility = ChopsticksUtilityInfo() | if get(g:utility.items[3], "state", "") !=# "ready" || get(g:utility.items[3], "reason", "") !=# "w!!" || get(g:utility.items[3], "diagnostic", 1) | cquit | endif' \
        -c 'let g:completion_keys = ChopsticksKeymapContractKeys("completion_keymaps") | let g:completion = ChopsticksCompletionInfo() | if join(g:completion_keys, "/") !=# "Tab/S-Tab/CR" || maparg("<Tab>", "i") !~# "pumvisible" || maparg("<S-Tab>", "i") !~# "pumvisible" || maparg("<CR>", "i") !~# "asyncomplete#close_popup" || get(g:completion.items[4], "state", "") !=# "ready" || get(g:completion.items[4], "reason", "") !=# "Tab/S-Tab/CR" || get(g:completion.items[4], "diagnostic", 1) | cquit | endif' \
        -c 'if len(ChopsticksKeymapAuditIssues()) != 0 | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_KEYMAP_PHASE="completion missing map audit"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_completion_keymaps = 1' \
        -c 'source .vimrc' \
        -c 'silent! iunmap <Tab>' \
        -c 'let g:completion = ChopsticksCompletionInfo() | let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if get(g:completion.items[4], "state", "") !=# "missing" || stridx(get(g:completion.items[4], "detail", ""), "<Tab>") < 0 || g:keymap.ok || empty(filter(copy(g:health.issues), "v:val.code ==# \"completion.completion-keymaps\" && stridx(v:val.detail, \"<Tab>\") >= 0")) | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_KEYMAP_PHASE="auto-pairs opt-in"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_auto_pairs = 1' \
        -c 'source .vimrc' \
        -c 'runtime plugin/auto-pairs.vim' \
        -c 'doautocmd BufEnter' \
        -c 'let g:auto_pairs_ch = {"kind": "auto_pairs_map", "lhs": "<C-h>", "text": "AutoPairsDelete", "label": "opt-in auto-pairs Ctrl-H"}' \
        -c 'if !has_key(g:plugs, "auto-pairs") || !exists("g:AutoPairsLoaded") || !maparg("<CR>", "i", 0, 1).buffer || !maparg("<BS>", "i", 0, 1).buffer || !ChopsticksKeymapSpecReady(g:auto_pairs_ch) || !maparg("<Space>", "i", 0, 1).buffer | cquit | endif' \
        -c 'if maparg("<CR>", "i") !~# "AutoPairsReturn" || maparg("<BS>", "i") !~# "AutoPairsDelete" || !ChopsticksKeymapSpecReady(g:auto_pairs_ch) || maparg("<Space>", "i") !~# "AutoPairsSpace" | cquit | endif' \
        -c 'if len(ChopsticksKeymapAuditIssues()) != 0 | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_KEYMAP_PHASE="auto-pairs and completion opt-ins"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_auto_pairs = 1' \
        -c 'let g:chopsticks_enable_completion_keymaps = 1' \
        -c 'source .vimrc' \
        -c 'runtime plugin/auto-pairs.vim' \
        -c 'doautocmd BufEnter' \
        -c 'if maparg("<Tab>", "i") !~# "pumvisible" || maparg("<S-Tab>", "i") !~# "pumvisible" | cquit | endif' \
        -c 'let g:completion_keys = ChopsticksKeymapContractKeys("completion_keymaps") | let g:completion = ChopsticksCompletionInfo() | if join(g:completion_keys, "/") !=# "Tab/S-Tab/CR/CR" || maparg("<CR>", "i") !~# "AutoPairsOldCRWrapper" || maparg("<CR>", "i") !~# "AutoPairsReturn" || get(g:completion.items[4], "state", "") !=# "ready" || get(g:completion.items[4], "reason", "") !=# "Tab/S-Tab/CR(auto-pairs)" || get(g:completion.items[4], "diagnostic", 1) | cquit | endif' \
        -c 'if len(ChopsticksKeymapAuditIssues()) != 0 | cquit | endif' \
        -c 'qa!' 2>&1

    CHOPSTICKS_TEST_STEP=
    CHOPSTICKS_TEST_KEYMAP_PHASE=
    step "Terminal, SSH, and TTY behavior"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_terminal_keymaps = 1' \
        -c 'source .vimrc' \
        -c 'if has("terminal") && (maparg("<Esc><Esc>", "t") !~# "<C-\\\\><C-N>" || maparg("<C-h>", "t") !~# "NavigateWindow" || maparg("<C-j>", "t") !~# "NavigateWindow" || maparg("<C-k>", "t") !~# "NavigateWindow" || maparg("<C-l>", "t") !~# "NavigateWindow") | cquit | endif' \
        -c 'if has("terminal") && ChopsticksNavigationInfo().terminal_adapter !=# "vim terminal maps" | cquit | endif' \
        -c 'let g:nav = ChopsticksNavigationInfo() | if get(g:nav, "title", "") !=# "navigation" || !ChopsticksInfoShapeIssue(g:nav, "ChopsticksNavigationInfo()").ok || len(get(g:nav, "items", [])) != 6 || get(g:nav.items[0], "label", "") !=# "project search" || get(g:nav.items[1], "label", "") !=# "file sidebar" || get(g:nav.items[4], "label", "") !=# "terminal navigation" || get(g:nav.items[4], "severity", "") !=# "attention" || get(g:nav.items[4], "action", "") !~# "terminal_keymaps" || get(g:nav.items[5], "label", "") !=# "tmux navigator" || get(g:nav.items[5], "severity", "") !=# "setup" || get(g:nav.items[5], "action", "") !~# "PlugInstall" | cquit | endif' \
        -c 'if len(ChopsticksKeymapAuditIssues()) != 0 | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if get(g:, "chopsticks_enable_input_method", 1) != 0 | cquit | endif' \
        -c 'if exists(":ChopsticksInputMethodStatus") != 2 || exists(":ChopsticksInputMethodToggle") != 2 || !exists("*ChopsticksInputMethodInfo") | cquit | endif' \
        -c 'let g:im = ChopsticksInputMethodInfo() | if get(g:im, "title", "") !=# "input method" || !ChopsticksInfoShapeIssue(g:im, "ChopsticksInputMethodInfo()").ok || len(get(g:im, "items", [])) != 1 || get(g:im.items[0], "state", "") !=# "off" || get(g:im.items[0], "diagnostic", 1) || !empty(get(g:im, "details", [])) | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-input-method-off.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'off input method switch  (disabled by default)' "$TMP_ROOT/status-input-method-off.txt"

    mkdir -p "$TMP_ROOT/fake-im"
    printf '%s\n' 'com.apple.inputmethod.SCIM.ITABC' > "$TMP_ROOT/fake-im/state"
    cat > "$TMP_ROOT/fake-im/im-select" <<'IMEOF'
#!/usr/bin/env bash
set -eu
if [ "$#" -eq 0 ]; then
    printf '%s\n' "get" >> "$FAKE_IM_LOG"
    cat "$FAKE_IM_STATE"
else
    printf '%s\n' "set:$1" >> "$FAKE_IM_LOG"
    printf '%s\n' "$1" > "$FAKE_IM_STATE"
fi
IMEOF
    chmod +x "$TMP_ROOT/fake-im/im-select"
    FAKE_IM_STATE="$TMP_ROOT/fake-im/state" \
        FAKE_IM_LOG="$TMP_ROOT/fake-im/log" \
        PATH="$TMP_ROOT/fake-im:$PATH" \
        XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_input_method = 1' \
        -c 'let g:chopsticks_input_method_default = "com.apple.keylayout.ABC"' \
        -c 'source .vimrc' \
        -c 'set filetype=markdown' \
        -c 'let g:im = ChopsticksInputMethodInfo() | if !g:im.available || !g:im.buffer_enabled || get(g:im.items[0], "state", "") !=# "ready" || get(g:im.items[0], "diagnostic", 1) || len(get(g:im, "details", [])) < 3 | cquit | endif' \
        -c 'doautocmd InsertLeave' \
        -c 'if get(b:, "chopsticks_input_method_saved", "") !=# "com.apple.inputmethod.SCIM.ITABC" | cquit | endif' \
        -c 'doautocmd InsertEnter' \
        -c 'qa!' 2>&1
    grep -Fxq 'set:com.apple.keylayout.ABC' "$TMP_ROOT/fake-im/log"
    grep -Fxq 'set:com.apple.inputmethod.SCIM.ITABC' "$TMP_ROOT/fake-im/log"

    printf '%s\n' 'com.apple.inputmethod.SCIM.ITABC' > "$TMP_ROOT/fake-im/state"
    : > "$TMP_ROOT/fake-im/log"
    FAKE_IM_STATE="$TMP_ROOT/fake-im/state" \
        FAKE_IM_LOG="$TMP_ROOT/fake-im/log" \
        PATH="$TMP_ROOT/fake-im:$PATH" \
        XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_input_method = 1' \
        -c 'let g:chopsticks_input_method_default = "com.apple.keylayout.ABC"' \
        -c 'let g:chopsticks_input_method_filetypes = ["markdown"]' \
        -c 'source .vimrc' \
        -c 'set filetype=python' \
        -c 'if ChopsticksInputMethodInfo().buffer_enabled || ChopsticksInputMethodInfo().buffer_reason !~# "filetype not allowed" | cquit | endif' \
        -c 'doautocmd InsertLeave' \
        -c 'if exists("b:chopsticks_input_method_saved") | cquit | endif' \
        -c 'qa!' 2>&1
    test ! -s "$TMP_ROOT/fake-im/log"

    printf '%s\n' 'com.apple.inputmethod.SCIM.ITABC' > "$TMP_ROOT/fake-im/state"
    : > "$TMP_ROOT/fake-im/log"
    FAKE_IM_STATE="$TMP_ROOT/fake-im/state" \
        FAKE_IM_LOG="$TMP_ROOT/fake-im/log" \
        PATH="$TMP_ROOT/fake-im:$PATH" \
        SSH_CONNECTION='127.0.0.1 10000 127.0.0.1 22' \
        XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_input_method = 1' \
        -c 'let g:chopsticks_input_method_default = "com.apple.keylayout.ABC"' \
        -c 'source .vimrc' \
        -c 'let g:runtime = ChopsticksRuntimeInfo() | if !g:runtime.remote || g:runtime.remote_source !=# "SSH_CONNECTION" || get(g:runtime.details[1], "value", "") !=# "SSH session  via SSH_CONNECTION" || len(get(g:runtime, "items", [])) != len(g:runtime.features) + 2 || get(g:runtime.items[-1], "label", "") !=# "remote session" || !get(g:runtime.items[-1], "diagnostic", 0) || get(g:runtime.items[-1], "severity", "") !=# "info" || get(g:runtime.items[-1], "action", "") !~# "SSH-safe" | cquit | endif' \
        -c 'let g:im = ChopsticksInputMethodInfo() | if !ChopsticksRuntimeInfo().remote || ChopsticksRuntimeInfo().remote_source !=# "SSH_CONNECTION" || !g:im.remote || g:im.remote_source !=# "SSH_CONNECTION" || g:im.available || g:im.reason !=# "disabled on SSH" || get(g:im.items[0], "state", "") !=# "off" || !get(g:im.items[0], "diagnostic", 0) || get(g:im.items[0], "severity", "") !=# "info" || get(g:im.items[0], "action", "") !~# "disable_on_ssh" | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-input-method-ssh.txt" \
        -c 'silent %print | redir END | doautocmd InsertLeave | qa!' 2>&1
    grep -Fq 'session   SSH session  via SSH_CONNECTION' \
        "$TMP_ROOT/status-input-method-ssh.txt"
    grep -Fq 'OK  remote session  (detected via SSH_CONNECTION)' \
        "$TMP_ROOT/status-input-method-ssh.txt"
    grep -Fq 'off input method switch  (disabled on SSH)' \
        "$TMP_ROOT/status-input-method-ssh.txt"
    test ! -s "$TMP_ROOT/fake-im/log"

    printf '%s\n' 'com.apple.inputmethod.SCIM.ITABC' > "$TMP_ROOT/fake-im/state"
    : > "$TMP_ROOT/fake-im/log"
    FAKE_IM_STATE="$TMP_ROOT/fake-im/state" \
        FAKE_IM_LOG="$TMP_ROOT/fake-im/log" \
        PATH="$TMP_ROOT/fake-im:$PATH" \
        SSH_CONNECTION='127.0.0.1 10000 127.0.0.1 22' \
        XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_input_method = 1' \
        -c 'let g:chopsticks_input_method_default = "com.apple.keylayout.ABC"' \
        -c 'let g:chopsticks_input_method_disable_on_ssh = 0' \
        -c 'source .vimrc' \
        -c 'set filetype=markdown' \
        -c 'if !ChopsticksInputMethodInfo().available || !ChopsticksInputMethodInfo().buffer_enabled | cquit | endif' \
        -c 'doautocmd InsertLeave' \
        -c 'if get(b:, "chopsticks_input_method_saved", "") !=# "com.apple.inputmethod.SCIM.ITABC" | cquit | endif' \
        -c 'qa!' 2>&1
    grep -Fxq 'set:com.apple.keylayout.ABC' "$TMP_ROOT/fake-im/log"

    TMUX=/tmp/chopsticks-test XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if has_key(g:plugs, "vim-tmux-navigator") | cquit | endif' \
        -c 'qa!' 2>&1

    TMUX=/tmp/chopsticks-test XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim --cmd 'let g:chopsticks_enable_tmux_navigator = 1' \
        -u .vimrc -i NONE -es -N \
        -c 'if !has_key(g:plugs, "vim-tmux-navigator") || !exists("g:loaded_tmux_navigator") || exists(":TmuxNavigateLeft") != 2 | cquit | endif' \
        -c 'if maparg("<C-h>", "n") !~# "TmuxNavigateLeft" || maparg("<C-j>", "n") !~# "TmuxNavigateDown" || maparg("<C-k>", "n") !~# "TmuxNavigateUp" || maparg("<C-l>", "n") !~# "TmuxNavigateRight" | cquit | endif' \
        -c 'if has("terminal") && (maparg("<C-h>", "t") !~# "TmuxNavigateLeft" || maparg("<C-j>", "t") !~# "TmuxNavigateDown" || maparg("<C-k>", "t") !~# "TmuxNavigateUp" || maparg("<C-l>", "t") !~# "TmuxNavigateRight") | cquit | endif' \
        -c 'let g:nav = ChopsticksNavigationInfo() | if !g:nav.tmux_ready || g:nav.window_adapter !=# "tmux navigator" || get(g:nav.items[2], "reason", "") !=# "tmux navigator" || get(g:nav.items[3], "reason", "") !=# "SPC z" || get(g:nav.items[5], "state", "") !=# "ready" || get(g:nav.items[5], "diagnostic", 1) | cquit | endif' \
        -c 'if len(ChopsticksKeymapAuditIssues()) != 0 | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-tmux-navigator.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq 'OK  window navigation  (tmux navigator)' "$TMP_ROOT/status-tmux-navigator.txt"
    grep -Fq 'OK  window layout  (SPC z)' "$TMP_ROOT/status-tmux-navigator.txt"
    grep -Fq 'OK  project search  (SPC SPC/SPC /)' "$TMP_ROOT/status-tmux-navigator.txt"
    grep -Fq 'OK  file sidebar  (SPC e/SPC E)' "$TMP_ROOT/status-tmux-navigator.txt"
    grep -Fq 'OK  terminal navigation  (tmux navigator)' "$TMP_ROOT/status-tmux-navigator.txt"
    grep -Fq 'OK  tmux navigator  (loaded)' "$TMP_ROOT/status-tmux-navigator.txt"

    TMUX=/tmp/chopsticks-test XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_tmux_navigator = 1' \
        -c 'source .vimrc' \
        -c 'if !has_key(g:plugs, "vim-tmux-navigator") | cquit | endif' \
        -c 'let g:nav = ChopsticksNavigationInfo() | if g:nav.tmux_reason !=# "plugin not loaded yet" || !get(g:nav.items[5], "diagnostic", 0) || get(g:nav.items[5], "detail", "") !=# "plugin not loaded yet" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'setfiletype netrw' \
        -c 'if &filetype !=# "netrw" | cquit | endif' \
        -c 'if !maparg("<C-l>", "n", 0, 1).buffer | cquit | endif' \
        -c 'if maparg("<C-h>", "n") !~# "NavigateWindow" || maparg("<C-l>", "n") !~# "NavigateWindow" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let g:core = ChopsticksCoreInfo() | if &exrc || &secure || get(g:core.items[7], "state", "") !=# "off" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_exrc = 1' \
        -c 'source .vimrc' \
        -c 'let g:core = ChopsticksCoreInfo() | if !&exrc || !&secure || get(g:core.items[7], "state", "") !=# "ready" || get(g:core.items[7], "reason", "") !=# "exrc+secure" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if maparg("<Space>c=", "n") !=# "" | cquit | endif' \
        -c 'if maparg("<Space>=", "v") !~# "=" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_enable_reindent_file = 1' \
        -c 'source .vimrc' \
        -c 'let g:reindent_keys = ChopsticksKeymapContractKeys("full_file_reindent") | let g:editing = ChopsticksEditingInfo() | if join(g:reindent_keys, "/") !=# "SPC c=" || maparg("<Space>c=", "n") !~# "gg=G" || get(g:editing.items[4], "label", "") !=# "full-file reindent" || get(g:editing.items[4], "state", "") !=# "ready" || get(g:editing.items[4], "reason", "") !=# "SPC c=" | cquit | endif' \
        -c 'qa!' 2>&1

    TERM=xterm-256color XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let g:core = ChopsticksCoreInfo() | if g:is_tty || &ttimeoutlen != 10 || get(g:core.details[1], "value", "") !=# "timeout=500 ttimeout=10ms" || get(g:core.items[5], "reason", "") !=# "rich timing" | cquit | endif' \
        -c 'qa!' 2>&1

    TERM=xterm-256color COLORTERM=truecolor XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u .vimrc -i NONE -es -N \
        -c 'let g:ui = ChopsticksUiInfo() | if g:is_tty || !g:has_true_color || get(g:ui.items[1], "label", "") !=# "truecolor" || get(g:ui.items[1], "state", "") !=# "ready" || get(g:ui.items[1], "reason", "") !=# "termguicolors" | cquit | endif' \
        -c 'qa!' 2>&1

    TERM=linux XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let g:ui = ChopsticksUiInfo() | let g:core = ChopsticksCoreInfo() | if !g:is_tty || &ttimeoutlen != 50 || get(g:core.details[1], "value", "") !=# "timeout=500 ttimeout=50ms" || get(g:core.items[5], "reason", "") !=# "TTY timing" || get(g:ui.details[0], "value", "") !=# "TTY fallback" || get(g:ui.items[0], "reason", "") !=# "TTY default" || get(g:ui.items[1], "state", "") !=# "off" || get(g:ui.items[2], "reason", "") !=# "TTY fallback" || get(g:ui.items[3], "state", "") !=# "off" || get(g:ui.items[4], "state", "") !=# "off" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if !exists("loaded_gzip") || !exists("loaded_logiPat") || !exists("loaded_rrhelper") || !exists("loaded_spellfile_plugin") | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'silent! delcommand LspStatus' \
        -c 'silent! delcommand LspInstallServer' \
        -c 'if ChopsticksLspInfo().stack.reason !=# "installed; not loaded yet" | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-lsp-not-loaded.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'OK  vim-lsp stack  (installed; not loaded yet)' "$TMP_ROOT/status-lsp-not-loaded.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_profile = "minimal"' \
        -c 'source .vimrc' \
        -c 'if !exists("*ChopsticksLspInfo") || !exists("*ChopsticksLspLearningEnabled") || !exists("*ChopsticksProfileInfo") || !exists("*ChopsticksUiInfo") || !exists("*ChopsticksLanguageInfo") || !exists("*ChopsticksLintInfo") || !exists("*ChopsticksCompletionInfo") | cquit | endif' \
        -c 'if ChopsticksProfileInfo().profile !=# "minimal" || ChopsticksLspInfo().stack.state !=# "off" || ChopsticksLspLearningEnabled() || !empty(get(ChopsticksLspInfo(), "footers", [])) || get(ChopsticksUiInfo().items[5], "state", "") !=# "off" || get(ChopsticksLanguageInfo().items[3], "state", "") !=# "off" || get(ChopsticksLanguageInfo().items[4], "state", "") !=# "off" || get(ChopsticksLintInfo().items[0], "state", "") !=# "off" || get(ChopsticksLintInfo().items[1], "state", "") !=# "off" || get(ChopsticksLintInfo().items[2], "state", "") !=# "off" || get(ChopsticksCompletionInfo().items[0], "state", "") !=# "off" || get(ChopsticksCompletionInfo().items[4], "state", "") !=# "off" | cquit | endif' \
        -c 'let g:daily_loop = ChopsticksLearningDailyLoopInfo() | let g:lsp_loop = ChopsticksLearningLspLoopInfo() | if get(g:daily_loop, "lsp_enabled", 1) || get(g:lsp_loop, "enabled", 1) || get(g:daily_loop.summary_lines, 0, "") !=# "files → s jump → edit" || join(get(g:daily_loop, "drill_steps", []), ", ") !=# "SPC SPC, s, edit, SPC rr, SPC /, SPC gs" || join(get(g:daily_loop, "tasks", []), ", ") !=# "project navigation, code, grep, git, Markdown, SSH" || len(get(g:daily_loop, "tutor_rows", [])) != 5 || get(g:daily_loop.tutor_rows[0], "key", "") !=# "SPC SPC" || get(g:daily_loop.tutor_rows[2], "key", "") !=# "SPC rr" || get(g:daily_loop.tutor_rows[-1], "key", "") !=# "SPC gs" | cquit | endif' \
        -c 'let g:editing = ChopsticksEditingInfo() | if get(g:editing.items[1], "label", "") !=# "undo tree" || get(g:editing.items[1], "state", "") !=# "off" || get(g:editing.items[1], "diagnostic", 1) || !empty(ChopsticksKeymapAuditIssues()) | cquit | endif' \
        -c 'if len(filter(copy(ChopsticksProfileInfo().features), "v:val.enabled")) != 0 | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-minimal.txt" \
        -c 'silent %print | redir END | qa!' 2>&1
    grep -Fq 'off vim-lsp stack  (LSP disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off python  (LSP disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off ALE stack  (lint disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off lint keymaps  (lint disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off format on save  (lint disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off completion engine  (LSP disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off vim-lsp completion source  (LSP disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off auto popup  (LSP disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off popup menu  (LSP disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off completion keymaps  (LSP disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off start screen  (disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off markdown preview  (disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off go syntax  (disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off ALE linters  (lint disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    grep -Fq 'off ALE formatters  (lint disabled by profile)' "$TMP_ROOT/status-minimal.txt"
    if grep -Fq 'LSP actions are buffer-local' "$TMP_ROOT/status-minimal.txt"; then
        cat "$TMP_ROOT/status-minimal.txt"
        exit 1
    fi
    if grep -Fq 'Install LSP servers' "$TMP_ROOT/status-minimal.txt"; then
        cat "$TMP_ROOT/status-minimal.txt"
        exit 1
    fi

    mkdir -p "$TMP_ROOT/missing-home/.vim/autoload"
    cp "$HOME/.vim/autoload/plug.vim" "$TMP_ROOT/missing-home/.vim/autoload/plug.vim"
    HOME="$TMP_ROOT/missing-home" XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim -u .vimrc -i NONE -es -N \
        -c 'if ChopsticksLspInfo().stack.state !=# "missing" | cquit | endif' \
        -c 'ChopsticksStatus' \
        -c "redir! > $TMP_ROOT/status-missing-plugin.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'vim-lsp not installed; run :PlugInstall' "$TMP_ROOT/status-missing-plugin.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'let g:lsp_buffer_keys = ChopsticksKeymapContractKeys("lsp_buffer_keymaps") | let g:lsp_definition_keys = ChopsticksKeymapContractKeys("lsp_definition_references") | let g:lsp_hover_keys = ChopsticksKeymapContractKeys("lsp_hover") | let g:lsp_format_keys = ChopsticksKeymapContractKeys("lsp_format") | let g:lsp_diagnostic_keys = ChopsticksKeymapContractKeys("lsp_diagnostics")' \
        -c 'if len(g:lsp_buffer_keys) < 12 || join(g:lsp_definition_keys, "/") !=# "gd/gr" || join(g:lsp_hover_keys, "/") !=# "K" || join(g:lsp_format_keys, "/") !=# "SPC cf/v SPC cf" || join(g:lsp_diagnostic_keys, "/") !=# "[d/]d" || index(g:lsp_buffer_keys, "SPC ci") < 0 | cquit | endif' \
        -c 'doautocmd User lsp_buffer_enabled' \
        -c 'if maparg("gd", "n") !~# "lsp-definition" || maparg("gr", "n") !~# "lsp-references" || maparg("gI", "n") !~# "lsp-implementation" || maparg("gy", "n") !~# "lsp-type-definition" || maparg("K", "n") !~# "lsp-hover" | cquit | endif' \
        -c 'if maparg("[d", "n") !~# "lsp-previous-diagnostic" || maparg("]d", "n") !~# "lsp-next-diagnostic" | cquit | endif' \
        -c 'if maparg("<Space>ca", "n") !~# "lsp-code-action" || maparg("<Space>cr", "n") !~# "lsp-rename" || maparg("<Space>cf", "n") !~# "lsp-document-format" | cquit | endif' \
        -c 'if maparg("<Space>cf", "x") !~# "lsp-document-range-format" | cquit | endif' \
        -c 'if maparg("<Space>ci", "n") !~# "LspStatus" || maparg("<Space>co", "n") !~# "lsp-document-symbol-search" | cquit | endif' \
        -c 'if maparg("<Space>cd", "n") !=# "" || maparg("<Space>ck", "n") !=# "" || maparg("<Space>cp", "n") !=# "" || maparg("<Space>cn", "n") !=# "" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "classic"' \
        -c 'source .vimrc' \
        -c 'let g:lsp_buffer_keys = ChopsticksKeymapContractKeys("lsp_buffer_keymaps") | let g:lsp_definition_keys = ChopsticksKeymapContractKeys("lsp_definition_references") | let g:lsp_hover_keys = ChopsticksKeymapContractKeys("lsp_hover") | let g:lsp_format_keys = ChopsticksKeymapContractKeys("lsp_format") | let g:lsp_diagnostic_keys = ChopsticksKeymapContractKeys("lsp_diagnostics") | if len(g:lsp_buffer_keys) < 12 || join(g:lsp_definition_keys, "/") !=# ",dd/,dr" || join(g:lsp_hover_keys, "/") !=# ",dk" || join(g:lsp_format_keys, "/") !=# ",f/v ,f" || join(g:lsp_diagnostic_keys, "/") !=# ",dp/,dn/,cD" | cquit | endif' \
        -c 'doautocmd User lsp_buffer_enabled' \
        -c 'if maparg("gd", "n") !=# "" || maparg("K", "n") !=# "" || maparg("gI", "n") !=# "" || maparg("gr", "n") !=# "" | cquit | endif' \
        -c 'if maparg(",dd", "n") !~# "lsp-definition" || maparg(",dt", "n") !~# "lsp-type-definition" || maparg(",di", "n") !~# "lsp-implementation" || maparg(",dr", "n") !~# "lsp-references" || maparg(",dk", "n") !~# "lsp-hover" | cquit | endif' \
        -c 'if maparg(",dp", "n") !~# "lsp-previous-diagnostic" | cquit | endif' \
        -c 'if maparg(",dn", "n") !~# "lsp-next-diagnostic" | cquit | endif' \
        -c 'if maparg(",f", "n") !~# "lsp-document-format" || maparg(",f", "x") !~# "lsp-document-range-format" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "space"' \
        -c 'source .vimrc' \
        -c 'if mapleader !=# "\<Space>" || maplocalleader !=# "," | cquit | endif' \
        -c 'if maparg(",ff", "n") !=# "" || maparg(",w", "n") !=# "" || maparg(",mt", "n") !=# "" || maparg(",gp", "n") !=# "" || maparg("<Space>gp", "n") !=# "" | cquit | endif' \
        -c 'if maparg("<Space>f", "n") !=# "" || maparg("<Space>u", "n") !=# "" || maparg("<Space>c", "n") !=# "" || maparg("<Space>x", "n") !=# "" || maparg("<Space>wm", "n") !=# "" || maparg("<Space>w+", "n") !=# "" || maparg("<Space>w-", "n") !=# "" | cquit | endif' \
        -c 'if maparg("<Space><Space>", "n") !~# "SmartFiles" || maparg("<Space>ff", "n") !~# "SmartFiles" || maparg("<Space>,", "n") !~# "Buffers" || maparg("<Space>/", "n") !~# "Rg" || maparg("<Space>sw", "n") !~# "RgWord" || maparg("<Space>st", "n") !~# "Tags" | cquit | endif' \
        -c 'if maparg("<Space>e", "n") !~# "ToggleSidebar" || maparg("<Space>E", "n") !~# "ToggleSidebar" || maparg("<Space>bd", "n") !~# "Bclose" || maparg("<Space><Tab>", "n") !~# "Balternate" || maparg("<Space>z", "n") !~# "ToggleMaximize" | cquit | endif' \
        -c 'if maparg("<Space>w", "n") !~# ":w" || maparg("<Space>W", "n") !~# ":wa" || maparg("<Space>q", "n") !~# ":q" || maparg("<Space>qq", "n") !=# "" || maparg("<Space>qx", "n") !=# "" || maparg("<Space>fc", "n") !~# "ChopsticksConfig" || maparg("<Space>fv", "n") !~# "[$]MYVIMRC" || maparg("<Space>fV", "n") !~# "ChopsticksReload" || maparg("<Space>U", "n") !~# "UndotreeToggle" || maparg("<Space>fs", "n") !=# "" || maparg("<Space>bu", "n") !=# "" | cquit | endif' \
        -c 'if maparg("<Space>gl", "n") !~# "Git log" || maparg("<Space>gC", "n") !~# "Commits" | cquit | endif' \
        -c 'qa!' 2>&1

    step "Space, classic, cheat, and tutor surfaces"
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
        -c 'if maparg("<Space>?", "n") !~# ":bd" | cquit | endif' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 42 | cquit | endif' \
        -c "redir! > $TMP_ROOT/cheat-default.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'chopsticks         SPC ? close' "$TMP_ROOT/cheat-default.txt"
    if grep -Fq '<Space>? close' "$TMP_ROOT/cheat-default.txt"; then
        cat "$TMP_ROOT/cheat-default.txt"
        exit 1
    fi
    grep -Fq ':ChopsticksStatus   check LSP setup' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'trained loop:' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'files → s jump → gd/K' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'run → grep → git' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC SPC   files' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC ff    files' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC fb    buffers' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC sw    grep word' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'gd        definition' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'K         hover docs' "$TMP_ROOT/cheat-default.txt"
    grep -Fq '[d ]d     LSP diagnostics' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC c=    re-indent file (opt-in)' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ',mp       markdown preview' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ',mt       table of contents' "$TMP_ROOT/cheat-default.txt"
    grep -Fq '[e ]e     ALE errors' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC xd    ALE detail' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC uf    format on save' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC cW    strip trailing whitespace' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC sr    replace word' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC =     indent selection' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC U     undo tree' "$TMP_ROOT/cheat-default.txt"
    if vim -u NONE -i NONE -es -N \
        -c 'if !has("clipboard") | cquit | endif' \
        -c 'qa!' >/dev/null 2>&1; then
        grep -Fq 'SPC y/p   clipboard y/p' "$TMP_ROOT/cheat-default.txt"
    fi
    grep -Fq 'Alt+j/k   move line' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'Ctrl-hjkl windows' "$TMP_ROOT/cheat-default.txt"
    grep -Fq '<C-w>hjkl native fallback' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC bp/bn prev / next buf' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC bo    close other buffers' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC tt/th terminal / split' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ']l [l     next / prev loc' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC xq/xQ open / close qf' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC xl/xL open / close loclist' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC us    spell check' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC w     save' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'SPC fc    edit local config' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 's+2ch     easymotion jump' "$TMP_ROOT/cheat-default.txt"
    grep -Fq 'cl / cc   native s / S substitute' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksHelp        full help' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksConfig      local config' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksReload      reload config' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksTutor       practice' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksStatus      health' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksDoctor      issues' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksKeymapAudit key audit' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksBeta        release checklist' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksBetaLog     release notes' "$TMP_ROOT/cheat-default.txt"
    grep -Fq ':ChopsticksBetaSession new release note' "$TMP_ROOT/cheat-default.txt"
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
    grep -Fq ':ChopsticksTutor       practice' "$TMP_ROOT/cheat-command.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "classic"' \
        -c 'source .vimrc' \
        -c 'normal ,?' \
        -c 'if maparg(",?", "n") !~# ":bd" | cquit | endif' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 42 | cquit | endif' \
        -c "redir! > $TMP_ROOT/cheat-classic.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'chopsticks         ,? close' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',ff       files' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',rG       grep word' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',gB       FZF buffer commits' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',h ,l     prev / next buf' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',tv ,th   terminal v / h' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ']l [l     next / prev loc' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',qo ,qc   open / close qf' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',ss       spell check' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq 'trained loop:' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq 'files → jump → inspect' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq 'run → grep → git' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',dd       definition' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',dk       hover docs' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',dp ,dn   LSP diagnostics' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',mp       markdown preview' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',mt       table of contents' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq '[e ]e     ALE errors' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',aD       ALE detail' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',af       format on save' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',S+2ch    easymotion jump' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',W        strip trailing whitespace' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',*        replace word' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',F        indent selection' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',u        undo tree' "$TMP_ROOT/cheat-classic.txt"
    if vim -u NONE -i NONE -es -N \
        -c 'if !has("clipboard") | cquit | endif' \
        -c 'qa!' >/dev/null 2>&1; then
        grep -Fq ',y ,p     clipboard y/p' "$TMP_ROOT/cheat-classic.txt"
    fi
    grep -Fq 'Alt+j/k   move line' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ',ec       edit local config' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ':ChopsticksConfig      local config' "$TMP_ROOT/cheat-classic.txt"
    grep -Fq ':ChopsticksDoctor      issues' "$TMP_ROOT/cheat-classic.txt"
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
    grep -Fq 'files → s jump → edit' "$TMP_ROOT/cheat.txt"
    if grep -Fq 'gd/K' "$TMP_ROOT/cheat.txt"; then
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
    grep -Fq ']l [l     next / prev loc' "$TMP_ROOT/cheat-space.txt"
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
    grep -Fq ':ChopsticksHelp        full help' "$TMP_ROOT/tutor-default.txt"
    grep -Fq ':ChopsticksConfig      local config' "$TMP_ROOT/tutor-default.txt"
    grep -Fq ':ChopsticksDoctor      issues' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'Ctrl-h/j/k/l split navigation' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'SPC e, Ctrl-h/l  enter/leave sidebar' "$TMP_ROOT/tutor-default.txt"
    grep -Fq '[q/]q [l/]l   qf / loclist' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 's + 2 chars jump to visible text' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 's + 2 chars  visible jump' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'SPC S        same jump fallback' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'cl / cc      native s / S substitute' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'SPC U        undo tree' "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'gd / gr / K inspect definition / refs / docs' \
        "$TMP_ROOT/tutor-default.txt"
    grep -Fq 'gd / gr / K  definition / refs / docs' "$TMP_ROOT/tutor-default.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_profile = "minimal"' \
        -c 'source .vimrc' \
        -c 'ChopsticksTutor' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 78 | cquit | endif' \
        -c "redir! > $TMP_ROOT/tutor-minimal.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 's + 2 chars  visible jump' "$TMP_ROOT/tutor-minimal.txt"
    grep -Fq 'SPC rr       run current file' "$TMP_ROOT/tutor-minimal.txt"
    grep -Fq 'Repeat: SPC SPC, s, edit, SPC rr, SPC /, SPC gs.' \
        "$TMP_ROOT/tutor-minimal.txt"
    if grep -Fq 'undo tree' "$TMP_ROOT/tutor-minimal.txt"; then
        cat "$TMP_ROOT/tutor-minimal.txt"
        exit 1
    fi
    if grep -Eq 'definition|LSP diagnostics|gd/K|hover docs|SPC cf' \
        "$TMP_ROOT/tutor-minimal.txt"; then
        cat "$TMP_ROOT/tutor-minimal.txt"
        exit 1
    fi

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
    grep -Fq ':ChopsticksConfig      local config' "$TMP_ROOT/tutor-classic.txt"
    grep -Fq ':ChopsticksBetaSession new release note' "$TMP_ROOT/tutor-classic.txt"
    grep -Fq 'Ctrl-h/j/k/l  split navigation' "$TMP_ROOT/tutor-classic.txt"
    grep -Fq '[q/]q [l/]l   qf / loclist' "$TMP_ROOT/tutor-classic.txt"
    grep -Fq ',S + 2 chars  EasyMotion jump' "$TMP_ROOT/tutor-classic.txt"
    grep -Fq ',u            undo tree' "$TMP_ROOT/tutor-classic.txt"

    step "Release guide surfaces"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'ChopsticksBeta' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 78 | cquit | endif' \
        -c "redir! > $TMP_ROOT/beta-guide.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'chopsticks release 2.3.0' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'Validate the long-term project loop before tagging.' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'Record real editing friction before release.' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'no GitHub/private wiki is needed to remember the daily loop' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'window/sidebar navigation beats native <C-w> only' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'SPC SPC   find file' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 's / SPC S jump on screen' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'gd / gr   definition / references' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'K         hover docs' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'SPC /     grep project' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'SPC rr    run current file' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'SPC gs    git status' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'SPC cf    format' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'SPC ?     active cheat sheet' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'whether SPC ?, :ChopsticksTutor, or :ChopsticksStatus answered it' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'README, QUICKSTART, SPC ?, and tutor teach the same layout' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'commands' "$TMP_ROOT/beta-guide.txt"
    grep -Fq ':ChopsticksBeta        release checklist' "$TMP_ROOT/beta-guide.txt"
    grep -Fq ':ChopsticksBetaLog     release notes' "$TMP_ROOT/beta-guide.txt"
    grep -Fq ':ChopsticksBetaSession new release note' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'references' "$TMP_ROOT/beta-guide.txt"
    grep -Fq 'BETA.md        release checklist and rollback' "$TMP_ROOT/beta-guide.txt"

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_profile = "minimal"' \
        -c 'source .vimrc' \
        -c 'ChopsticksBeta' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 78 | cquit | endif' \
        -c "redir! > $TMP_ROOT/beta-guide-minimal.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq 'SPC SPC   find file' "$TMP_ROOT/beta-guide-minimal.txt"
    grep -Fq 's / SPC S jump on screen' "$TMP_ROOT/beta-guide-minimal.txt"
    grep -Fq 'SPC /     grep project' "$TMP_ROOT/beta-guide-minimal.txt"
    grep -Fq 'SPC rr    run current file' "$TMP_ROOT/beta-guide-minimal.txt"
    grep -Fq 'SPC gs    git status' "$TMP_ROOT/beta-guide-minimal.txt"
    grep -Fq 'task: project navigation, code, grep, git, Markdown, SSH' \
        "$TMP_ROOT/beta-guide-minimal.txt"
    if grep -Eq 'gd / gr|K         hover docs|SPC cf|LSP, Markdown' \
        "$TMP_ROOT/beta-guide-minimal.txt"; then
        cat "$TMP_ROOT/beta-guide-minimal.txt"
        exit 1
    fi

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "classic"' \
        -c 'source .vimrc' \
        -c 'ChopsticksBeta' \
        -c 'if max(map(getline(1, "$"), "strdisplaywidth(v:val)")) > 78 | cquit | endif' \
        -c "redir! > $TMP_ROOT/beta-guide-classic.txt" \
        -c 'silent %print' \
        -c 'redir END' \
        -c 'qa!' 2>&1
    grep -Fq ',ff       find file' "$TMP_ROOT/beta-guide-classic.txt"
    grep -Fq ',S        jump on screen' "$TMP_ROOT/beta-guide-classic.txt"
    grep -Fq ',dd / ,dr definition / references' "$TMP_ROOT/beta-guide-classic.txt"
    grep -Fq ',dk       hover docs' "$TMP_ROOT/beta-guide-classic.txt"
    grep -Fq ',rg       grep project' "$TMP_ROOT/beta-guide-classic.txt"
    grep -Fq ',cr       run current file' "$TMP_ROOT/beta-guide-classic.txt"
    grep -Fq ',gs       git status' "$TMP_ROOT/beta-guide-classic.txt"
    grep -Fq ',f        format' "$TMP_ROOT/beta-guide-classic.txt"
    grep -Fq ',?        active cheat sheet' "$TMP_ROOT/beta-guide-classic.txt"
    grep -Fq 'whether ,?, :ChopsticksTutor, or :ChopsticksStatus answered it' "$TMP_ROOT/beta-guide-classic.txt"
    grep -Fq 'README, QUICKSTART, ,?, and tutor teach the same layout' "$TMP_ROOT/beta-guide-classic.txt"
    if grep -Fq 'SPC SPC   find file' "$TMP_ROOT/beta-guide-classic.txt" ||
        grep -Fq 's / SPC S jump on screen' "$TMP_ROOT/beta-guide-classic.txt" ||
        grep -Fq 'gd / gr   definition / references' "$TMP_ROOT/beta-guide-classic.txt" ||
        grep -Fq 'K         hover docs' "$TMP_ROOT/beta-guide-classic.txt" ||
        grep -Fq 'SPC /     grep project' "$TMP_ROOT/beta-guide-classic.txt" ||
        grep -Fq 'SPC rr    run current file' "$TMP_ROOT/beta-guide-classic.txt" ||
        grep -Fq 'SPC gs    git status' "$TMP_ROOT/beta-guide-classic.txt" ||
        grep -Fq 'SPC cf    format' "$TMP_ROOT/beta-guide-classic.txt" ||
        grep -Fq 'SPC ?     active cheat sheet' "$TMP_ROOT/beta-guide-classic.txt" ||
        grep -Fq 'whether SPC ?' "$TMP_ROOT/beta-guide-classic.txt" ||
        grep -Fq 'README, QUICKSTART, SPC ?' "$TMP_ROOT/beta-guide-classic.txt"; then
        cat "$TMP_ROOT/beta-guide-classic.txt"
        exit 1
    fi

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_release_label = "v9.9.9"' \
        -c 'source .vimrc' \
        -c 'let g:beta = ChopsticksBetaInfo() | if get(g:beta, "label", "") !=# "v9.9.9" || get(g:beta.details[0], "label", "") !=# "release" || get(g:beta, "log_path", "") !~# "chopsticks-v9.9.9.md" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_beta_label = "legacy-test"' \
        -c 'source .vimrc' \
        -c 'let g:beta = ChopsticksBetaInfo() | if get(g:, "chopsticks_release_label", "") !=# "legacy-test" || get(g:beta, "label", "") !=# "legacy-test" | cquit | endif' \
        -c 'qa!' 2>&1

    beta_log="$TMP_ROOT/release log/chopsticks-2.3.0.md"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c "let g:chopsticks_beta_log = '$beta_log'" \
        -c 'source .vimrc' \
        -c 'ChopsticksBetaLog' \
        -c 'if expand("%:p") !~# "chopsticks-2.3.0.md" || &l:filetype !=# "markdown" | cquit | endif' \
        -c 'qa!' 2>&1
    grep -Fq '# chopsticks 2.3.0 release log' "$beta_log"
    grep -Fq 'First key tried when stuck:' "$beta_log"
    grep -Fq 'Did SPC ?, :ChopsticksTutor, or :ChopsticksStatus answer it:' "$beta_log"

    beta_log_classic="$TMP_ROOT/release log/chopsticks-classic.md"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:chopsticks_keymap_style = "classic"' \
        -c "let g:chopsticks_beta_log = '$beta_log_classic'" \
        -c 'source .vimrc' \
        -c 'ChopsticksBetaLog' \
        -c 'qa!' 2>&1
    grep -Fq 'Did ,?, :ChopsticksTutor, or :ChopsticksStatus answer it:' \
        "$beta_log_classic"
    if grep -Fq 'Did SPC ?' "$beta_log_classic"; then
        cat "$beta_log_classic"
        exit 1
    fi

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

    step "Markdown and file safety"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N README.md \
        -c 'let g:chopsticks_keymap_style = "space"' \
        -c 'source .vimrc' \
        -c 'set filetype=markdown' \
        -c 'let g:markdown_keys = ChopsticksKeymapContractKeys("markdown_maps") | let g:language = ChopsticksLanguageInfo() | if join(g:markdown_keys, "/") !=# ",mt/,mp" || maparg(",mt", "n") !~# "Toc" || maparg(",mp", "n") !~# "PrevimOpen" || get(g:language.details[2], "value", "") !=# "markdown" || get(g:language.items[2], "state", "") !=# "ready" || get(g:language.items[2], "reason", "") !=# "Toc/PrevimOpen" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N README.md \
        -c 'let g:chopsticks_keymap_style = "space"' \
        -c 'source .vimrc' \
        -c 'set filetype=markdown' \
        -c 'silent! nunmap <buffer> ,mt' \
        -c 'let g:language = ChopsticksLanguageInfo() | let g:keymap = ChopsticksKeymapAuditInfo() | let g:health = ChopsticksHealthInfo() | if get(g:language.items[2], "state", "") !=# "missing" || stridx(get(g:language.items[2], "detail", ""), "Toc") < 0 || g:keymap.ok || empty(filter(copy(g:health.issues), "v:val.code ==# \"languages.markdown-maps\" && stridx(v:val.detail, \"Toc\") >= 0")) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" \
        vim --cmd 'let g:chopsticks_keymap_style = "classic"' \
        -u .vimrc -i NONE -es -N \
        -c 'let g:markdown_keys = ChopsticksKeymapContractKeys("markdown_maps") | if join(g:markdown_keys, "/") !=# ",mt/,mp" || maparg(",mt", "n") !~# "Toc" || maparg(",mp", "n") !~# "PrevimOpen" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N README.md \
        -c 'set filetype=markdown' \
        -c 'let g:language = ChopsticksLanguageInfo() | if &l:spell || &l:conceallevel != 0 || &l:signcolumn !=# "no" || exists("g:lsp_settings_filetype_markdown") || get(g:language.items[1], "reason", "") !=# "quiet defaults" || get(g:language.items[1], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N \
        -c 'if maparg("s", "n") !~# "easymotion-overwin-f2" | cquit | endif' \
        -c 'if maparg("<Space>w", "n") =~# "!" | cquit | endif' \
        -c 'if !&swapfile || !&writebackup || &directory !~# "\.vim/.swap" | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:ale_fix_on_save = 0' \
        -c 'source .vimrc' \
        -c 'let g:lint = ChopsticksLintInfo() | if g:ale_fix_on_save != 0 || get(g:lint.items[2], "label", "") !=# "format on save" || get(g:lint.items[2], "state", "") !=# "off" || get(g:lint.items[2], "reason", "") !=# "disabled by user" || get(g:lint.items[2], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u NONE -i NONE -es -N \
        -c 'let g:LargeFile = 0' \
        -c 'source .vimrc' \
        -c 'let g:files = ChopsticksFileSafetyInfo() | let g:health = ChopsticksHealthInfo() | if get(g:files.items[1], "label", "") !=# "large file guard" || get(g:files.items[1], "state", "") !=# "missing" || !get(g:files.items[1], "diagnostic", 0) || empty(filter(copy(g:health.issues), "v:val.code ==# \"file-safety.large-file-threshold\" && v:val.detail =~# \"invalid g:LargeFile\"")) | cquit | endif' \
        -c 'qa!' 2>&1

    truncate -s 11000000 "$TMP_ROOT/large.py"
    XDG_CONFIG_HOME="$EMPTY_XDG" vim -u .vimrc -i NONE -es -N "$TMP_ROOT/large.py" \
        -c 'set filetype=python' \
        -c 'if &l:syntax !=# "" || &l:undolevels != -1 || &l:swapfile || get(b:, "ale_enabled", 1) != 0 | cquit | endif' \
        -c 'let g:files = ChopsticksFileSafetyInfo() | if !g:files.large_buffer || get(g:files.items[2], "label", "") !=# "current buffer" || get(g:files.items[2], "state", "") !=# "ready" || get(g:files.items[2], "value", "") !=# "large file" || get(g:files.items[2], "reason", "") !~# "reduced" || get(g:files.items[2], "diagnostic", 1) | cquit | endif' \
        -c 'qa!' 2>&1

    step "Runner execution and startup budget"
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
        -c 'let g:runner = ChopsticksRunnerInfo() | if get(g:runner, "title", "") !=# "run file" || get(g:runner, "filetype", "") !=# "c" || get(g:runner.items[0], "state", "") !=# "ready" || get(g:runner.items[0], "value", "") !=# "c" || get(g:runner.items[0], "reason", "") !=# "gcc" || get(g:runner.items[0], "diagnostic", 1) | cquit | endif' \
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
