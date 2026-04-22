# Changelog

## Unreleased

### Added
- `:ChopsticksStatus` diagnostic command — checks system tools, LSP servers, linters, formatters
- `,af` toggle format-on-save (ALE `fix_on_save`)
- `,gL` git log graph (last 20 commits)
- `,gC` FZF git commits search, `,gB` buffer commits

### Fixed
- `g:loaded_logipat` typo → `g:loaded_logiPat` — logiPat was loading fully (0.478ms wasted)

### Changed
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
