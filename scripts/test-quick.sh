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
    bash -n scripts/ci-install-plugins.sh
    bash -n scripts/release-notes.sh
    test -x install.sh
    test -x get.sh
    test -x scripts/test.sh
    test -x scripts/ci-install-plugins.sh
    test -x scripts/release-notes.sh

    need shellcheck
    shellcheck install.sh get.sh scripts/test.sh \
        scripts/test-common.sh scripts/test-quick.sh scripts/test-vim.sh \
        scripts/ci-install-plugins.sh scripts/release-notes.sh
}

check_vim_only_runtime() {
    step "Vim-only runtime gates"

    local forbidden_runtime
    forbidden_runtime="$(
        grep -R -n -E 'stdpath\(|nvim_|lua[[:space:]]*<<|init\.lua|\.lua' \
            .vimrc modules || true
    )"
    if [ -n "$forbidden_runtime" ]; then
        echo "Neovim/Lua runtime marker found:" >&2
        echo "$forbidden_runtime" >&2
        exit 1
    fi

    local unexpected_nvim_gate
    unexpected_nvim_gate="$(
        grep -R -n -E "has\(['\"]nvim['\"]\)" .vimrc modules \
            | grep -v '^\.vimrc:' \
            | grep -v '^modules/env\.vim:' || true
    )"
    if [ -n "$unexpected_nvim_gate" ]; then
        echo "Unexpected Neovim branch outside the runtime gate:" >&2
        echo "$unexpected_nvim_gate" >&2
        exit 1
    fi
}

check_release_notes() {
    step "Release notes extraction"

    local latest_version
    latest_version="$(awk '/^## [0-9]+\.[0-9]+\.[0-9]+/{ print $2; exit }' CHANGELOG.md)"
    test -n "$latest_version"
    scripts/release-notes.sh "v$latest_version" > "$TMP_ROOT/release-notes.txt"
    grep -Fq "## $latest_version" "$TMP_ROOT/release-notes.txt"
}

