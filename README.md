<p align="center">
  <img src=".github/demo.gif" alt="chopsticks Vim demo: open the in-editor keymap, jump, switch files, run, grep, and inspect Git" width="720">
  <br>
  <sub>First minute after install: open the in-editor map, then use it.</sub>
</p>

<h1 align="center">chopsticks</h1>

<p align="center">
  <strong>Pure Vim project workflow for people who already know Vim.</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="MIT License"></a>
  <a href="https://www.vim.org/"><img src="https://img.shields.io/badge/Vim-8.2%20%7C%209.x-brightgreen?style=flat-square" alt="Vim 8.2 or 9.x"></a>
  <a href="#install"><img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey?style=flat-square" alt="Platform"></a>
  <a href="https://github.com/m1ngsama/chopsticks/actions"><img src="https://img.shields.io/github/actions/workflow/status/m1ngsama/chopsticks/check.yml?style=flat-square&label=checks" alt="Checks"></a>
  <a href="https://github.com/m1ngsama/chopsticks/releases"><img src="https://img.shields.io/github/v/release/m1ngsama/chopsticks?style=flat-square&color=orange" alt="Release"></a>
</p>

---

Install current `main`:

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
```

Open Vim once, wait for pinned plugins to install, restart Vim, then press
`SPC ?`. That is the active map for your profile. `:ChopsticksTutor` gives you
a guided lap when you want one.

---

## Why

Vim already gives you the editing language: operators, motions, text objects,
windows, registers, `gd`, `K`, `:help`.

The part that drifts is the project layer around editing. Every machine ends up
with a slightly different answer for files, grep, Git, LSP, running the current
file, terminal behavior, health checks, and key help.

chopsticks makes that layer one habit:

```text
SPC ?    show the active map
SPC SPC  open a project file
s{2}     jump on the visible screen
SPC rr   run the current file
SPC /    search the project
SPC gs   inspect Git
```

It keeps standard Vim and LSP habits where the muscle memory is already right:
`gd`, `gr`, `K`, `Ctrl-h/j/k/l`, `<C-w>hjkl`, `cl`, and `cc`. Git push and pull
are deliberately not default hotkeys; use explicit shell or Fugitive commands
for operations that change remote state.

Everything here is Vimscript for Vim 8.2 and Vim 9.x. There is no Neovim
runtime, no Lua runtime, no `stdpath()`, and no `init.lua`. The core does not
need Node.js. The config is meant to survive terminal Vim, SSH, tmux, and slow
remote machines.

## What ships

- `minimal`: navigation, editing assists, Git, Markdown basics, survival keys,
  and the in-editor learning surfaces.
- `engineer`: `minimal` plus LSP, completion, linting, formatting, language
  plugins, and diagnostics.
- `full`: `engineer` plus heavier Markdown feedback for users who want it.

The daily help surface is inside Vim: `SPC ?`, `:ChopsticksTutor`,
`:ChopsticksHelp`, `:ChopsticksStatus`, `:ChopsticksDoctor`, and native
`:help chopsticks`. GitHub Wiki is disabled on purpose.

[QUICKSTART.md](QUICKSTART.md) is the five-minute path. [BETA.md](BETA.md) is
the release checklist and rollback guide.

## Install

These commands install current `main`. For release checklist and rollback
steps, use [BETA.md](BETA.md).

```bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash -s -- --profile=minimal
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash -s -- --install-tools
curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash -s -- --dry-run --profile=full
```

Or manually:

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim && ./install.sh --profile=engineer
```

Default install manages the Vim config and pinned Vim plugins only. Pass
`--install-tools` when you want chopsticks to install optional system tools,
formatter suites, language tools, or tmux integration. Tool installation
supports macOS (brew), Debian/Ubuntu (apt), Arch (pacman), Fedora (dnf). Set
`CHOPSTICKS_DEST=/absolute/path` before running `get.sh` to install somewhere
other than `~/.vim`.

