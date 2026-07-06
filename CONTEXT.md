# Chopsticks

Chopsticks is a personal Vim dotfile kit that turns plain Vim into one trained
project loop for navigation, grep, git, running files, diagnostics, and key
help. It exists to stay portable across local terminals and SSH sessions while
remaining small enough for one person to understand and maintain.

## Language

**Chopsticks**:
The managed Vim configuration shipped by this repository.
_Avoid_: Vim distro, Neovim config, plugin bundle

**Runtime Core**:
The Vimscript loaded from `.vimrc` and `modules/*.vim` during Vim startup.
_Avoid_: Neovim runtime, Lua layer

**Runtime Gate**:
The startup and `ChopsticksRuntimeInfo()` checks that require Vim 8.2/9.x and
reject Neovim before loading the rest of **Chopsticks**.
_Avoid_: best-effort compatibility note

**Runtime Gate Item**:
A state-bearing entry and detail rows returned by `ChopsticksRuntimeInfo()` for
editor version, session, terminal capability, Vim compatibility, and required
Vim feature readiness, with diagnostic severity/action metadata for
**Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` knowing runtime compatibility or feature
branching rules

**Runtime Capability Adapter**:
The shared `ChopsticksRuntimeFeatureSpec()` and
`ChopsticksRuntimeFeatureAvailable()` functions that normalize Vim feature and
platform checks for required and optional runtime capabilities such as terminal,
job, timers, popup, clipboard, persistent undo, Unix, and macOS.
_Avoid_: each **Chopsticks Module** calling `has('clipboard')`,
`has('terminal')`, `has('timers')`, `has('persistent_undo')`, or platform
feature checks directly

**Remote Session**:
An SSH-launched Vim detected from `SSH_CONNECTION`, `SSH_CLIENT`, or `SSH_TTY`
and surfaced by `ChopsticksRuntimeInfo()`.
_Avoid_: local terminal with a remote-looking `$TERM`

**Chopsticks Module**:
A Vimscript file under `modules/` that owns one user-facing concern.
_Avoid_: component, misc script

**Module Load**:
The `.vimrc` manifest and `ChopsticksModuleInfo()` interface that record which
**Chopsticks Modules** exist on disk, were declared, loaded, missed, duplicated,
or failed during startup.
_Avoid_: unobservable source order

**Module Load Item**:
A state-bearing entry and detail rows returned by `ChopsticksModuleInfo()` for
module inventory and module load readiness, with diagnostic severity/action
metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` knowing manifest/load branching rules

**Editor Core**:
The baseline Vim options, survival maps, centered search/scroll behavior,
persistence defaults, timing defaults, autocmd hygiene, and project-local
config policy owned by `modules/core.vim` and surfaced by
`ChopsticksCoreInfo()`.
_Avoid_: invisible startup defaults or misc keymaps hidden from health checks

**Editor Core Item**:
A state-bearing entry and detail rows returned by `ChopsticksCoreInfo()` for
editor defaults, survival maps, search motion, core toggles, persistence,
performance, autocmd hygiene, and project-local config state, with diagnostic
severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus`, **Chopsticks Doctor**, or **Keymap Audit**
reconstructing core option, timing, persistence, autocmd, or exrc policy

**Command Surface**:
The user-facing `:Chopsticks...` commands and the `ChopsticksCommandInfo()`
interface that compares the declared command catalog with Vim-defined commands
after startup.
_Avoid_: undocumented command drift

**Command Surface Item**:
A state-bearing entry and detail rows returned by `ChopsticksCommandInfo()` for
public command availability and uncataloged command drift, with diagnostic
severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` knowing command verification branching rules

**Command Owner Group**:
A named ownership subset of **Command Surface** returned by
`ChopsticksCommandNames()` for modules that need command readiness or compact
command rows by owning concern.
_Avoid_: filtering the command catalog or rewriting owner command lists in
callers

**Command Header**:
A compact, display-ready command row returned by `ChopsticksCommandHeader()` for
status header groups such as `help` and `config`.
_Avoid_: `:ChopsticksStatus` or local preference rows owning header command
lists

**Command Display Group**:
A named, display-ready subset of **Command Surface** returned by
`ChopsticksCommandLines()` for shared in-editor command lists such as survival
commands in the **Learning Surface** and release-candidate commands in the
beta guide.
_Avoid_: hand-maintained `:Chopsticks...` command rows in each learning view

**Command Surface Adapter**:
The shared fallback-aware `ChopsticksCommandNamesOr()`,
`ChopsticksCommandHeaderOr()`, and `ChopsticksCommandLinesOr()` functions that
hide late-load `exists()` checks and fallback copying for modules consuming
**Command Owner Groups**, **Command Headers**, and **Command Display Groups**.
_Avoid_: each **Chopsticks Module** defining command catalog, command line, or
status-header fallback wrappers

**Command Availability Adapter**:
The shared `ChopsticksCommandAvailable()` and `ChopsticksMissingCommands()`
functions that hide Vim command existence checks and missing-command display
formatting.
_Avoid_: each **Chopsticks Module** calling `exists(':Command')` or rebuilding
colon-prefixed missing command lists

**Profile**:
A named feature envelope that selects plugin and behavior defaults.
_Avoid_: mode, flavor

**Profile Resolution**:
The `ChopsticksProfileInfo()` interface that records requested profile/keymap
values, validates them, and reports the resolved safe values used by the
runtime.
_Avoid_: silent fallback

**Profile Resolution Item**:
A state-bearing entry and detail rows returned by `ChopsticksProfileInfo()` for
resolved profile, keymap, runtime envelope, feature groups, opt-ins, Markdown
mode, invalid requested values, and plugin pinning policy, with diagnostic
severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` knowing profile/keymap fallback or feature-label
branching rules

**Local Preferences**:
The user-owned config loaded from `${XDG_CONFIG_HOME:-~/.config}/chopsticks.vim`.
_Avoid_: editing managed .vimrc

**Local Preference Load**:
The `ChopsticksLocalConfigInfo()` interface that records the local preference
path, source, load state, and source errors without preventing the **Runtime
Core** from opening.
_Avoid_: unreported vimrc startup failure

**Local Preference Load Item**:
A state-bearing entry and detail rows returned by `ChopsticksLocalConfigInfo()`
for local preference path, source, commands, load state, and source errors,
with diagnostic severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` knowing local preference load branching rules

**Managed File Adapter**:
The shared `ChopsticksEnsureDir()`, `ChopsticksEnsureParentDir()`,
`ChopsticksEnsureManagedFile()`, `ChopsticksAppendManagedFile()`, and
`ChopsticksOpenManagedFile()` functions that hide local directory creation,
seed-file writes, append writes, escaped `:edit`, filetype setup, and new-buffer
template seeding for Chopsticks-owned local files.
_Avoid_: each **Chopsticks Module** manually combining `fnamemodify()`,
`isdirectory()`, `mkdir()`, `filereadable()`, `writefile()`, `fnameescape()`,
`:edit`, and `setlocal filetype`

**Scratch Surface Adapter**:
The shared `ChopsticksOpenScratchBuffer()` function that hides nofile scratch
buffer toggle/refresh policy, split and size setup, read-only line population,
scratch-local options, and buffer-local close/help maps for Chopsticks-owned
in-editor views.
_Avoid_: each **Chopsticks Module** manually combining `bufwinnr()`, `:new`,
`:resize`, `buftype=nofile`, `bufhidden=wipe`, `nobuflisted`, `noswapfile`,
read-only flags, and buffer-local close mappings

**Display Adapter**:
The shared `ChopsticksDisplayKeyLine()` and `ChopsticksStatusDisplay()`
functions that hide fixed-column key/label row formatting and
**Info Row Contract** to `:ChopsticksStatus` scratch-view rendering.
_Avoid_: each **Chopsticks Module** manually combining `printf('%-...')`,
status detail/state/section formatting, recursive info-section walking, footer
collection, and ready/missing/optional summary counts

