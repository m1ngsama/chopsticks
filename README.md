# chopsticks

Vim config for people who ship code on any machine. Pure VimScript. No Node.js. Works over SSH.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Vim 8.0+](https://img.shields.io/badge/Vim-8.0%2B-brightgreen?style=flat-square)](https://www.vim.org/)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey?style=flat-square)](#install)

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

## Why

You SSH into a box. You need to edit code. You want LSP, fuzzy find, git integration, format-on-save — not a 20-minute setup ritual.

chopsticks gives you 29 plugins, 12 modules, and a sane config in one command. It degrades gracefully on TTY. It works the same on your MacBook and your Arch server.

## What's in the box

| | |
|-|-|
| **LSP** | completion, go-to-def, hover, rename, code actions — pure VimScript |
| **Lint + format** | ALE runs black, prettier, gofmt, rustfmt on save |
| **Fuzzy find** | files, buffers, grep, tags, marks, commands — FZF |
| **Git** | status, diff, blame, push, pull, conflict markers |
| **Zen mode** | `,zen` — Goyo + Limelight, distraction-free writing |
| **Run file** | `,cr` — auto-detects language, runs it |
| **TTY-aware** | degrades gracefully on SSH, console, slow links |

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

Or manually:

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh
```

macOS (brew), Debian/Ubuntu (apt), Arch (pacman), Fedora (dnf).

Open vim. Plugins install on first launch. Restart when done.

## Keys

Leader: `,` — press `,?` for the full cheat sheet.

```
Ctrl+p    fuzzy find file          gd    go to definition
,rg       ripgrep project          K     hover docs
,gs       git status               ,cr   run current file
,zen      zen mode                 ,f    format
,w        save                     ,q    quit
jk        exit insert mode         ,?    cheat sheet
```

**Files** — `Ctrl+p` find / `,b` buffers / `,rg` grep / `,rG` grep word / `,fh` recent / `,e` browser / `,,` last file

**Code** — `gd` def / `gy` type / `gi` impl / `gr` refs / `K` docs / `[g` `]g` diagnostics / `,rn` rename / `,ca` action / `,o` outline

**Edit** — `s`+2ch jump / `gc` comment / `cs"'` surround / `Alt+j/k` move line / `,u` undo tree / `,y` clipboard / `,*` replace word

**Git** — `,gs` status / `,gd` diff / `,gb` blame / `,gc` commit / `,gp` push / `]x` `[x` conflict markers

**Windows** — `Ctrl+hjkl` navigate (+ tmux) / `,z` maximize / `,h` `,l` buffers / `,tv` `,th` terminal / `Esc Esc` exit terminal

## LSP

```vim
:LspInstallServer    " auto-detects filetype
:LspStatus           " check what's running
```

pylsp, gopls, rust-analyzer, clangd, marksman — no Node.js. JS/TS servers need Node.

ALE and vim-lsp coexist cleanly (`ale_disable_lsp=1`). ALE handles linting + formatting. vim-lsp handles everything else.

## Architecture

```
~/.vim/
├── .vimrc              thin loader
├── modules/
│   ├── env.vim         TTY detection, truecolor
│   ├── plugins.vim     vim-plug + 29 plugins
│   ├── core.vim        settings, keymaps, performance
│   ├── ui.vim          colorscheme, statusline, startify
│   ├── editing.vim     easymotion, yank highlight
│   ├── navigation.vim  fzf, netrw, windows, terminal
│   ├── lsp.vim         vim-lsp, asyncomplete
│   ├── lint.vim        ale, format-on-save
│   ├── git.vim         fugitive, gitgutter
│   ├── writing.vim     markdown, previm, zen mode
│   ├── languages.vim   vim-go, filetype settings
│   └── tools.vim       cheat sheet, run file, helpers
└── tutor/
    └── chopsticks.tutor
```

Each module is self-contained. Comment out `call s:load('git')` in `.vimrc` to disable git. Add `call s:load('mine')` to load your own.

## Learn

```vim
:ChopsticksLearn     " interactive tutorial — 10 lessons
:Tutor               " vim basics (if needed first)
,?                   " cheat sheet
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Plugins not loading | `:PlugInstall` then `:PlugUpdate` |
| LSP not starting | `:LspInstallServer` for current filetype |
| Colors wrong | `export COLORTERM=truecolor` in shell rc |
| `Ctrl+s` freezes | `stty -ixon` in shell rc |
| Everything slow | Large file? Check `:echo &syntax` — auto-disabled >10MB |

More in the [wiki](https://github.com/m1ngsama/chopsticks/wiki).

## License

[MIT](LICENSE)
