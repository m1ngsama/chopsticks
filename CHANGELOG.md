# Changelog

## Unreleased

### Added

- `~/.config/chopsticks.vim` local pre-load config for profile and user choices
- `g:chopsticks_enable_markdown_preview` to control Previm independently
- `g:chopsticks_profile` with `minimal`, `engineer`, and `full` profiles
- `.markdownlint.json` aligned with the project's README/changelog style
- `:ChopsticksStatus` diagnostic command — checks system tools, LSP servers, linters, formatters
- `,af` toggle format-on-save (ALE `fix_on_save`)
- `,gL` git log graph (last 20 commits)
- `,gC` FZF git commits search, `,gB` buffer commits
- Interactive installer profile selection for `minimal`, `engineer`, and `full`
- `install.sh --profile=minimal|engineer|full` for scripted profile selection
- `install.sh --dry-run` to show the resolved profile/config path without writes
- `install.sh --configure-only` to update local profile config without reinstalling
- `get.sh --dry-run` for safe bootstrap previews before clone/update/install
- `CHOPSTICKS_DEST=/absolute/path` to test or install the bootstrap target elsewhere
- `scripts/test.sh` local test runner reused by GitHub Actions
- `scripts/test.sh quick`, `--help`, and `list` for easier local test discovery

### Fixed

- README badge and `install.sh` recommend Vim 8.1+ instead of 8.0+ —
  the runtime conditionally relies on patches `8.1.0360` (diffopt) and
  `8.1.1517` (completeopt+=popup), so 8.0 users hit option errors
- `install.sh` no longer silently `PlugClean!`s user-added plugins from
  `~/.vim/plugged`; it now lists undeclared plugin directories first and
  asks before removing them (`--yes` skips the removal entirely)
- `install.sh` Python tools now prefer `pipx` and `pip3 --user` over
  `pip3 install --break-system-packages`; the break-system path is gated
  behind `CHOPSTICKS_ALLOW_BREAK_SYSTEM=1` so PEP 668 distros are no
  longer silently polluted
- `g:loaded_logipat` typo → `g:loaded_logiPat` — logiPat was loading fully (0.478ms wasted)
- `get.sh` now refuses to update an existing `~/.vim` git repo unless its
  origin is chopsticks
- Large file protection now stays active after filetype and syntax autocommands
- `g:ale_fix_on_save = 0` in local config is now respected
- Local config now respects absolute `XDG_CONFIG_HOME` instead of hardcoding
  `~/.config`

### Changed

- `install.sh` "First steps inside Vim" block now leads with `,?`
  (cheat sheet) — the single best onboarding asset is now the first
  thing a new user sees after install, not the fourth
- `set exrc`/`set secure` are now opt-in via `g:chopsticks_enable_exrc = 1`;
  Vim no longer sources project-local `.vimrc`/`.exrc` from the working
  directory by default
- Normal-mode `,F` (reindent the entire file with `gg=G`) is now opt-in
  via `g:chopsticks_enable_reindent_file = 1`; visual-mode `,F` (reindent
  selection) stays as the default since it's bounded by the user's pick
- `,?` cheat sheet is now profile-aware and hides LSP/ALE/preview/UndoTree keys
  when those features are disabled
- Module reload/source paths now use `fnameescape()` so installs in paths with
  spaces are handled correctly
- CI now verifies path-safe module loading, the local config hook, and
  minimal-profile cheat sheet output
- Markdown now opens in quiet writing mode by default: no real-time markdownlint,
  no Marksman LSP, no spell noise, no conceal, no sign column, and no realtime preview
- Native `s` is no longer shadowed by EasyMotion; use `,S` for the two-character jump
- `,w` now uses a normal `:write` instead of forced `:write!`
- Swap files are enabled again and stored under `~/.vim/.swap` for crash recovery
- Installer defaults are slimmer: only core search tools stay selected by default;
  language and lint suites are opt-in
- `:ChopsticksStatus` now respects disabled LSP/lint profiles instead of reporting
  intentionally disabled tools as missing
- `,sv` now clears the load guard before sourcing `$MYVIMRC`
- CI now verifies key plugin directories, Markdown quiet defaults, markdownlint,
  and an explicit startup-time threshold