**Learning Display Adapter**:
The shared `ChopsticksLearningRowLines()`,
`ChopsticksLearningRowLinesOr()`, `ChopsticksLearningTaskLine()`, and
`ChopsticksLearningDrillLine()` functions that turn **Learning Surface** row,
task, and drill models into cheat-sheet, tutor, and release-guide display
lines.
_Avoid_: cheat sheet, tutor, and beta guide each manually looping over
`{'key', 'label'}` rows, preserving preformatted learning lines, applying
custom row gaps, joining task lists, or formatting daily-drill steps

**Learning Model Adapter**:
The shared `ChopsticksLearningLoopEnabled()`, `ChopsticksLearningKey()`, and
`ChopsticksLearningInfoRowLinesOr()` functions that turn **Learning Surface**
info dictionaries into fallback-safe LSP learning readiness, key summaries, and
row-field display lines for learning views.
_Avoid_: tutor, cheat sheet, and beta guide each repeating `has_key()` enabled
checks, nested `keys` dictionary reads, or `get(info, '..._rows', [])` fallback
branches

**Utility Actions**:
The config/reload, managed vimrc edit, path-copy, classic save-all, and opt-in
sudo-save workflow owned by `modules/utilities.vim` and surfaced by
`ChopsticksUtilityInfo()`.
_Avoid_: catch-all ownership of navigation, editing, window layout, or plugin
policy

**Utility Action Item**:
A state-bearing entry and detail rows returned by `ChopsticksUtilityInfo()` for
config/reload maps, managed vimrc editing, path-copy clipboard capability,
classic save-all, and sudo-save opt-in state, with diagnostic severity/action
metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` or **Chopsticks Doctor** knowing utility-map,
clipboard, or sudo-save branching rules

**Buffer Lifecycle**:
The listed-buffer, alternate-buffer, close-buffer, and buffer navigation
workflow owned by `modules/buffers.vim` and surfaced by
`ChopsticksBufferInfo()`.
_Avoid_: scattered `:bdelete`, `:bnext`, and alternate-file mappings

**Buffer Lifecycle Item**:
A state-bearing entry and detail rows returned by `ChopsticksBufferInfo()` for
safe buffer close, buffer navigation maps, alternate-buffer switching, current
listed-buffer count, and current/alternate buffer context, with diagnostic
severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` or **Chopsticks Doctor** knowing buffer-map and
delete-safety branching rules

**Editing Assist**:
The visible-jump, undo-history, blank-line insertion, cleanup, substitution,
and indentation workflow owned by `modules/editing.vim` and surfaced by
`ChopsticksEditingInfo()`.
_Avoid_: misc editing maps hidden inside a catch-all utility module

**Editing Assist Item**:
A state-bearing entry and detail rows returned by `ChopsticksEditingInfo()` for
visible jump readiness, undo tree availability, cleanup/substitution/indent
maps, blank-line insertion maps, and full-file reindent opt-in state, with
diagnostic severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus`, **Chopsticks Doctor**, or utilities knowing
editing-map branching rules

**File Safety**:
The automatic write-directory creation and large-file protection workflow owned
by `modules/files.vim` and surfaced by `ChopsticksFileSafetyInfo()`.
_Avoid_: invisible autocmd-only file handling

**File Safety Item**:
A state-bearing entry and detail rows returned by `ChopsticksFileSafetyInfo()`
for write-directory guard, large-file thresholds, TTY large-file threshold, and
current-buffer protection state, with diagnostic severity/action metadata for
**Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` or **Chopsticks Doctor** knowing file autocmd and
large-file branching rules

**Quickfix Loop**:
The built-in Vim quickfix and location-list workflow owned by
`modules/quickfix.vim` and surfaced by `ChopsticksQuickfixInfo()`.
_Avoid_: invisible quickfix autocmds and undocumented navigation maps

**Quickfix Item**:
A state-bearing entry and detail rows returned by `ChopsticksQuickfixInfo()`
for quickfix auto-window, location-list auto-window, quickfix navigation maps,
and current quickfix/location-list entry counts, with diagnostic
severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` or **Chopsticks Doctor** knowing quickfix autocmd
and navigation-map branching rules

**Space Layout**:
The default QWERTY keymap where `Space` is the command leader and comma stays
available as localleader.
_Avoid_: Neovim-style leader layout

**Classic Layout**:
The legacy comma-led keymap kept for users who trained earlier chopsticks
versions.
_Avoid_: old mode

**Ergonomic Contract**:
The rule set that preserves native Vim habits, SSH safety, and intentionally
unbound dangerous operations.
_Avoid_: shortcut list

**Keymap Contract Spec**:
A state-free map expectation returned by `ChopsticksKeymapContractSpecs()` for
the active **Space Layout** or **Classic Layout**, including required maps,
forbidden maps, leader invariants, opt-in map branches, attach-time scope
metadata, and optional display group metadata.
_Avoid_: hand-maintained audit-only key lists

**Keymap Readiness Adapter**:
The shared `ChopsticksKeymapSpecIssue()`, `ChopsticksKeymapSpecReady()`, and
`ChopsticksKeymapMissingKeys()` functions that evaluate map, forbidden-map,
leader, and auto-pairs **Keymap Contract Specs** for **Keymap Audit** and
`Chopsticks...Info()` producers.
_Avoid_: each **Chopsticks Module** defining its own `maparg()` readiness
rules or missing-key collector

**Keymap Contract Adapter**:
The shared fallback-aware `ChopsticksKeymapContractSpecsOr()`,
`ChopsticksKeymapContractFirstSpecOr()`,
`ChopsticksKeymapContractKeysOr()`, and
`ChopsticksKeymapContractLinesOr()` functions that hide late-load `exists()`
checks and fallback copying for modules consuming **Keymap Contract Groups**
and **Keymap Display Groups**.
_Avoid_: each **Chopsticks Module** defining `s:ContractSpecs`,
`s:ContractKeys`, `s:FirstContractSpec`, or local keymap line fallback
wrappers

**Keymap Contract Group**:
A named subset of **Keymap Contract Specs** returned by
`ChopsticksKeymapContractSpecsFor()` and `ChopsticksKeymapContractKeys()` for
modules that need to verify or summarize map readiness by concern.
_Avoid_: each module rebuilding keymap specs for its own status rows

**Keymap Display Group**:
A named, display-ready subset of **Keymap Contract Specs** returned by
`ChopsticksKeymapContractLines()` for shared learning rows such as survival
keymaps.
_Avoid_: hand-maintained survival key rows in each learning view

**Keymap Audit**:
The `:ChopsticksKeymapAudit` command that verifies the active keymap against
the **Keymap Contract Spec** for the **Ergonomic Contract**.
_Avoid_: documentation-only checklist

**Keymap Audit Item**:
A state-bearing entry and detail rows returned by `ChopsticksKeymapAuditInfo()`
for active layout, audit command, pass/fail state, issue count, and diagnostic
severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` counting keymap issues or formatting audit state

**Learning Surface**:
The active cheat sheet, guided tutor, native Vim help, and release-candidate
guide entry points owned by `modules/learning.vim` and surfaced by
`ChopsticksLearningInfo()` so a user can recover the daily loop from inside
Vim.
_Avoid_: private wiki, README-only onboarding, or scattered help availability
checks