check_docs() {
    step "Markdown lint"
    need markdownlint
    markdownlint README.md QUICKSTART.md CONTRIBUTING.md CHANGELOG.md \
        BETA.md CONTEXT.md docs/adr/*.md

    step "Documentation consistency"
    test -f CONTEXT.md
    test -f docs/adr/0001-vim-only-runtime.md
    test -f docs/adr/0002-pin-vim-plugins-by-default.md
    test -f docs/adr/0003-system-tools-are-explicit-opt-in.md
    test -f docs/adr/0004-keymaps-must-pass-the-ergonomic-contract.md
    test -f docs/adr/0007-learning-surface-model-is-shared.md
    test -f docs/adr/0008-learning-surface-consumers-use-model-adapters.md
    test -f docs/adr/0009-learning-surface-producer-lives-in-learning-module.md
    grep -Fq 'Vim 8.2 and Vim 9.x only' docs/adr/0001-vim-only-runtime.md
    grep -Fq 'g:chopsticks_pin_plugins' docs/adr/0002-pin-vim-plugins-by-default.md
    grep -Fq -- '--install-tools' docs/adr/0003-system-tools-are-explicit-opt-in.md
    grep -Fq ':ChopsticksKeymapAudit' \
        docs/adr/0004-keymaps-must-pass-the-ergonomic-contract.md
    grep -Fq 'ChopsticksLearningRowLines()' \
        docs/adr/0007-learning-surface-model-is-shared.md
    grep -Fq 'ChopsticksLearningLoopEnabled()' \
        docs/adr/0008-learning-surface-consumers-use-model-adapters.md
    grep -Fq 'modules/learning.vim' \
        docs/adr/0009-learning-surface-producer-lives-in-learning-module.md
    grep -Fq '**Ergonomic Contract**' CONTEXT.md
    grep -Fq '**Keymap Contract Spec**' CONTEXT.md
    grep -Fq '**Keymap Readiness Adapter**' CONTEXT.md
    grep -Fq '**Keymap Contract Adapter**' CONTEXT.md
    grep -Fq '**Keymap Contract Group**' CONTEXT.md
    grep -Fq '**Keymap Display Group**' CONTEXT.md
    grep -Fq '**Command Header**' CONTEXT.md
    grep -Fq '**Learning Surface**' CONTEXT.md
    grep -Fq '**Learning Surface Item**' CONTEXT.md
    grep -Fq 'ChopsticksLearningEntrypointInfo()' CONTEXT.md
    grep -Fq '**Help Surface**' CONTEXT.md
    grep -Fq '**Help Surface Item**' CONTEXT.md
    grep -Fq '**Runtime Gate**' CONTEXT.md
    grep -Fq '**Remote Session**' CONTEXT.md
    grep -Fq '**Profile Resolution**' CONTEXT.md
    grep -Fq '**Local Preference Load**' CONTEXT.md
    grep -Fq '**Module Load**' CONTEXT.md
    grep -Fq '**Editor Core**' CONTEXT.md
    grep -Fq '**Editor Core Item**' CONTEXT.md
    grep -Fq '**Command Surface**' CONTEXT.md
    grep -Fq '**Command Surface Item**' CONTEXT.md
    grep -Fq '**Command Owner Group**' CONTEXT.md
    grep -Fq '**Command Display Group**' CONTEXT.md
    grep -Fq '**Command Surface Adapter**' CONTEXT.md
    grep -Fq '**Command Availability Adapter**' CONTEXT.md
    grep -Fq '**Learning Display Adapter**' CONTEXT.md
    grep -Fq '**Learning Model Adapter**' CONTEXT.md
    grep -Fq 'modules/learning.vim' CONTEXT.md
    grep -Fq '**Plugin State Adapter**' CONTEXT.md
    grep -Fq '**Tool Availability Adapter**' CONTEXT.md
    grep -Fq '**Utility Actions**' CONTEXT.md
    grep -Fq '**Utility Action Item**' CONTEXT.md
    grep -Fq '**Visual Surface**' CONTEXT.md
    grep -Fq '**Visual Surface Item**' CONTEXT.md
    grep -Fq '**Language Surface**' CONTEXT.md
    grep -Fq '**Language Surface Item**' CONTEXT.md
    grep -Fq '**Lint Loop**' CONTEXT.md
    grep -Fq '**Lint Loop Item**' CONTEXT.md
    grep -Fq '**Completion Loop**' CONTEXT.md
    grep -Fq '**Completion Loop Item**' CONTEXT.md
    grep -Fq '**LSP Attach Keymap**' CONTEXT.md
    grep -Fq '**Chopsticks Doctor**' CONTEXT.md
    grep -Fq '**Health Diagnostic Item**' CONTEXT.md
    grep -Fq '**Info Row Contract**' CONTEXT.md
    grep -Fq '**Health Issue Adapter**' CONTEXT.md
    grep -Fq '**Info Shape Contract**' CONTEXT.md
    grep -Fq '**Info Fallback Adapter**' CONTEXT.md
    grep -Fq 'ChopsticksInfoSection()' CONTEXT.md
    grep -Fq 'malformed note/footer entries' CONTEXT.md
    grep -Fq 'shared adapter' CONTEXT.md
    grep -Fq '**Buffer Lifecycle**' CONTEXT.md
    grep -Fq '**Buffer Lifecycle Item**' CONTEXT.md
    grep -Fq '**Editing Assist**' CONTEXT.md
    grep -Fq '**Editing Assist Item**' CONTEXT.md
    grep -Fq '**File Safety**' CONTEXT.md
    grep -Fq '**File Safety Item**' CONTEXT.md
    grep -Fq '**Quickfix Loop**' CONTEXT.md
    grep -Fq '**Quickfix Item**' CONTEXT.md
    grep -Fq '**Git Loop**' CONTEXT.md
    grep -Fq '**Git Loop Item**' CONTEXT.md
    grep -Fq '**Project Run**' CONTEXT.md
    grep -Fq '**Project Run Item**' CONTEXT.md
    grep -Fq '**Project Search**' CONTEXT.md
    grep -Fq '**Project Search Item**' CONTEXT.md
    grep -Fq '**File Sidebar**' CONTEXT.md
    grep -Fq '**File Sidebar Item**' CONTEXT.md
    grep -Fq '**Window Layout**' CONTEXT.md
    grep -Fq '**Window Layout Item**' CONTEXT.md
    grep -Fq 'docs/adr/' README.md
    grep -Fq 'docs/adr/' CONTRIBUTING.md
    grep -Fq 'v:version < 802' .vimrc
    grep -Fq 'has('\''nvim'\'')' .vimrc

    for command in ChopsticksHelp ChopsticksConfig ChopsticksReload
    do
        for file in README.md BETA.md doc/chopsticks.txt modules/cheatsheet.vim \
            modules/tutor.vim modules/status.vim
        do
            grep -Fq "$command" "$file" || {
                echo "Missing $command in $file" >&2
                exit 1
            }
        done
    done
    for command in ChopsticksBeta ChopsticksBetaLog ChopsticksBetaSession
    do
        for file in README.md BETA.md doc/chopsticks.txt modules/cheatsheet.vim \
            modules/tutor.vim modules/beta.vim
        do
            grep -Fq "$command" "$file" || {
                echo "Missing $command in $file" >&2
                exit 1
            }
        done
    done
    grep -Fq '*chopsticks.txt*' doc/chopsticks.txt
    grep -Fq '*chopsticks-space*' doc/chopsticks.txt
    grep -Fq 'command! ChopsticksHelp' modules/help.vim
    grep -Fq 'function! ChopsticksHelpInfo' modules/help.vim
    grep -Fq 'command! ChopsticksConfig' modules/utilities.vim
    grep -Fq 'command! ChopsticksReload' modules/utilities.vim
    grep -Fq 'command! ChopsticksDoctor' modules/health.vim
    grep -Fq 'function! ChopsticksKeymapContractSpecs' modules/keymap.vim
    grep -Fq 'function! ChopsticksKeymapContractSpecsFor' modules/keymap.vim
    grep -Fq 'function! ChopsticksKeymapContractKeys' modules/keymap.vim
    grep -Fq 'function! ChopsticksKeymapContractLines' modules/keymap.vim
    grep -Fq 'function! ChopsticksKeymapSpecIssue' modules/env.vim
    grep -Fq 'function! ChopsticksKeymapSpecReady' modules/env.vim
    grep -Fq 'function! ChopsticksKeymapMissingKeys' modules/env.vim
    grep -Fq 'function! ChopsticksKeymapContractSpecsOr' modules/env.vim
    grep -Fq 'function! ChopsticksKeymapContractFirstSpecOr' modules/env.vim
    grep -Fq 'function! ChopsticksKeymapContractKeysOr' modules/env.vim
    grep -Fq 'function! ChopsticksKeymapContractLinesOr' modules/env.vim
    grep -Fq 'function! ChopsticksCommandAvailable' modules/env.vim
    grep -Fq 'function! ChopsticksMissingCommands' modules/env.vim
    grep -Fq 'function! ChopsticksPluginSpec' modules/env.vim
    grep -Fq 'function! ChopsticksPluginDeclared' modules/env.vim
    grep -Fq 'function! ChopsticksPluginDir' modules/env.vim
    grep -Fq 'function! ChopsticksPluginInstalled' modules/env.vim
    grep -Fq 'function! ChopsticksInfoOr' modules/info.vim
    grep -Fq 'function! ChopsticksLspLearningEnabledOr' modules/env.vim
    grep -Fq 'function! ChopsticksToolAvailable' modules/env.vim
    grep -Fq 'function! ChopsticksMissingTools' modules/env.vim
    grep -Fq 'function! ChopsticksToolState' modules/env.vim
    grep -Fq 'function! ChopsticksToolOffState' modules/env.vim
    grep -Fq 'ChopsticksKeymapSpecIssue(a:spec)' modules/keymap.vim
    grep -Fq 'ChopsticksKeymapContractSpecs().specs' modules/keymap.vim
    grep -Fq 'core_survival' modules/keymap.vim
    grep -Fq 'core_toggles' modules/keymap.vim
    grep -Fq 'clipboard_maps' modules/keymap.vim
    grep -Fq 'clipboard_summary' modules/keymap.vim
    grep -Fq 'line_move' modules/keymap.vim
    grep -Fq 'line_move_summary' modules/keymap.vim
    grep -Fq "'display_groups': ['survival_core', 'core_survival']" modules/keymap.vim
    grep -Fq 'utility_config' modules/keymap.vim
    grep -Fq 'utility_path_copy' modules/keymap.vim
    grep -Fq 'ChopsticksKeymapMissingKeys(s:SurvivalMapSpecs())' \
        modules/core.vim
    grep -Fq 'ChopsticksKeymapMissingKeys(s:SearchMotionSpecs())' \
        modules/core.vim
    grep -Fq 'ChopsticksKeymapMissingKeys(s:RunMapSpecs())' \
        modules/runner.vim
    grep -Fq 'ChopsticksKeymapMissingKeys(s:CompletionMapSpecs())' \
        modules/lsp.vim
    grep -Fq "ChopsticksPluginDeclared('vim-easymotion')" modules/editing.vim
    grep -Fq "ChopsticksPluginInstalled('undotree')" modules/editing.vim
    grep -Fq "ChopsticksPluginDeclared('vim-fugitive')" modules/git.vim
    grep -Fq "ChopsticksPluginDeclared('ale')" modules/lint.vim
    grep -Fq "ChopsticksPluginDeclared('vim-markdown')" modules/languages.vim
    grep -Fq "ChopsticksPluginInstalled('vim-markdown')" modules/languages.vim
    grep -Fq 'ChopsticksPluginDeclared(a:plugin)' modules/lsp.vim
    grep -Fq 'ChopsticksPluginInstalled(a:plugin)' modules/lsp.vim
    grep -Fq "ChopsticksPluginDeclared('fzf.vim')" modules/navigation.vim
    grep -Fq "ChopsticksPluginDeclared('vim-startify')" modules/ui.vim
    grep -Fq "ChopsticksPluginDeclared('ale')" modules/keymap.vim
    grep -Fq "ChopsticksPluginDeclared('undotree')" modules/tutor.vim
    grep -Fq "ChopsticksPluginDeclared('previm')" modules/cheatsheet.vim
    local plugin_state_consumers=(
        modules/beta.vim
        modules/cheatsheet.vim
        modules/editing.vim
        modules/git.vim
        modules/keymap.vim
        modules/languages.vim
        modules/lint.vim
        modules/lsp.vim
        modules/navigation.vim
        modules/tutor.vim
        modules/ui.vim
    )
    if grep -Eq 'function! s:(PlugDir|PlugInstalled|PluginDeclared)' \
        "${plugin_state_consumers[@]}" || \
        grep -Eq "exists\\(['\"]g:plugs|has_key\\(g:plugs|get\\(g:plugs|g:plugs\\[" \
        "${plugin_state_consumers[@]}"; then
        echo "Plugin state consumers must use ChopsticksPlugin...()" >&2
        exit 1
    fi
    grep -Fq "ChopsticksToolAvailable('rg')" modules/core.vim
    grep -Fq "ChopsticksToolAvailable('git')" modules/git.vim
    grep -Fq 'ChopsticksToolAvailable(l:cmd)' modules/runner.vim
    grep -Fq 'ChopsticksToolAvailable(l:cmd)' modules/input_method.vim
    grep -Fq "ChopsticksToolAvailable('xdg-open')" modules/languages.vim
    grep -Fq "ChopsticksMissingTools(['fzf', 'rg'])" modules/navigation.vim
    grep -Fq "ChopsticksToolState('ripgrep'" modules/tools.vim
    grep -Fq "ChopsticksToolOffState('markdownlint (md)'" modules/tools.vim
    local tool_availability_consumers=(
        modules/core.vim
        modules/git.vim
        modules/input_method.vim
        modules/languages.vim
        modules/navigation.vim
        modules/runner.vim
        modules/tools.vim
    )
    if grep -Eq 'executable\(' "${tool_availability_consumers[@]}" || \
        grep -Eq 'function! s:(Tool|OffTool|MissingTools)\(' \
        modules/navigation.vim modules/tools.vim; then
        echo "Tool availability consumers must use ChopsticksTool...()" >&2
        exit 1
    fi
    grep -Fq "ChopsticksInfoOr('ChopsticksLearningEntrypointInfo'" \
        modules/beta.vim
    grep -Fq "ChopsticksInfoOr('ChopsticksLearningDailyLoopInfo'" \
        modules/tutor.vim
    grep -Fq "ChopsticksLearningLoopEnabled(l:loop, l:lsp_loop" \
        modules/beta.vim
    grep -Fq "ChopsticksLearningLoopEnabled(l:loop, l:lsp_loop" \
        modules/tutor.vim
    grep -Fq "ChopsticksLspLearningEnabledOr(" modules/learning.vim
    grep -Fq "ChopsticksInfoOr('ChopsticksHelpInfo'" modules/learning.vim
    grep -Fq "ChopsticksInfoOr('ChopsticksStatusHeaderInfo'" \
        modules/status.vim
    local info_fallback_consumers=(
        modules/beta.vim
        modules/cheatsheet.vim
        modules/learning.vim
        modules/status.vim
        modules/tutor.vim
    )
    if grep -Eq "exists\\(['\"]\\*Chopsticks(Learning|Lsp|HelpInfo|BetaInfo)" \
        "${info_fallback_consumers[@]}"; then
        echo "Info fallback consumers must use ChopsticksInfoOr()/ChopsticksLspLearningEnabledOr()" >&2
        exit 1
    fi
    grep -Fq 'ChopsticksKeymapSpecReady(l:spec)' \
        modules/learning.vim
    if grep -Eq 'function! s:(MapReady|SpecReady|MissingKeys|MissingSpecKeys|MissingMaps)' \
        modules/*.vim || \
        grep -Eq 'function! s:(MapRhs|ExpectMap|ExpectNoMap|ExpectAutoPairsMap)' \
        modules/keymap.vim; then
        echo "Keymap readiness must use ChopsticksKeymapSpecReady/MissingKeys()" >&2
        exit 1
    fi
    grep -Fq 'buffer_close' modules/keymap.vim
    grep -Fq 'buffer_close_all' modules/keymap.vim
    grep -Fq 'buffer_close_others' modules/keymap.vim
    grep -Fq 'buffer_navigation' modules/keymap.vim
    grep -Fq 'buffer_alternate' modules/keymap.vim
    grep -Fq 'project_search' modules/keymap.vim
    grep -Fq 'project_files' modules/keymap.vim
    grep -Fq 'project_files_picker' modules/keymap.vim
    grep -Fq 'project_buffers' modules/keymap.vim
    grep -Fq 'project_buffers_picker' modules/keymap.vim
    grep -Fq 'project_git_files' modules/keymap.vim
    grep -Fq 'project_recent_files' modules/keymap.vim
    grep -Fq 'project_buffer_lines' modules/keymap.vim
    grep -Fq 'project_commands' modules/keymap.vim
    grep -Fq 'project_marks' modules/keymap.vim
    grep -Fq 'project_search_history' modules/keymap.vim
    grep -Fq 'project_command_history' modules/keymap.vim
    grep -Fq 'project_grep' modules/keymap.vim
    grep -Fq 'project_grep_picker' modules/keymap.vim
    grep -Fq 'project_grep_word' modules/keymap.vim
    grep -Fq 'project_tags' modules/keymap.vim
    grep -Fq 'file_sidebar' modules/keymap.vim
    grep -Fq 'window_layout' modules/keymap.vim
    grep -Fq 'window_navigation' modules/keymap.vim
    grep -Fq 'visible_jump' modules/keymap.vim
    grep -Fq 'edit_cleanup' modules/keymap.vim
    grep -Fq 'edit_cleanup_summary' modules/keymap.vim
    grep -Fq 'blank_lines' modules/keymap.vim
    grep -Fq 'undo_tree' modules/keymap.vim
    grep -Fq 'full_file_reindent' modules/keymap.vim
    grep -Fq 'quickfix_navigation' modules/keymap.vim
    grep -Fq 'quickfix_window' modules/keymap.vim
    grep -Fq 'loclist_window' modules/keymap.vim
    grep -Fq 'terminal_entry' modules/keymap.vim
    grep -Fq 'git_keymaps' modules/keymap.vim
    grep -Fq 'git_status' modules/keymap.vim
    grep -Fq 'git_commit' modules/keymap.vim
    grep -Fq 'git_diff' modules/keymap.vim
    grep -Fq 'git_blame' modules/keymap.vim
    grep -Fq 'git_log' modules/keymap.vim
    grep -Fq 'git_commit_picker' modules/keymap.vim
    grep -Fq 'git_buffer_commit_picker' modules/keymap.vim
    grep -Fq 'git_conflict_navigation' modules/keymap.vim
    grep -Fq 'project_run' modules/keymap.vim
    grep -Fq 'project_task_picker' modules/keymap.vim
    grep -Fq 'project_run_last' modules/keymap.vim
    grep -Fq 'lint_keymaps' modules/keymap.vim
    grep -Fq 'markdown_maps' modules/keymap.vim
    grep -Fq 'completion_keymaps' modules/keymap.vim
    grep -Fq 'lsp_buffer_keymaps' modules/keymap.vim
    grep -Fq 'lsp_definition_references' modules/keymap.vim
    grep -Fq 'lsp_definition' modules/keymap.vim
    grep -Fq 'lsp_references' modules/keymap.vim
    grep -Fq 'lsp_implementation' modules/keymap.vim
    grep -Fq 'lsp_type_definition' modules/keymap.vim
    grep -Fq 'lsp_hover' modules/keymap.vim
    grep -Fq 'lsp_format' modules/keymap.vim
    grep -Fq 'lsp_format_normal' modules/keymap.vim
    grep -Fq 'lsp_code_action' modules/keymap.vim
    grep -Fq 'lsp_rename' modules/keymap.vim
    grep -Fq 'lsp_diagnostics' modules/keymap.vim
    grep -Fq 'lsp_previous_diagnostic' modules/keymap.vim
    grep -Fq 'lsp_next_diagnostic' modules/keymap.vim
    grep -Fq 'learning_entrypoint' modules/keymap.vim
    grep -Fq 'function! s:LspBufferMapSpec' modules/keymap.vim
    grep -Fq "'scope': 'lsp_buffer'" modules/keymap.vim
    grep -Fq "'audit': 0" modules/keymap.vim
    grep -Fq "'display_groups': ['survival_config', 'utility_config']" modules/keymap.vim
    grep -Fq "'display_groups': ['buffer_navigation', 'buffer_lifecycle']" modules/keymap.vim
    grep -Fq "'display_groups': ['buffer_close_all', 'buffer_lifecycle']" modules/keymap.vim
    grep -Fq "'display_groups': ['buffer_close_others', 'buffer_lifecycle']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_search', 'project_files']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['project_files_picker']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_buffers']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_buffers_picker']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['project_git_files']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_recent_files']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_buffer_lines']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_commands']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_marks']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_search_history']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_command_history']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_search', 'project_grep']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['project_grep_picker']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_search', 'project_grep_word']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['project_search', 'project_tags']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['file_sidebar']" modules/keymap.vim
    grep -Fq "'display_groups': ['window_layout']" modules/keymap.vim
    grep -Fq "'display_groups': ['window_navigation']" modules/keymap.vim
    grep -Fq "'display_groups': ['core_toggles']" modules/keymap.vim
    grep -Fq 'clipboard_summary' modules/keymap.vim
    grep -Fq "'display_groups': ['line_move', 'line_move_summary']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['visible_jump', 'visible_jump_summary']" modules/keymap.vim
    grep -Fq "'display_groups': ['edit_cleanup', 'edit_cleanup_summary']" modules/keymap.vim
    grep -Fq "'display_groups': ['blank_lines']" modules/keymap.vim
    grep -Fq "'display_groups': ['undo_tree']" modules/keymap.vim
    grep -Fq "'display_groups': ['full_file_reindent']" modules/keymap.vim
    grep -Fq "'display_groups': ['quickfix_navigation']" modules/keymap.vim
    grep -Fq "'display_groups': ['quickfix_window']" modules/keymap.vim
    grep -Fq "'display_groups': ['loclist_window']" modules/keymap.vim
    grep -Fq "'display_groups': ['terminal_entry']" modules/keymap.vim
    grep -Fq "'display_groups': ['git_keymaps', 'git_status']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['git_keymaps', 'git_commit']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['git_keymaps', 'git_diff']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['git_keymaps', 'git_blame']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['git_keymaps', 'git_log']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['git_commit_picker']" modules/keymap.vim
    grep -Fq "'display_groups': ['git_buffer_commit_picker']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['git_conflict_navigation']" \
        modules/keymap.vim
    grep -Fq "'display_groups': ['project_run']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_task_picker']" modules/keymap.vim
    grep -Fq "'display_groups': ['project_run_last']" modules/keymap.vim
    grep -Fq "'display_groups': ['lint_keymaps']" modules/keymap.vim
    grep -Fq "'display_groups': ['markdown_maps']" modules/keymap.vim
    grep -Fq "'display_groups': ['completion_keymaps']" modules/keymap.vim
    grep -Fq "'display_groups': ['learning_entrypoint']" modules/keymap.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('core_survival'" \
        modules/core.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('core_survival'" \
        modules/core.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('core_toggles'" \
        modules/core.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('core_toggles'" \
        modules/core.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('buffer_navigation'" \
        modules/buffers.vim
    grep -Fq "ChopsticksKeymapContractFirstSpecOr('buffer_close'" \
        modules/buffers.vim
    grep -Fq "ChopsticksKeymapContractFirstSpecOr('buffer_close_all'" \
        modules/buffers.vim
    grep -Fq "ChopsticksKeymapContractFirstSpecOr(" \
        modules/buffers.vim
    grep -Fq "'buffer_close_others'" modules/buffers.vim
    grep -Fq "ChopsticksKeymapContractFirstSpecOr('buffer_alternate'" \
        modules/buffers.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('utility_config'" \
        modules/utilities.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('utility_config'" \
        modules/utilities.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('utility_path_copy'" \
        modules/utilities.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('utility_path_copy'" \
        modules/utilities.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('visible_jump'" \
        modules/editing.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('visible_jump_summary'" \
        modules/editing.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('edit_cleanup'" \
        modules/editing.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('edit_cleanup_summary'" \
        modules/editing.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('blank_lines'" \
        modules/editing.vim
    grep -Fq "ChopsticksKeymapContractFirstSpecOr('undo_tree'" \
        modules/editing.vim
    grep -Fq "ChopsticksKeymapContractFirstSpecOr('full_file_reindent'" \
        modules/editing.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('quickfix_navigation'" \
        modules/quickfix.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('quickfix_navigation'" \
        modules/quickfix.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('git_keymaps'" \
        modules/git.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('git_conflict_navigation'" \
        modules/git.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('git_status'" modules/git.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('git_log'" modules/git.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('project_run'" \
        modules/runner.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr(" \
        modules/runner.vim
    grep -Fq "'project_task_picker'" modules/runner.vim
    grep -Fq "'project_run_last'" modules/runner.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('project_run'" \
        modules/runner.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('lint_keymaps'" \
        modules/lint.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('lint_keymaps'" \
        modules/lint.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('markdown_maps'" \
        modules/languages.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('completion_keymaps'" \
        modules/lsp.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('completion_keymaps'" \
        modules/lsp.vim
    grep -Fq "function! s:LspBufferMapSpecs" modules/lsp.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('lsp_buffer_keymaps'" \
        modules/lsp.vim
    grep -Fq "function! s:ApplyLspMapSpec" modules/lsp.vim
    grep -Fq "function! ChopsticksLspLearningEnabled" modules/lsp.vim
    grep -Fq "s:StackState().state !=# 'off'" modules/lsp.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('project_search'" \
        modules/navigation.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('project_search'" \
        modules/navigation.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('file_sidebar'" \
        modules/navigation.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('window_layout'" \
        modules/navigation.vim
    grep -Fq "ChopsticksKeymapContractSpecsOr('window_navigation'" \
        modules/navigation.vim
    grep -Fq 'function! s:DiscoveredChopsticksCommands' modules/env.vim
    grep -Fq 'function! s:CommandHeader' modules/env.vim
    grep -Fq 'function! ChopsticksCommandHeader' modules/env.vim
    grep -Fq 'function! ChopsticksCommandHeaderOr' modules/env.vim
    grep -Fq 'function! ChopsticksCommandNames' modules/env.vim
    grep -Fq 'function! ChopsticksCommandNamesOr' modules/env.vim
    grep -Fq 'function! ChopsticksCommandLines' modules/env.vim
    grep -Fq 'function! ChopsticksCommandLinesOr' modules/env.vim
    grep -Fq 'function! s:LearningEntrypointKey' modules/env.vim
    grep -Fq "ChopsticksInfoOr('ChopsticksLearningEntrypointInfo'" \
        modules/env.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('learning_entrypoint'" modules/env.vim
    grep -Fq "'groups': ['survival']" modules/env.vim
    grep -Fq "'groups': ['survival', 'beta']" modules/env.vim
    grep -Fq "s:CommandHeader('help'" modules/env.vim
    grep -Fq "s:CommandHeader('config'" modules/env.vim
    grep -Fq "ChopsticksCommandNamesOr('tutor'" modules/learning.vim
    grep -Fq "ChopsticksCommandNamesOr('beta'" modules/learning.vim
    grep -Fq "ChopsticksCommandLinesOr('survival'" modules/cheatsheet.vim
    grep -Fq "\\ 'learning'," .vimrc
    grep -Fq 'ChopsticksKeymapContractFirstSpecOr(' modules/learning.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('learning_entrypoint'" \
        modules/learning.vim
    grep -Fq "ChopsticksKeymapContractLinesOr('learning_entrypoint'" \
        modules/learning.vim
    grep -Fq "ChopsticksKeymapContractLinesOr('survival_core'" \
        modules/cheatsheet.vim
    grep -Fq "ChopsticksKeymapContractLinesOr('survival_config'" \
        modules/cheatsheet.vim
    grep -Fq "ChopsticksKeymapContractLinesOr('survival_core'" \
        modules/tutor.vim
    grep -Fq "ChopsticksKeymapContractLinesOr('survival_config'" \
        modules/tutor.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('learning_entrypoint'" \
        modules/status.vim
    local contract_consumer_modules=(
        modules/beta.vim
        modules/buffers.vim
        modules/cheatsheet.vim
        modules/core.vim
        modules/editing.vim
        modules/git.vim
        modules/languages.vim
        modules/learning.vim
        modules/lint.vim
        modules/lsp.vim
        modules/navigation.vim
        modules/quickfix.vim
        modules/runner.vim
        modules/status.vim
        modules/tutor.vim
        modules/utilities.vim
    )
    if grep -Eq 'function! s:(ContractSpecs|ContractKeys|FirstContractSpec|KeymapLines)' \
        "${contract_consumer_modules[@]}" || \
        grep -Eq 'function! ChopsticksKeymapContract(SpecsOr|FirstSpecOr|KeysOr|LinesOr)' \
        "${contract_consumer_modules[@]}" || \
        grep -Eq "exists\\(['\"]\\*ChopsticksKeymapContract(SpecsFor|Keys|Lines)" \
        "${contract_consumer_modules[@]}"; then
        echo "Keymap contract access must use ChopsticksKeymapContract...Or()" >&2
        exit 1
    fi
    grep -Fq "function! s:LspCheatLines" modules/cheatsheet.vim
    grep -Fq "function! s:GitCheatLines" modules/cheatsheet.vim
    grep -Fq "function! s:GitPickerCheatLines" modules/cheatsheet.vim
    grep -Fq "function! ChopsticksLearningDailyLoopInfo" \
        modules/learning.vim
    grep -Fq "function! ChopsticksLearningLspLoopInfo" \
        modules/learning.vim
    grep -Fq "function! ChopsticksLearningEntrypointInfo" \
        modules/learning.vim
    grep -Fq "function! ChopsticksLearningInfo" modules/learning.vim
    grep -Fq "'open_lhs': l:lhs" modules/learning.vim
    grep -Fq "'close_lhs': l:lhs" modules/learning.vim
    grep -Fq "'cheat_title': '  chopsticks         ' . l:key . ' close'" \
        modules/learning.vim
    grep -Fq "'guide_lines': s:LearningEntrypointLines('     ', 9)" \
        modules/learning.vim
    grep -Fq "'tutor_lines': s:LearningEntrypointLines('     ', 10)" \
        modules/learning.vim
    grep -Fq "'session_prompt': '- Did ' . l:key" modules/learning.vim
    grep -Fq "function! s:CheatSheetTitle" modules/cheatsheet.vim
    grep -Fq "function! s:CheatSheetOpenLhs" modules/cheatsheet.vim
    grep -Fq "function! s:CheatSheetCloseLhs" modules/cheatsheet.vim
    grep -Fq "function! s:MapCheatSheetEntrypoint" modules/cheatsheet.vim
    grep -Fq "call s:MapCheatSheetEntrypoint()" modules/cheatsheet.vim
    grep -Fq "let l:close_lhs = s:CheatSheetCloseLhs()" modules/cheatsheet.vim
    if grep -Fq 'function! ChopsticksLearning' modules/cheatsheet.vim; then
        echo "Learning Surface producers must live in modules/learning.vim" >&2
        exit 1
    fi
    if grep -Fq '<Space>? close' modules/cheatsheet.vim; then
        echo "Cheat sheet title must use LearningEntrypointInfo" >&2
        exit 1
    fi
    if grep -Fq 'nnoremap <buffer> <silent> <leader>?' modules/cheatsheet.vim; then
        echo "Cheat sheet close map must use LearningEntrypointInfo" >&2
        exit 1
    fi
    if grep -Fq 'nnoremap <silent> <leader>?' modules/cheatsheet.vim; then
        echo "Cheat sheet open map must use LearningEntrypointInfo" >&2
        exit 1
    fi
    grep -Fq "function! s:LearningDailyLoopInfo" modules/cheatsheet.vim
    grep -Fq "function! s:LearningLspLoopInfo" modules/cheatsheet.vim
    grep -Fq "function! s:TrainedLoopLines" modules/cheatsheet.vim
    grep -Fq "'summary_lines':" modules/learning.vim
    grep -Fq "'drill_steps':" modules/learning.vim
    grep -Fq "'tasks':" modules/learning.vim
    grep -Fq "'visible_jump': l:visible_jump_info" modules/learning.vim
    grep -Fq "'tutor_training_line':" modules/learning.vim
    grep -Fq "'tutor_lines':" modules/learning.vim
    grep -Fq "get(s:LearningDailyLoopInfo(), 'visible_jump', {})" \
        modules/cheatsheet.vim
    grep -Fq "'tutor_rows': l:tutor_rows" modules/learning.vim
    grep -Fq "'beta_rows': l:beta_rows" modules/learning.vim
    grep -Fq "'cheat_rows':" modules/learning.vim
    grep -Fq "'cheat_command_lines':" modules/learning.vim
    grep -Fq "'tutor_rows':" modules/learning.vim
    grep -Fq "'beta_rows':" modules/learning.vim
    grep -Fq "definition_references_docs" modules/learning.vim
    grep -Fq "actions_rename_format" modules/learning.vim
    grep -Fq "workspace_symbols" modules/learning.vim
    grep -Fq "function! s:MarkdownCheatLines" modules/cheatsheet.vim
    grep -Fq "function! s:LintCheatLines" modules/cheatsheet.vim
    grep -Fq "function! s:VisibleJumpCheatLines" modules/cheatsheet.vim
    grep -Fq "function! s:ReindentCheatLine" modules/cheatsheet.vim
    grep -Fq "function! s:ClipboardCheatLines" modules/cheatsheet.vim
    grep -Fq "function! s:LineMoveCheatLine" modules/cheatsheet.vim
    grep -Fq "function! s:CheatContractPairLine" modules/cheatsheet.vim
    grep -Fq "s:CheatContractLine('project_buffers'" \
        modules/cheatsheet.vim
    grep -Fq "s:CheatContractLine('project_files_picker'" \
        modules/cheatsheet.vim
    grep -Fq "s:CheatContractLine('project_grep_word'" \
        modules/cheatsheet.vim
    grep -Fq "s:CheatContractLine('git_diff'" modules/cheatsheet.vim
    grep -Fq "s:CheatContractLine('git_commit_picker'" \
        modules/cheatsheet.vim
    grep -Fq "s:CheatContractPairLine('quickfix_window'" \
        modules/cheatsheet.vim
    grep -Fq "s:CheatContractPairLine('terminal_entry'" \
        modules/cheatsheet.vim
    grep -Fq "s:CheatContractLine('window_layout'" modules/cheatsheet.vim
    grep -Fq "ChopsticksKeymapContractLinesOr('core_toggles'" \
        modules/cheatsheet.vim
    grep -Fq "ChopsticksKeymapContractLinesOr('edit_cleanup_summary'" \
        modules/cheatsheet.vim
    grep -Fq "s:CheatContractLine('undo_tree'" modules/cheatsheet.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('markdown_maps'" \
        modules/cheatsheet.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('lint_keymaps'" \
        modules/cheatsheet.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('visible_jump_summary'" \
        modules/cheatsheet.vim
    grep -Fq "s:CheatContractLine('full_file_reindent'" modules/cheatsheet.vim
    grep -Fq "s:ContractPair('clipboard_summary'" modules/cheatsheet.vim
    grep -Fq "s:CheatContractPairLine('line_move_summary'" \
        modules/cheatsheet.vim
    grep -Fq "ChopsticksKeymapContractKeysOr(" modules/cheatsheet.vim
    grep -Fq "'lsp_definition_references'" modules/learning.vim
    grep -Fq "s:ContractKey('lsp_format_normal'" modules/learning.vim
    grep -Fq "function! s:LearningEntrypointInfo" modules/tutor.vim
    grep -Fq "function! s:LearningEntrypointLines" modules/tutor.vim
    grep -Fq "ChopsticksInfoOr('ChopsticksLearningEntrypointInfo'" \
        modules/tutor.vim
    grep -Fq "function! s:VisibleJumpTrainingLine" modules/tutor.vim
    grep -Fq "function! s:VisibleJumpTutorLines" modules/tutor.vim
    grep -Fq "function! s:VisibleJumpInfo" modules/tutor.vim
    grep -Fq "get(s:LearningDailyLoopInfo(), 'visible_jump', {})" \
        modules/tutor.vim
    grep -Fq "function! s:UndoTreeTutorLine" modules/tutor.vim
    grep -Fq "function! s:LspTutorAvailable" modules/tutor.vim
    grep -Fq "function! s:LspTrainingLine" modules/tutor.vim
    grep -Fq "function! s:LspTutorLines" modules/tutor.vim
    grep -Fq "function! ChopsticksLearningRowLines" modules/env.vim
    grep -Fq "function! ChopsticksLearningRowLinesOr" modules/env.vim
    grep -Fq "function! ChopsticksLearningTaskLine" modules/env.vim
    grep -Fq "function! ChopsticksLearningDrillLine" modules/env.vim
    grep -Fq "function! ChopsticksLearningLoopEnabled" modules/env.vim
    grep -Fq "function! ChopsticksLearningKey" modules/env.vim
    grep -Fq "function! ChopsticksLearningInfoRowLinesOr" modules/env.vim
    grep -Fq "ChopsticksLearningInfoRowLinesOr(l:loop, 'tutor_rows'" \
        modules/tutor.vim
    grep -Fq "ChopsticksLearningDrillLine(l:loop" modules/tutor.vim
    grep -Fq "ChopsticksLearningInfoRowLinesOr(l:lsp_loop, 'tutor_rows'" \
        modules/tutor.vim
    grep -Fq "ChopsticksLearningLoopEnabled(l:loop, l:lsp_loop" \
        modules/tutor.vim
    grep -Fq "ChopsticksLearningKey(l:lsp_loop" modules/tutor.vim
    grep -Fq "ChopsticksLearningInfoRowLinesOr(l:loop, 'beta_rows'" \
        modules/beta.vim
    grep -Fq "ChopsticksLearningInfoRowLinesOr(l:lsp_loop, 'beta_rows'" \
        modules/beta.vim
    grep -Fq "ChopsticksLearningLoopEnabled(l:loop, l:lsp_loop" \
        modules/beta.vim
    grep -Fq "ChopsticksLearningTaskLine(l:loop" modules/beta.vim
    grep -Fq "ChopsticksLearningInfoRowLinesOr(l:visible_jump, 'cheat_rows'" \
        modules/cheatsheet.vim
    grep -Fq "ChopsticksLearningInfoRowLinesOr(l:lsp_loop" \
        modules/cheatsheet.vim
    grep -Fq "function! s:DailyLoopTutorLines" modules/tutor.vim
    grep -Fq "function! s:LearningDailyLoopInfo" modules/tutor.vim
    grep -Fq "function! s:LearningLspLoopInfo" modules/tutor.vim
    grep -Fq "ChopsticksInfoOr('ChopsticksLearningDailyLoopInfo'" \
        modules/tutor.vim
    grep -Fq "ChopsticksInfoOr('ChopsticksLearningLspLoopInfo'" \
        modules/tutor.vim
    grep -Fq "call extend(l:lines, s:DailyLoopTutorLines())" \
        modules/tutor.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('visible_jump_summary'" \
        modules/tutor.vim
    grep -Fq "s:ContractKey('undo_tree'" modules/tutor.vim
    if grep -Fq "ChopsticksLspLearningEnabledOr(" \
        modules/tutor.vim modules/beta.vim; then
        echo "Learning consumers must use ChopsticksLearningLoopEnabled()" >&2
        exit 1
    fi
    grep -Fq "'tutor_rows'" modules/tutor.vim
    grep -Fq "s:VisibleJumpPrimaryKey()" modules/tutor.vim
    grep -Fq "s:VisibleJumpTutorLines()" modules/tutor.vim
    grep -Fq "s:LspTutorAvailable()" modules/tutor.vim
    grep -Fq "s:LspTutorLines()" modules/tutor.vim
    grep -Fq "function! s:ProjectBuffersKey" modules/tutor.vim
    grep -Fq "function! s:GitStatusDiffBlame" modules/tutor.vim
    grep -Fq "function! s:WindowNavigationLabel" modules/tutor.vim
    grep -Fq "function! s:LspDefinitionReferencesDocs" modules/tutor.vim
    grep -Fq "s:ContractKey('lsp_definition'" modules/tutor.vim
    grep -Fq "s:ContractKey('lsp_format_normal'" modules/tutor.vim
    grep -Fq "ChopsticksCommandNamesOr('beta'" modules/beta.vim
    grep -Fq "ChopsticksCommandLinesOr('beta'" modules/beta.vim
    grep -Fq "function! s:ContractKey" modules/beta.vim
    grep -Fq "s:ContractKey('learning_entrypoint'" modules/beta.vim
    grep -Fq "function! s:LearningEntrypointInfo" modules/beta.vim
    grep -Fq "ChopsticksInfoOr('ChopsticksLearningEntrypointInfo'" \
        modules/beta.vim
    grep -Fq "function! s:LearningFeedbackLine" modules/beta.vim
    grep -Fq "function! s:LearningConsistencyLine" modules/beta.vim
    grep -Fq "function! s:LearningSessionPrompt" modules/beta.vim
    if grep -Fq "ChopsticksKeymapContractLines('learning_entrypoint'" \
        modules/beta.vim; then
        echo "Beta guide must consume LearningEntrypointInfo for entrypoint rows" >&2
        exit 1
    fi
    grep -Fq "function! s:DailyLoopLines" modules/beta.vim
    grep -Fq "function! s:LearningDailyLoopInfo" modules/beta.vim
    grep -Fq "function! s:LearningLspLoopInfo" modules/beta.vim
    grep -Fq "ChopsticksInfoOr('ChopsticksLearningDailyLoopInfo'" \
        modules/beta.vim
    grep -Fq "ChopsticksInfoOr('ChopsticksLearningLspLoopInfo'" \
        modules/beta.vim
    grep -Fq "s:ContractKey('project_files'" modules/beta.vim
    grep -Fq "ChopsticksKeymapContractKeysOr(" modules/beta.vim
    grep -Fq "'visible_jump_summary'" modules/beta.vim
    grep -Fq "s:ContractKey('project_grep'" modules/beta.vim
    grep -Fq "s:ContractKey('project_run'" modules/beta.vim
    grep -Fq "s:ContractKey('git_status'" modules/beta.vim
    grep -Fq "function! s:LspDailyLoopAvailable" modules/beta.vim
    grep -Fq "'beta_rows'" modules/beta.vim
    grep -Fq "function! s:RecordTaskLine" modules/beta.vim
    grep -Fq "ChopsticksCommandLinesOr('survival'" modules/cheatsheet.vim
    grep -Fq "ChopsticksKeymapContractLinesOr('survival_core'" \
        modules/cheatsheet.vim
    grep -Fq "ChopsticksKeymapContractLinesOr('survival_config'" \
        modules/cheatsheet.vim
    grep -Fq "ChopsticksCommandLinesOr('survival'" modules/tutor.vim
    local command_consumer_modules=(
        modules/beta.vim
        modules/cheatsheet.vim
        modules/status.vim
        modules/tutor.vim
    )
    if grep -Eq 'function! s:(CatalogCommands|CommandLines|StatusHeaderCommand)' \
        "${command_consumer_modules[@]}" || \
        grep -Eq "exists\\(['\"]\\*ChopsticksCommand(Names|Lines|Header)" \
        "${command_consumer_modules[@]}" || \
        grep -Eq 'ChopsticksCommand(Names|Lines|Header)\(' \
        "${command_consumer_modules[@]}"; then
        echo "Command Surface consumers must use ChopsticksCommand...Or()" >&2
        exit 1
    fi
    grep -Fq "ChopsticksMissingCommands(['ChopsticksCheatSheet'])" \
        modules/learning.vim
    grep -Fq "ChopsticksCommandAvailable('ChopsticksHelp')" \
        modules/learning.vim
    grep -Fq "ChopsticksCommandAvailable('ChopsticksHelp')" \
        modules/help.vim
    grep -Fq "ChopsticksMissingCommands(['Files', 'Buffers', 'GFiles', 'Rg', 'RgWord', 'Tags'])" \
        modules/navigation.vim
    grep -Fq "ChopsticksMissingCommands(['ChopsticksConfig', 'ChopsticksReload'])" \
        modules/utilities.vim
    local command_availability_consumers=(
        modules/cheatsheet.vim
        modules/help.vim
        modules/learning.vim
        modules/navigation.vim
        modules/utilities.vim
    )
    if grep -Eq 'function! s:(CommandReady|MissingCommands)' \
        "${command_availability_consumers[@]}" || \
        grep -Eq "exists\\(['\"]:" "${command_availability_consumers[@]}"; then
        echo "Command availability consumers must use ChopsticksCommand...()" >&2
        exit 1
    fi
    grep -Fq "ChopsticksKeymapContractLinesOr('survival_core'" \
        modules/tutor.vim
    grep -Fq "ChopsticksKeymapContractLinesOr('survival_config'" \
        modules/tutor.vim
    local public_command
    while IFS= read -r public_command; do
        grep -Fq "s:PublicCommand('$public_command'" modules/env.vim || {
            echo "Missing $public_command in Command Surface catalog" >&2
            exit 1
        }
    done < <(sed -n 's/.*command! \(Chopsticks[A-Za-z0-9_]*\).*/\1/p' \
        modules/*.vim | sort -u)
    while IFS= read -r public_command; do
        grep -R -q "^command! ${public_command}[[:space:]]" modules || {
            echo "Command Surface catalog points to undefined $public_command" >&2
            exit 1
        }
        grep -Fq ":$public_command" doc/chopsticks.txt || {
            echo "Missing :$public_command in doc/chopsticks.txt" >&2
            exit 1
        }
    done < <(sed -n "s/.*s:PublicCommand('\(Chopsticks[A-Za-z0-9_]*\)'.*/\1/p" \
        modules/env.vim | sort -u)
    for command in ChopsticksBeta ChopsticksBetaLog ChopsticksBetaSession; do
        grep -Fq "command! $command" modules/beta.vim || {
            echo "Missing $command definition in modules/beta.vim" >&2
            exit 1
        }
    done
    for file in README.md doc/chopsticks.txt modules/cheatsheet.vim \
        modules/tutor.vim
    do
        grep -Fq 'ChopsticksDoctor' "$file" || {
            echo "Missing ChopsticksDoctor in $file" >&2
            exit 1
        }
    done
    grep -Fq 'ChopsticksDoctor' modules/env.vim
    for file in README.md doc/chopsticks.txt modules/cheatsheet.vim \
        modules/tutor.vim
    do
        grep -Fq 'ChopsticksKeymapAudit' "$file" || {
            echo "Missing ChopsticksKeymapAudit in $file" >&2
            exit 1
        }
    done
    grep -Fq 'ChopsticksKeymapAudit' modules/env.vim
    grep -Fq "\\ 'info'," .vimrc
    grep -Fq 'function! ChopsticksInfoPath' modules/info.vim
    grep -Fq 'function! ChopsticksInfoShapeIssue' modules/info.vim
    grep -Fq 'function! ChopsticksInfoCall' modules/info.vim
    grep -Fq 'function! ChopsticksInfoSurfaceSpecs' modules/info.vim
    grep -Fq 'function! ChopsticksInfoSurfaceSpec' modules/info.vim
    grep -Fq 'function! ChopsticksInfoSurfaceSpecsFor' modules/info.vim
    grep -Fq 'function! ChopsticksInfoSection' modules/info.vim
    grep -Fq 'function! ChopsticksInfoDetail' modules/info.vim
    grep -Fq 'function! ChopsticksInfoItem' modules/info.vim
    grep -Fq 'function! ChopsticksInfoDiagnosticItem' modules/info.vim
    grep -Fq 'function! ChopsticksInfoItemValue' modules/info.vim
    if grep -Fq 'function! ChopsticksInfoPath' modules/env.vim ||
        grep -Fq 'function! ChopsticksInfoCall' modules/env.vim ||
        grep -Fq 'function! s:InfoSurfaceSpecs' modules/env.vim ||
        grep -Fq 'function! ChopsticksStatusInfoFromSpec' modules/env.vim; then
        echo "Shared info contracts must be owned by modules/info.vim" >&2
        exit 1
    fi
    grep -Fq "return ChopsticksInfoSection('runtime'" modules/env.vim
    grep -Fq "return ChopsticksInfoSection('local preferences'" modules/env.vim
    grep -Fq "return ChopsticksInfoSection('status header'" modules/env.vim
    grep -Fq "return ChopsticksInfoSection('modules'" modules/env.vim
    grep -Fq "return ChopsticksInfoSection('command surface'" modules/env.vim
    grep -Fq "return ChopsticksInfoSection('profile'" modules/env.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/core.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/core.vim
    grep -Fq "return ChopsticksInfoSection('editor core'" modules/core.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/plugins.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/plugins.vim
    grep -Fq "return ChopsticksInfoSection('plugin reproducibility'" modules/plugins.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/lsp.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/lsp.vim
    grep -Fq "return ChopsticksInfoSection('lsp servers'" modules/lsp.vim
    grep -Fq "return ChopsticksInfoSection('completion'" modules/lsp.vim
    grep -Fq 'ChopsticksInfoItem(' modules/tools.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/tools.vim
    grep -Fq 'return ChopsticksInfoSection(a:title' modules/tools.vim
    grep -Fq "return ChopsticksInfoSection('toolchain'" modules/tools.vim
    if grep -Fq "'title': a:title" modules/tools.vim; then
        echo "Toolchain sections must use the Info Shape Contract" >&2
        exit 1
    fi
    grep -Fq 'ChopsticksInfoDetail(' modules/learning.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/learning.vim
    grep -Fq "return ChopsticksInfoSection('learning'" modules/learning.vim
    if grep -Fq "'title': 'editor core'" modules/core.vim ||
        grep -Fq "'title': 'plugin reproducibility'" modules/plugins.vim ||
        grep -Fq "'title': 'lsp servers'" modules/lsp.vim ||
        grep -Fq "'title': 'completion'" modules/lsp.vim ||
        grep -Fq "'title': 'learning'" modules/learning.vim; then
        echo "Core info producers must use the Info Shape Contract" >&2
        exit 1
    fi
    grep -Fq 'ChopsticksInfoDetail(' modules/buffers.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/buffers.vim
    grep -Fq "return ChopsticksInfoSection('buffers'" modules/buffers.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/quickfix.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/quickfix.vim
    grep -Fq "return ChopsticksInfoSection('quickfix'" modules/quickfix.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/files.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/files.vim
    grep -Fq "return ChopsticksInfoSection('file safety'" modules/files.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/runner.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/runner.vim
    grep -Fq "return ChopsticksInfoSection('project run'" modules/runner.vim
    if grep -Fq "'title': 'buffers'" modules/buffers.vim ||
        grep -Fq "'title': 'quickfix'" modules/quickfix.vim ||
        grep -Fq "'title': 'file safety'" modules/files.vim ||
        grep -Fq "'title': 'project run'" modules/runner.vim; then
        echo "Leaf info producers must use the Info Shape Contract" >&2
        exit 1
    fi
    grep -Fq 'ChopsticksInfoDetail(' modules/editing.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/editing.vim
    grep -Fq "return ChopsticksInfoSection('editing'" modules/editing.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/git.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/git.vim
    grep -Fq "return ChopsticksInfoSection('git'" modules/git.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/lint.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/lint.vim
    grep -Fq "return ChopsticksInfoSection('lint'" modules/lint.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/utilities.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/utilities.vim
    grep -Fq "return ChopsticksInfoSection('utilities'" modules/utilities.vim
    if grep -Fq "'title': 'editing'" modules/editing.vim ||
        grep -Fq "'title': 'git'" modules/git.vim ||
        grep -Fq "'title': 'lint'" modules/lint.vim ||
        grep -Fq "'title': 'utilities'" modules/utilities.vim; then
        echo "Daily loop info producers must use the Info Shape Contract" >&2
        exit 1
    fi
    grep -Fq 'ChopsticksInfoDetail(' modules/help.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/help.vim
    grep -Fq "return ChopsticksInfoSection('help surface'" modules/help.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/keymap.vim
    grep -Fq 'ChopsticksInfoItem(' modules/keymap.vim
    grep -Fq "return ChopsticksInfoSection('keymap contract'" modules/keymap.vim
    grep -Fq "return ChopsticksInfoSection('keymap audit'" modules/keymap.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/health.vim
    grep -Fq "return ChopsticksInfoSection('health'" modules/health.vim
    grep -Fq 'return ChopsticksInfoSection(a:title' modules/info.vim
    grep -Fq "function! s:InfoSurfaceSpecs" modules/info.vim
    grep -Fq "'name': 'beta'" modules/info.vim
    grep -Fq "'function': 'ChopsticksBetaInfo'" modules/info.vim
    grep -Fq "'status_enabled_only': 1" modules/info.vim
    grep -Fq "'name': 'toolchain'" modules/info.vim
    grep -Fq "'function': 'ChopsticksToolchainInfo'" modules/info.vim
    grep -Fq "'health_options': {'check_items': 0, 'check_sections': 1}" \
        modules/info.vim
    grep -Fq "'name': 'lsp'" modules/info.vim
    grep -Fq "'function': 'ChopsticksLspInfo'" modules/info.vim
    grep -Fq "'health_function': 's:CheckKeymap'" modules/info.vim
    grep -Fq 'function! ChopsticksStatusInfoFromSpec' modules/info.vim
    grep -Fq 'function! s:StatusInfoFallback' modules/info.vim
    grep -Fq "ChopsticksInfoSection('lsp servers'" modules/status.vim
    grep -Fq "ChopsticksInfoSection('release guide'" modules/status.vim
    grep -Fq "function! s:StatusHeaderHelpKey" modules/status.vim
    grep -Fq "function! s:StatusHeaderFallbackInfo" modules/status.vim
    grep -Fq "function! s:StatusInfoSpec" modules/status.vim
    grep -Fq "function! s:StatusInfoSpecFromSurface" modules/status.vim
    grep -Fq "function! s:StatusInfoFromSpec" modules/status.vim
    grep -Fq "function! s:IncludeStatusInfo" modules/status.vim
    grep -Fq "function! s:StatusInfoRegistry" modules/status.vim
    grep -Fq "ChopsticksInfoSurfaceSpecsFor('status')" modules/status.vim
    grep -Fq "let l:spec.enabled_only = 1" modules/status.vim
    grep -Fq 'Status Section Registry' CONTEXT.md
    grep -Fq 'ChopsticksStatusInfoFromSpec()' CONTEXT.md
    grep -Fq "ChopsticksCommandHeaderOr('help'" \
        modules/status.vim
    grep -Fq "ChopsticksCommandHeaderOr('config'" \
        modules/status.vim
    grep -Fq "ChopsticksInfoOr('ChopsticksLearningEntrypointInfo'" \
        modules/status.vim
    grep -Fq "ChopsticksKeymapContractKeysOr('learning_entrypoint'" \
        modules/status.vim
    grep -Fq "ChopsticksInfoSection('status header'" modules/status.vim
    if grep -Fq ':ChopsticksHelp  :ChopsticksTutor  SPC ?' modules/status.vim; then
        echo "Status header fallback must use LearningEntrypointInfo" >&2
        exit 1
    fi
    if grep -Fq 'function! s:InfoByName' modules/status.vim ||
        grep -Fq 'function! s:CallInfo' modules/status.vim ||
        grep -Fq 'function! s:StatusInfoFallback' modules/status.vim ||
        grep -Fq 'function! s:ToolchainInfo' modules/status.vim ||
        grep -Fq 'function! s:LspInfo' modules/status.vim ||
        grep -Fq 'function! s:BetaInfo' modules/status.vim ||
        grep -Fq "'ChopsticksBetaInfo', 'release guide'" modules/status.vim ||
        grep -Fq "'ChopsticksToolchainInfo', 'toolchain'" modules/status.vim ||
        grep -Fq "'ChopsticksLspInfo', 'lsp servers'" modules/status.vim; then
        echo "Status sections must be loaded through the Status Section Registry" >&2
        exit 1
    fi
    grep -Fq 'ChopsticksInfoDetail(' modules/languages.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/languages.vim
    grep -Fq "return ChopsticksInfoSection('languages'" modules/languages.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/ui.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/ui.vim
    grep -Fq "return ChopsticksInfoSection('ui'" modules/ui.vim
    grep -Fq 'ChopsticksInfoItem(' modules/navigation.vim
    grep -Fq 'ChopsticksInfoDiagnosticItem(' modules/navigation.vim
    grep -Fq "return ChopsticksInfoSection('navigation'" modules/navigation.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/input_method.vim
    grep -Fq 'ChopsticksInfoItem(' modules/input_method.vim
    grep -Fq "return ChopsticksInfoSection('input method'" modules/input_method.vim
    grep -Fq 'ChopsticksInfoDetail(' modules/beta.vim
    grep -Fq "return ChopsticksInfoSection('release guide'" modules/beta.vim
    if grep -Fq "'title': 'help surface'" modules/help.vim ||
        grep -Fq "'title': 'languages'" modules/languages.vim ||
        grep -Fq "'title': 'ui'" modules/ui.vim ||
        grep -Fq "'title': 'navigation'" modules/navigation.vim ||
        grep -Fq "'title': 'input method'" modules/input_method.vim ||
        grep -Fq "'title': 'release guide'" modules/beta.vim; then
        echo "Auxiliary info producers must use the Info Shape Contract" >&2
        exit 1
    fi
    if grep -Fq "'title': 'keymap contract'" modules/keymap.vim ||
        grep -Fq "'title': 'keymap audit'" modules/keymap.vim ||
        grep -Fq "'title': 'health'" modules/health.vim ||
        grep -Fq "'title': a:title" modules/status.vim ||
        grep -Fq "'title': 'lsp servers'" modules/status.vim ||
        grep -Fq "'title': 'release guide'" modules/status.vim ||
        grep -Fq "'title': 'status header'" modules/status.vim; then
        echo "Audit, health, and status fallback info must use the Info Shape Contract" >&2
        exit 1
    fi
    if grep -Fq 'function! s:CoreDetail' modules/core.vim ||
        grep -Fq 'function! s:InfoDetail' modules/env.vim ||
        grep -Fq 'function! s:InfoItem' modules/env.vim ||
        grep -Fq 'function! s:InfoItemValue' modules/env.vim ||
        grep -Fq 'function! s:CoreItem' modules/core.vim ||
        grep -Fq 'function! s:CoreDiagnostic' modules/core.vim ||
        grep -Fq 'function! s:PluginDetail' modules/plugins.vim ||
        grep -Fq 'function! s:PluginItem' modules/plugins.vim ||
        grep -Fq 'function! s:InfoDetail' modules/lsp.vim ||
        grep -Fq 'function! s:CompletionItem' modules/lsp.vim ||
        grep -Fq 'function! s:CompletionDiagnostic' modules/lsp.vim ||
        grep -Fq 'let l:item = {' modules/tools.vim ||
        grep -Fq 'function! s:InfoDetail' modules/cheatsheet.vim ||
        grep -Fq 'function! s:LearningItem' modules/cheatsheet.vim ||
        grep -Fq 'function! s:LearningDiagnostic' modules/cheatsheet.vim ||
        grep -Fq 'function! s:InfoDetail' modules/buffers.vim ||
        grep -Fq 'function! s:InfoItem' modules/buffers.vim ||
        grep -Fq 'function! s:InfoDetail' modules/quickfix.vim ||
        grep -Fq 'function! s:InfoItem' modules/quickfix.vim ||
        grep -Fq 'function! s:InfoDetail' modules/files.vim ||
        grep -Fq 'function! s:InfoItem' modules/files.vim ||
        grep -Fq 'function! s:InfoDetail' modules/runner.vim ||
        grep -Fq 'function! s:InfoItem' modules/runner.vim ||
        grep -Fq 'function! s:InfoDetail' modules/editing.vim ||
        grep -Fq 'function! s:InfoItem' modules/editing.vim ||
        grep -Fq 'function! s:InfoDetail' modules/git.vim ||
        grep -Fq 'function! s:InfoItem' modules/git.vim ||
        grep -Fq 'function! s:InfoDetail' modules/lint.vim ||
        grep -Fq 'function! s:LintItem' modules/lint.vim ||
        grep -Fq 'function! s:LintDiagnostic' modules/lint.vim ||
        grep -Fq 'function! s:InfoDetail' modules/utilities.vim ||
        grep -Fq 'function! s:UtilityItem' modules/utilities.vim ||
        grep -Fq 'function! s:UtilityDiagnostic' modules/utilities.vim ||
        grep -Fq 'function! s:HelpDetail' modules/help.vim ||
        grep -Fq 'function! s:HelpItem' modules/help.vim ||
        grep -Fq 'function! s:HelpDiagnostic' modules/help.vim ||
        grep -Fq 'function! s:InfoDetail' modules/keymap.vim ||
        grep -Fq 'function! s:InfoItem' modules/keymap.vim ||
        grep -Fq 'function! s:InfoDetail' modules/health.vim ||
        grep -Fq 'function! s:LanguageDetail' modules/languages.vim ||
        grep -Fq 'function! s:LanguageItem' modules/languages.vim ||
        grep -Fq 'function! s:LanguageDiagnostic' modules/languages.vim ||
        grep -Fq 'function! s:UiDetail' modules/ui.vim ||
        grep -Fq 'function! s:UiItem' modules/ui.vim ||
        grep -Fq 'function! s:UiDiagnostic' modules/ui.vim ||
        grep -Fq 'function! s:NavigationItem' modules/navigation.vim ||
        grep -Fq 'function! s:InputMethodDetail' modules/input_method.vim ||
        grep -Fq 'function! s:InputMethodItem' modules/input_method.vim ||
        grep -Fq 'function! s:BetaDetail' modules/beta.vim; then
        echo "Migrated info producers must use the Info Row Contract" >&2
        exit 1
    fi
    grep -Fq 'function! ChopsticksStatusInfoFromSpec' modules/info.vim
    grep -Fq 'ChopsticksInfoCall(l:function_name)' modules/info.vim
    grep -Fq "ChopsticksInfoItem(a:label, 'missing', a:reason)" modules/info.vim
    grep -Fq "ChopsticksInfoItem('vim-lsp stack', 'missing'" modules/status.vim
    grep -Fq "ChopsticksInfoDetail('help'" modules/status.vim
    grep -Fq 'function! s:StatusMissingInfo' modules/info.vim
    grep -Fq 'returned invalid status info' modules/info.vim
    grep -Fq "l:status ==# 'thrown'" modules/info.vim
    grep -Fq "'status': 'thrown'" modules/info.vim
    grep -Fq '() failed: ' modules/info.vim
    if grep -Fq 'function! s:NormalizeInfo' modules/status.vim ||
        grep -Fq 'function! s:CallInfo' modules/status.vim ||
        grep -Fq 'function! s:StatusInfoFailure' modules/status.vim ||
        grep -Fq 'ChopsticksInfoShapeIssue(a:info, a:source)' modules/status.vim ||
        grep -Fq 'call(a:name' modules/status.vim; then
        echo "Status info loading must use ChopsticksInfoCall()" >&2
        exit 1
    fi
    if grep -Fq "{'label': a:label" modules/status.vim ||
        grep -Fq "{'label': 'vim-lsp stack'" modules/status.vim ||
        grep -Fq "{'label': 'help'" modules/status.vim; then
        echo "Status fallback rows must use the Info Row Contract" >&2
        exit 1
    fi
    grep -Fq 'function! s:CheckInfoInterface' modules/health.vim
    grep -Fq 'function! s:KnownSeverity' modules/health.vim
    grep -Fq 'function! s:Severity' modules/health.vim
    grep -Fq 'function! s:DiagnosticSeverity' modules/health.vim
    grep -Fq 'function! s:OrderedIssues' modules/health.vim
    grep -Fq 'function! s:CheckRequiredItemInterface' modules/health.vim
    grep -Fq 'function! s:CheckDiagnosticSections' modules/health.vim
    grep -Fq 'function! s:AddInfoShapeIssue' modules/health.vim
    grep -Fq 'ChopsticksInfoCall(a:function_name)' modules/health.vim
    grep -Fq 'function! s:HealthCheckRegistry' modules/health.vim
    grep -Fq 'function! s:RequiredItemHealthCheck' modules/health.vim
    grep -Fq 'function! s:RunHealthCheck' modules/health.vim
    grep -Fq 'function! s:RunHealthChecks' modules/health.vim
    grep -Fq 'function! s:HealthCheckFromSurface' modules/health.vim
    grep -Fq "s:RequiredItemHealthCheck(" modules/health.vim
    grep -Fq "ChopsticksInfoSurfaceSpecsFor('health')" modules/health.vim
    grep -Fq "get(a:surface, 'health_function', '')" modules/health.vim
    grep -Fq "get(a:check, 'kind', 'function') ==# 'required-items'" \
        modules/health.vim
    grep -Fq "get(a:check, 'options', {})" modules/health.vim
    grep -Fq 'call s:RunHealthChecks(l:issues)' modules/health.vim
    grep -Fq 'Health Check Registry' CONTEXT.md
    grep -Fq '**Info Interface Loader**' CONTEXT.md
    grep -Fq 'Navigation Items**, **Toolchain Sections**, **LSP Items**' \
        CONTEXT.md
    if grep -Fq 'function! s:CheckInfoShape' modules/health.vim ||
        grep -Fq 'call(a:function_name' modules/health.vim ||
        grep -Fq "'runtime', 'ChopsticksRuntimeInfo'" modules/health.vim ||
        grep -Fq "'toolchain', 'ChopsticksToolchainInfo'" modules/health.vim ||
        grep -Fq "'lsp', 'ChopsticksLspInfo'" modules/health.vim ||
        grep -Fq "'input-method', 'ChopsticksInputMethodInfo'" modules/health.vim; then
        echo "Health info loading must use ChopsticksInfoCall()" >&2
        exit 1
    fi
    if grep -Fq 'function! s:ValidateInfoShape' modules/status.vim ||
        grep -Fq 'function! s:CheckInfoListField' modules/health.vim ||
        grep -Fq 'function! s:CheckInfoListEntries' modules/health.vim; then
        echo "Info shape validation must use ChopsticksInfoShapeIssue()" >&2
        exit 1
    fi
    if grep -Fq 'call s:CheckRuntime(l:issues)' modules/health.vim ||
        grep -Fq 'call s:CheckInputMethod(l:issues)' modules/health.vim ||
        grep -Fq 'call s:CheckToolchain(l:issues)' modules/health.vim ||
        grep -Fq 'call s:CheckNavigation(l:issues)' modules/health.vim ||
        grep -Fq 'call s:CheckLsp(l:issues)' modules/health.vim; then
        echo "ChopsticksHealthInfo() must run checks through the Health Check Registry" >&2
        exit 1
    fi
    if grep -Fq 'function! s:CheckRuntime' modules/health.vim ||
        grep -Fq 'function! s:CheckCore' modules/health.vim ||
        grep -Fq 'function! s:CheckHelp' modules/health.vim ||
        grep -Fq 'function! s:CheckRunner' modules/health.vim ||
        grep -Fq 'function! s:CheckNavigation' modules/health.vim ||
        grep -Fq 'function! s:CheckToolchain' modules/health.vim ||
        grep -Fq 'function! s:CheckLsp' modules/health.vim ||
        grep -Fq 'function! s:CheckInputMethod' modules/health.vim; then
        echo "Regular health checks must be required-items registry specs" >&2
        exit 1
    fi
    grep -Fq 's:CheckRequiredItemInterface(a:issues,' modules/health.vim
    grep -Fq "'ChopsticksCoreInfo'" modules/info.vim
    grep -Fq "{'check_items': 0, 'check_sections': 1}" modules/info.vim
    grep -Fq "l:status ==# 'thrown'" modules/health.vim
    grep -Fq "fix ' . a:function_name . '() and reload chopsticks" \
        modules/health.vim
    grep -Fq 'returned invalid diagnostic info' modules/health.vim
    grep -Fq 'return a Dictionary from ' modules/health.vim
    grep -Fq "s:Severity(get(l:issue, 'severity', 'info'), 'info')" \
        modules/health.vim
    grep -Fq 'let l:issues = s:OrderedIssues(l:issues)' modules/health.vim
    grep -Fq ' is not a List' modules/info.vim
    grep -Fq 'return a List from ' modules/info.vim
    grep -Fq ' is not a Dictionary' modules/info.vim
    grep -Fq 'return Dictionary entries from ' modules/info.vim
    grep -Fq ' is not a String' modules/info.vim
    grep -Fq 'return String entries from ' modules/info.vim
    grep -Fq 'returned no diagnostic items' modules/health.vim
    grep -Fq 'return an items list from ' modules/health.vim
    grep -Fq 'ChopsticksLspInfo() returned no diagnostic items' \
        scripts/test-vim.sh
    if grep -Fq "let l:runtime = get(l:result" modules/health.vim; then
        echo "Runtime health must use the shared Health Issue Adapter" >&2
        exit 1
    fi
    if grep -Fq "let l:config = get(l:result" modules/health.vim; then
        echo "Local config health must use the shared Health Issue Adapter" >&2
        exit 1
    fi
    if grep -Fq "let l:modules = get(l:result" modules/health.vim; then
        echo "Module health must use the shared Health Issue Adapter" >&2
        exit 1
    fi
    if grep -Fq "let l:profile = get(l:result" modules/health.vim; then
        echo "Profile health must use the shared Health Issue Adapter" >&2
        exit 1
    fi
    if grep -Fq "let l:plugins = get(l:result" modules/health.vim; then
        echo "Plugin health must use the shared Health Issue Adapter" >&2
        exit 1
    fi
    if grep -Fq "for l:command in get(l:commands, 'missing', [])" \
        modules/health.vim; then
        echo "Command health must use the shared Health Issue Adapter" >&2
        exit 1
    fi
    grep -Fq 'command! ChopsticksKeymapAudit' modules/keymap.vim

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
    grep -q 'Optional tools: disabled' "$TMP_ROOT/install-dry-run.txt"
    test ! -e "$TMP_ROOT/dry/chopsticks.vim"

    ./install.sh --help > "$TMP_ROOT/install-help.txt"
    grep -q -- '--install-tools' "$TMP_ROOT/install-help.txt"

    XDG_CONFIG_HOME="$TMP_ROOT/dry-tools" ./install.sh --dry-run \
        --profile=full --install-tools | tee "$TMP_ROOT/install-dry-run-tools.txt"
    grep -q 'Optional tools: enabled (--install-tools)' \
        "$TMP_ROOT/install-dry-run-tools.txt"
    test ! -e "$TMP_ROOT/dry-tools/chopsticks.vim"

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
            check_vim_only_runtime
            check_docs
            check_release_notes
            check_installer_modes
            check_bootstrap
            ;;
        shell) check_shell ;;
        vim-only) check_vim_only_runtime ;;
        docs)
            check_docs
            check_release_notes
            ;;
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
