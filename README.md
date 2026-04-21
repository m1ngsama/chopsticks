# chopsticks

> Flowing vim for any machine — SSH servers included.
> Solarized · vim-lsp (no Node.js) · Markdown-first · One-command install.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Vim 8.0+](https://img.shields.io/badge/Vim-8.0%2B-brightgreen?style=flat-square)](https://www.vim.org/)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey?style=flat-square)](#installation)
[![Release](https://img.shields.io/github/v/release/m1ngsama/chopsticks?style=flat-square&label=release&color=orange)](https://github.com/m1ngsama/chopsticks/releases)
[![Last Commit](https://img.shields.io/github/last-commit/m1ngsama/chopsticks?style=flat-square)](https://github.com/m1ngsama/chopsticks/commits/main)
[![Stars](https://img.shields.io/github/stars/m1ngsama/chopsticks?style=flat-square)](https://github.com/m1ngsama/chopsticks/stargazers)

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

---

## Contents

- [Design Principles](#design-principles)
- [Requirements](#requirements)
- [Installation](#installation)
- [LSP](#lsp)
- [Key Mappings](#key-mappings)
- [Markdown](#markdown)
- [Features](#features)
- [Plugins](#plugins)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

---

## Design Principles

| Principle | What it means |
|-----------|--------------|
| **Flowing writing** | Every plugin earns its place by reducing interruptions to thought |
| **No Node.js** | vim-lsp runs on pure VimScript — works on any machine, including SSH servers |
| **Solarized** | One palette, everywhere — vim statusline matches tmux bar exactly |
| **TTY-aware** | SSH and console environments degrade gracefully without breaking |
| **KISS** | No icon fonts, no Nerd Font glyphs — plain ASCII throughout |

---

## Requirements

| Tool | Role |
|------|------|
| Vim 8.0+ | Required — `install.sh` installs it if missing |
| git | Required |
| curl | Required |
| ripgrep | Recommended — enables `,rg` project search |
| fzf | Recommended — enables `Ctrl+p` fuzzy finder |
| Node.js | Optional — enables npm formatters (prettier, eslint) |

`install.sh` detects your environment and installs missing dependencies.

---

## Installation

### One command

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

Non-interactive / CI:

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash -s -- --yes
```

### Git clone

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh
```

### What the installer does

1. Detects OS and package manager
2. Verifies or installs `curl`, `git`, `vim`
3. Backs up existing `~/.vimrc`, then symlinks `~/.vimrc → ~/.vim/.vimrc`
4. Installs vim-plug and runs `:PlugInstall`
5. Offers to install system tools (ripgrep, fzf, ctags, shellcheck, hadolint, marksman)
6. Offers to install npm formatters (prettier, eslint, etc.) — requires Node.js
7. Offers to install Python formatters/linters (black, isort, flake8, etc.)
8. Offers to install Go tools (gopls, goimports, staticcheck)
9. Offers to append vim-tmux-navigator bindings to `~/.tmux.conf`

**Supported platforms:** macOS (Homebrew), Debian/Ubuntu (apt), Arch (pacman), Fedora (dnf).

---

## LSP

Code intelligence is provided by **vim-lsp** — a pure VimScript LSP client with no
Node.js dependency. It works on any machine, including servers accessed via SSH.

Install a language server for the current file:

```vim
:LspInstallServer   " auto-detects filetype and installs the correct server
:LspStatus          " check server status
```

Supported languages and their servers:

| Language | Server |
|----------|--------|
| Python | pylsp / pyright |
| JavaScript / TypeScript | typescript-language-server |
| Go | gopls |
| Rust | rust-analyzer |
| C / C++ | clangd |
| Shell | bash-language-server |
| HTML | vscode-html-language-server |
| CSS / SCSS | vscode-css-language-server |
| JSON | vscode-json-language-server |
| YAML | yaml-language-server |
| Markdown | marksman |
| SQL | sqls |

**Note:** While vim-lsp itself needs no Node.js, some language servers (TypeScript,
HTML, CSS, JSON, YAML) are npm packages that require Node.js to run. Python (pylsp),
Go (gopls), and Rust (rust-analyzer) language servers do not need Node.js.

**Markdown LSP** requires `marksman` as a standalone binary:

```bash
brew install marksman    # macOS
sudo pacman -S marksman  # Arch
# or: install.sh handles it automatically
```

---

## Key Mappings

**Leader key:** `,` (comma)

Press `,?` at any time to open the built-in cheat sheet.

### Files and Buffers

| Key | Action |
|-----|--------|
| `Ctrl+p` | Fuzzy file search — git-aware (FZF) |
| `,e` | Open netrw file browser |
| `,E` | Open netrw in vertical split |
| `,b` | Search open buffers (FZF) |
| `,rg` | Project-wide search (ripgrep + FZF) |
| `,rG` | Ripgrep word under cursor (fixed-string) |
| `,,` | Switch to last file |
| `,l` / `,h` | Next / previous buffer |
| `,bd` | Close current buffer (preserves window layout) |
| `,wa` | Save all open buffers |
| `,cd` | Change working directory to current file's directory |

### Code Intelligence (vim-lsp)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `gi` | Go to implementation |
| `gr` | Show references |
| `K` | Hover documentation |
| `[g` / `]g` | Previous / next LSP diagnostic |
| `[e` / `]e` | Previous / next ALE error |
| `,rn` | Rename symbol |
| `,f` | Format buffer / selection |
| `,ca` | Code action |
| `,o` | File outline (symbols) |
| `,ws` | Workspace symbols |
| `Tab` / `Shift+Tab` | Navigate completion popup |
| `Enter` | Confirm completion |

### Markdown

| Key | Action |
|-----|--------|
| `,mp` | Open live preview in browser (previm) |
| `,mt` | Table of contents (side window) |
| `zr` / `zm` | Unfold / fold all headings |

### Git (vim-fugitive)

| Key | Action |
|-----|--------|
| `,gs` | Git status |
| `,gc` | Git commit |
| `,gp` | Git push |
| `,gl` | Git pull |
| `,gd` | Git diff |
| `,gb` | Git blame |

### Editing

| Key | Action |
|-----|--------|
| `s` + 2 chars | EasyMotion — jump anywhere on screen |
| `gc` | Toggle comment (visual mode too) |
| `Space` | Toggle code fold |
| `Y` | Yank to end of line |
| `Ctrl+d` / `Ctrl+u` | Half-page scroll, cursor centred |
| `Alt+j` / `Alt+k` | Move line down / up (normal and visual) |
| `,u` | Undo tree (visual branch history) |
| `F2` | Toggle paste mode |
| `F3` / `F4` | Toggle line numbers / relative numbers |
| `F5` | Toggle undo tree |
| `F6` | Toggle invisible characters |
| `gV` | Reselect last paste |
| `//` | Search visual selection |

### Survival

| Key | Action |
|-----|--------|
| `jk` | Exit insert mode |
| `Esc` | Exit insert / visual mode |
| `jk` | Exit insert mode |
| `Ctrl+s` | Save (any mode) |
| `,w` | Save |
| `,x` | Save and quit |
| `,q` | Quit |
| `,?` | Open cheat sheet |

### Windows, Tabs, tmux

| Key | Action |
|-----|--------|
| `Ctrl+h/j/k/l` | Navigate Vim splits **and** tmux panes |
| `,tv` / `,th` | Open terminal (vertical / horizontal split) |
| `Esc Esc` | Exit terminal mode |
| `,tn` / `,tc` | New tab / close tab |
| `,tl` | Toggle to last tab |
| `,ev` / `,sv` | Edit / reload `~/.vimrc` |
| `,cp` / `,cf` | Copy file path / filename to clipboard |
| `,*` | Search and replace word under cursor |
| `,F` | Re-indent entire file |
| `,W` | Strip trailing whitespace |
| `,ms` | Open scratch markdown buffer |
| `,ss` | Toggle spell checking |

---

## Markdown

chopsticks treats Markdown as a first-class language.

### In-buffer rendering (concealment)

`vim-markdown` hides syntax markers and renders formatting inline:
- `**bold**` displays as bold text
- `# Heading` hides the `#` characters
- Tables align automatically

The raw syntax reappears when the cursor enters that line.

### Live browser preview (previm)

```vim
,mp    " open rendered preview in browser — updates on every save
```

No Node.js required. Uses `open` (macOS) or `xdg-open` (Linux).

### Table of contents

```vim
,mt    " open TOC in a side window — press Enter to jump to heading
```

---

## Features

### Statusline

A native, hand-written statusline using the Solarized palette:

```
 N  ~/.vimrc [+]                  main  [vim]  42:7  68%
```

- Mode block changes colour by mode (Normal=yellow, Insert=blue, Visual=magenta, Replace=red)
- Git branch via vim-fugitive
- Background matches tmux status bar for a seamless bottom band

### Session Management

```vim
:Obsess     " start tracking the current session
:Obsess!    " stop tracking
```

Sessions auto-restore when you open Vim in the same directory.

### Project-Local Config

Drop a `.vimrc` in any project root to override settings:

```vim
" my-project/.vimrc
set shiftwidth=2
let g:ale_python_black_options = '--line-length=100'
```

### tmux Integration

`Ctrl+h/j/k/l` navigates seamlessly between Vim splits and tmux panes.

Add to `~/.tmux.conf` (or let `install.sh` append it):

```tmux
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\S+\/)?g?(view|n?vim?x?)(diff)?$'"
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
```

### TTY / SSH Support

Detected automatically when `$TERM` is unset, `dumb`, `linux`, `screen`, or contains `builtin`. In TTY mode:

- True colour and cursorline disabled
- FZF preview windows disabled
- IndentLine guides disabled
- Simplified statusline (no colour)
- Syntax column limit reduced to 120 characters

### Large File Handling

Files over 10 MB automatically disable syntax highlighting, undo history, and
linting to prevent stalling.

---

## Plugins

### Navigation
- **fzf + fzf.vim** — fuzzy finder for files, buffers, tags, ripgrep

### Git
- **vim-fugitive** — full Git integration
- **vim-gitgutter** — diff signs in the sign column

### LSP and Completion
- **vim-lsp** — pure VimScript LSP client
- **vim-lsp-settings** — auto-configures language servers
- **asyncomplete.vim** — async completion engine
- **asyncomplete-lsp.vim** — LSP completion source

### Linting and Formatting
- **ALE** — async linting and format-on-save

### Markdown
- **vim-markdown** — folding, concealment, table alignment
- **previm** — live browser preview

### Language Syntax
- **vim-javascript** — enhanced JS syntax
- **yats.vim** — TypeScript syntax
- **vim-go** — Go syntax and tooling

### Editing
- **vim-surround** — change/delete/add surroundings
- **vim-commentary** — `gc` to toggle comments
- **vim-repeat** — repeat plugin maps with `.`
- **vim-unimpaired** — bracket shortcut pairs
- **targets.vim** — additional text objects
- **auto-pairs** — auto-close brackets and quotes
- **vim-easymotion** — `s` + 2 chars to jump anywhere

### UI
- **vim-solarized8** — color scheme (truecolor support)
- **undotree** — visual undo branch history
- **vim-startify** — startup dashboard and session list
- **indentLine** — indent guides (non-TTY)

### Session and Navigation
- **vim-obsession** — session tracking
- **vim-tmux-navigator** — seamless Vim/tmux pane navigation

---

## Customization

### Per-project overrides

Create `.vimrc` in your project root:

```vim
" project/.vimrc
set shiftwidth=2
let g:ale_python_black_options = '--line-length=120'
```

### Modify keybindings

Edit `~/.vimrc` directly (`,ev` opens it from inside Vim). Reload with `,sv`.

---

## Troubleshooting

**Plugins not loading**

```vim
:PlugInstall    " install missing plugins
:PlugUpdate     " update all plugins
```

**LSP server not starting**

```vim
:LspInstallServer   " install server for current filetype
:LspStatus          " check server status
```

**Markdown preview not opening**

`previm` uses `open` (macOS) or `xdg-open` (Linux). Make sure a browser is
set as the default handler for HTML files.

**Colors look wrong**

```bash
export TERM=xterm-256color       # add to ~/.bashrc or ~/.zshrc
export COLORTERM=truecolor       # for true colour
```

**ALE linters not found**

```bash
which flake8 black prettier eslint   # verify tools are on PATH
```

**`Ctrl+s` freezes the terminal**

Add `stty -ixon` to your `~/.bashrc`, `~/.zshrc`, or `~/.config/fish/config.fish`.

---

## License

[MIT](LICENSE) © m1ng