First launch installs plugins automatically (30-60s). Restart vim when done.
Use `./install.sh --dry-run --profile=full` to inspect the resolved profile,
config path, and optional-tool mode without changing files. Use `./install.sh
--configure-only --profile=minimal` to switch profiles without reinstalling
plugins or tools.

## Profiles

Default profile: `engineer`. Interactive installs ask for this profile before
plugins are installed; `--profile=minimal`, `--profile=engineer`, or
`--profile=full` selects it without prompting. `--yes` keeps the existing local
profile or uses `engineer`.

```vim
" Put this in ${XDG_CONFIG_HOME:-~/.config}/chopsticks.vim.
let g:chopsticks_profile = 'engineer'  " default: LSP, ALE, syntax extras
" let g:chopsticks_profile = 'minimal' " core navigation/editing/git/markdown
" let g:chopsticks_profile = 'full'    " engineer + heavier Markdown feedback
let g:chopsticks_keymap_style = 'space' " default: Space leader grouped layout
" let g:chopsticks_keymap_style = 'classic' " optional legacy comma layout
let g:chopsticks_enable_jk_escape = 1  " optional: insert-mode jk exits insert
let g:chopsticks_enable_ctrl_s_save = 1 " optional: Ctrl-S saves
let g:chopsticks_enable_sudo_save_bang = 1 " optional: :w!! sudo save
let g:chopsticks_enable_completion_keymaps = 1 " optional: Tab/Enter completion
let g:chopsticks_enable_auto_pairs = 1 " optional: automatic pair insertion
let g:chopsticks_enable_terminal_keymaps = 1 " optional: terminal Esc/Ctrl navigation
let g:chopsticks_enable_tmux_navigator = 1 " optional: vim-tmux-navigator integration
let g:chopsticks_enable_exrc = 1 " optional: source project-local .vimrc/.exrc from CWD
let g:chopsticks_enable_reindent_file = 1 " optional: full-file reindent map
let g:chopsticks_enable_input_method = 1 " optional: switch IM around Insert mode
let g:chopsticks_input_method_default = 'com.apple.keylayout.ABC' " macOS default
" let g:chopsticks_input_method_filetypes = ['markdown', 'text', 'gitcommit']
" let g:chopsticks_pin_plugins = 0 " optional: test plugin updates before relocking
```

`minimal` avoids LSP, ALE, completion plugins, extra language syntax plugins,
Startify, UndoTree, and browser Markdown preview. `full` keeps those and opts
into Markdown lint, format, spell, conceal, Marksman, and LSP virtual text.

Project updates leave `~/.config/chopsticks.vim` alone, so put local choices
there instead of editing the managed `.vimrc`. Plugins are pinned to revisions
verified by the smoke suite; set `g:chopsticks_pin_plugins = 0` only when you
are deliberately testing updates. The `SPC ?` cheat sheet follows the active
profile and only shows keys for enabled features. Inside Vim, use
`:ChopsticksConfig` to edit that local file and `:ChopsticksReload` after
saving it. If that file has a Vimscript error, chopsticks keeps loading and
reports the source error in `:ChopsticksStatus` and `:ChopsticksDoctor`.
Invalid profile or keymap values fall back to safe defaults, but
`:ChopsticksStatus` and `:ChopsticksDoctor` report the requested value and the
resolved value. `:ChopsticksStatus` shows the resolved profile, keymap, enabled
feature groups, opt-in habits, Markdown mode, Vim runtime, SSH session state,
module inventory/load state, public command surface, local preference load
state, and active plugin lock coverage. `:ChopsticksDoctor` reports low Vim
versions, module inventory drift or source errors, missing public commands, bad
profile/keymap values, local preference source errors, missing runtime features,
missing lock coverage, unapplied pins, and missing plugin directories as
actionable health issues. Each Doctor issue includes a stable `[domain.label]`
code for release notes, tests, and personal troubleshooting notes.
When both completion keymaps and auto-pairs are enabled, auto-pairs owns the
buffer-local `<CR>` map and wraps the completion `<CR>` behavior. The keymap
audit checks that this opt-in interaction stays intact.

## Keys

