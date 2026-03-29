# chopsticks — Vim Configuration

A native Vim configuration optimized for full-stack engineering workflows.
Vim 8.0+ · Tiered LSP · TTY-aware · Zero icon fonts · 14 languages.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Vim 8.0+](https://img.shields.io/badge/Vim-8.0%2B-brightgreen.svg)](https://www.vim.org/)

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh
```

See [QUICKSTART.md](QUICKSTART.md) for the 5-minute guide.

---

## Design Principles

- **KISS** — No icon fonts, no unicode glyphs, plain ASCII throughout
- **Tiered LSP** — CoC (full) with vim-lsp fallback; works with or without Node.js
- **TTY-aware** — Automatic detection and optimization for console/SSH environments
- **Engineering-first** — Git workflow, session management, project-local config
- **Batteries included** — `install.sh` handles all dependencies automatically

---

## Requirements

| Requirement | Minimum | Notes |
|-------------|---------|-------|
| Vim | 8.0+ | vim9script not required |
| git | any | For cloning and fugitive |
| curl | any | For vim-plug auto-install |
| Node.js | 14.14+ | Optional — enables CoC LSP |
| ripgrep (rg) | any | Optional — enables `:Rg` search |
| fzf | any | Optional — enables `Ctrl+p` fuzzy search |
| ctags | any | Optional — enables `F8` tag browser |

---

## Installation

### Automatic (recommended)

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim
./install.sh
```

The installer:
1. Checks Vim version and detects OS / package managers
2. Backs up any existing `~/.vimrc` (timestamped)
3. Creates symlinks: `~/.vimrc -> ~/.vim/.vimrc` and `~/.vim/coc-settings.json`
4. Installs vim-plug and runs `:PlugInstall`
5. Optionally installs system tools, language tools, and CoC extensions

Supported platforms: **macOS** (Homebrew), **Debian/Ubuntu** (apt), **Arch Linux** (pacman), **Fedora** (dnf).

Use `--yes` for non-interactive / CI environments:

```bash
./install.sh --yes
```

### Manual

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
ln -sf ~/.vim/.vimrc ~/.vimrc
ln -sf ~/.vim/coc-settings.json ~/.vim/coc-settings.json
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall </dev/null
```

---

## LSP: Tiered Backend System

Code intelligence is provided by one of two backends, selected automatically:

| Condition | Backend | Features |
|-----------|---------|----------|
| Vim 8.0.1453+ AND Node.js 14.14+ | **CoC** | Full LSP, snippets, extensions ecosystem |
| Vim 8.0+ (no Node.js) | **vim-lsp** | LSP via language server binaries, asyncomplete |
| Any Vim | **ALE** | Linting and auto-fix (always active) |

Both backends expose identical key mappings: `gd`, `K`, `[g`, `]g`, `<leader>rn`, `<leader>ca`.

### CoC setup (with Node.js)

Install language server extensions from inside Vim:

```vim
:CocInstall coc-pyright       " Python
:CocInstall coc-tsserver      " JavaScript / TypeScript
:CocInstall coc-go            " Go
:CocInstall coc-rust-analyzer " Rust
:CocInstall coc-json coc-yaml " JSON, YAML
:CocInstall coc-html coc-css  " HTML, CSS
:CocInstall coc-sh            " Shell
:CocInstall coc-sql           " SQL
```

`install.sh` installs all of the above automatically when prompted.

**Markdown LSP** — `marksman` is configured via `coc-settings.json` (not a CoC
extension — install `marksman` binary via `brew install marksman` or download from
[releases](https://github.com/artempyanykh/marksman/releases)).

### vim-lsp setup (without Node.js)

Install language server binaries for your languages, then run:

```vim
:LspInstallServer   " auto-installs the right server for the current filetype
```

Supported languages: Python, Go, Rust, TypeScript, JavaScript, Shell, HTML,
CSS/SCSS, JSON, YAML, Markdown, SQL — via `vim-lsp-settings`.

---

## Key Mappings

Leader key: `,` (comma)

Press `,` and wait 500ms for an interactive guide to all bindings (vim-which-key).

### Files and Buffers

| Key | Action |
|-----|--------|
| `Ctrl+n` | Toggle file tree (NERDTree) |
| `,n` | Reveal current file in NERDTree |
| `Ctrl+p` | Fuzzy file search (FZF — git-aware) |
| `,b` | Search open buffers (FZF) |
| `,rg` | Project-wide search (ripgrep+FZF) |
| `,rt` | Search tags (FZF) |
| `,gF` | Search git-tracked files (FZF) |
| `,l` | Next buffer |
| `,h` | Previous buffer |
| `,bd` | Close current buffer |
| `,,` | Switch to last file |

### Windows and Tabs

| Key | Action |
|-----|--------|
| `Ctrl+h/j/k/l` | Navigate between windows |
| `<Leader>=` | Increase window height |
| `<Leader>-` | Decrease window height |
| `<Leader>+` | Increase window width |
| `<Leader>_` | Decrease window width |
| `,tn` | New tab |
| `,tc` | Close tab |
| `,tl` | Toggle to last tab |

### Code Intelligence (CoC / vim-lsp)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `gi` | Go to implementation |
| `gr` | Show references |
| `K` | Hover documentation |
| `[g` | Previous diagnostic |
| `]g` | Next diagnostic |
| `,rn` | Rename symbol |
| `,f` | Format selection |
| `,ca` | Code action (cursor) |
| `,o` | File outline |
| `,ws` | Workspace symbols |
| `,cD` | Diagnostics list |
| `,cr` | Resume last CoC list |
| `,qf` | Quick-fix current line (CoC) |
| `,cl` | Run code lens (CoC) |
| `Tab` | Next completion item |
| `Shift+Tab` | Previous completion item |
| `Enter` | Confirm completion |

Text objects (CoC only): `if`/`af` (function), `ic`/`ac` (class)

### Linting (ALE)

| Key | Action |
|-----|--------|
| `[e` | Next error/warning |
| `]e` | Previous error/warning |
| `,aD` | Show error details |

Signs: `X` = error, `!` = warning

### Git Workflow (fugitive)

| Key | Action |
|-----|--------|
| `,gs` | Git status |
| `,gc` | Git commit |
| `,gp` | Git push |
| `,gl` | Git pull |
| `,gd` | Git diff |
| `,gb` | Git blame |
| `,gF` | Search git-tracked files (FZF) |

### Engineering Utilities

| Key | Action |
|-----|--------|
| `,ev` | Edit `~/.vimrc` |
| `,sv` | Reload `~/.vimrc` |
| `,F` | Format entire file |
| `,W` | Strip trailing whitespace |
| `,wa` | Save all open buffers |
| `,wd` | Change CWD to current buffer's dir |
| `,cp` | Copy file path to clipboard |
| `,cf` | Copy filename to clipboard |
| `,y` | Yank to system clipboard |
| `,Y` | Yank line to system clipboard |
| `,*` | Search+replace word under cursor |
| `,qo` | Open quickfix list |
| `,qc` | Close quickfix list |
| `,tv` | Open terminal (vertical split) |
| `,th` | Open terminal (horizontal, 10 rows) |
| `Esc` | Exit terminal mode |

### Navigation and Editing

| Key | Action |
|-----|--------|
| `s`+2ch | EasyMotion jump to any location |
| `Space` | Toggle code fold |
| `Y` | Yank to end of line (like `D`, `C`) |
| `n` / `N` | Search next/prev (cursor centered) |
| `Ctrl+d/u` | Half-page scroll (cursor centered) |
| `>` | Indent (keeps visual selection) |
| `<` | Dedent (keeps visual selection) |
| `[q` / `]q` | Previous/next quickfix (vim-unimpaired) |
| `[e` / `]e` | Previous/next ALE error/warning |
| `F2` | Toggle paste mode |
| `F3` | Toggle line numbers |
| `F4` | Toggle relative line numbers |
| `F5` | Toggle undo history (UndoTree) |
| `F8` | Toggle code tag browser (Tagbar) |
| `0` | Jump to first non-blank character |
| `Alt+j/k` | Move line up/down |

---

## Features

### Startup Screen (vim-startify)

Opens when Vim is launched without a file argument. Shows:
- Session list for current directory
- Recently opened files
- Bookmarks

Session auto-saves on quit. Auto-loads `Session.vim` if found in the current
directory. Auto-changes to git root on file open.

**`vim .` layout** — NERDTree on the left, Startify on the right.

### Keybinding Guide (vim-which-key)

Press `,` and pause for 500ms. A popup lists all available leader bindings
organized by group. Useful for onboarding and discovering shortcuts.

### Session Management

```vim
:Obsess              " Start tracking session
:Obsess!             " Stop tracking
```

Sessions stored in `~/.vim/sessions/` and automatically resumed by vim-prosession
on the next Vim launch in the same directory.

### Project-Local Config

Place a `.vimrc` in any project root:

```vim
" project/.vimrc
set shiftwidth=2
let g:ale_python_black_options = '--line-length=100'
```

Loaded automatically. Security-restricted via `set secure`.

### Large File Handling

Files over 10 MB automatically disable syntax highlighting and undo history
to prevent Vim from freezing.

### TTY / Console Support

Detected automatically when `$TERM` is `linux` or `screen`. In TTY mode:
- True color and cursorline disabled
- Powerline separators replaced with plain ASCII
- FZF preview windows disabled
- NERDTree auto-open skipped
- Syntax column limit reduced to 120
- Simpler status line

---

## Language Support

| Language | Indent | Formatter | Linter | LSP (CoC) |
|----------|--------|-----------|--------|-----------|
| Python | 4sp | black + isort | flake8, pylint | coc-pyright |
| JavaScript | 2sp | prettier | eslint | coc-tsserver |
| TypeScript | 2sp | prettier | eslint, tsserver | coc-tsserver |
| Go | tab | gofmt, goimports | staticcheck | coc-go |
| Rust | 4sp | rustfmt | cargo | coc-rust-analyzer |
| Shell | 2sp | — | shellcheck | coc-sh |
| YAML | 2sp | prettier | yamllint | coc-yaml |
| HTML | 2sp | prettier | — | coc-html |
| CSS / SCSS | 2sp | prettier | stylelint | coc-css |
| Less | 2sp | prettier | — | — |
| JSON | 2sp | prettier | — | coc-json |
| Markdown | 2sp | prettier | markdownlint | marksman (coc-settings.json) |
| SQL | 4sp | sqlfluff | sqlfluff | — |
| Dockerfile | 2sp | — | hadolint | — |

`install.sh` installs all linters and formatters automatically.
ALE runs them asynchronously; format-on-save active when using CoC.

---

## Plugin List

### Navigation
- **NERDTree** — File tree explorer
- **fzf + fzf.vim** — Fuzzy finder (file, buffer, tag, ripgrep)

### Git
- **vim-fugitive** — Git commands inside Vim
- **vim-gitgutter** — Diff signs in the sign column

### LSP and Completion
- **coc.nvim** — Full LSP + completion (requires Node.js 14.14+)
- **vim-lsp** — Pure VimScript LSP client (fallback, no Node.js)
- **vim-lsp-settings** — Auto-configure language servers for vim-lsp
- **asyncomplete.vim** — Async completion (used with vim-lsp)

### Linting
- **ALE** — Asynchronous Lint Engine (always active)

### UI
- **vim-airline** — Status and tabline
- **vim-startify** — Startup screen with sessions
- **vim-which-key** — Keybinding hint popup
- **indentLine** — Indent guide lines (non-TTY)
- **undotree** — Undo history visualizer
- **tagbar** — Code structure sidebar

### Editing
- **vim-surround** — Change surrounding quotes, brackets, tags
- **vim-commentary** — `gc` to toggle comments
- **auto-pairs** — Auto-close brackets and quotes
- **vim-easymotion** — Jump anywhere with 2 keystrokes
- **vim-unimpaired** — Bracket shortcut pairs
- **targets.vim** — Extra text objects
- **vim-snippets** — Snippet library (used with CoC/UltiSnips)

### Language Packs
- **vim-polyglot** — Syntax for 100+ languages
- **vim-go** — Go development tools (formatting + highlighting; LSP handled by coc-go)

### Session
- **vim-obsession** — Continuous session saving
- **vim-prosession** — Project-level session management

### Color Schemes
- **gruvbox** (default), **dracula**, **solarized**, **onedark**

---

## Color Scheme

Change in `.vimrc` (find the `colorscheme` line):

```vim
colorscheme dracula    " or: gruvbox, solarized, onedark
```

True color is enabled automatically when the terminal supports it
(`$COLORTERM=truecolor`). Falls back to 256-color, then 16-color (TTY).

---

## Troubleshooting

**Plugins not installed:**
```vim
:PlugInstall
:PlugUpdate
```

**CoC not working:**
```bash
node --version   # must be >= 14.14
```

**Markdown LSP not starting:**
```bash
marksman --version   # must be installed separately
brew install marksman           # macOS
sudo pacman -S marksman         # Arch
# or: ./install.sh (installs automatically)
```

**vim-lsp server not starting:**
```vim
:LspInstallServer          " install server for current filetype
:LspStatus                 " check server status
```

**Colors look wrong:**
```bash
export TERM=xterm-256color   # add to ~/.bashrc or ~/.zshrc
```

**ALE not finding linters:**
```bash
which flake8 black prettier eslint   # confirm tools are on PATH
```

---

## References

- [vim-plug](https://github.com/junegunn/vim-plug)
- [coc.nvim](https://github.com/neoclide/coc.nvim)
- [vim-lsp](https://github.com/prabirshrestha/vim-lsp)
- [vim-lsp-settings](https://github.com/mattn/vim-lsp-settings)
- [amix/vimrc](https://github.com/amix/vimrc)

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE) © m1ng