**Learning Surface Item**:
A state-bearing entry and detail rows returned by `ChopsticksLearningInfo()`
for active cheat sheet map readiness, tutor command readiness, native help doc
readiness, and release guide command readiness, with diagnostic severity/action
metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` or **Chopsticks Doctor** knowing cheat sheet,
tutor, helptag, or beta-guide branching rules

**Help Surface**:
The native Vim help entrypoint, managed help document, and helptag generation
owned by `modules/help.vim` and surfaced by `ChopsticksHelpInfo()`.
_Avoid_: README-only reference docs or scattered checks for `doc/chopsticks.txt`

**Help Surface Item**:
A state-bearing entry and detail rows returned by `ChopsticksHelpInfo()` for
the `:ChopsticksHelp` command, `doc/chopsticks.txt`, and generated Vim help
tags, with diagnostic severity/action metadata for **Chopsticks Doctor**.
_Avoid_: **Learning Surface**, `:ChopsticksStatus`, or **Chopsticks Doctor**
guessing native help document paths or helptag readiness

**Git Loop**:
The status, diff, blame, commit, log, gutter, and conflict-marker workflow owned
by `modules/git.vim` and surfaced by `ChopsticksGitInfo()`.
_Avoid_: scattered Fugitive mappings with no setup state

**Git Loop Item**:
A state-bearing entry and detail rows returned by `ChopsticksGitInfo()` for
the Git command, Fugitive, GitGutter, Git keymaps, conflict navigation, and
current repository context, with diagnostic severity/action metadata for
**Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` or **Chopsticks Doctor** knowing Git plugin and
keymap branching rules

**Project Run**:
The current-buffer run-file workflow owned by `modules/runner.vim` and surfaced
by `ChopsticksRunnerInfo()`.
_Avoid_: hidden keymap-only runner logic

**Project Run Item**:
A state-bearing entry and detail rows returned by `ChopsticksRunnerInfo()` for
the active filetype, run keymap, supported runner catalog, and executable
readiness, with diagnostic severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` or **Chopsticks Doctor** knowing filetype runner
branching rules

**Chopsticks Doctor**:
The `:ChopsticksDoctor` command and `ChopsticksHealthInfo()` interface that
turn runtime, editor core, plugin, tool, LSP, navigation, and input-method
checks into an actionable issue list.
_Avoid_: ad hoc troubleshooting notes

**Health Diagnostic Item**:
A `diagnostic` item returned by an owning `Chopsticks...Info()` interface,
carrying severity, issue label, detail, and action metadata for
**Chopsticks Doctor**.
_Avoid_: **Chopsticks Doctor** reinterpreting module-specific fields

**Info Row Contract**:
The shared `ChopsticksInfoDetail()`, `ChopsticksInfoItem()`, and
`ChopsticksInfoDiagnosticItem()` constructors used by
`Chopsticks...Info()` producers to build detail rows, state-bearing items, and
**Health Diagnostic Items** with one field layout.
_Avoid_: each Module hand-building the same `label`/`state`/`reason` and
diagnostic metadata dictionaries

**Health Severity**:
One of `attention`, `setup`, `optional`, or `info`, used by
**Chopsticks Doctor** to order issues and compute **Health Summary** rows.
_Avoid_: ad hoc severity strings that disappear from the summary line

**Health Issue Adapter**:
The internal **Chopsticks Doctor** implementation that converts
**Health Diagnostic Items** into **Health Issue Codes** and display-ready
issues through one shared `Chopsticks...Info()` loader for modules whose
interfaces return state-bearing `items`.
_Avoid_: repeated item-to-issue glue in each health check

**Health Check Registry**:
The script-local registry in `modules/health.vim` that declares the ordered
health check specs run by `ChopsticksHealthInfo()`, including regular
`required-items` checks and custom check adapters.
_Avoid_: long hand-coded check call chains or one-function wrappers around
`s:CheckRequiredItemInterface()`

**Info Shape Contract**:
The shared `ChopsticksInfoSection()` constructor and
`ChopsticksInfoShapeIssue()` validation for every `Chopsticks...Info()`
Dictionary, requiring `details`, `items`, `notes`, `sections`, and `footers`
containers to be Lists, requiring row and section entries to be Dictionaries,
requiring `notes` and `footers` entries to be Strings, and applying the same
rule recursively to nested `sections`.
_Avoid_: separate malformed-info rules in `:ChopsticksStatus` and
**Chopsticks Doctor**

**Info Interface Loader**:
The shared `ChopsticksInfoCall()` function that calls a `Chopsticks...Info()`
interface and classifies missing functions, thrown exceptions, invalid return
types, malformed **Info Shape Contract** output, and ready info dictionaries.
_Avoid_: `:ChopsticksStatus` and **Chopsticks Doctor** each implementing their
own `exists()`/`call()`/`try`/shape-validation loader

**Info Fallback Adapter**:
The shared `ChopsticksInfoOr()` and `ChopsticksLspLearningEnabledOr()`
functions that turn late-loaded `Chopsticks...Info()` producers and LSP learning
readiness into fallback-safe values for learning views.
_Avoid_: **Learning Surface** consumers repeating `exists('*Chopsticks...')`
branches or reimplementing LSP learning availability fallback

**Health Issue Code**:
A stable `[domain.label]` identifier attached to each **Chopsticks Doctor**
issue so tests, docs, and troubleshooting notes can reference a problem without
depending on display wording.
_Avoid_: prose-only error message

**Health Issue Order**:
The severity-first ordering used by `ChopsticksHealthInfo().issues` and
`:ChopsticksDoctor`: `attention`, `setup`, `optional`, then `info`, while
preserving module order inside each severity.
_Avoid_: issue lists where low-priority info hides urgent setup problems

**Health Summary**:
The severity-ordered counts returned by `ChopsticksHealthInfo()` for
`attention`, `setup`, `optional`, and `info` diagnostics.
_Avoid_: duplicated status-line severity formatting

**Health Summary Item**:
Detail rows returned by `ChopsticksHealthInfo()` for doctor state, the
display-ready severity summary, and the `:ChopsticksDoctor` command.
_Avoid_: `:ChopsticksStatus` reconstructing doctor state or command rows

**Plugin Lock**:
A verified plugin commit used by vim-plug so the same **Profile** resolves to
the same plugin code over time.
_Avoid_: latest plugin version

**Plugin State Adapter**:
The shared `ChopsticksPluginSpec()`, `ChopsticksPluginDeclared()`,
`ChopsticksPluginDir()`, and `ChopsticksPluginInstalled()` functions that hide
the `g:plugs` dictionary shape and plugin directory checks for modules that
need plugin declaration or install state.
_Avoid_: each **Chopsticks Module** reading `g:plugs`, `dir`, or
`isdirectory()` directly

**Plugin Reproducibility Item**:
A state-bearing entry and detail rows returned by `ChopsticksPluginInfo()` for
plugin lock coverage, applied pins, and installed plugin directories, with
diagnostic severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` knowing plugin lock/pin/install branching rules

**Visual Surface**:
The colorscheme, truecolor policy, statusline, tabline, layout-stability
settings, and start screen owned by `modules/ui.vim` and surfaced by
`ChopsticksUiInfo()`.
_Avoid_: hidden presentation setup spread across runtime, profile, and plugin
policy

**Visual Surface Item**:
A state-bearing entry and detail rows returned by `ChopsticksUiInfo()` for
color palette readiness, rich terminal truecolor, statusline/tabline readiness,
stable sign/fill layout, and start-screen profile state, with diagnostic
severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` or **Chopsticks Doctor** knowing colorscheme,
TTY fallback, statusline, tabline, or Startify branching rules

**Language Surface**:
The Vim-side Markdown writing defaults, Markdown preview/maps, vim-go
syntax-only policy, and per-filetype indentation defaults owned by
`modules/languages.vim` and surfaced by `ChopsticksLanguageInfo()`.
_Avoid_: mixing Vim language editing defaults with LSP server installation,
ALE lint/format policy, or external tool availability

**Language Surface Item**:
A state-bearing entry and detail rows returned by `ChopsticksLanguageInfo()`
for Markdown syntax readiness, Markdown writing defaults, Markdown maps,
Markdown preview, vim-go syntax-only state, and filetype autocmd readiness,
with diagnostic severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus`, **Chopsticks Doctor**, or **Keymap Audit**
knowing Markdown buffer defaults, preview branching, vim-go intelligence
disablement, or filetype autocmd policy