Default layout: `space`, leader `SPC`, localleader `,`.

This is the canonical layout for QWERTY keyboards with CapsLock mapped to
tap-Esc / hold-Ctrl. Escape and Ctrl stay at the system layer; Vim keeps the
native `<C-w>` window model as a fallback and standard LSP motions (`gd`,
`gr`, `K`).
Git push/pull are intentionally not bound to default hotkeys. Normal-mode `s`
is a screen-local EasyMotion jump; use `cl` for native `s` substitute and `cc`
for native `S`.

For learning the kit, use `:ChopsticksTutor` to train the core loop, `SPC ?`
for the active keymap, `:ChopsticksHelp` / `:help chopsticks` for full native
Vim help, `:ChopsticksConfig` for local preferences, `:ChopsticksStatus` for
tool/LSP/navigation health, and `:ChopsticksDoctor` for the actionable problem
list. Use `:ChopsticksKeymapAudit` when changing mappings or validating a new
profile. GitHub Wiki is deliberately disabled; the in-editor cheatmap, tutor,
and native Vim help are the source of truth for daily usage.
For Chinese/Japanese writing on macOS, install `im-select` and opt into
`g:chopsticks_enable_input_method`; chopsticks will remember the buffer's
Insert-mode input source and switch Normal mode back to `ABC`.
Input-method switching is disabled on SSH sessions by default; set
`g:chopsticks_input_method_disable_on_ssh = 0` only if the remote machine owns
the input-source command you want to run. Use
`:ChopsticksInputMethodStatus`, `:ChopsticksInputMethodEnable`,
`:ChopsticksInputMethodDisable`, and `:ChopsticksInputMethodToggle` to inspect
or change the switcher inside Vim.
`QUICKSTART.md` is the 5-minute path; this README is the full reference.
During release checks, `:ChopsticksBeta` opens the in-editor checklist,
`:ChopsticksBetaLog` opens editable local notes, and `:ChopsticksBetaSession`
appends a timestamped session block.

```
SPC SPC   fuzzy find file          gd       go to definition
SPC /     ripgrep project          K        hover docs
SPC e     toggle file sidebar      SPC rr   run current file
Ctrl-h/l  enter/leave sidebar      Ctrl-hjkl windows
SPC gs    git status               SPC cf   format
SPC w     save                     SPC q    quit
Esc       exit insert mode         SPC ?    cheat sheet
:ChopsticksConfig local prefs       :ChopsticksReload reload
```

<details>
<summary><strong>Canonical Space keybindings</strong></summary>

### Fast Path

`SPC SPC` files | `SPC ,` buffers | `SPC /` grep | `SPC Tab` alternate buffer | `SPC e` browser | `SPC E` browser (file dir)

### Files

`SPC ff` files | `SPC fb` buffers | `SPC fg` git files | `SPC fr` recent | `SPC fl` buffer lines | `SPC fL` all lines | `SPC fc` local config | `SPC fv` edit vimrc | `SPC fV` reload

### Search

`SPC sg` grep | `SPC sw` grep word | `SPC s/` search history | `SPC s:` command history | `SPC sm` marks | `SPC st` tags | `SPC sr` replace word

### Code

`gd` def | `gr` refs | `gI` impl | `gy` type | `K` docs | `[d` `]d` LSP diagnostics | `[e` `]e` ALE errors | `SPC ca` action | `SPC cr` rename | `SPC cf` format | `SPC co` outline | `SPC ci` LSP status | `SPC rr` run

### Edit

`s`+2ch jump | `SPC S` jump fallback | `cl` native `s` substitute | `cc` native `S` substitute | `gc` comment | `cs"'` surround | `Alt+j/k` move line | `SPC U` undo tree | `SPC y` clipboard | `SPC =` re-indent visual | `SPC cW` strip whitespace | `[<Space>` `]<Space>` blank lines

### Git

`SPC gs` status | `SPC gd` diff | `SPC gb` blame | `SPC gc` commit | `SPC gl` log graph | `SPC gC` FZF commits | `SPC gB` buffer commits | `]x` `[x` conflict

