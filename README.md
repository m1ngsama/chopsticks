# chopsticks

> A batteries-included Vim configuration for full-stack engineering.
> Tiered LSP · 14 languages · TTY-aware · Zero icon fonts · One-command install.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Vim 8.0+](https://img.shields.io/badge/Vim-8.0%2B-brightgreen?style=flat-square)](https://www.vim.org/)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey?style=flat-square)](#installation)
[![Release](https://img.shields.io/github/v/release/m1ngsama/chopsticks?style=flat-square&label=release&color=orange)](https://github.com/m1ngsama/chopsticks/releases)
[![Last Commit](https://img.shields.io/github/last-commit/m1ngsama/chopsticks?style=flat-square)](https://github.com/m1ngsama/chopsticks/commits/main)
[![Stars](https://img.shields.io/github/stars/m1ngsama/chopsticks?style=flat-square)](https://github.com/m1ngsama/chopsticks/stargazers)
[![Issues](https://img.shields.io/github/issues/m1ngsama/chopsticks?style=flat-square)](https://github.com/m1ngsama/chopsticks/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square)](https://github.com/m1ngsama/chopsticks/pulls)
[![Plugins](https://img.shields.io/badge/plugins-30%2B-blueviolet?style=flat-square)](#plugins)
[![Languages](https://img.shields.io/badge/languages-14-informational?style=flat-square)](#language-support)

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

> **New to Vim?** Read [Step 0 in QUICKSTART.md](QUICKSTART.md#step-0-vim-basics) first —
> a 2-minute intro to modes and the 4 commands that get you out of any jam.

---

## Contents

- [Design Principles](#design-principles)
- [Requirements](#requirements)
- [Installation](#installation)
- [LSP: Tiered Backend](#lsp-tiered-backend)
- [Key Mappings](#key-mappings)
- [Features](#features)
- [Language Support](#language-support)
- [Plugins](#plugins)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Design Principles

| Principle | What it means |
|-----------|--------------|
| **KISS** | No icon fonts, no Nerd Font glyphs — plain ASCII everywhere |
| **Tiered LSP** | CoC (full) when Node.js is available; vim-lsp (pure VimScript) otherwise |
| **TTY-aware** | Automatically detects SSH/console environments and degrades gracefully |
| **Engineering-first** | Git workflow, persistent sessions, project-local config, large-file safety |
| **Batteries included** | `install.sh` handles vim-plug, plugins, system tools, and language servers |

---

## Requirements

| Tool | Minimum | Role |
|------|---------|------|
| Vim | **8.0+** | Required — `install.sh` installs it if missing |
| git | any | Required — `install.sh` installs it if missing |
| curl | any | Required — `install.sh` installs it if missing |
| Node.js | 14.14+ | Optional — enables CoC LSP; `install.sh` offers nvm install |
| ripgrep | any | Optional — enables `,rg` / `,rG` project search |
| fzf | any | Optional — enables `Ctrl+p` fuzzy finder |
| ctags | any | Optional — enables `,tt` tag browser |
| tmux | 1.8+ | Optional — enables seamless pane navigation |

`install.sh` detects your environment and installs missing dependencies automatically.
On macOS it will offer to install Homebrew if not present. On any platform it will
offer to install Node.js via nvm if missing.

---

## Installation

### One command (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

This bootstrap script clones the repo to `~/.vim`, then runs the full installer.
It works correctly even when piped from curl — interactive prompts use `/dev/tty`.

For non-interactive or CI environments:

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash -s -- --yes
```

### Traditional (git clone)

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh
```

### What the installer does

1. **Preflight** — checks network, detects OS and package manager, verifies or installs `curl`, `git`, and `vim`
2. **sudo** — authenticates once upfront; gracefully skips system packages when unavailable
3. **macOS** — offers to install Homebrew if `brew` is not found
4. **Node.js** — offers to install via nvm if not found (falls back to vim-lsp if declined)
5. **Python** — offers to install Python 3 if missing; bootstraps pip3 if only python3 is present
6. **Symlinks** — backs up any existing `~/.vimrc` with a timestamp, then symlinks `~/.vimrc → ~/.vim/.vimrc`
7. **Plugins** — installs vim-plug and runs `:PlugInstall` (with a progress notice during the black-screen period)
8. **System tools** — ripgrep, fzf, ctags, shellcheck, hadolint, marksman (verified downloads)
9. **Language tools** — npm formatters, pip formatters/linters, Go tools
10. **CoC extensions** — all language servers in one step
11. **tmux** — optionally appends vim-tmux-navigator bindings to `~/.tmux.conf`

**Supported platforms:** macOS (Homebrew), Debian/Ubuntu (apt), Arch Linux (pacman), Fedora (dnf).

### Manual

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
ln -sf ~/.vim/.vimrc ~/.vimrc
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall </dev/null
```

---

## LSP: Tiered Backend

Code intelligence is provided by one of two backends, chosen automatically at startup:

| Condition | Backend | Capabilities |
|-----------|---------|-------------|
| Vim 8.0.1453+ **and** Node.js 14.14+ | **CoC** | Full LSP, snippets, extension ecosystem |
| Vim 8.0+ (no Node.js) | **vim-lsp** | LSP via language server binaries, asyncomplete |
| Any Vim | **ALE** | Async linting + auto-fix (always active, both backends) |

Both CoC and vim-lsp expose the same key mappings so switching backends is transparent.

### With Node.js (CoC)

Install language server extensions from inside Vim — or let `install.sh` do it automatically:

```vim
:CocInstall coc-pyright       " Python
:CocInstall coc-tsserver      " JavaScript / TypeScript
:CocInstall coc-go            " Go
:CocInstall coc-rust-analyzer " Rust
:CocInstall coc-json coc-yaml " JSON, YAML
:CocInstall coc-html coc-css  " HTML, CSS/SCSS
:CocInstall coc-sh            " Shell
:CocInstall coc-sql           " SQL
```

**Markdown LSP** uses `marksman` as an external binary (not a CoC extension):

```bash
brew install marksman           # macOS
sudo pacman -S marksman         # Arch
# or: ./install.sh handles it automatically
```

### Without Node.js (vim-lsp)

Open a source file, then run:

```vim
:LspInstallServer   " detects filetype and installs the correct server
:LspStatus          " check server status
```

Supported: Python, Go, Rust, TypeScript/JavaScript, Shell, HTML, CSS/SCSS, JSON, YAML, Markdown, SQL.

---

## Key Mappings

**Leader key:** `,` (comma)

Press `,` and wait 500 ms to see an interactive guide to all bindings (vim-which-key).
Press `,?` to open the built-in cheat sheet at any time.

### Survival

| Key | Action |
|-----|--------|
| `jk` | Exit insert mode → Normal (ergonomic Escape) |
| `Esc` | Exit insert / visual mode (standard) |
| `Ctrl+s` | Save file (normal and insert mode) |
| `,w` | Save file |
| `,x` | Save and quit |
| `,q` | Quit |
| `,?` | Open cheat sheet |

> **`Ctrl+s` note:** some terminals freeze on `Ctrl+s` (XON/XOFF). Add `stty -ixon`
> to your `~/.bashrc` / `~/.zshrc` to disable this permanently.

### Files and Buffers

| Key | Action |
|-----|--------|
| `Ctrl+p` | Fuzzy file search — git-aware (FZF) |
| `Ctrl+n` | Toggle file tree (NERDTree) |
| `,n` | Reveal current file in NERDTree |
| `,b` | Search open buffers (FZF) |
| `,rg` | Project-wide search (ripgrep + FZF) |
| `,rG` | Ripgrep for word under cursor (literal match) |
| `,rt` | Search tags (FZF) |
| `,gF` | Search git-tracked files (FZF) |
| `,l` | Next buffer |
| `,h` | Previous buffer |
| `,bd` | Close current buffer (preserves window layout) |
| `,,` | Switch to last file |

### Windows, Tabs, and tmux

| Key | Action |
|-----|--------|
| `Ctrl+h/j/k/l` | Navigate between Vim splits **and** tmux panes |
| `,=` | Increase window height |
| `,-` | Decrease window height |
| `,+` | Increase window width |
| `,_` | Decrease window width |
| `,tn` | New tab |
| `,tc` | Close tab |
| `,tl` | Toggle to last tab |
| `,tv` | Open terminal (vertical split) |
| `,th` | Open terminal (horizontal split) |
| `Esc Esc` | Exit terminal mode |

### Code Intelligence (CoC / vim-lsp)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `gi` | Go to implementation |
| `gr` | Show all references |
| `K` | Hover documentation |
| `[g` | Previous diagnostic |
| `]g` | Next diagnostic |
| `,rn` | Rename symbol |
| `,f` | Format selection |
| `,F` | Format whole file |
| `,ca` | Code action (cursor position) |
| `,o` | File outline (symbols) |
| `,ws` | Workspace symbols |
| `,cD` | Diagnostics list |
| `,qf` | Quick-fix current line (CoC) |
| `Tab` | Next completion item |
| `Shift+Tab` | Previous completion item |
| `Enter` | Confirm completion |

Text objects (CoC): `if`/`af` (function inner/around), `ic`/`ac` (class inner/around).

### Linting (ALE — always active)

| Key | Action |
|-----|--------|
| `[e` | Previous error / warning |
| `]e` | Next error / warning |
| `,aD` | Show error detail |
| `,ad` | Full diagnostics list |

Signs in the gutter: `X` = error, `!` = warning.

### Git (vim-fugitive)

| Key | Action |
|-----|--------|
| `,gs` | Git status (stage with `s`, commit with `cc`) |
| `,gc` | Git commit |
| `,gp` | Git push |
| `,gl` | Git pull |
| `,gd` | Git diff |
| `,gb` | Git blame |

### Search and Replace

| Key | Action |
|-----|--------|
| `n` / `N` | Next / previous match (cursor centered) |
| `//` | Search for visually selected text |
| `,*` | Search and replace word under cursor (file-wide) |
| `,rG` | Ripgrep word under cursor across project |
| `,<CR>` | Clear search highlight |

### Clipboard

| Key | Action |
|-----|--------|
| `,y` | Yank to system clipboard |
| `,Y` | Yank line to system clipboard |
| `,p` | Paste from system clipboard (after cursor) |
| `,P` | Paste from system clipboard (before cursor) |

### Editing and Navigation

| Key | Action |
|-----|--------|
| `s` + 2 chars | EasyMotion — jump anywhere on screen |
| `Space` | Toggle code fold |
| `Y` | Yank to end of line (consistent with `D`, `C`) |
| `Ctrl+d/u` | Half-page scroll (cursor stays centered) |
| `>` / `<` | Indent / dedent (keeps visual selection) |
| `Alt+j/k` | Move current line down / up |
| `0` | Jump to first non-blank character |
| `[q` / `]q` | Previous / next quickfix entry (vim-unimpaired) |
| `,u` | Toggle undo tree (visual branch history) |
| `,tt` | Toggle tagbar (code structure) |
| `F2` | Toggle paste mode |
| `F3` | Toggle absolute line numbers |
| `F4` | Toggle relative line numbers |

### Config and Utilities

| Key | Action |
|-----|--------|
| `,ev` | Edit `~/.vimrc` |
| `,sv` | Reload `~/.vimrc` |
| `,wa` | Save all open buffers |
| `,wd` | Change working directory to current file's location |
| `,cp` | Copy absolute file path to clipboard |
| `,cf` | Copy filename to clipboard |
| `,qo` / `,qc` | Open / close quickfix list |

---

## Features

### Startup Dashboard

Running `vim` (no arguments) opens a full-screen Startify dashboard showing recent
files, sessions, and bookmarks. Running `vim .` opens NERDTree on the left with
the dashboard on the right.

### Keybinding Guide

Press `,` and pause for 500 ms. A popup (vim-which-key) lists all leader bindings
organized into groups. No need to memorize everything upfront.

### Built-in Cheat Sheet

Press `,?` to open an inline reference covering modes, survival commands, search,
code intelligence, git, and clipboard — without leaving Vim.

### Session Management

```vim
:Obsess     " start tracking the current session
:Obsess!    " stop tracking
```

Sessions are stored in `~/.vim/sessions/` and automatically restored by vim-prosession
the next time you open Vim in the same directory.

### Project-Local Config

Drop a `.vimrc` in any project root to override settings for that project:

```vim
" project/.vimrc
set shiftwidth=2
let g:ale_python_black_options = '--line-length=100'
```

Loaded automatically via `set exrc`. Restricted to safe options via `set secure`.

### tmux Integration

`Ctrl+h/j/k/l` navigates seamlessly between Vim splits and tmux panes — no prefix
key, no mode switch.

**Vim side:** handled by vim-tmux-navigator (installed automatically).

**tmux side:** add to `~/.tmux.conf` (or let `install.sh` append it):

```tmux
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\S+\/)?g?(view|n?vim?x?)(diff)?$'"
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
```

Then reload: `tmux source-file ~/.tmux.conf`

> **Note:** the `C-l` binding replaces the terminal's screen-clear shortcut inside
> tmux. To restore it, add `bind C-l send-keys 'C-l'` — then use `prefix + C-l`.

### Large File Handling

Files over 10 MB automatically disable syntax highlighting, undo history, and
linting to prevent Vim from stalling.

### TTY / Console Support

Detected automatically when `$TERM` is `linux` or `screen`. In TTY mode:

- True color and cursorline disabled
- Powerline separators replaced with plain ASCII
- FZF preview windows disabled
- IndentLine guides disabled
- Syntax column limit reduced to 120 characters
- Simpler built-in status line used instead of airline

---

## Language Support

| Language | Indent | Formatter | Linter | LSP |
|----------|--------|-----------|--------|-----|
| Python | 4 sp | black, isort | flake8, pylint | coc-pyright |
| JavaScript | 2 sp | prettier | eslint | coc-tsserver |
| TypeScript | 2 sp | prettier | eslint, tsserver | coc-tsserver |
| Go | tab | gofmt, goimports | staticcheck | coc-go |
| Rust | 4 sp | rustfmt | cargo | coc-rust-analyzer |
| Shell | 2 sp | — | shellcheck | coc-sh |
| YAML | 2 sp | prettier | yamllint | coc-yaml |
| HTML | 2 sp | prettier | — | coc-html |
| CSS / SCSS | 2 sp | prettier | stylelint | coc-css |
| Less | 2 sp | prettier | — | — |
| JSON | 2 sp | prettier | — | coc-json |
| Markdown | 2 sp | prettier | markdownlint | marksman |
| SQL | 4 sp | sqlfluff | sqlfluff | — |
| Dockerfile | 2 sp | — | hadolint | — |

`install.sh` installs all formatters and linters automatically.
ALE runs them asynchronously; format-on-save is active for all supported languages.

---

## Plugins

### Navigation
- **NERDTree** — file tree explorer
- **fzf + fzf.vim** — fuzzy finder for files, buffers, tags, and ripgrep

### Git
- **vim-fugitive** — full Git integration inside Vim
- **vim-gitgutter** — diff signs in the sign column

### LSP and Completion
- **coc.nvim** — full LSP + completion via Node.js (recommended)
- **vim-lsp** — pure VimScript LSP client (Node.js-free fallback)
- **vim-lsp-settings** — auto-configures language servers for vim-lsp
- **asyncomplete.vim** — async completion engine (vim-lsp mode)

### Linting
- **ALE** — asynchronous lint engine, always active regardless of LSP backend

### UI
- **vim-airline** — status line and tabline
- **vim-startify** — startup dashboard with session management
- **vim-which-key** — keybinding hint popup on leader pause
- **indentLine** — indent guide lines (non-TTY only)
- **undotree** — visual undo branch history
- **tagbar** — code structure sidebar via ctags

### Editing
- **vim-surround** — change surrounding quotes, brackets, and tags
- **vim-commentary** — `gc` to toggle comments
- **auto-pairs** — auto-close brackets and quotes
- **vim-easymotion** — jump anywhere on screen with 2 keystrokes (`s`)
- **vim-unimpaired** — bracket shortcut pairs (`[q`/`]q`, etc.)
- **targets.vim** — additional text objects
- **vim-snippets** — snippet library (used with CoC)
- **vim-tmux-navigator** — seamless `Ctrl+h/j/k/l` across Vim and tmux

### Language Packs
- **vim-polyglot** — syntax for 100+ languages
- **vim-go** — Go syntax and tooling (LSP handled by coc-go)

### Session
- **vim-obsession** — continuous session saving
- **vim-prosession** — project-level session management

### Color Schemes
- **gruvbox** (default), **dracula**, **solarized**, **onedark**

---

## Customization

### Change the color scheme

In `~/.vimrc`, find and update the `colorscheme` line:

```vim
colorscheme dracula    " options: gruvbox, solarized, onedark
```

True color is enabled automatically when `$COLORTERM=truecolor`. Falls back to
256-color, then 16-color in TTY.

### Per-project overrides

Create `.vimrc` in your project root. Anything placed here overrides the global
config for that directory:

```vim
" my-project/.vimrc
set shiftwidth=2
let g:ale_python_black_options = '--line-length=120'
```

### Modify keybindings

Edit `~/.vimrc` directly (`,ev` opens it from inside Vim). Reload with `,sv`.

---

## Troubleshooting

**Plugins not loading**

```vim
:PlugInstall    " install any missing plugins
:PlugUpdate     " update all plugins
```

**CoC not working**

```bash
node --version  # must be 14.14+
```

Inside Vim: `:CocInfo` for diagnostics, `:CocInstall <extension>` to add a language server.

**vim-lsp server not starting**

```vim
:LspInstallServer   " install the correct server for the current filetype
:LspStatus          " check server status
```

**Markdown LSP not starting**

`marksman` must be installed as a standalone binary (not a CoC extension):

```bash
brew install marksman        # macOS
sudo pacman -S marksman      # Arch
# or: ./install.sh handles it automatically
```

**Colors look wrong**

```bash
export TERM=xterm-256color   # add to ~/.bashrc or ~/.zshrc
```

For true color: `export COLORTERM=truecolor`.

**ALE linters not found**

```bash
which flake8 black prettier eslint  # verify tools are on PATH
```

If tools were installed with `pip install --user` or `npm install -g`, make sure
the respective bin directories are on `$PATH`.

**`Ctrl+s` freezes the terminal**

Add `stty -ixon` to your `~/.bashrc`, `~/.zshrc`, or `~/.config/fish/config.fish`.
This disables XON/XOFF flow control permanently.

---

## Contributing

Bug reports and pull requests are welcome. Please follow these guidelines:

### Reporting a bug

1. Search [existing issues](https://github.com/m1ngsama/chopsticks/issues) before opening a new one.
2. Include your Vim version (`vim --version`), OS, and a minimal reproduction.
3. If the bug is plugin-specific, check whether it reproduces with a minimal config
   (`vim -u NONE`) or only with chopsticks loaded.

### Proposing a change

1. Open an issue first to discuss the change, especially for non-trivial additions.
2. Keep the scope focused — one feature or fix per PR.
3. Follow existing conventions: augroups for autocmds, TTY guards for visual features,
   conditional plugin loading where appropriate.
4. Update `CHANGELOG.md` with a summary of the change.

### Scope

Chopsticks is an opinionated configuration. Changes should align with the design
principles above — in particular, KISS (no icon fonts, minimal dependencies) and
TTY-compatibility. Neovim-only features and Lua configs are out of scope.

---

## Acknowledgements

Inspired by [amix/vimrc](https://github.com/amix/vimrc).
Built with [vim-plug](https://github.com/junegunn/vim-plug),
[coc.nvim](https://github.com/neoclide/coc.nvim),
[vim-lsp](https://github.com/prabirshrestha/vim-lsp),
and the broader Vim plugin community.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE) © m1ng