**Lint Loop**:
The ALE-backed lint, error navigation, detail view, format-on-save toggle, and
Markdown lint/format policy owned by `modules/lint.vim` and surfaced by
`ChopsticksLintInfo()`.
_Avoid_: treating external formatter availability as the same concern as Vim's
ALE adapter state

**Lint Loop Item**:
A state-bearing entry and detail rows returned by `ChopsticksLintInfo()` for
ALE stack readiness, lint keymaps, format-on-save state, and Markdown lint
policy, with diagnostic severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` or **Chopsticks Doctor** knowing ALE map,
format-on-save, or Markdown quiet-default branching rules

**Completion Loop**:
The asyncomplete-backed popup menu, vim-lsp completion source, auto-popup
behavior, and opt-in insert-mode completion keymaps owned by `modules/lsp.vim`
and surfaced by `ChopsticksCompletionInfo()`.
_Avoid_: treating completion ergonomics as hidden LSP setup or generic keymap
policy

**Completion Loop Item**:
A state-bearing entry and detail rows returned by `ChopsticksCompletionInfo()`
for completion plugin readiness, vim-lsp source readiness, popup menu settings,
auto-popup behavior, and completion keymaps, with diagnostic severity/action
metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus`, **Chopsticks Doctor**, or **Keymap Audit**
reconstructing completion plugin, popup, or auto-pairs interaction policy

**Optional Tool**:
An external CLI that can improve formatting, LSP, grep, preview, or integration
but is not required for the **Runtime Core** to load.
_Avoid_: runtime dependency

**Tool Availability Adapter**:
The shared `ChopsticksToolAvailable()`, `ChopsticksMissingTools()`,
`ChopsticksToolState()`, and `ChopsticksToolOffState()` functions that hide
external command availability checks and the common enabled/off/ready/missing
tool-state shape.
_Avoid_: each **Chopsticks Module** calling `executable()` directly or
rebuilding **Toolchain Item** state dictionaries

**Toolchain Item**:
A state-bearing entry returned by `ChopsticksToolchainInfo()` for a required,
optional, missing, ready, or explicitly disabled external tool, with diagnostic
severity/action metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` guessing tool policy from global variables

**Toolchain Section**:
A display-ready group returned by `ChopsticksToolchainInfo()` for project
tools, optional language runtimes, linters, or formatters, with setup/optional
diagnostic severity metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` owning tool grouping or format-on-save wording

**LSP Item**:
A state-bearing entry returned by `ChopsticksLspInfo()` for the vim-lsp stack
or a filetype language server, with install action and diagnostic severity
metadata for **Chopsticks Doctor**.
_Avoid_: `:ChopsticksStatus` knowing LSP stack/server branching rules

**LSP Section**:
The display-ready title, install suffix, state-bearing rows, and usage notes
returned by `ChopsticksLspInfo()`.
_Avoid_: `:ChopsticksStatus` owning LSP installation prompts or attach-time
guidance

**LSP Attach Keymap**:
The buffer-local vim-lsp action maps installed after `User lsp_buffer_enabled`,
represented as `lsp_buffer` **Keymap Contract Specs** and consumed by
`modules/lsp.vim` and learning surfaces.
_Avoid_: hard-coded LSP key rows that can drift from attached buffer maps

**Project Search**:
The FZF-backed file, buffer, grep, word-grep, and tag navigation workflow owned
by `modules/navigation.vim` and backed by the `fzf`, `fzf.vim`, and `rg`
adapters.
High-frequency file and grep entry points are exposed through narrower
**Keymap Contract Groups** while **Project Search** remains the broad status
summary.
_Avoid_: undocumented FZF maps scattered across navigation docs

**Project Search Item**:
A state-bearing entry returned by `ChopsticksNavigationInfo()` for FZF command,
external tool, and project-search map readiness, with diagnostic
severity/action metadata for **Chopsticks Doctor** when search setup is broken.
_Avoid_: `:ChopsticksStatus` or **Chopsticks Doctor** knowing FZF/rg keymap
branching rules

**File Sidebar**:
The netrw sidebar workflow owned by `modules/navigation.vim`, using built-in Vim
file browsing instead of a Neovim tree plugin.
_Avoid_: Neovim-only file tree dependencies

**File Sidebar Item**:
A state-bearing entry returned by `ChopsticksNavigationInfo()` for netrw command
and sidebar map readiness, with diagnostic severity/action metadata for
**Chopsticks Doctor** when sidebar entry points are broken.
_Avoid_: `:ChopsticksStatus` knowing netrw or sidebar key choices

**Window Layout**:
The split maximize and resize workflow owned by `modules/navigation.vim`, where
space layout keeps only `SPC z` and classic layout keeps `,z`, `,=`, and `,-`.
_Avoid_: `modules/utilities.vim` owning window-layout maps

**Window Layout Item**:
A state-bearing entry returned by `ChopsticksNavigationInfo()` for maximize and
resize map readiness, with diagnostic severity/action metadata for
**Chopsticks Doctor** when the window layout contract is broken.
_Avoid_: `:ChopsticksStatus` knowing maximize/resize key choices

**Navigation Item**:
A state-bearing entry returned by `ChopsticksNavigationInfo()` for window
movement, **Project Search**, **File Sidebar**, **Window Layout**, terminal, or
tmux navigation readiness, with diagnostic severity/action metadata for
**Chopsticks Doctor** when a navigation path is broken.
_Avoid_: `:ChopsticksStatus` knowing terminal/tmux branching rules

**Input Method Item**:
A state-bearing entry and detail rows returned by `ChopsticksInputMethodInfo()`
for optional input-source switching readiness, with diagnostic severity/action
metadata for **Chopsticks Doctor** when the opt-in switch is unavailable or
disabled by SSH policy.
_Avoid_: `:ChopsticksStatus` knowing SSH/input-source branching rules

**Release Candidate Item**:
Detail rows returned by `ChopsticksBetaInfo()` for beta label, active keymap,
local release log path, release-candidate commands, and active cheat sheet key
guidance.
_Avoid_: `:ChopsticksStatus` calculating beta log paths or owning beta command
lists

**Status Footer**:
A display-ready next-step line returned by an owning `Chopsticks...Info()`
interface for the end of `:ChopsticksStatus`.
_Avoid_: `:ChopsticksStatus` owning install or remediation prompts

**Status Info Adapter**:
The shared `ChopsticksStatusInfoFromSpec()` adapter in `modules/env.vim` that
calls each `Chopsticks...Info()` interface from a **Status Section Registry**
spec, turning missing, thrown, invalid-type, or malformed status info into a
fallback **Status Section** or rendered missing row.
_Avoid_: one broken Module preventing the daily status surface from opening

**Status Section Registry**:
The script-local registry in `modules/status.vim` that declares ordered status
section specs, fallback info, and optional visibility rules for
`:ChopsticksStatus`.
_Avoid_: long hand-coded `s:InfoByName()` lists or one-function status wrappers
around `s:CallInfo()`

**Status Section**:
A display-ready title plus detail rows, state-bearing rows, and notes returned
by an owning `Chopsticks...Info()` interface and rendered by
`:ChopsticksStatus`, including nested `sections` rendered recursively.
_Avoid_: one-off `:ChopsticksStatus` wrappers for every module

**Status Header**:
The display-ready help, config path, and command rows returned by
`ChopsticksStatusHeaderInfo()` for the top of `:ChopsticksStatus`, with
public command rows derived from the **Command Surface** catalog and the active
help key derived from **Keymap Contract Groups**.
_Avoid_: `:ChopsticksStatus` owning header command lists or keymap-specific
help hints

**TTY Mode**:
The reduced-capability path used when Vim runs in a terminal, slow SSH session,
or environment without GUI assumptions.
_Avoid_: degraded editor

## Relationships

- **Chopsticks** loads the **Runtime Core** from one `.vimrc` and many
  **Chopsticks Modules**.
