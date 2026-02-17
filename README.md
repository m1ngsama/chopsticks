# chopsticks - Vim Configuration

A native Vim configuration optimized for engineering workflows. Designed for
Vim 8.0+ with automatic fallbacks for minimal environments (TTY, no Node.js).

## Quick Install

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh
```

See [QUICKSTART.md](QUICKSTART.md) for the 5-minute guide.

---

## Design Principles

- **KISS**: No icon fonts, no unicode glyphs, plain ASCII throughout
- **Tiered LSP**: CoC (full) with vim-lsp fallback - works with or without Node.js
- **TTY-aware**: Automatic detection and optimization for console environments
- **Engineering-first**: Git workflow, session management, project-local config

---

## Requirements

| Requirement    | Minimum     | Notes                          |
|----------------|-------------|--------------------------------|
| Vim            | 8.0+        | vim9script not required        |
| git            | any         | For cloning and fugitive       |
| curl           | any         | For vim-plug auto-install      |
| Node.js        | 14.14+      | Optional, enables CoC LSP      |
| ripgrep (rg)   | any         | Optional, enables :Rg search   |
| fzf            | any         | Optional, enables :Files/:GFiles |
| ctags          | any         | Optional, enables :TagbarToggle |

---

## Installation

### Automatic

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim
./install.sh
```

The script:
1. Checks for a working Vim installation
2. Backs up your existing `~/.vimrc` if present
3. Creates a symlink: `~/.vimrc -> ~/.vim/.vimrc`
4. Installs vim-plug
5. Runs `:PlugInstall` to download all plugins
6. Optionally installs CoC language servers (if Node.js is available)