### Windows

`Ctrl-h/j/k/l` windows | `<C-w>h/j/k/l` native fallback | `SPC z` maximize | `SPC bp` `SPC bn` buffers | `SPC bd` close buffer | `SPC bo` close other buffers | `SPC tt` `SPC th` terminal | `]q` `[q` quickfix | `]l` `[l` loclist | `SPC xq` `SPC xQ` open/close quickfix | `SPC xl` `SPC xL` open/close loclist

### Markdown

`,mp` preview in browser | `,mt` table of contents

### Toggle

`F2` paste | `F3` line numbers | `F4` relative numbers | `F6` invisible chars | `SPC us` spell check | `SPC uf` format on save

### Survival

`SPC w` save | `SPC W` save all | `SPC q` quit | `:x` / `ZZ` save and quit | `SPC fc` local config | `SPC fV` reload | `SPC ?` cheat sheet | `:ChopsticksHelp` full help | `:ChopsticksTutor` practice | `:ChopsticksStatus` diagnostics

</details>

<details>
<summary><strong>Legacy classic keybindings</strong></summary>

### Classic Files

`,ff` find | `,b` buffers | `,rg` grep | `,rG` grep word | `,fh` recent | `,fl` lines | `,e` browser | `,E` browser (file dir) | `,,` last file

### Classic Code

`,dd` def | `,dt` type | `,di` impl | `,dr` refs | `,dk` docs | `,dp` `,dn` diagnostics | `[e` `]e` ALE errors | `,rn` rename | `,ca` action | `,o` outline | `,cr` run

### Classic Edit

`,S`+2ch jump | `gc` comment | `cs"'` surround | `Alt+j/k` move line | `,u` undo tree | `,y` clipboard | `,*` replace word | `,F` re-indent (v) | `,W` strip whitespace | `[<Space>` `]<Space>` blank lines

### Classic Git

`,gs` status | `,gd` diff | `,gb` blame | `,gc` commit | `,gL` log graph | `,gC` FZF commits | `,gB` buffer commits | `]x` `[x` conflict

### Classic Windows

`Ctrl-h/j/k/l` windows | `<C-w>h/j/k/l` native fallback | `,z` maximize | `,h` `,l` buffers | `,bd` close buffer | `,=` `,-` resize | `,tv` `,th` terminal

### Classic Markdown

`,mp` preview in browser | `,mt` table of contents

### Classic Toggle

`F2` paste | `F3` line numbers | `F4` relative numbers | `F6` invisible chars | `,ss` spell check | `,af` format on save

### Utilities

`,cp` copy full path | `,cf` copy filename | `,ec` local config | `,ev` edit vimrc | `,sv` reload | `,wa` save all | `:ChopsticksStatus` diagnostics

</details>

## LSP

```vim
:LspInstallServer    " auto-detects filetype
:LspStatus           " check what's running
:ChopsticksStatus    " see runtime, plugin locks, tools, LSP, and linters
:ChopsticksDoctor    " actionable health issues and setup hints
```

pylsp, gopls, rust-analyzer, clangd, and sqls need no Node.js. JS/TS servers
need Node.
Markdown LSP (`marksman`) is opt-in so prose buffers stay quiet by default.
`:ChopsticksStatus` separates the Vim LSP stack from individual servers:
profile disabled, plugin missing, plugin installed but not loaded yet, and
per-filetype server installation are reported independently.

ALE and vim-lsp coexist cleanly (`ale_disable_lsp=1`). ALE handles linting + formatting. vim-lsp handles everything else.

## Markdown

Markdown opens in writing mode: wrapped text, no spell noise, no concealed
syntax, no sign column, no real-time markdownlint, and no Marksman diagnostics.
The explicit commands still work:

```vim
,mp    " preview in browser
,mt    " table of contents
```

Opt into heavier Markdown tooling from your own vimrc before loading
chopsticks:

```vim
let g:chopsticks_markdown_lint = 1
let g:chopsticks_markdown_format_on_save = 1
let g:chopsticks_markdown_lsp = 1
let g:chopsticks_markdown_spell = 1
let g:chopsticks_markdown_conceal = 1
let g:previm_enable_realtime = 1
```