- The **Runtime Gate** rejects unsupported editors before the **Runtime Core**
  continues loading.
- **Runtime Gate Items** keep editor version, session, terminal capability, Vim
  compatibility, and required feature policy in `ChopsticksRuntimeInfo()` so
  `:ChopsticksStatus` only formats state-bearing rows and details while
  **Chopsticks Doctor** reports runtime issues from the same item interface.
- The **Runtime Capability Adapter** keeps Vim feature and platform capability
  checks in `modules/env.vim`, so **Editor Core**, **Utility Actions**,
  **Keymap Audit**, **Learning Surface**, **Navigation Items**,
  **Completion Loop**, **Visual Surface**, **Language Surface**, and **Input
  Method Items** do not each know how to call `has()` for clipboard, terminal,
  timers, popup, persistence, Unix, or macOS policy.
- **Module Load** makes module inventory, ordering, and source errors visible
  through **Chopsticks Doctor** and `:ChopsticksStatus`.
- **Module Load Items** keep manifest inventory and module load policy in
  `ChopsticksModuleInfo()` so `:ChopsticksStatus` only formats state-bearing
  rows and details while **Chopsticks Doctor** reports module issues from the
  same item interface.
- The **Command Surface** is checked after **Module Load** so discoverability
  failures become diagnostics instead of stale docs.
- **Command Surface Items** keep public command availability policy in
  `ChopsticksCommandInfo()` and compare that catalog with Vim-defined
  `:Chopsticks...` commands, so `:ChopsticksStatus` only formats
  state-bearing rows and details while **Chopsticks Doctor** reports missing or
  uncataloged command issues from the same item interface.
- The **Command Surface Adapter** keeps fallback-aware command names, header
  rows, and display rows in `modules/env.vim`, so **Learning Surface**,
  **Runtime Status**, and release-candidate views do not each implement
  late-load command catalog checks or fallback copying.
- The **Command Availability Adapter** keeps Vim command existence checks and
  colon-prefixed missing command lists in `modules/env.vim`, so **Learning
  Surface**, **Buffer Lifecycle**, **Git Loop**, **Project Search**, **File
  Sidebar**, **Window Layout**, **Lint Loop**, **Completion Loop**, **Visual
  Surface**, **Utility Actions**, and **Help Surface** do not each know how to
  call `exists(':Command')` or format missing command names.
- A **Remote Session** is runtime context, so SSH-sensitive **Chopsticks
  Modules** consume `ChopsticksRuntimeInfo()` instead of each parsing the
  environment independently.
- A **Profile** selects plugin and behavior defaults; **Local Preferences**
  override those defaults without editing managed files.
- **Profile Resolution** makes invalid **Local Preferences** visible while
  falling back to safe defaults.
- **Profile Resolution Items** keep resolved profile, keymap, runtime envelope,
  feature group, opt-in, Markdown, and invalid-request policy in
  `ChopsticksProfileInfo()` so `:ChopsticksStatus` only formats state-bearing
  rows and details, while **Chopsticks Doctor** reports invalid profile/keymap
  values and plugin pinning info from the same item interface.
- **Local Preference Load** makes source errors in **Local Preferences** visible
  through **Chopsticks Doctor** and `:ChopsticksStatus`.
- **Local Preference Load Items** keep local preference path, source, command,
  and source-error policy in `ChopsticksLocalConfigInfo()` so
  `:ChopsticksStatus` only formats state-bearing rows and details, while
  **Chopsticks Doctor** reports local preference source errors from the same
  item interface.
- The **Managed File Adapter** keeps directory creation, seed-file writes,
  append writes, escaped editing, filetype setup, and buffer-template seeding in
  `modules/env.vim`, so **Local Preferences**, **Release Candidate Items**,
  **Editor Core**, and **File Safety** do not each assemble local-file
  side-effect policy from low-level Vim file functions.
- The **Scratch Surface Adapter** keeps nofile scratch buffer toggle/refresh
  behavior, split sizing, scratch-local options, read-only population, and
  buffer-local close/help maps in `modules/env.vim`, so **Learning Surface**,
  **Runtime Status**, **Chopsticks Doctor**, and **Keymap Audit** do not each
  assemble temporary-buffer UI policy from low-level window and buffer
  commands.
- The **Display Adapter** keeps fixed-column key/label rows and
  `:ChopsticksStatus` **Info Row Contract** rendering in `modules/env.vim`, so
  **Learning Surface**, **Command Display Groups**, **Keymap Display Groups**,
  **Runtime Status**, **Chopsticks Doctor**, and **Keymap Audit** do not each
  own ad hoc display row spacing or status summary counting.
- The **Learning Display Adapter** keeps **Learning Surface** row conversion,
  task-list formatting, and daily-drill formatting in `modules/env.vim`, so
  cheat sheet, tutor, and beta guide consume the same row model instead of each
  rebuilding `{'key', 'label'}` loops, custom `gap` handling, and task/drill
  joins.
- The **Learning Model Adapter** keeps **Learning Surface** consumer fallback
  rules in `modules/env.vim`, so cheat sheet, tutor, and beta guide do not each
  reimplement LSP learning readiness precedence, nested LSP key lookup, or
  row-field fallback rendering.
- **Editor Core** consumes **Keymap Contract Groups** for survival, core
  toggle, clipboard, and line-move map readiness, so F-key/spell, system
  clipboard, and Alt-line-move drift is caught by the same executable
  **Ergonomic Contract** as the rest of the trained layout.
- **Utility Actions** keep config/reload, managed vimrc edit, path-copy,
  classic save-all, and sudo-save policy in `modules/utilities.vim` without
  absorbing navigation or editing workflow ownership.
- **Utility Action Items** keep config/reload maps, path-copy clipboard
  capability, classic save-all, and sudo-save opt-in policy in
  `ChopsticksUtilityInfo()` so `:ChopsticksStatus` only renders rows and
  **Chopsticks Doctor** reports utility setup from the same item interface.
- **Utility Actions** consume **Keymap Contract Groups** for config and
  path-copy map readiness, so utility status rows do not rebuild keymap specs
  already owned by the executable **Ergonomic Contract**.
- **Buffer Lifecycle** keeps close/delete safety, previous/next navigation, and
  alternate-buffer switching in `modules/buffers.vim` instead of spreading
  buffer workflow policy through core settings or docs.
- **Buffer Lifecycle Items** keep `:Bclose`, `:Balternate`, buffer navigation
  map readiness, and current buffer context in `ChopsticksBufferInfo()` so
  `:ChopsticksStatus` only renders rows and **Chopsticks Doctor** reports
  buffer lifecycle issues from the same item interface.
- **Buffer Lifecycle** consumes **Keymap Contract Groups** for close,
  navigation, and alternate-buffer map readiness, so buffer status rows do not
  rebuild keymap specs already owned by the executable **Ergonomic Contract**.
- **Editing Assist** keeps visible jump, undo history, blank-line insertion,
  whitespace cleanup, substitution, and indentation maps in
  `modules/editing.vim` instead of spreading editing workflow policy through a
  catch-all utility module.
- **Editing Assist Items** keep editing plugin readiness, cleanup maps, and
  full-file reindent opt-in policy in `ChopsticksEditingInfo()` so
  `:ChopsticksStatus` only renders rows and **Chopsticks Doctor** reports
  editing assist issues from the same item interface.
- **Editing Assist** consumes **Keymap Contract Groups** for visible jump,
  undo tree, cleanup, blank-line insertion, and full-file reindent map
  readiness, so editing status rows do not rebuild keymap specs already owned
  by the executable **Ergonomic Contract**.
- **File Safety** keeps automatic write-directory creation and large-file
  protection visible without requiring maintainers to inspect autocmd bodies.
- **File Safety Items** keep write guard, large-file threshold, TTY threshold,
  and current-buffer protection policy in `ChopsticksFileSafetyInfo()` so
  `:ChopsticksStatus` only renders rows and **Chopsticks Doctor** reports file
  safety issues from the same item interface.
