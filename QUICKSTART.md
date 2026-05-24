# Quick Start

Five minutes to understand the chopsticks project loop.

This guide assumes you already know Vim's editing language. chopsticks keeps
that language intact and gives you one stable layer for the work around it:
jump on the visible screen, switch project files, grep, run, inspect code,
check git, and ask Vim which keys are active.

## Install

These commands install the stable `main` branch. For beta testing this branch,
use [BETA.md](BETA.md).

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

The default keymap style is `space`: `SPC` is the command leader and `,` is
reserved for filetype-local actions. To use the legacy comma layout instead,
add this to `${XDG_CONFIG_HOME:-~/.config}/chopsticks.vim`:

```vim
let g:chopsticks_keymap_style = 'classic'
```

To switch later without reinstalling anything:

```bash
cd ~/.vim && ./install.sh --configure-only --profile=full
```

## Daily loop

Train this first. It is the core reason to use chopsticks instead of assembling
the same pieces yourself:

```
SPC SPC         open a project file
s + 2 chars     jump to visible text
gd / gr / K     inspect definition, references, docs
SPC rr          run the current file
SPC /           grep the project
SPC gs          check git status
SPC ?           show the active keymap
```

## Survival

```
Esc             back to Normal
SPC w           save
SPC qx          save + quit
:q!             force quit
SPC ?           cheat sheet (toggle sidebar)
SPC fc          edit local preferences
:ChopsticksHelp  full native help
```

Classic layout equivalents:

```
Esc             back to Normal
,w              save
,x              save + quit
:q!             force quit
,?              cheat sheet (toggle sidebar)
,ec             edit local preferences
:ChopsticksHelp  full native help
```

## Find things

```
SPC SPC         fuzzy find file (git-aware)
SPC /           ripgrep project
SPC ,           search buffers
SPC fr          recent files
SPC e           sidebar at project cwd
SPC E           sidebar at current file dir
SPC Tab         last file
```

## Write code

```
gd              go to definition
K               hover docs
SPC cr          rename symbol
SPC ca          code action
SPC cf          format
SPC rr          run current file
Tab / S-Tab     cycle completions
```

**First time in a new language?** Run `:LspInstallServer` — it auto-detects filetype and installs the right server. Do this once per language.

## Git

```
SPC gs          status (s=stage, cc=commit)
SPC gd          diff
SPC gb          blame
SPC gl          log graph
]x / [x         conflict markers
```

## Edit

In the default Space layout, Normal-mode `s` is a fast visible-text jump.
Use `cl` when you want Vim's original single-character substitute behavior,
and `cc` when you want Vim's original line substitute behavior.

```
s + 2 chars     EasyMotion jump
SPC S + 2 chars same jump, discoverable fallback
cl / cc         native s / S substitute replacements
gc              toggle comment
cs"'            change surrounding " to '
Alt+j / Alt+k   move line
SPC U           undo tree
SPC y           clipboard yank
```

## Navigate

```
Ctrl-h/j/k/l    splits
<C-w>h/j/k/l    native Vim fallback
SPC e, Ctrl-h/l open sidebar, enter/leave it
SPC bp / SPC bn prev / next buffer
SPC z           maximize window
SPC tt / SPC th terminal
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
:ChopsticksHelp        full native Vim help
:ChopsticksConfig      edit local preferences
:ChopsticksReload      reload after saving local preferences
:ChopsticksTutor       guided practice for the final keymap
:ChopsticksStatus       see what's installed and what's missing
```

The `SPC ?` cheat sheet follows your active profile, so `minimal` users only see
keys for features that are actually loaded.

Inside Vim, `:help chopsticks` opens the same reference after helptags are
available. See [README](README.md) for the full reference. For beta testing and
rollback, see [BETA.md](BETA.md).