- Installer plugin validation now checks every plugin required by the active profile
- The optional tool menu now hides LSP/lint suites in `minimal` and selects
  Marksman by default in `full`
- tmux integration is written as a managed block so future installer runs can
  update it without appending duplicate bindings
- Installer cleanup now restores the cursor after interrupted checkbox menus
- Bootstrap dry-run now refuses unrelated existing git repos before any writes
- CI now shares shell, installer, bootstrap, docs, and Vim smoke checks with
  the local test runner
- CI now checks the test runner help and group-list commands
- Skip 2 more built-in plugins: openPlugin, manpager (10 → 12 total)
- Remove deprecated `set ttyfast` (no-op since Vim 8)
- Add `grepprg=rg --vimgrep` — `:grep` now uses ripgrep + quickfix
- Add `diffopt` with histogram algorithm and indent-heuristic
- Consolidate FZF Rg/RgWord/GFiles commands (DRY refactor)
- vim-tmux-navigator: conditional load (only inside tmux), fallback `Ctrl+hjkl` mappings outside
- Add `Ctrl+hjkl` window navigation fallback when tmux-navigator not loaded

## 2.1.0 — 2025-04-22

### Added

- Cheat sheet (`,?`) — vertical sidebar, one key per line, section headers
- Previm markdown preview restored (lazy-loaded, `,mp`)
- `:LspInstallServer` added to cheat sheet

### Changed

- Plugin count: 25 (restored previm, dropped 5 bloat plugins)
- QUICKSTART updated — removed stale references, improved first-launch guidance

## 2.0.0 — 2025-04-21

### Added

- Sidebar toggle (`,e` / `,E`) — left-side netrw with `topleft vertical`, winfixwidth, proper toggle
- Enriched statusline — SLMode, SLGit, SLAle, SLFlags
- Toggle feedback — F2/F3/F4/F6/`,ss` echo current state
- `vim .` layout — netrw left + Startify right (removed in later refactor)
- Interactive tutorial (`:ChopsticksLearn` — removed in later release)

### Removed (Unix minimalism refactor)

- **565 lines** of dead code and bloat
- 5 plugins: Goyo, Limelight, vim-obsession, indentLine, vim-unimpaired
- `modules/writing.vim` — folded into `languages.vim`
- `tutor/chopsticks.tutor` — removed (269 lines)
- Tab management keybindings (8 mappings), spell nav bindings (4 mappings)
- Dead functions: HasPaste(), CleanExtraSpaces(), ToggleNumber(), SynStack
- TTY welcome message, `,so`, `,ms`, `,sh` mappings

### Changed

- CI plugin threshold lowered to 20
- README: hero layout with demo GIF, badges, architecture diagram
- vim-markdown settings absorbed from writing.vim into languages.vim

## 1.3.0 — 2025-04-20

### Changed

- Startup: 39ms → 19ms (51% faster)
- Dropped vim-unimpaired for performance
- Runtime tuning across modules

## 1.2.0 — 2025-04-19

### Added

- Hero README with demo GIF, CI badges
- GitHub Actions CI (startup test on macOS + Ubuntu, shellcheck)
- Issue/PR templates

### Changed

- Documentation rewrite — clean, short, for engineers

## 1.1.0 — 2025-04-18

### Added

- 12-module architecture (env → plugins → core → ui → editing → navigation → lsp → lint → git → writing → languages → tools)
- Zen mode (Goyo + Limelight)
- Run file (`,cr`) with auto filetype detection
- Smart search (SmartFiles, Rg, RgWord)
- EasyMotion, yank highlight, undo tree
- Robust installer (`get.sh`) with preflight checks

### Changed

- `.vimrc` split into 12 self-contained modules
- Comprehensive bug audit (14 fixes)

## 1.0.0 — 2025-04-16

### Added

- Initial Vim configuration — migrated from Neovim
- vim-plug plugin manager
- vim-lsp + asyncomplete (pure VimScript LSP)
- ALE linting + format-on-save
- FZF fuzzy finder
- Fugitive + GitGutter
- Solarized colorscheme
- TTY detection and graceful degradation
- Platform installer (macOS, Debian, Arch, Fedora)