- **Quickfix Loop** keeps Vim's built-in quickfix and location-list flow useful
  without depending on GUI-only panels or external engines.
- **Quickfix Items** keep quickfix auto-window, location-list auto-window, and
  quickfix navigation policy in `ChopsticksQuickfixInfo()` so
  `:ChopsticksStatus` only renders rows and **Chopsticks Doctor** reports
  quickfix setup issues from the same item interface.
- **Quickfix Loop** consumes **Keymap Contract Groups** for `[q`/`]q`
  navigation map readiness, so quickfix status rows do not rebuild keymap specs
  already owned by the executable **Ergonomic Contract**.
- **Space Layout** and **Classic Layout** both satisfy the same
  **Ergonomic Contract**.
- **Keymap Contract Specs** keep required maps, forbidden maps, leader
  invariants, and opt-in branches in `ChopsticksKeymapContractSpecs()` so the
  **Ergonomic Contract** is queryable instead of living only inside audit
  control flow.
- The **Keymap Readiness Adapter** keeps map, forbidden-map, leader, and
  auto-pairs readiness semantics in one shared interface, so **Keymap Audit**
  and `Chopsticks...Info()` producers do not each implement their own
  `maparg()` checks.
- The **Keymap Contract Adapter** keeps fallback-aware spec, key, and line
  access in `modules/env.vim`, so **Editor Core**, **Utility Actions**,
  **Buffer Lifecycle**, **Editing Assist**, **Quickfix Loop**,
  **Learning Surface**, **Git Loop**, **Project Search**, **File Sidebar**,
  **Window Layout**, **Project Run**, **Lint Loop**, **Language Surface**, and
  **Completion Loop** do not each implement late-load keymap checks or
  fallback copying.
- **Keymap Contract Groups** keep map readiness specs and compact key lists in
  `ChopsticksKeymapContractSpecsFor()` and `ChopsticksKeymapContractKeys()` so
  **Editor Core**, **Utility Actions**, **Buffer Lifecycle**,
  **Editing Assist**, **Quickfix Loop**, **Learning Surface**, **Git Loop**,
  **Project Search**, **File Sidebar**, **Window Layout**, **Project Run**,
  **Lint Loop**, **Language Surface**, and **Completion Loop** can report map
  readiness from the same **Ergonomic Contract** checked by **Keymap Audit**.
- **Keymap Display Groups** keep shared keymap learning rows in
  `ChopsticksKeymapContractLines()` so the **Learning Surface** does not
  hand-maintain survival key rows separately from the executable
  **Ergonomic Contract**.
- **Keymap Audit** is the executable check for the active
  **Keymap Contract Spec**.
- **Keymap Audit Items** keep active layout, audit command, pass/fail state,
  and issue-count policy in `ChopsticksKeymapAuditInfo()` so
  `:ChopsticksStatus` only renders the returned **Status Section** while
  **Chopsticks Doctor** reports ergonomic contract issues from the same item
  interface.
- **Learning Surface** keeps cheat sheet, tutor, native help, and release-guide
  readiness visible from inside Vim so onboarding and memory recovery do not
  depend on external notes.
- **Learning Surface Items** keep active cheat sheet map readiness, tutor
  command readiness, native help doc readiness, and release guide command
  readiness in `ChopsticksLearningInfo()` in `modules/learning.vim` so
  `:ChopsticksStatus` only renders rows and **Chopsticks Doctor** reports
  learning entrypoint issues from the same item interface.
- `modules/learning.vim` owns **Learning Surface** producer interfaces, while
  cheat sheet, tutor, and beta guide remain consumer views for those models.
- **Learning Surface** consumes **Command Surface** owner groups for tutor and
  release-guide command readiness so command ownership stays local to
  `ChopsticksCommandInfo()`.
- **Learning Surface** consumes **Keymap Contract Groups** for active cheat
  sheet entrypoint readiness, so `SPC ?` and `,?` status rows do not rebuild
  keymap specs already owned by the executable **Ergonomic Contract**.
- **Learning Surface** exposes `ChopsticksLearningEntrypointInfo()` for the
  active cheat sheet key, cheat-sheet title, global open map, buffer-local
  close map, tutor display row, beta-guide display row, and beta session
  recovery prompt so cheat sheet, beta, and tutor do not rebuild the
  stuck-recovery entrypoint.
- **Runtime Status** consumes `ChopsticksLearningEntrypointInfo()` for the
  status-header help key and `:ChopsticksStatus` header fallback when that
  interface is loaded, while keeping a keymap contract fallback for env-only
  smoke tests.
- **Runtime Status** consumes **Command Header** rows for status-header help and
  config commands so status fallbacks do not maintain their own public command
  lists.
- **Learning Surface** consumes **Command Display Groups** for shared survival
  command rows and **Keymap Display Groups** for shared survival key rows in
  the cheat sheet and tutor so public command wording stays local to the
  **Command Surface** and keymap wording stays local to the
  **Keymap Contract Spec**.
- **Learning Surface** consumes **Keymap Contract Groups** for daily-loop and
  **Editing Assist** rows in the cheat sheet, tutor, and beta guide so learning
  views do not keep a second key table for visible jump or undo-history maps.
- **Learning Surface** exposes `ChopsticksLearningDailyLoopInfo()` for the
  shared daily-loop summary, visible-jump learning rows, tutor trained-loop
  rows, tutor drill steps, beta-guide key rows, and beta-guide task list so
  cheat sheet, tutor, and beta guide do not each rebuild the trained loop.
- **Learning Surface** exposes `ChopsticksLearningLspLoopInfo()` for shared
  LSP learning key summaries, active cheat-sheet rows, and code-loop rows so
  tutor, beta guide, and cheat sheet do not each rebuild LSP key groups or
  profile-aware row visibility.
- **Learning Surface** consumes the `ChopsticksLspLearningEnabled()` interface
  before rendering tutor code-loop rows and beta-guide daily-loop rows so
  profiles with LSP disabled keep the same daily project loop without teaching
  buffer-local LSP maps that cannot attach.
- **Help Surface** keeps native Vim help command, document, and helptag policy
  in `ChopsticksHelpInfo()` so **Learning Surface** can consume help readiness
  instead of reconstructing help paths.
- **Help Surface Items** keep `:ChopsticksHelp`, `doc/chopsticks.txt`, and
  helptag readiness in `ChopsticksHelpInfo()` so `:ChopsticksStatus` only
  renders rows and **Chopsticks Doctor** reports help setup from the same item
  interface.
- **Git Loop** is part of the trained project loop, but Fugitive, GitGutter,
  Git keymaps, and conflict navigation readiness live in `ChopsticksGitInfo()`.
- **Git Loop Items** keep Git command, plugin command, keymap, and conflict
  navigation policy in `ChopsticksGitInfo()` so `:ChopsticksStatus` only
  renders rows and **Chopsticks Doctor** reports Git setup issues from the same
  item interface.
- **Git Loop** consumes **Keymap Contract Groups** for Fugitive map readiness,
  status/log summaries, and conflict-marker navigation, so Git status rows do
  not rebuild keymap specs already owned by the executable
  **Ergonomic Contract**.
- **Project Run** is part of the trained project loop, but its executable
  policy lives in the runner module rather than the keymap or status renderer.
- **Project Run Items** keep run-file keymap, current filetype, supported
  runner catalog, and executable readiness in `ChopsticksRunnerInfo()` so
  `:ChopsticksStatus` only renders rows and **Chopsticks Doctor** reports
  missing runner commands from the same item interface.
- **Project Run** consumes **Keymap Contract Groups** for run-file map
  readiness and key summaries, so runner status rows do not rebuild keymap
  specs already owned by the executable **Ergonomic Contract**.
- **Chopsticks Doctor** is the executable health report for setup and runtime
  problems across **Chopsticks Modules**.
