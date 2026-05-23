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

## Modes

| Mode   | Enter           | Leave         |
| ------ | --------------- | ------------- |
| Normal | startup default | —             |
| Insert | `i` / `a` / `o` | `Esc`         |
| Visual | `v` / `V`       | `Esc`         |

## Survival

```
Esc             back to Normal
SPC w           save
SPC qx          save + quit
:q!             force quit
SPC ?           cheat sheet (toggle sidebar)
```

Classic layout equivalents:

```
Esc             back to Normal
,w              save
,x              save + quit
:q!             force quit
,?              cheat sheet (toggle sidebar)
```

## Find things

```
SPC SPC         fuzzy find file (git-aware)
SPC /           ripgrep project
SPC ,           search buffers
SPC fr          recent files
SPC e           file browser
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
<C-w>h/j/k/l   splits
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
:ChopsticksTutor       guided practice for the final keymap
:ChopsticksStatus       see what's installed and what's missing
```

The `SPC ?` cheat sheet follows your active profile, so `minimal` users only see
keys for features that are actually loaded.

See [README](README.md) for the full reference. For beta testing and rollback,
see [BETA.md](BETA.md).
