# Quick Start

Five minutes from zero to a working Vim setup.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

Open vim. Plugins install automatically on first launch (30-60s). Restart vim.

## Modes

| Mode | Enter | Leave |
|------|-------|-------|
| Normal | startup default | — |
| Insert | `i` / `a` / `o` | `Esc` or `jk` |
| Visual | `v` / `V` | `Esc` |

## Survival

```
Esc / jk        back to Normal
,w              save
,x              save + quit
:q!             force quit
Ctrl+s          save from any mode
,?              cheat sheet (toggle sidebar)
```

## Find things

```
Ctrl+p          fuzzy find file (git-aware)
,rg             ripgrep project
,b              search buffers
,fh             recent files
,e              file browser
,,              last file
```

## Write code

```
gd              go to definition
K               hover docs
,rn             rename symbol
,ca             code action
,f              format
,cr             run current file
Tab / S-Tab     cycle completions
```

Install language servers with `:LspInstallServer` (auto-detects filetype).

## Git

```
,gs             status (s=stage, cc=commit)
,gd             diff
,gb             blame
,gp             push
]x / [x         conflict markers
```

## Edit

```
s + 2 chars     EasyMotion jump
gc              toggle comment
cs"'            change surrounding " to '
Alt+j / Alt+k   move line
,u              undo tree
,y              clipboard yank
```

## Navigate

```
Ctrl+h/j/k/l   splits + tmux panes
,h / ,l         prev / next buffer
,z              maximize window
,tv / ,th       terminal
```

## Markdown

```
,mp             preview in browser
,mt             table of contents
```

See [README](README.md) for the full reference. See the [wiki](https://github.com/m1ngsama/chopsticks/wiki) for deep dives.
