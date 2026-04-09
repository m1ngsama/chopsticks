# Quick Start

Five minutes from zero to a working Vim engineering environment.

> **New to Vim?** Read Step 0 first — it takes 2 minutes and prevents the most
> common beginner frustration. Already know how Vim modes work? [Skip to Step 1](#step-1-install).

---

## Step 0: Vim Basics

> **When confused, press `Esc` until things feel normal again — then keep reading.**

Vim is **modal**: the keyboard behaves differently depending on which mode you are in.
Most people get stuck because they try to type text while in Normal mode.

### The Three Modes

| Mode | Purpose | How to enter | How to leave |
|------|---------|--------------|--------------|
| **Normal** | Navigate and run commands | Startup default | — (you're already here) |
| **Insert** | Type text | `i` before cursor, `a` after, `o` new line below | `Esc` or `jk` |
| **Visual** | Select text | `v` char-by-char, `V` whole lines | `Esc` |

### 4 Survival Commands

Learn these before anything else. They will get you out of every stuck situation.

| Command | Action |
|---------|--------|
| `Esc` or `jk` | Exit insert/visual mode — return to Normal |
| `:q!` then `Enter` | Force quit without saving (emergency exit) |
| `,x` | Save and quit |
| `,w` or `Ctrl+s` | Save the file |

Once in Normal mode, press `,?` to open a cheat sheet covering everything else.

---

## Step 1: Install

**One command — works on macOS and Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

This clones the repo to `~/.vim` and runs the full installer. Interactive prompts
let you choose which optional tools to install (ripgrep, Node.js, Python tools, etc.).

The installer automatically handles missing dependencies — it will offer to install
`git`, Homebrew (macOS), or Node.js via nvm if they are not found.

**Traditional install:**
```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh
```

**Non-interactive (CI / server / scripting):**
```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash -s -- --yes
```

---

## Step 2: Open Vim

```bash
vim
```

The startup screen (vim-startify) shows recent files and sessions.
Press `Ctrl+p` to find a file, or just type a path.

To open a project:
```bash
vim .        # NERDTree on left, Startify on right
vim myfile   # opens file directly
```

---

## Step 3: Set Up LSP (pick your path)

### Path A: With Node.js (CoC — full LSP)

```bash
node --version   # must be >= 14.14
```

Inside Vim, install language servers for your stack:

```vim
:CocInstall coc-pyright coc-tsserver coc-go coc-rust-analyzer
```

Or let `install.sh` do it — it asks during setup.

### Path B: Without Node.js (vim-lsp — no dependencies)

Open a source file, then run:

```vim
:LspInstallServer
```

This auto-detects and installs the correct language server for the current filetype.

---

## The 12 Keys That Matter

```
,           (pause 500ms)   Show all keybindings (which-key)
,?                          Open cheat sheet inside Vim
Esc / jk                    Exit insert mode → Normal (memorize this)
Ctrl+s                      Save (works in normal and insert mode)
Ctrl+p                      Fuzzy find file
Ctrl+n                      Toggle file tree
gd                          Go to definition
K                           Show documentation
[g  /  ]g                   Prev / next LSP diagnostic
,rn                         Rename symbol
,rG                         Search word under cursor (ripgrep)
,gs                         Git status
,w  /  ,x                   Save / Save+quit
```

---

## Daily Use

### Navigate Code

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `gi` | Go to implementation |
| `gr` | List all references |
| `K` | Show docs for symbol under cursor |
| `Ctrl+o` | Jump back |
| `Ctrl+i` | Jump forward |

### Edit Code

| Key | Action |
|-----|--------|
| `Tab` | Select next completion item |
| `Enter` | Confirm completion |
| `gc` | Toggle comment (visual mode too) |
| `cs"'` | Change surrounding `"` to `'` |
| `ds(` | Delete surrounding `(` |
| `s`+2ch | EasyMotion: jump anywhere |

### Manage Errors

| Key | Action |
|-----|--------|
| `]g` | Jump to next diagnostic |
| `[g` | Jump to previous diagnostic |
| `K` | Read the error message |
| `,ca` | Apply code action / auto-fix |

### Git Workflow

```
,gs   git status (stage with 's', commit with 'cc')
,gd   diff current file
,gb   blame current file
,gc   commit
,gp   push
,gl   pull
```

---

## Language Workflows

### Python

```bash
# tools installed by install.sh; or manually:
pip install black flake8 pylint isort
```

Auto-formats with `black` + `isort` on save. Lint errors show as `X`/`!` in the sign column.

### JavaScript / TypeScript

```bash
npm install -g prettier eslint typescript
```

Auto-formats with `prettier` on save.

### Go

```bash
# tools installed by install.sh; or manually:
go install golang.org/x/tools/gopls@latest
go install golang.org/x/tools/cmd/goimports@latest
go install honnef.co/go/tools/cmd/staticcheck@latest
```

`gofmt` + `goimports` run on save automatically.

### Markdown

Install `marksman` for LSP support (completions, link checking):

```bash
brew install marksman          # macOS
sudo pacman -S marksman        # Arch
# or: ./install.sh (handles it automatically)
```

---

## Customize

Edit config live:
```vim
,ev     " opens ~/.vimrc in Vim
,sv     " reloads config without restarting
```

Per-project settings: create `.vimrc` in your project root.
```vim
" project/.vimrc
set shiftwidth=2
let g:ale_python_black_options = '--line-length=100'
```

Change color scheme in `~/.vimrc`:
```vim
colorscheme dracula    " or: gruvbox, solarized, onedark
```

---

## Quick Reference Card

```
BASICS (learn these first)
  Esc / jk        Exit insert mode → Normal
  Ctrl+s          Save (normal + insert mode)
  :q! + Enter     Emergency quit without saving
  ,?              Open cheat sheet

FILES
  Ctrl+n          File tree toggle
  Ctrl+p          Fuzzy find file (git-aware)
  ,b              Search open buffers
  ,rg             Search file contents (ripgrep)
  ,rG             Ripgrep word under cursor
  ,w    Save  |  ,q  Quit  |  ,x  Save+quit
  ,wa             Save all buffers
  ,,              Switch to last file

CODE
  gd          Go to definition
  K           Show documentation
  [g / ]g     Prev/next LSP diagnostic
  [e / ]e     Prev/next ALE error
  ,rn         Rename symbol
  ,ca         Code action / auto-fix
  ,f          Format selection  |  ,F  Format whole file

GIT
  ,gs  Status  |  ,gd  Diff  |  ,gb  Blame
  ,gc  Commit  |  ,gp  Push  |  ,gl  Pull

WINDOWS / PANES
  Ctrl+h/j/k/l    Move between Vim windows or tmux panes
  ,h / ,l         Prev / next buffer
  ,tv         Open terminal (vertical)
  ,th         Open terminal (horizontal)
  Esc         Exit terminal mode
  ,u          Undo tree  |  ,tt  Tag browser

SEARCH & REPLACE
  /text       Search forward  |  ?text  backward
  //          Search for visually selected text
  ,*          Replace word under cursor (file-wide)

CLIPBOARD
  ,y / ,Y     Yank / yank line to system clipboard
  ,p / ,P     Paste from system clipboard (after / before)
```

---

See [README.md](README.md) for the complete reference.
