# Quick Start

Five minutes from zero to a working Vim engineering environment.

## Step 1: Install

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh
```

The script handles everything: symlinks, vim-plug, plugin download.
No root access required.

## Step 2: Open Vim

```bash
vim
```

The startup screen shows recent files and sessions. Press `q` to dismiss
or just start typing a filename to open.

## Step 3: Install LSP (pick one path)

### Path A: With Node.js (full CoC)

```bash
node --version   # confirm >= 14.14
```

Inside Vim, install language servers for your stack:

```vim
:CocInstall coc-pyright coc-tsserver coc-go coc-rust-analyzer
```

### Path B: Without Node.js (vim-lsp)

Open a file of your language, then run:

```vim
:LspInstallServer
```

This auto-detects and installs the correct language server binary.

---

## Daily Use

### The 10 keys that matter most

```
,w          Save
,q          Quit
Ctrl+n      File tree
Ctrl+p      Fuzzy find file
gd          Go to definition
K           Show docs
[g  ]g      Prev/next diagnostic
,rn         Rename symbol
,gs         Git status
,           (pause 500ms) Show all shortcuts
```

### Open a project

```bash
cd ~/my-project && vim
```

NERDTree auto-opens when you launch Vim on a directory. Use `Ctrl+p` to
fuzzy-search files by name. Use `,rg` to search file contents.

### Navigate code

| Key   | Action                          |
|-------|---------------------------------|
| `gd`  | Go to definition                |
| `gy`  | Go to type definition           |
| `gi`  | Go to implementation            |
| `gr`  | List all references             |
| `K`   | Show docs for symbol under cursor |
| `Ctrl+o` | Jump back                  |
| `Ctrl+i` | Jump forward               |

### Edit code

| Key     | Action                              |
|---------|-------------------------------------|
| `Tab`   | Select next completion item         |
| `Enter` | Confirm completion                  |
| `gc`    | Toggle comment (works in visual mode too) |
| `cs"'`  | Change surrounding `"` to `'`      |
| `ds(`   | Delete surrounding `(`              |
| `s`+2ch | EasyMotion: jump anywhere           |

### Manage errors

| Key    | Action                        |
|--------|-------------------------------|
| `]g`   | Jump to next diagnostic       |
| `[g`   | Jump to previous diagnostic   |
| `K`    | Read the error message        |
| `,ca`  | Apply code action / auto-fix  |

### Git workflow

```
,gs   git status (stage files with 's', commit with 'cc')
,gd   diff current file
,gb   blame current file
,gc   commit
,gp   push
,gl   pull
```

---

## Common Workflows

### Python project

```bash
pip install black flake8 pylint isort
vim my_script.py
```

Auto-formats with black on save. Lint errors show in the sign column as
`X` (error) and `!` (warning). Jump between them with `[g` / `]g`.

### JavaScript / TypeScript project

```bash
npm install -g prettier eslint typescript
vim src/index.ts
```

Auto-formats with prettier on save. Use `:CocInstall coc-tsserver` for
full IntelliSense (requires Node.js).

### Go project

```bash
go install golang.org/x/tools/gopls@latest
vim main.go
```

gofmt runs on save automatically. `gd` jumps to definitions even across
package boundaries when gopls is running.

---

## Customize

Edit config live:
```vim
,ev     " opens ~/.vimrc in Vim
,sv     " reloads config without restarting
```

Per-project overrides: create `.vimrc` in your project root.

---

## Quick Reference

```
FILES
  Ctrl+n      File tree toggle
  Ctrl+p      Fuzzy find file
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
  ,gs         Status  |  ,gd  Diff  |  ,gb  Blame
  ,gc         Commit  |  ,gp  Push  |  ,gl  Pull

WINDOWS
  Ctrl+h/j/k/l    Move between panes
  ,tv         Open terminal (vertical)
  ,th         Open terminal (horizontal)
  Esc         Exit terminal mode
  F5          Undo tree  |  F8  Tag browser

SEARCH
  /text       Search forward
  ?text       Search backward
  ,<CR>       Clear search highlight
  ,*          Replace word under cursor (project)
```

---

See [README.md](README.md) for the complete reference.
