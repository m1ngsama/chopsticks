# Quick Start

Five minutes from zero to a working Vim environment.

---

## Step 0: Vim Basics (2 minutes)

> **When confused, press `Esc` until things feel normal again.**

Vim is **modal** — the keyboard behaves differently depending on which mode you are in.

| Mode | Purpose | Enter | Leave |
|------|---------|-------|-------|
| **Normal** | Navigate and run commands | default on startup | — |
| **Insert** | Type text | `i` before / `a` after / `o` new line | `Esc` or `jk` |
| **Visual** | Select text | `v` char / `V` line | `Esc` |

### 4 commands that get you out of any jam

| Command | Action |
|---------|--------|
| `Esc` or `jk` | Exit insert / visual mode → Normal |
| `:q!` then `Enter` | Force quit without saving |
| `,x` | Save and quit |
| `,w` or `Ctrl+s` | Save |

Once in Normal mode, press `,?` to open the cheat sheet.
Run `:ChopsticksLearn` for a full interactive tutorial.

---

## Step 1: Install

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

Traditional:
```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh
```

Non-interactive / CI:
```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash -s -- --yes
```

---

## Step 2: Open Vim

```bash
vim          # startup dashboard (recent files + sessions)
vim .        # startup dashboard, current directory listed
vim myfile   # edit a specific file
```

> **First launch:** Vim will automatically install plugins on the first open
> (takes 30–60 seconds depending on network). This is normal — wait for it
> to finish, then restart Vim.

---

## Step 3: Set Up LSP

Open a source file, then run:

```vim
:LspInstallServer
```

This auto-detects the filetype and installs the correct language server.
vim-lsp itself runs on pure VimScript — no Node.js required. However,
some language servers (JS/TS, HTML, CSS, JSON, YAML) are npm packages
that need Node.js to run. Python, Go, and Rust servers don't need it.

Check status:
```vim
:LspStatus
```

**Markdown LSP** (`marksman`) needs a standalone binary:
```bash
brew install marksman    # macOS
sudo pacman -S marksman  # Arch
# install.sh handles this automatically
```

---

## The Keys That Matter

```
,?              Open cheat sheet (all bindings in one place)
Esc / jk        Exit insert mode → Normal
Ctrl+s          Save
Ctrl+p          Fuzzy find file
,e              File browser (netrw)
gd              Go to definition
K               Show documentation
[g / ]g         Prev / next LSP diagnostic
,rn             Rename symbol
,rG             Search word under cursor (ripgrep)
,gs             Git status
,mp             Markdown live preview in browser
,w / ,x         Save / Save+quit
```

---

## Daily Use

### Navigate Code

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `gi` | Go to implementation |
| `gr` | List references |
| `K` | Docs for symbol under cursor |
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
| `s` + 2 chars | EasyMotion: jump anywhere |

### Manage Errors

| Key | Action |
|-----|--------|
| `]g` | Jump to next LSP diagnostic |
| `[g` | Jump to previous diagnostic |
| `K` | Read the error message |
| `,ca` | Apply code action / auto-fix |
| `,cr` | Run current file (auto-detects language) |

### Markdown & Writing

| Key | Action |
|-----|--------|
| `,mp` | Open live preview in browser |
| `,mt` | Table of contents (side window) |
| `,zen` | Zen mode (Goyo + Limelight) |
| `zr` / `zm` | Unfold / fold all headings |

Formatting in the buffer is live: `**bold**` renders as bold,
headings hide their `#` markers. Raw syntax reappears when
the cursor enters that line.

### Git Workflow

```
,gs   git status (stage with 's', commit with 'cc')
,gd   diff current file
,gb   blame
,gc   commit
,gp   push
,gl   pull
[x / ]x   navigate conflict markers
```

---

## Quick Reference Card

```
BASICS
  Esc / jk        Exit insert mode → Normal
  Ctrl+s          Save
  :q! + Enter     Emergency quit
  ,?              Open cheat sheet

FILES
  Ctrl+p          Fuzzy find file (git-aware)
  ,e              File browser (netrw)
  ,b              Search open buffers
  ,rg             Search file contents (ripgrep)
  ,rG             Ripgrep word under cursor
  ,w  Save  |  ,q  Quit  |  ,x  Save+quit
  ,wa             Save all buffers
  ,,              Switch to last file

CODE
  gd  Definition  |  gy  Type def  |  gi  Impl  |  gr  References
  K               Show documentation
  [g / ]g         Prev / next LSP diagnostic
  [e / ]e         Prev / next ALE error
  ,rn  Rename   ,ca  Code action   ,f  Format
  ,cr             Run current file

SEARCH
  ,rg  Ripgrep   ,rG  Ripgrep word   ,fh  Recent files
  ,fl  Lines in buffer   ,fc  Commands   ,fm  Marks
  /text  Forward  |  ?text  Backward  |  n  next  |  N  prev
  //     Search visually selected text
  ,*     Replace word under cursor (file-wide)

MARKDOWN
  ,mp  Preview  |  ,mt  TOC  |  ,zen  Zen mode

GIT
  ,gs  Status   ,gd  Diff   ,gb  Blame
  ,gc  Commit   ,gp  Push   ,gl  Pull
  [x / ]x       Navigate conflict markers

WINDOWS
  Ctrl+h/j/k/l  Navigate splits and tmux panes
  ,z             Maximize / restore window
  ,h / ,l        Prev / next buffer
  ,tv / ,th      Terminal (vertical / horizontal)
  Esc Esc        Exit terminal mode
  ]q / [q        Next / prev quickfix entry
```

---

See [README.md](README.md) for the complete reference.
