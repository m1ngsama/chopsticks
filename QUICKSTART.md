# Quick Start

Five minutes from zero to a working Vim setup.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash -s -- --profile=minimal
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash -s -- --dry-run --profile=full
```

Open vim. First launch auto-installs plugins — **wait 30-60s, don't close vim**. Restart when done.

Default profile is `engineer`. Interactive installs ask for a profile first;
`--profile=minimal`, `--profile=engineer`, or `--profile=full` selects it
without prompting. You can later put `let g:chopsticks_profile = 'minimal'` in
`${XDG_CONFIG_HOME:-~/.config}/chopsticks.vim` for a smaller core-only setup,
or use `full` for the heavier Markdown/LSP feedback.

To switch later without reinstalling anything:

```bash
cd ~/.vim && ./install.sh --configure-only --profile=full
```

## Modes

| Mode   | Enter           | Leave         |
| ------ | --------------- | ------------- |
| Normal | startup default | —             |
| Insert | `i` / `a` / `o` | `Esc` or `jk` |
| Visual | `v` / `V`       | `Esc`         |

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
,dd             go to definition
,dk             hover docs
,rn             rename symbol
,ca             code action
,f              format
,cr             run current file
Tab / S-Tab     cycle completions
```

**First time in a new language?** Run `:LspInstallServer` — it auto-detects filetype and installs the right server. Do this once per language.

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
,S + 2 chars    EasyMotion jump
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

Markdown is quiet by default: no real-time lint, no spell noise, no concealed
syntax. Enable the heavier Markdown tools only when you want them.

## Health check

```
:ChopsticksStatus       see what's installed and what's missing
```

The `,?` cheat sheet follows your active profile, so `minimal` users only see
keys for features that are actually loaded.

See [README](README.md) for the full reference. See the [wiki](https://github.com/m1ngsama/chopsticks/wiki) for deep dives.
