# chopsticks

> Flowing vim for any machine — SSH servers included.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Vim 8.0+](https://img.shields.io/badge/Vim-8.0%2B-brightgreen?style=flat-square)](https://www.vim.org/)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey?style=flat-square)](#installation)
[![Release](https://img.shields.io/github/v/release/m1ngsama/chopsticks?style=flat-square&label=release&color=orange)](https://github.com/m1ngsama/chopsticks/releases)

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

---

## What You Get

**30 plugins. One command. Zero Node.js dependency.**

| Feature | What it does |
|---------|-------------|
| **LSP everywhere** | Completion, go-to-definition, hover docs, rename — pure VimScript, works over SSH |
| **Format on save** | ALE runs black, prettier, gofmt automatically. Errors show in statusline. |
| **Fuzzy everything** | Files, buffers, grep, tags, marks, command history — all via FZF with preview |
| **Zen mode** | Goyo + Limelight: distraction-free writing. `,zen` and the world disappears |
| **Run any file** | `,cr` detects filetype and runs it: Python, Go, Rust, JS, C, Shell, and more |
| **Smart indentation** | vim-sleuth auto-detects tabs vs spaces from existing files. No config needed. |
| **Yank highlight** | Yanked text flashes — instant visual feedback, never guess what you copied |
| **Search that clears** | Search highlights disappear after you stop moving. No more `,<cr>` spam. |
| **Git workflow** | Status, diff, blame, push, pull. Conflict marker navigation with `[x`/`]x`. |
| **Window maximize** | `,z` toggles current split to full screen and back. |
| **Sudo save** | `:w!!` when you forgot to open as root |
| **ALE in statusline** | Error and warning counts always visible — no surprises |
| **30+ key mappings** | Every common action is one or two keystrokes away. `,?` shows them all. |
| **TTY-aware** | SSH, console, slow connections — degrades gracefully, never breaks |

---

## Installation

### One command

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

### Git clone

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh
```

### Non-interactive / CI

```bash
curl -fsSL ... | bash -s -- --yes
```

**Supported:** macOS (Homebrew), Debian/Ubuntu (apt), Arch (pacman), Fedora (dnf).

The installer detects your environment, installs vim-plug, plugins, and offers
system tools (ripgrep, fzf, ctags, shellcheck, marksman) plus language-specific
formatters and linters.

---

## Key Mappings

**Leader key:** `,` (comma). Press `,?` to open the built-in cheat sheet.

### Files and Search

| Key | Action |
|-----|--------|
| `Ctrl+p` | Fuzzy file search — git-aware |
| `,b` | Search open buffers |
| `,rg` | Project-wide ripgrep search |
| `,rG` | Ripgrep word under cursor |
| `,fh` | Recent files history |
| `,fl` / `,fL` | Search lines in buffer / all buffers |
| `,fc` | Commands | `,fm` Marks |
| `,f/` / `,f:` | Search / command history |
| `,e` / `,E` | File browser / vertical split |
| `,,` | Switch to last file |
| `,cd` | Change CWD to current file's directory |

### Code Intelligence (vim-lsp)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gy` | Type definition |
| `gi` | Implementation |
| `gr` | References |
| `K` | Hover documentation |
| `[g` / `]g` | Previous / next LSP diagnostic |
| `[e` / `]e` | Previous / next ALE error |
| `,rn` | Rename symbol |
| `,f` | Format buffer / selection |
| `,ca` | Code action |
| `,o` | File outline (symbols) |
| `,ws` | Workspace symbols |
| `,cr` | **Run current file** (auto-detects language) |

Install LSP servers on demand:
```vim
:LspInstallServer   " auto-detects filetype
:LspStatus          " check server status
```

| Language | Server |
|----------|--------|
| Python | pylsp |
| JS / TS | typescript-language-server |
| Go | gopls |
| Rust | rust-analyzer |
| C / C++ | clangd |
| Shell | bash-language-server |
| HTML / CSS / JSON / YAML | vscode-*-language-server |
| Markdown | marksman |
| SQL | sqls |

### Markdown and Writing

| Key | Action |
|-----|--------|
| `,zen` | **Zen mode** — Goyo + Limelight, distraction-free |
| `,mp` | Live browser preview (previm) |
| `,mt` | Table of contents |
| `zr` / `zm` | Unfold / fold all headings |

Markdown buffers automatically enable `wrap`, `spell`, and concealment
(bold renders as bold, headings hide `#` markers, raw syntax shows on cursor line).

### Git

| Key | Action |
|-----|--------|
| `,gs` | Status |
| `,gd` | Diff |
| `,gb` | Blame |
| `,gc` | Commit |
| `,gp` | Push |
| `,gl` | Pull |
| `[x` / `]x` | Navigate conflict markers |

### Editing

| Key | Action |
|-----|--------|
| `s` + 2 chars | EasyMotion — jump anywhere on screen |
| `gc` | Toggle comment (works in visual mode) |
| `Y` | Yank to end of line |
| `,y` / `,Y` | Yank to system clipboard |
| `Alt+j` / `Alt+k` | Move line down / up |
| `,u` | Undo tree (visual branch history) |
| `,F` | Re-indent entire file |
| `,W` | Strip trailing whitespace |
| `,*` | Search and replace word under cursor |
| `gV` | Reselect last paste |
| `//` | Search visual selection |

### Windows and Navigation

| Key | Action |
|-----|--------|
| `Ctrl+h/j/k/l` | Navigate Vim splits **and** tmux panes |
| `,z` | **Maximize / restore** current window |
| `,h` / `,l` | Previous / next buffer |
| `,bd` | Close buffer (keep window layout) |
| `,tv` / `,th` | Terminal (vertical / horizontal) |
| `Esc Esc` | Exit terminal mode |
| `]q` / `[q` | Next / previous quickfix entry |
| `Ctrl+d` / `Ctrl+u` | Half-page scroll, cursor centred |

### Quick Reference

| Key | Action |
|-----|--------|
| `,?` | Open built-in cheat sheet |
| `jk` | Exit insert mode |
| `Ctrl+s` | Save (any mode) |
| `:w!!` | Sudo save |
| `,w` / `,x` / `,q` | Save / save+quit / quit |
| `,ev` / `,sv` | Edit / reload `~/.vimrc` |
| `,so` | Source current vim file |
| `F2` Paste | `F3` Line# | `F4` Relative# | `F6` Invisible chars |

---

## Features

### Statusline

Native, hand-written. Solarized palette. Shows mode, file, git branch, filetype,
ALE error/warning count, and cursor position. Background matches tmux bar.

```
 N  ~/.vimrc [+]              E:1 W:3   main  [vim]  42:7  68%
```

Mode block changes colour: Normal=yellow, Insert=blue, Visual=magenta, Replace=red.

### Smart Defaults

- **vim-sleuth** auto-detects indentation from existing files
- **Yank highlight** flashes copied text for 150ms
- **Search highlight** auto-clears after cursor stops moving
- **QuickFix** auto-opens after `:grep`, `:make`, or `:Rg`
- **Format on save** via ALE (black, prettier, gofmt, rustfmt, etc.)
- **Auto-create directories** on save — write to `new/path/file.txt` without `mkdir` first
- **Cursor restore** — reopens files at the last cursor position

### Session Management

```vim
:Obsess     " start tracking the current session
:Obsess!    " stop tracking
```

Sessions auto-restore when you open Vim in the same directory.

### TTY / SSH Support

Detected automatically. In TTY mode:
- True colour and cursorline disabled
- FZF preview windows disabled
- IndentLine guides disabled
- Simplified statusline
- Syntax column limit reduced

### Large File Handling

Files over 10 MB: syntax highlighting, undo history, and linting automatically disabled.

### Project-Local Config

```vim
" my-project/.vimrc
set shiftwidth=2
let g:ale_python_black_options = '--line-length=100'
```

---

## Plugins (30)

| Category | Plugins |
|----------|---------|
| **Navigation** | fzf, fzf.vim |
| **Git** | vim-fugitive, vim-gitgutter |
| **LSP** | vim-lsp, vim-lsp-settings, asyncomplete.vim, asyncomplete-lsp.vim |
| **Lint/Format** | ALE |
| **Editing** | vim-surround, vim-commentary, vim-repeat, vim-unimpaired, vim-sleuth, targets.vim, auto-pairs, vim-easymotion |
| **Language** | vim-javascript, yats.vim, vim-markdown, vim-go |
| **Writing** | previm, goyo.vim, limelight.vim |
| **UI** | vim-solarized8, undotree, vim-startify, indentLine |
| **Session** | vim-obsession, vim-tmux-navigator |

---

## Learn

New to chopsticks? Run the interactive tutorial:

```vim
:ChopsticksLearn
```

It walks you through every feature — file finding, LSP, git, zen mode,
and more — with exercises you can try in real time. (For Vim basics, run
`:Tutor` first.)

---

## Architecture

chopsticks follows the Unix philosophy: each concern lives in its own file.

```
~/.vim/
├── .vimrc              ← thin loader (sources modules in order)
├── modules/
│   ├── env.vim         ← environment detection (TTY, truecolor)
│   ├── plugins.vim     ← vim-plug bootstrap + 30 plugin declarations
│   ├── core.vim        ← general settings, keymaps, performance
│   ├── ui.vim          ← colorscheme, statusline, startify
│   ├── editing.vim     ← EasyMotion, yank highlight, search auto-clear
│   ├── navigation.vim  ← FZF, netrw, window management, terminal
│   ├── lsp.vim         ← vim-lsp + asyncomplete
│   ├── lint.vim        ← ALE linting and format-on-save
│   ├── git.vim         ← Fugitive, GitGutter, conflict navigation
│   ├── writing.vim     ← Markdown, previm, goyo + limelight
│   ├── languages.vim   ← vim-go, per-filetype settings
│   └── tools.vim       ← cheat sheet, run file, helpers
└── tutor/
    └── chopsticks.tutor  ← interactive tutorial
```

Each module is self-contained. Want to disable git integration? Remove
`call s:load('git')` from `.vimrc`. Want to add your own module? Create
`modules/mine.vim` and add `call s:load('mine')`.

---

## Customization

Edit `~/.vimrc` directly (`,ev` opens it, `,sv` reloads), or edit individual
modules under `modules/`. Per-project overrides go in a `.vimrc` at your
project root.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Plugins not loading | `:PlugInstall` then `:PlugUpdate` |
| LSP not starting | `:LspInstallServer` for current filetype |
| Colors look wrong | `export COLORTERM=truecolor` in your shell rc |
| ALE linters missing | `which flake8 black prettier eslint` to verify PATH |
| `Ctrl+s` freezes terminal | Add `stty -ixon` to `~/.bashrc` or `~/.zshrc` |
| Markdown preview broken | Ensure `open` (macOS) or `xdg-open` (Linux) works |

---

## License

[MIT](LICENSE)
