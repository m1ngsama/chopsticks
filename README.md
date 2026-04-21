<p align="center">
  <img src=".github/demo.gif" alt="chopsticks demo" width="720">
</p>

<h1 align="center">chopsticks</h1>

<p align="center">
  <strong>Vim for engineers. 29 plugins, 19ms startup, works over SSH.</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="MIT License"></a>
  <a href="https://www.vim.org/"><img src="https://img.shields.io/badge/Vim-8.0%2B-brightgreen?style=flat-square" alt="Vim 8.0+"></a>
  <a href="#install"><img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey?style=flat-square" alt="Platform"></a>
  <a href="https://github.com/m1ngsama/chopsticks/actions"><img src="https://img.shields.io/github/actions/workflow/status/m1ngsama/chopsticks/test.yml?style=flat-square&label=tests" alt="Tests"></a>
  <a href="https://github.com/m1ngsama/chopsticks/releases"><img src="https://img.shields.io/github/v/release/m1ngsama/chopsticks?style=flat-square&color=orange" alt="Release"></a>
</p>

---

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

---

## Why

You SSH into a server. You need to edit code. You want LSP, fuzzy find, git integration, format-on-save — not a 20-minute setup.

chopsticks gives you a production-ready Vim config in one command. Pure VimScript — no Node.js for the core. Degrades gracefully on TTY. Works the same on your MacBook and your headless Arch box.

**19ms startup** with 29 plugins, LSP, linting, and a hand-built statusline. Faster than most people's empty vimrc.

## What's in the box

| | |
|-|-|
| **LSP** | completion, go-to-def, hover, rename, code actions — pure VimScript ([vim-lsp](https://github.com/prabirshrestha/vim-lsp)) |
| **Lint + format** | [ALE](https://github.com/dense-analysis/ale) runs black, prettier, gofmt, rustfmt on save |
| **Fuzzy find** | files, buffers, grep, tags, marks, commands — [FZF](https://github.com/junegunn/fzf.vim) |
| **Git** | status, diff, blame, push, pull, conflict markers — [fugitive](https://github.com/tpope/vim-fugitive) + [gitgutter](https://github.com/airblade/vim-gitgutter) |
| **Zen mode** | `,zen` — [Goyo](https://github.com/junegunn/goyo.vim) + [Limelight](https://github.com/junegunn/limelight.vim) |
| **Run file** | `,cr` — auto-detects Python, Go, Rust, JS, C, Shell, and more |
| **TTY-aware** | degrades gracefully on SSH, console, slow links — never breaks |
| **19ms startup** | lazy-loaded plugins, deferred LSP init, zero redundant work |

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

Or manually:

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh
```

Supports macOS (brew), Debian/Ubuntu (apt), Arch (pacman), Fedora (dnf).

First launch installs plugins automatically (30-60s). Restart vim when done.

## Keys

Leader: `,` — press `,?` for the full cheat sheet inside vim.

```
Ctrl+p    fuzzy find file          gd    go to definition
,rg       ripgrep project          K     hover docs
,gs       git status               ,cr   run current file
,zen      zen mode                 ,f    format
,w        save                     ,q    quit
jk        exit insert mode         ,?    cheat sheet
```

<details>
<summary><strong>All keybindings</strong></summary>

### Files

`Ctrl+p` find | `,b` buffers | `,rg` grep | `,rG` grep word | `,fh` recent | `,e` browser | `,,` last file

### Code

`gd` def | `gy` type | `gi` impl | `gr` refs | `K` docs | `[g` `]g` diagnostics | `,rn` rename | `,ca` action | `,o` outline | `,cr` run

### Edit

`s`+2ch jump | `gc` comment | `cs"'` surround | `Alt+j/k` move line | `,u` undo tree | `,y` clipboard | `,*` replace word

### Git

`,gs` status | `,gd` diff | `,gb` blame | `,gc` commit | `,gp` push | `]x` `[x` conflict

### Windows

`Ctrl+hjkl` navigate (+ tmux) | `,z` maximize | `,h` `,l` buffers | `,tv` terminal | `Esc Esc` exit terminal

### Writing

`,zen` zen mode | `,mp` markdown preview | `,mt` table of contents

</details>

## LSP

```vim
:LspInstallServer    " auto-detects filetype
:LspStatus           " check what's running
```

pylsp, gopls, rust-analyzer, clangd, marksman, sqls — no Node.js. JS/TS servers need Node.

ALE and vim-lsp coexist cleanly (`ale_disable_lsp=1`). ALE handles linting + formatting. vim-lsp handles everything else.

## Architecture

```
~/.vim/
├── .vimrc              thin loader (12 lines)
├── modules/
│   ├── env.vim         TTY detection, truecolor
│   ├── plugins.vim     vim-plug + 29 plugins
│   ├── core.vim        settings, keymaps, performance
│   ├── ui.vim          solarized, statusline, startify
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

Each module is self-contained. Comment out one line in `.vimrc` to disable it. Add your own with `call s:load('mine')`.

## Learn

```vim
:ChopsticksLearn     " interactive tutorial — 10 lessons
,?                   " cheat sheet (every binding)
```

## Performance

| Metric | Value |
|--------|-------|
| Startup time | **19ms** (29 plugins loaded) |
| Lazy-loaded | 8 plugins (on command or filetype) |
| Built-in plugins skipped | 10 (gzip, tar, zip, vimball, etc.) |
| Runtime lint delay | 200ms (no thrashing during edits) |
| Large file threshold | 10MB (auto-disables syntax + undo) |
| TTY large file | 500KB (syntax disabled) |

Measured with `vim --startuptime`. We benchmark every change.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Plugins not loading | `:PlugInstall` then `:PlugUpdate` |
| LSP not starting | `:LspInstallServer` for current filetype |
| Colors wrong | `export COLORTERM=truecolor` in shell rc |
| `Ctrl+s` freezes | `stty -ixon` in shell rc |
| Everything slow | Large file? Auto-disabled >10MB |

More in the [wiki](https://github.com/m1ngsama/chopsticks/wiki).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The two rules that matter: no Node.js dependencies, and don't regress startup time.

## License

[MIT](LICENSE)
