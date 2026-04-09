# Changelog

All notable changes to chopsticks are documented here.

---

## [1.2.0] - 2026-04-09

Installer robustness overhaul and one-command bootstrap.

### Added

- **`get.sh`** — one-command bootstrap: `curl -fsSL .../get.sh | bash`
  - Installs `git` if missing (apt / pacman / dnf / brew)
  - Clones repo to `~/.vim`; `git pull` if already present
  - `exec bash install.sh </dev/tty` — interactive prompts work correctly even when piped from curl
- **Network connectivity check** — warns early if `github.com` is unreachable
- **`curl` preflight** — detects missing curl, auto-installs or dies with clear instructions
- **`git` preflight** — same as curl
- **`vim` auto-install** — attempts `pkg_install` before dying if vim is not found
- **`sudo` availability check** — authenticates once upfront; `--yes` mode skips sudo gracefully with a warning
- **macOS Homebrew installer** — offers to install Homebrew when `brew` is missing on macOS
- **Node.js via nvm** — when Node.js is missing, offers to install nvm + Node.js LTS automatically
- **Python 3 installer** — offers to install python3 via package manager when missing
- **`safe_download()`** helper — verifies downloads are non-empty and not HTML error pages (guards against GitHub 404 / rate-limit pages being silently treated as binaries)
- **`pkg_install()`** helper — unified cross-platform install (brew / apt / pacman / dnf)
- **`arch_github()` / `arch_linux_x64()`** helpers — normalize `uname -m` including `aarch64` → `arm64`
- **`trap on_error ERR`** — catches unexpected failures, shows line number and debug command
- **`trap EXIT`** — cleans up temp files (`/tmp/chopsticks-hadolint`, `/tmp/chopsticks-marksman`)
- **Symlink verification** — confirms `[[ -L ]]` after `ln -sf`
- **vim-plug fallback** — if curl download fails, falls back to `git clone`; verifies file is non-empty
- **`vim +PlugInstall` error handling** — warns on non-zero exit instead of silent continue
- **Screen-dark notice** — informs user before each Vim fullscreen step (PlugInstall, CocInstall)

### Changed

- `set -e` → `set -eo pipefail` — pipeline failures now propagate correctly
- `ask()` now reads from `/dev/tty` with a test-open check (`{ true </dev/tty; }`) — interactive prompts work under `curl | bash` and non-interactive SSH sessions fall back to "no" safely
- Binary downloads (hadolint, marksman) use named temp files and `safe_download()` instead of bare curl
- Arch architecture detection handles `aarch64` in addition to `arm64`
- System tools section checks `HAS_SUDO` before running apt / pacman / dnf commands

---

## [1.1.1] - 2026-04-09

Systematic absorption of best practices from amix/vimrc, tpope/vim-sensible,
ThePrimeagen, skwp/YADR, and spf13-vim — settings and mappings that appear
consistently across all top global configs but were missing here.

### Added

- **`set ttimeoutlen=10`** — eliminates the ~500ms ESC lag in terminal Vim; separates
  keycode timeout from leader-key timeout (`timeoutlen` unchanged at 500ms)
- **`set display+=lastline`** — shows truncated long lines instead of replacing them with `@@@`
- **`set complete-=i`** — `Ctrl+n/p` no longer scans all included files; completion is instant
- **`set wildignorecase`** — case-insensitive filename completion in wildmenu and `:find`
- **`set path+=**`** — recursive `:find` across the project; wildignore excludes
  `node_modules`, `__pycache__`, `dist`, `build`, `.git`
- **`set sessionoptions`** — removes `options` from saved sessions (prevents stale plugin
  settings from contaminating restored sessions)
- **`set listchars`** — defines visible whitespace characters; TTY uses ASCII symbols,
  modern terminals use Unicode (tab `→`, trail `·`, extends `▸`)
- **`F6`** — toggle visible whitespace on/off
- **`formatoptions-=cro`** on `BufEnter` — disables automatic comment-leader insertion
  when pressing Enter or `o/O`; runs on BufEnter to override filetype plugins