For Markdown LSP, install or select `marksman` first.

## Architecture

```
~/.vim/
├── .vimrc              thin loader
├── CONTEXT.md          project vocabulary and long-term constraints
├── docs/
│   └── adr/            recorded architecture decisions
├── doc/
│   └── chopsticks.txt  :help chopsticks
└── modules/
    ├── env.vim         profile, TTY detection, truecolor, built-in skips
    │                   :ChopsticksRuntimeInfo runtime compatibility
    ├── info.vim        shared info shape, surface registry, status adapter
    ├── input_method.vim optional im-select integration for CJK writing
    ├── plugins.vim     vim-plug + pinned profile/option-driven plugins
    ├── core.vim        settings, keymaps, performance
    ├── ui.vim          solarized, statusline, startify
    ├── editing.vim     editing assist, easymotion, undo history
    ├── navigation.vim  project search, netrw sidebar, windows, terminal
    ├── lsp.vim         vim-lsp, asyncomplete, LSP diagnostics
    ├── lint.vim        ale, format-on-save
    ├── git.vim         fugitive, gitgutter, conflict nav
    ├── languages.vim   vim-go, markdown, filetype settings
    ├── buffers.vim     buffer lifecycle commands
    ├── utilities.vim   config/reload, path copy, sudo-save helpers
    ├── files.vim       auto mkdir, large-file protection
    ├── runner.vim      run current file
    ├── quickfix.vim    quickfix and location-list helpers
    ├── keymap.vim      :ChopsticksKeymapAudit ergonomic contract
    ├── tools.vim       external toolchain diagnostics
    ├── health.vim      :ChopsticksDoctor machine-readable health
    ├── status.vim      :ChopsticksStatus diagnostics
    ├── learning.vim    Learning Surface model and readiness
    ├── cheatsheet.vim  SPC ?, :ChopsticksCheatSheet reference view
    ├── tutor.vim       :ChopsticksTutor guided practice
    ├── beta.vim        :ChopsticksBeta release checklist
    └── help.vim        :ChopsticksHelp native Vim help
```

Each module is self-contained. Comment out one line in `.vimrc` to disable it. Add your own with `call s:load('mine')`.
Use [CONTEXT.md](CONTEXT.md) for project vocabulary and `docs/adr/` for
decisions that future changes must not re-litigate casually.

## Performance

| Metric                   | Value                                       |
| ------------------------ | ------------------------------------------- |
| Lazy-loaded              | 7 plugins (on command or filetype)          |
| Built-in plugins skipped | 12 (gzip, tar, zip, vimball, logiPat, etc.) |
| Large file threshold     | 10MB (auto-disables syntax + undo)          |
| TTY large file           | 500KB (syntax disabled)                     |

## Troubleshooting

| Problem             | Fix                                           |
| ------------------- | --------------------------------------------- |
| Plugins not loading | `:PlugInstall` then `:PlugUpdate`             |
| LSP not starting    | `:LspInstallServer` for current filetype      |
| Colors wrong        | `export COLORTERM=truecolor` in shell rc      |
| Optional `Ctrl+s` freezes | `stty -ixon` in shell rc                |
| Everything slow     | Large file? Auto-disabled >10MB               |
| What's installed?   | `:ChopsticksStatus` shows runtime and optional tools |

For deeper checks, start with `:ChopsticksStatus`, `SPC ?`,
`:ChopsticksTutor`, `:ChopsticksHelp`, `:ChopsticksConfig`, and
[QUICKSTART.md](QUICKSTART.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The rules that matter most: Vim only,
no Node.js in the Vim runtime, pinned plugins, documented architectural
decisions, and no unjustified startup regression.

Regenerate the README demo after changing public keybindings:

```bash
vhs .github/demo.tape
```

The tape uses `.github/demo-project` and forces the current repository `.vimrc`,
so the GIF should show the same keymap the code actually ships.

## License

[MIT](LICENSE)
