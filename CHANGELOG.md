# Changelog

All notable changes to chopsticks are documented here.

---

## [1.0.0] - 2026-03-29

First stable release. Full-stack engineering environment out of the box — automatic
installation, tiered LSP, TTY fallback, and coverage for 14 languages.

### Added
- **Arch Linux support** in `install.sh` — pacman branch for all system tools
- **`hadolint`** added to system tools installation (Dockerfile linting)
- **`staticcheck`** added to Go tools (replaces archived `golint`)
- **`yamllint`** added to pip tools (YAML linting)
- **`coc-settings.json`** — configures `marksman` as Markdown LSP for CoC via
  `languageserver` entry; symlinked automatically by `install.sh`
- **pip3 bootstrap** in `install.sh` — auto-installs pip3 when python3 is present
  but pip3 is absent (common on Ubuntu minimal images)
- **9 named augroups** in `.vimrc` — all loose `autocmd` statements now wrapped
  with `autocmd!` to prevent doubling on `:source $MYVIMRC`:
  `ChopstickTabHistory`, `ChopstickResize`, `ChopstickStdin`, `CocHighlight`,
  `ChopstickCleanup`, `ChopstickFiletype`, `ChopstickTTYLargeFile`,
  `ChopstickWhichKey`, `ChopstickStartify`
- **TTY-safe plugin install** — `vim +PlugInstall +qall </dev/null` prevents
  Vim from blocking in non-interactive/piped environments

### Changed
- SQL tooling unified to **`sqlfluff`** (pip) — `sqlfmt` removed from npm section
- Go linter changed from `golint` (archived 2023) to **`staticcheck`**
- Markdown LSP changed from broken `coc-marksman` (npm) to **`marksman`** binary
  configured via `coc-settings.json`

### Fixed
- **vim-go startup hang** on Arch Linux — removed `:GoUpdateBinaries` post-install
  hook; set `g:go_gopls_enabled = 0` to prevent conflict with `coc-go`
- **E495 errors** (`<afile>` in special buffers) — all `<afile>` usages guarded
  with `!empty(expand('<afile>'))` and `empty(&buftype)` checks
- **`g:go_def_mode` conflict** — now conditional: uses `gopls` when CoC active,
  `godef` when vim-lsp active (avoids error when gopls is disabled)
- **vim startup UX** — NERDTree + Startify layout for `vim .` and bare `vim`
- **`coc-marksman` silent failure** — package does not exist on npm; replaced with
  native `languageserver` configuration in `coc-settings.json`
- **CoC startup warning** in no-node environments — `g:coc_start_at_startup = 0`
  and `g:coc_disable_startup_warning = 1` set when `g:use_coc = 0`

---

## [0.9.0] - 2026-02-21

### Added
- **Full-stack language coverage** — LSP, lint, and format for: Python,
  JavaScript, TypeScript, Go, Rust, Shell, YAML, HTML, CSS/SCSS, Less,
  JSON, Markdown, SQL, Dockerfile
- **`install.sh` overhaul** — automated installation of system tools, npm tools,
  pip tools, Go tools, and CoC language server extensions with platform detection
  and interactive prompts; `--yes` flag for non-interactive mode
- **vim-startify** startup screen with dynamic header (version, cwd, git branch)
- **vim-which-key** keybinding popup on `,` + 500ms pause
- **Startup layout** — `vim .` opens NERDTree left + Startify right; bare `vim`
  opens Startify with NERDTree alongside
- **Session management** via vim-obsession + vim-prosession
- **Large file handling** — syntax and undo disabled for files > 10 MB
- **Project-local config** — `.vimrc` in project root auto-loaded via `set exrc`
- **Persistent undo** — `~/.vim/.undo/` with `undolevels=1000`

### Changed
- Tiered LSP backend: CoC (Node.js) preferred, vim-lsp (no Node.js) as fallback
- All CoC and vim-lsp keybindings unified (`gd`, `K`, `[g`/`]g`, `,rn`, `,ca`)
- ALE `fix_on_save` disabled when vim-lsp active (prevents double-format)
- NERDTree autocmd wrapped in `augroup NERDTreeAutoClose`

### Fixed
- Multiple leader key conflicts resolved (`,ad`, `,cd`, `,cp`, `,sp`, `,t`)
- CtrlP removed (redundant with FZF)
- Duplicate `set` options cleaned up
- `<leader>A` dead mapping (no alternate-file plugin) removed

---

## [0.1.0] - 2024

Initial release — base Vim configuration with vim-plug, basic plugins, and
TTY/non-TTY detection.
