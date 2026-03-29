# Quick Start

Five minutes from zero to a working Vim engineering environment.

---

## Step 1: Install

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh
```

The script handles everything: symlinks, vim-plug, plugins, and all tools.
It detects your OS (macOS/Debian/Arch/Fedora) and installs what it can automatically.

**Non-interactive (CI / server):**
```bash
./install.sh --yes
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

## The 10 Keys That Matter

```
,           (pause 500ms)   Show all shortcuts
Ctrl+p                      Fuzzy find file
Ctrl+n                      Toggle file tree
gd                          Go to definition
K                           Show documentation
[g  /  ]g                   Prev / next diagnostic
,rn                         Rename symbol
,rg                         Search project contents
,gs                         Git status
,w  /  ,q                   Save / Quit
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
FILES
  Ctrl+n      File tree toggle
  Ctrl+p      Fuzzy find file (git-aware)
  ,b          Search open buffers
  ,rg         Search file contents (ripgrep)
  ,w          Save  |  ,q  Quit  |  ,x  Save+quit
  ,wa         Save all buffers

CODE
  gd          Go to definition
  K           Show documentation
  [g / ]g     Prev/next diagnostic
  ,rn         Rename symbol
  ,ca         Code action
  ,f          Format selection
  ,F          Format whole file

GIT
  ,gs  Status  |  ,gd  Diff  |  ,gb  Blame
  ,gc  Commit  |  ,gp  Push  |  ,gl  Pull

WINDOWS
  Ctrl+h/j/k/l    Move between panes
  ,tv         Open terminal (vertical)
  ,th         Open terminal (horizontal)
  Esc         Exit terminal mode
  F5          Undo tree  |  F8  Tag browser

SEARCH
  /text       Search forward
  ?text       Search backward
  ,*          Replace word under cursor (project-wide)
```

---

See [README.md](README.md) for the complete reference.