- **Health Diagnostic Items** let each owning `Chopsticks...Info()` interface
  describe health problems once; `:ChopsticksStatus` ignores diagnostic
  metadata while **Chopsticks Doctor** consumes it.
- The **Info Row Contract** keeps repeated detail, state item, and
  **Health Diagnostic Item** dictionary construction in `modules/env.vim`, so
  new **Chopsticks Modules** can return standard `Chopsticks...Info()` rows
  without copying field layouts or default diagnostic metadata.
- The **Info Shape Contract** keeps top-level and nested
  `Chopsticks...Info()` section construction in `modules/env.vim`, so new
  **Chopsticks Modules** can expose titles, details, items, footers, and nested
  sections without copying section field layout.
- The **Info Interface Loader** keeps missing function, thrown exception,
  invalid type, malformed shape, and successful `Chopsticks...Info()` call
  classification in `modules/env.vim`, so **Status Info Adapter** and
  **Health Issue Adapter** do not each implement their own call path.
- The **Info Fallback Adapter** gives **Learning Surface** consumers a single
  fallback-safe way to consume **Learning Surface**, **Help Surface**,
  **release candidate**, and LSP learning info, so the active cheat sheet,
  guided tutor, release-candidate guide, and status header do not each know
  late-load `exists()` or LSP stack fallback rules.
- The **Health Issue Adapter** keeps diagnostic-to-issue conversion inside
  `ChopsticksHealthInfo()` so new **Chopsticks Modules** do not duplicate
  issue-building policy. A **Chopsticks Module** with a normal
  `Chopsticks...Info()` item interface should use the shared adapter; only
  modules with extra ordering or grouping semantics keep custom health logic.
- The **Health Issue Adapter** consumes **Info Shape Contract** failures and
  turns them into actionable **Chopsticks Doctor** issues, so malformed
  `Chopsticks...Info()` output is reported through the same issue pipeline as
  runtime and setup problems.
- The **Health Check Registry** keeps the **Chopsticks Doctor** check order and
  check adapter list in one place, so adding a new regular
  **Chopsticks Module** health check is a single `required-items` registry row
  rather than a new wrapper function plus an aggregation edit.
- **Runtime Gate**, **Local Preference Load**, **Module Load**, **Command
  Surface**, **Profile Resolution**, **Plugin Reproducibility**,
  **Navigation Items**, **Toolchain Sections**, **LSP Items**, and **Input
  Method Items** health checks consume their own diagnostic rows through the
  **Health Issue Adapter**; legacy side fields such as `remote`, `missing`,
  `profile_valid`, `missing_locks`, `terminal_adapter`, `project`, `stack`, or
  `available` are diagnostic context, not alternate health interfaces.
- Standard **Health Diagnostic Item** interfaces must return a Dictionary with
  an `items` list, while section-oriented interfaces declare recursive
  `sections` consumption through the **Health Check Registry**; **Chopsticks
  Doctor** reports thrown errors, invalid return shapes, malformed
  `details`/`items`/`notes`/`sections`/`footers` containers, malformed
  row/section entries, malformed note/footer entries, nested section shape
  errors, and missing item or section lists instead of silently dropping their
  health signal.
- **Health Severity** values are normalized through the **Health Issue
  Adapter** so invalid severity metadata still lands in the visible summary
  order instead of creating hidden summary buckets.
- **Health Issue Codes** make **Chopsticks Doctor** output stable enough for
  tests, release notes, and personal troubleshooting notes.
- **Health Issue Order** makes the issue list match **Health Summary** severity
  priority so actionable problems appear before informational diagnostics.
- **Health Summary** gives `:ChopsticksStatus` and **Chopsticks Doctor** one
  shared severity order and display-ready count line.
- **Health Summary Items** keep doctor state, summary line, and command display
  policy in `ChopsticksHealthInfo()` so `:ChopsticksStatus` only renders the
  returned **Status Section**.
- **Plugin Locks** make a **Profile** reproducible until a maintainer
  deliberately tests and relocks plugin updates.
- The **Plugin State Adapter** keeps vim-plug declaration, plugin directory,
  and installed-directory checks in `modules/env.vim`, so **Editing Assist**,
  **Git Loop**, **Language Surface**, **Completion Loop**, **Visual Surface**,
  **Learning Surface**, and **Keymap Audit** do not each know the `g:plugs`
  dictionary shape.
- **Plugin Reproducibility Items** keep lock coverage, applied pins, and
  installed plugin directory policy in `ChopsticksPluginInfo()` so
  `:ChopsticksStatus` only formats state-bearing rows and details, while
  **Chopsticks Doctor** reports plugin reproducibility from the same item
  interface.
- **Visual Surface** keeps colorscheme, truecolor, statusline, tabline,
  layout-stability, and start-screen policy in `modules/ui.vim`, including
  explicit TTY fallbacks for SSH-safe use.
- **Visual Surface Items** keep UI readiness in `ChopsticksUiInfo()` so
  `:ChopsticksStatus` only renders rows and **Chopsticks Doctor** reports
  visual setup from the same item interface.
- **Language Surface** keeps Vim-side Markdown writing defaults, Markdown
  preview/maps, vim-go syntax-only policy, and filetype indentation defaults
  in `modules/languages.vim`, separate from LSP, ALE, and external tool
  setup.
- **Language Surface Items** keep language editing readiness in
  `ChopsticksLanguageInfo()` so `:ChopsticksStatus` only renders rows and
  **Chopsticks Doctor** reports language-surface setup from the same item
  interface.
- **Language Surface** consumes **Keymap Contract Groups** for Markdown table of
  contents and preview map readiness, so Markdown status rows do not rebuild
  keymap specs already owned by the executable **Ergonomic Contract**.
- **Lint Loop** keeps ALE adapter readiness, lint navigation maps,
  format-on-save state, and Markdown quiet-default policy in `modules/lint.vim`
  instead of mixing those concerns into external tool checks.
- **Lint Loop Items** keep ALE stack, keymap, format-on-save, and Markdown
  lint policy in `ChopsticksLintInfo()` so `:ChopsticksStatus` only renders
  rows and **Chopsticks Doctor** reports lint setup from the same item
  interface.
- **Lint Loop** consumes **Keymap Contract Groups** for ALE navigation, detail,
  and format-toggle map readiness, so lint status rows do not rebuild keymap
  specs already owned by the executable **Ergonomic Contract**.
- **Completion Loop** keeps asyncomplete readiness, vim-lsp completion source,
  popup-menu settings, auto-popup behavior, and insert-mode keymap policy in
  `modules/lsp.vim` without making callers know plugin globals or map wrappers.
- **Completion Loop Items** keep completion plugin, source, popup, auto-popup,
  and keymap state in `ChopsticksCompletionInfo()` so `:ChopsticksStatus` only
  renders rows and **Chopsticks Doctor** reports completion setup from the same
  item interface.
- **Completion Loop** consumes **Keymap Contract Groups** for opt-in
  insert-mode completion key readiness, so completion status rows do not
  rebuild keymap specs already owned by the executable **Ergonomic Contract**.
- **Optional Tools** may be installed by `install.sh --install-tools`, but the
  **Runtime Core** must still load when they are absent.
- The **Tool Availability Adapter** keeps external command availability and
  common ready/missing/off state construction in `modules/env.vim`, so
  **Editor Core**, **Project Search**, **Git Loop**, **Project Run**,
  **Input Method**, **Language Surface**, and **Toolchain Sections** do not
  each know how to call `executable()` or rebuild the same tool state shape.
- **Toolchain Items** keep external tool policy in `ChopsticksToolchainInfo()`
  so `:ChopsticksStatus` only formats tool state while **Chopsticks Doctor**
  reports enabled missing tools from the same item interface.