- **`InsertLeave * set nopaste`** — auto-disables paste mode on leaving insert, preventing
  permanently broken auto-indent
- **`colorcolumn=+1`** for all languages via `textwidth`:
  Python 88, Go 120, JS/TS 100, Rust 100, Shell 80 (Markdown disabled)
- **`vnoremap J/K`** with `gv=gv` — move selected lines down/up and re-indent (ThePrimeagen)
- **`gV`** — re-select last pasted text (`\`[v\`]` — spf13, YADR)
- **`cnoremap <C-p>/<C-n>`** — navigate command-line history matching typed prefix (amix, spf13)
- **`<leader>e :Explore`** — open built-in Netrw file browser; works on any Vim without plugins
- **`<leader>cd`** — change window-local CWD to current file's directory (was `<leader>wd`)
- **`<leader>sv`** — reloads vimrc and echoes confirmation

### Changed

- `<leader>wd` renamed to `<leader>cd`; now uses `lcd` (window-local) instead of `cd` (global)
- `wildignore` expanded with `*/node_modules/*`, `*/__pycache__/*`, `*/dist/*`, `*/build/*`

---

## [1.1.0] - 2026-04-09

Ergonomics and automation overhaul: community-standard keybindings, seamless
tmux integration, an in-Vim cheat sheet, a beginner onboarding section, and
several correctness fixes from a systematic review.

### Added

- **`jk` → `Esc`** in insert mode — ergonomic escape without reaching for the key
- **`Ctrl+s` save** in normal and insert mode (add `stty -ixon` to shell rc to enable
  in terminals that use XON/XOFF flow control)
- **`//` visual search** — search for visually selected text using `\V` very-nomagic escaping
- **`<leader>p` / `<leader>P`** — paste from system clipboard after/before cursor
- **`<leader>rG`** — ripgrep word under cursor with `-F` (literal, not regex)
- **`<leader>u`** — leader-key alias for UndoTree (complements `F5`)
- **`<leader>tt`** — leader-key alias for Tagbar (complements `F8`)
- **`,?` in-Vim cheat sheet** — opens a read-only buffer covering modes, survival
  commands, search, code intelligence, git, and clipboard; press `q` to close
- **vim-tmux-navigator** plugin — `Ctrl+h/j/k/l` navigates seamlessly across Vim
  splits and tmux panes without a prefix key
- **`install.sh` tmux step** — detects tmux and optionally appends the four
  navigator `bind-key` lines to `~/.tmux.conf`; warns about `C-l`/screen-clear tradeoff
- **`install.sh` survival guide** — post-install output now shows the 4 essential
  commands for first-time Vim users, plus the `stty -ixon` advisory
- **QUICKSTART.md Step 0** — new first section explaining Vim modes (Normal/Insert/Visual)
  and 4 survival commands; makes the guide usable by users who have never opened Vim
- **`let b:ale_enabled = 0`** in `LargeFileSettings()` — ALE no longer spawns
  linter subprocesses for files over 10 MB

### Changed

- **ALE lint triggers** — `ale_lint_on_text_changed` changed from `'never'` to `'normal'`;
  `ale_lint_on_insert_leave` and `ale_lint_on_enter` changed from `0` to `1` — diagnostics
  now refresh on buffer enter and after edits settle in normal mode
- **`<C-h/j/k/l>` manual maps removed** — vim-tmux-navigator owns these keys at
  plugin load time; the previous hand-rolled `<C-W>` maps were unreachable dead code
- **`<leader>pp` paste-mode toggle removed** — functionally identical to the existing
  `F2` pastetoggle; its presence caused a 500 ms delay on every `<leader>p` paste

### Fixed

- **ALE navigation direction reversed** — `[e` now correctly calls `ALEPrevious`
  and `]e` calls `ALENext`, matching the vim-unimpaired `[`/`]` convention
- **`<leader>rG` regex metacharacter bug** — without `-F`, characters like `.` `*`
  `(` in the cursor word were treated as regex, producing incorrect matches

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