### Manual

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
ln -sf ~/.vim/.vimrc ~/.vimrc
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall
```

---

## LSP: Tiered Backend System

Code intelligence is provided by one of two backends, selected automatically:

| Condition                        | Backend        | Features                                      |
|----------------------------------|----------------|-----------------------------------------------|
| Vim 8.0.1453+ AND Node.js 14.14+ | **CoC**        | Full LSP, snippets, extensions ecosystem      |
| Vim 8.0+ (no Node.js)            | **vim-lsp**    | LSP via language server binaries, asyncomplete|
| Any Vim                          | **ALE**        | Linting and auto-fix (always active)          |

Both backends expose identical key mappings (`gd`, `K`, `[g`, `]g`, `<leader>rn`, `<leader>ca`).

### CoC setup (with Node.js)

Install language server extensions from inside Vim:

```vim
:CocInstall coc-pyright       " Python
:CocInstall coc-tsserver      " JavaScript / TypeScript
:CocInstall coc-go            " Go
:CocInstall coc-rust-analyzer " Rust
:CocInstall coc-json coc-yaml " JSON, YAML
:CocInstall coc-html coc-css  " HTML, CSS
```

### vim-lsp setup (without Node.js)

Install language server binaries for your languages, then run:

```vim
:LspInstallServer   " auto-installs servers for the current filetype
```

Supported: `pylsp`, `gopls`, `rust-analyzer`, `typescript-language-server`,
`bash-language-server`, and all others covered by `vim-lsp-settings`.

---

## Key Mappings

Leader key: `,` (comma)

Press `,` and wait 500ms for an interactive guide to all bindings (vim-which-key).

### Files and Buffers

| Key        | Action                              |
|------------|-------------------------------------|
| `Ctrl+n`   | Toggle file tree (NERDTree)         |
| `,n`       | Reveal current file in NERDTree     |
| `Ctrl+p`   | Fuzzy file search (FZF)             |
| `,b`       | Search open buffers (FZF)           |
| `,rg`      | Project-wide search (ripgrep+FZF)   |
| `,l`       | Next buffer                         |
| `,h`       | Previous buffer                     |
| `,bd`      | Close current buffer                |
| `,,`       | Switch to last file                 |

### Windows and Tabs

| Key          | Action                          |
|--------------|---------------------------------|
| `Ctrl+h/j/k/l` | Navigate between windows      |
| `<Leader>=`  | Increase window height          |
| `<Leader>-`  | Decrease window height          |
| `<Leader>+`  | Increase window width           |
| `<Leader>_`  | Decrease window width           |
| `,tn`        | New tab                         |
| `,tc`        | Close tab                       |
| `,tl`        | Toggle to last tab              |

### Code Intelligence (CoC / vim-lsp)

| Key         | Action                          |
|-------------|---------------------------------|
| `gd`        | Go to definition                |
| `gy`        | Go to type definition           |
| `gi`        | Go to implementation            |
| `gr`        | Show references                 |
| `K`         | Hover documentation             |
| `[g`        | Previous diagnostic             |
| `]g`        | Next diagnostic                 |
| `,rn`       | Rename symbol                   |
| `,f`        | Format selection                |
| `,ca`       | Code action (cursor)            |
| `,qf`       | Quick-fix current line (CoC)    |
| `,cl`       | Run code lens (CoC)             |
| `,o`        | File outline                    |
| `,ws`       | Workspace symbols               |
| `,cd`       | Diagnostics list                |
| `Tab`       | Next completion item            |
| `Shift+Tab` | Previous completion item        |
| `Enter`     | Confirm completion              |

Text objects (CoC only): `if`/`af` (function), `ic`/`ac` (class)

### Linting (ALE)

| Key    | Action                |
|--------|-----------------------|
| `,aj`  | Next error/warning    |
| `,ak`  | Previous error/warning|
| `,ad`  | Show error details    |

Signs: `X` = error, `!` = warning

### Git Workflow (fugitive)

| Key    | Action         |
|--------|----------------|
| `,gs`  | Git status     |
| `,gc`  | Git commit     |
| `,gp`  | Git push       |
| `,gl`  | Git pull       |
| `,gd`  | Git diff       |
| `,gb`  | Git blame      |

### Engineering Utilities

| Key      | Action                          |
|----------|---------------------------------|
| `,ev`    | Edit `~/.vimrc`                 |
| `,sv`    | Reload `~/.vimrc`               |
| `,F`     | Format entire file (= indent)   |
| `,W`     | Strip trailing whitespace       |
| `,wa`    | Save all open buffers           |
| `,cp`    | Copy file path to clipboard     |
| `,cf`    | Copy filename to clipboard      |
| `,*`     | Search+replace word under cursor|
| `,tv`    | Open terminal (vertical split)  |
| `,th`    | Open terminal (horizontal, 10r) |
| `Esc`    | Exit terminal mode              |

### Navigation and Editing

| Key      | Action                               |
|----------|--------------------------------------|
| `s`+2ch  | EasyMotion jump to any location      |
| `Space`  | Toggle code fold                     |
| `F2`     | Toggle paste mode                    |
| `F3`     | Toggle line numbers                  |
| `F4`     | Toggle relative line numbers         |
| `F5`     | Toggle undo history (UndoTree)       |
| `F8`     | Toggle code tag browser (Tagbar)     |
| `0`      | Jump to first non-blank character    |
| `Alt+j`  | Move line down                       |
| `Alt+k`  | Move line up                         |

---

## Features

### vim-startify: Startup Screen

Opens when Vim is launched without a file argument. Shows:
- Recently opened files
- Sessions for the current directory
- Bookmarks

Session auto-saves on quit. Auto-loads `Session.vim` if found in the current
directory. Auto-changes to git root on file open.

### vim-which-key: Keybinding Guide

Press `,` and pause for 500ms. A popup lists all available leader bindings
organized by group. Useful for onboarding and discovering shortcuts.

### indentLine: Indent Guides

Draws `|` characters at each indent level. Disabled automatically in TTY
environments and for filetypes where it causes display problems (JSON,
Markdown, help).

### Session Management

```vim
:Obsess              " Start tracking session
:Obsess!             " Stop tracking
```

Sessions are stored in `~/.vim/sessions/` and automatically resumed by
vim-prosession on the next Vim launch in the same directory.

### Project-Local Config

Place a `.vimrc` in any project root:

```vim
" project/.vimrc
set shiftwidth=2
let g:ale_python_black_options = '--line-length=100'
```

Loaded automatically. Security-restricted via `set secure`.

### Large File Handling

Files over 10MB automatically disable syntax highlighting and undo history
to prevent Vim from freezing.

### TTY / Console Support

Detected automatically when `$TERM` is `linux` or `screen`, or when running
on a basic built-in terminal. In TTY mode:

- True color and cursorline disabled
- Powerline separators replaced with plain ASCII
- FZF preview windows disabled
- NERDTree auto-open skipped
- Syntax column limit reduced to 120
- Simpler status line used

---

## Language Support

| Language       | Indent | Formatter     | Linter              |
|----------------|--------|---------------|---------------------|
| Python         | 4sp    | black + isort | flake8, pylint      |
| JavaScript     | 2sp    | prettier      | eslint              |
| TypeScript     | 2sp    | prettier      | eslint, tsserver    |
| Go             | tab    | gofmt, goimports | gopls, golint    |
| Rust           | 4sp    | rustfmt       | cargo               |
| Shell          | 2sp    | -             | shellcheck          |
| YAML           | 2sp    | prettier      | yamllint            |
| HTML/CSS       | 2sp    | prettier      | -                   |
| Markdown       | 2sp    | prettier      | -                   |
| JSON           | 2sp    | prettier      | -                   |
| Dockerfile     | 2sp    | -             | hadolint            |

Install linters separately (e.g. `pip install black flake8`, `npm i -g prettier`).
ALE runs them asynchronously and auto-fixes on save.

---

## Plugin List

### Navigation
- **NERDTree** - File tree explorer
- **fzf + fzf.vim** - Fuzzy finder
- **CtrlP** - Fallback fuzzy finder (no fzf dependency)

### Git
- **vim-fugitive** - Git commands inside Vim
- **vim-gitgutter** - Diff signs in the sign column

### LSP and Completion
- **coc.nvim** - Full LSP + completion (requires Node.js 14.14+)
- **vim-lsp** - Pure VimScript LSP client (fallback, no Node.js)
- **vim-lsp-settings** - Auto-configure language servers for vim-lsp
- **asyncomplete.vim** - Async completion (used with vim-lsp)

### Linting
- **ALE** - Asynchronous Lint Engine (always active)

### UI
- **vim-airline** - Status and tabline
- **vim-startify** - Startup screen
- **vim-which-key** - Keybinding hint popup
- **indentLine** - Indent guide lines (non-TTY)
- **undotree** - Undo history visualizer
- **tagbar** - Code structure sidebar

### Editing
- **vim-surround** - Change surrounding quotes, brackets, tags
- **vim-commentary** - `gc` to toggle comments
- **auto-pairs** - Auto-close brackets and quotes
- **vim-easymotion** - Jump anywhere with 2 keystrokes
- **vim-unimpaired** - Bracket shortcut pairs
- **targets.vim** - Extra text objects
- **vim-snippets** - Snippet library (used with CoC/UltiSnips)

### Language Packs
- **vim-polyglot** - Syntax for 100+ languages
- **vim-go** - Go development tools

### Session
- **vim-obsession** - Continuous session saving
- **vim-prosession** - Project-level session management

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

**vim-lsp server not starting:**
```vim
:LspInstallServer          " install server for current filetype
:LspStatus                 " check server status
```

**Colors look wrong:**
```bash
# Add to ~/.bashrc or ~/.zshrc
export TERM=xterm-256color
```

**ALE not finding linters:**
```bash
which flake8 black prettier eslint   # confirm tools are on PATH
```

---

## References

- [amix/vimrc](https://github.com/amix/vimrc)
- [vim-plug](https://github.com/junegunn/vim-plug)
- [coc.nvim](https://github.com/neoclide/coc.nvim)
- [vim-lsp](https://github.com/prabirshrestha/vim-lsp)
- [vim-lsp-settings](https://github.com/mattn/vim-lsp-settings)

## License

MIT