- **Toolchain Sections** keep tool grouping and format-on-save display policy
  in `ChopsticksToolchainInfo()` so `:ChopsticksStatus` only renders returned
  **Status Sections** and **Chopsticks Doctor** reports missing tools from the
  same section/item interface.
- **Toolchain Sections** are consumed through the **Health Issue Adapter**, so
  section severity remains local to `ChopsticksToolchainInfo()` instead of
  being reconstructed inside **Chopsticks Doctor**.
- **LSP Items** keep vim-lsp stack and language-server policy in
  `ChopsticksLspInfo()` so `:ChopsticksStatus` only formats state-bearing
  rows and **Chopsticks Doctor** reports LSP setup from the same item
  interface.
- **LSP Items** are consumed through the **Health Issue Adapter**; stack-first
  behavior stays local to `ChopsticksLspInfo()` by marking server diagnostics
  inactive when the vim-lsp stack itself is missing.
- **LSP Sections** keep the LSP section title, install suffix, and attach-time
  guidance in `ChopsticksLspInfo()` so `:ChopsticksStatus` only renders the
  returned section metadata, rows, and notes.
- **Project Search** keeps FZF, ripgrep, file, buffer, grep, word-grep, and tag
  readiness in `modules/navigation.vim` so the project-motion loop is verified
  through one navigation interface.
- **Project Search Items** keep search command, external tool, and map readiness
  in `ChopsticksNavigationInfo()` so `:ChopsticksStatus` only formats rows and
  **Chopsticks Doctor** reports broken search setup from the same item
  interface.
- **Project Search** consumes **Keymap Contract Groups** for search map
  readiness and compact key summaries, so project-search status rows do not
  rebuild keymap specs already owned by the executable **Ergonomic Contract**.
- **File Sidebar** keeps netrw sidebar policy in `modules/navigation.vim` so
  Chopsticks stays Vim-only without depending on a Neovim tree plugin.
- **File Sidebar Items** keep sidebar command and key readiness in
  `ChopsticksNavigationInfo()` so `:ChopsticksStatus` only formats rows and
  **Chopsticks Doctor** reports broken sidebar setup from the same item
  interface.
- **File Sidebar** consumes **Keymap Contract Groups** for sidebar map
  readiness and compact key summaries, so netrw status rows stay aligned with
  the executable **Ergonomic Contract**.
- **Window Layout** keeps maximize and resize map ownership in
  `modules/navigation.vim` so `modules/utilities.vim` remains limited to
  config/reload, path-copy, classic save-all, and opt-in sudo-save helpers.
- **Window Layout Items** keep layout key readiness in
  `ChopsticksNavigationInfo()` so `:ChopsticksStatus` only formats
  state-bearing rows and **Chopsticks Doctor** reports broken layout maps from
  the same item interface.
- **Window Layout** consumes **Keymap Contract Groups** for maximize/resize map
  readiness and compact key summaries, so layout status rows stay aligned with
  the executable **Ergonomic Contract**.
- **Navigation Items** keep window, terminal, and tmux readiness policy in
  `ChopsticksNavigationInfo()` so `:ChopsticksStatus` only formats
  state-bearing rows and **Chopsticks Doctor** reports navigation setup from
  the same item interface.
- **Input Method Items** keep input-source command, SSH disablement, buffer
  eligibility, and status-detail policy in `ChopsticksInputMethodInfo()` so
  `:ChopsticksStatus` only formats state-bearing rows and details, while
  **Chopsticks Doctor** reports input-method setup from the same item
  interface.
- **Release Candidate Items** keep beta label, keymap, release-log path, and
  release-candidate command display in `ChopsticksBetaInfo()`, consuming the
  **Command Surface** beta owner group and **Keymap Contract Groups** for active
  cheat sheet guidance so `:ChopsticksStatus` only renders detail rows.
- The beta guide consumes the **Command Display Group** for beta commands and
  **Keymap Contract Groups** for daily-loop file, visible-jump, grep, run, Git
  status, **LSP Attach Keymap**, and active cheat sheet guidance, so
  `:ChopsticksBeta` does not hand-maintain release-candidate command rows or
  Space/classic key wording.
- **LSP Attach Keymap** keeps attach-time buffer maps in
  **Keymap Contract Specs** with `lsp_buffer` scope, so `modules/lsp.vim`,
  the beta guide, and tests consume one source for LSP action keys without
  making startup `:ChopsticksKeymapAudit` fail before a server attaches.
- **Learning Surface** consumes **LSP Attach Keymap** contract groups for cheat
  sheet and tutor LSP rows, so guided learning stays aligned with the actual
  buffer-local maps installed by vim-lsp.
- **Learning Surface** consumes **Keymap Contract Groups** for daily-loop
  **Project Search**, file pickers, buffer switch and close actions,
  **Git Loop**, **File Sidebar**, **Window Layout**, **Quickfix Loop**, and
  terminal entry rows in the cheat sheet and tutor, so the trained project loop
  does not hand-maintain key facts separately from **Keymap Audit**.
- **Learning Surface** consumes **Keymap Contract Groups** for **Editing
  Assist**, **Lint Loop**, and **Language Surface** rows in the cheat sheet, so
  cleanup, visible-jump, undo, lint, and Markdown key guidance stays aligned
  with the same executable **Ergonomic Contract** checked by **Keymap Audit**.
- **Status Footers** keep install and remediation prompts in the owning
  interface, such as `ChopsticksToolchainInfo()` or `ChopsticksLspInfo()`, so
  `:ChopsticksStatus` only renders footer lines after summary counts.
- **Status Info Adapter** keeps `:ChopsticksStatus` open when a
  `Chopsticks...Info()` interface is missing, throws, returns a non-Dictionary,
  or returns malformed fields rejected by the **Info Shape Contract**, by
  returning the registry fallback **Status Section** or a rendered missing row
  for that Module instead of crashing the whole status window.
- The **Status Section Registry** keeps the `:ChopsticksStatus` section order,
  fallback **Status Section** data, and optional release-candidate visibility
  in one place, so adding or moving a status section is a registry row rather
  than a new wrapper function plus an aggregation edit.
- **Status Sections** keep section titles and rows in the owning interface so
  `:ChopsticksStatus` can render single-section and multi-section
  `Chopsticks...Info()` dictionaries through one shared recursive section
  renderer.
- `:ChopsticksStatus` derives ready, missing, and optional totals from returned
  **Status Section** items instead of parsing rendered output lines.
- **Status Header** keeps top-level help, config, and command rows in
  `ChopsticksStatusHeaderInfo()` and consumes **Command Surface** header
  groups plus **Keymap Contract Groups** for the active cheat sheet key, so
  `:ChopsticksStatus` only renders header details.
- **TTY Mode** keeps **Chopsticks** usable over SSH by disabling or softening
  features that assume a rich local terminal.

## Example Dialogue

> **Dev:** "Can I add a Neovim branch for a plugin that needs `stdpath()`?"
> **Maintainer:** "No. The **Runtime Core** is Vim-only; add a Vim adapter or
> leave the plugin out."
>
> **Dev:** "Can the installer add every formatter by default?"
> **Maintainer:** "No. Formatters are **Optional Tools** and need
> `--install-tools`; a clean install should manage config and pinned plugins
> without taking over the machine."
>
> **Dev:** "Can I bind Git push to `SPC gp`?"
> **Maintainer:** "No. That violates the **Ergonomic Contract**; use an
> explicit command instead."

## Flagged Ambiguities

- "Vim-only" means Vim 8.2/9.x only. It excludes Neovim-only branches, Lua
  runtime code, `stdpath()`, and Neovim plugin dependencies.
- "No Node.js in the runtime" does not ban npm-installed **Optional Tools**.
  It bans Node-backed editor engines from the **Runtime Core**.
- "IDE" means one trained project loop inside Vim. It does not mean a GUI,
  LSP-only workflow, or replacement for Vim's editing language.
- "Install" can mean config/plugin setup or system tool installation. System
  tool installation is explicit and requires `--install-tools`.
