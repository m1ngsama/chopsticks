# chopsticks

[![check](https://github.com/m1ngsama/chopsticks/actions/workflows/check.yml/badge.svg)](https://github.com/m1ngsama/chopsticks/actions/workflows/check.yml)

![chopsticks rich Vim workflow][demo]

A Vim 9.1.1947+ configuration focused on development and Markdown writing.
The floor is 9.1.1947 because older builds have an
[upstream executable search-path vulnerability](https://github.com/vim/vim/security/advisories/GHSA-g77q-xrww-p834).
Neovim is not supported. Startup never uses the network and every plugin is
pinned to a commit.

[Configuration](docs/configuration.md) ·
[Performance](docs/performance.md) ·
[Troubleshooting](docs/troubleshooting.md) ·
[Contributing](CONTRIBUTING.md) ·
[Changelog](CHANGELOG.md) ·
[Security](SECURITY.md)

## Install

Requires Vim 9.1.1947+, Git, a system `fzf` executable,
and [vim-plug](https://github.com/junegunn/vim-plug). Install the executable
prerequisites first:

```sh
# macOS
brew install vim git fzf curl

# Debian or Ubuntu
sudo apt-get update
sudo apt-get install -y vim git fzf curl
```

Move aside an existing `~/.vimrc`, `~/chopsticks`, or
`~/.vim/autoload/plug.vim`, then install Chopsticks and the checksum-verified
vim-plug bootstrap on POSIX:

```sh
set -eu
chopsticks_repo="$HOME/chopsticks"
chopsticks_plug="$HOME/.vim/autoload/plug.vim"
if [ -e "$chopsticks_repo" ] || [ -L "$chopsticks_repo" ] || \
  [ -e "$HOME/.vimrc" ] || [ -L "$HOME/.vimrc" ]; then
  printf '%s\n' 'Refusing to overwrite ~/chopsticks or ~/.vimrc' >&2
  exit 1
fi
if [ -e "$chopsticks_plug" ] || [ -L "$chopsticks_plug" ]; then
  printf '%s\n' 'Refusing to overwrite ~/.vim/autoload/plug.vim' >&2
  exit 1
fi
git clone https://github.com/m1ngsama/chopsticks.git "$chopsticks_repo"
ln -s "$chopsticks_repo/.vimrc" "$HOME/.vimrc"

chopsticks_plug_dir="${chopsticks_plug%/*}"
mkdir -p "$chopsticks_plug_dir"
chopsticks_plug_tmp="$(mktemp "$chopsticks_plug_dir/.plug.vim.XXXXXX")"
trap 'rm -f "$chopsticks_plug_tmp"' EXIT HUP INT TERM
curl -fsSL \
  https://raw.githubusercontent.com/junegunn/vim-plug/88e31471818e9a29a8a20a0ee61360cfd7bdc1cd/plug.vim \
  -o "$chopsticks_plug_tmp"
chopsticks_plug_sha=7e2b20cd909da9c456498684c98f03c63829170f01e34595dd8e1818a217d37c
if command -v shasum >/dev/null 2>&1; then
  chopsticks_plug_actual="$(shasum -a 256 "$chopsticks_plug_tmp" | awk '{print $1}')"
elif command -v sha256sum >/dev/null 2>&1; then
  chopsticks_plug_actual="$(sha256sum "$chopsticks_plug_tmp" | awk '{print $1}')"
else
  printf '%s\n' 'No SHA-256 tool found (need shasum or sha256sum)' >&2
  exit 1
fi
if [ "$chopsticks_plug_actual" != "$chopsticks_plug_sha" ]; then
  printf '%s\n' 'vim-plug SHA-256 mismatch' >&2
  exit 1
fi
chmod 0644 "$chopsticks_plug_tmp"
mv "$chopsticks_plug_tmp" "$chopsticks_plug"
trap - EXIT HUP INT TERM
vim +PlugInstall +qall
```

On Windows, install the prerequisites from PowerShell:

```powershell
$ErrorActionPreference = 'Stop'
foreach ($package in 'vim.vim', 'Git.Git', 'junegunn.fzf') {
  winget install --exact --id $package
  if ($LASTEXITCODE -ne 0) {
    throw "WinGet failed to install $package (exit $LASTEXITCODE)"
  }
}
```

Close and reopen PowerShell so WinGet's PATH changes take effect, then confirm
all three commands resolve before continuing. The setup refuses to overwrite
an existing `~/chopsticks`, `~/_vimrc`, or `~/vimfiles/autoload/plug.vim`;
move any of them aside first:

```powershell
$ErrorActionPreference = 'Stop'
Get-Command vim, git, fzf

$chopsticksRepo = Join-Path $HOME 'chopsticks'
$vimrcPath = Join-Path $HOME '_vimrc'
$plugDirectory = Join-Path $HOME 'vimfiles\autoload'
$plugPath = Join-Path $plugDirectory 'plug.vim'
if ($null -ne (Get-Item -Force -ErrorAction SilentlyContinue -LiteralPath $chopsticksRepo)) {
  throw "Refusing to overwrite $chopsticksRepo"
}
if ($null -ne (Get-Item -Force -ErrorAction SilentlyContinue -LiteralPath $vimrcPath)) {
  throw "Refusing to overwrite $vimrcPath"
}
if ($null -ne (Get-Item -Force -ErrorAction SilentlyContinue -LiteralPath $plugPath)) {
  throw "Refusing to overwrite $plugPath"
}
git clone https://github.com/m1ngsama/chopsticks.git $chopsticksRepo
if ($LASTEXITCODE -ne 0) {
  throw "git clone failed (exit $LASTEXITCODE)"
}
"execute 'source ' . fnameescape(expand('~/chopsticks/.vimrc'))" |
  Set-Content -Encoding ascii -LiteralPath $vimrcPath

New-Item -ItemType Directory -Force -Path $plugDirectory | Out-Null
$plugTemporary = Join-Path $plugDirectory ("plug.vim.{0}.tmp" -f [guid]::NewGuid())
$plugUri = 'https://raw.githubusercontent.com/junegunn/vim-plug/88e31471818e9a29a8a20a0ee61360cfd7bdc1cd/plug.vim'
$plugSha = '7e2b20cd909da9c456498684c98f03c63829170f01e34595dd8e1818a217d37c'
try {
  Invoke-WebRequest -UseBasicParsing -Uri $plugUri -OutFile $plugTemporary
  if ((Get-FileHash -Algorithm SHA256 -LiteralPath $plugTemporary).Hash -ne $plugSha) {
    throw 'vim-plug SHA-256 mismatch'
  }
  Move-Item -LiteralPath $plugTemporary -Destination $plugPath
} finally {
  Remove-Item -ErrorAction SilentlyContinue -LiteralPath $plugTemporary
}
vim +PlugInstall +qall
if ($LASTEXITCODE -ne 0) {
  throw "Vim plugin installation failed (exit $LASTEXITCODE)"
}
```

Recommended optional tools:

```sh
brew install ripgrep fd lazygit marksman glow pandoc pngpaste
npm install --global markdownlint-cli prettier
```

iTerm2, WezTerm, Kitty, Ghostty, Windows Terminal, and VS Code terminals enable
Nerd Font v3 icons automatically when their active font supports them. Set
`g:chopsticks_icons = 0` before sourcing the file for ASCII output.

The vim-plug bootstrap is pinned and verified before Vim executes it. The fzf
plugin is also commit-pinned, but Chopsticks never runs its bundled downloader;
that downloader fetches a second release artifact without verifying a checksum.

## Interface

The default `balanced` profile keeps the editor informative without showing
every surface all the time. The other profiles change presentation only;
editing, LSP, Markdown, and navigation behavior stay the same.

| Profile    | Dashboard | Bufferline | Statusline                         |
| ---------- | --------- | ---------- | ---------------------------------- |
| `minimal`  | off       | off        | file, flags, diagnostics           |
| `balanced` | compact   | 2+ files   | adds writing, Git branch, progress |
| `rich`     | full      | always     | adds file icons, type, Git diff    |

Everforest is the default theme. A missing requested theme safely falls back
to Vim's built-in `default` theme. Transparency defaults to opaque because a
terminal can report truecolor support but cannot report whether its compositor
is actually transparent.

Override settings before sourcing `.vimrc`, or edit the personal switches near
the top of the file:

```vim
let g:chopsticks_ui_density = 'minimal' " minimal, balanced, or rich
let g:chopsticks_colorscheme = 'everforest'
let g:chopsticks_transparent_background = 0 " auto, 0, or 1
let g:chopsticks_dashboard = 'auto'           " auto, 0, or 1
let g:chopsticks_bufferline = 'auto'          " auto, 0, or 1
let g:chopsticks_system_clipboard = 'auto'     " auto, 0, or 1
```

Machine-specific overrides can live in `~/.vim/chopsticks.local.vim` on Unix
or `~/vimfiles/chopsticks.local.vim` on Windows. It is loaded before these
defaults and stays outside the repository.

On a local desktop build with `+clipboard`, `p`/`P` use the system clipboard
and yanks update it. `SPC p`/`SPC P` still paste Vim's register 0, which keeps
the last explicit yank available after a delete.

Change presentation live with:

```vim
:ChopsticksUiDensity rich
:ChopsticksTheme everforest
:ChopsticksTransparencyToggle
```

Calling `:ChopsticksUiDensity` without an argument cycles all three profiles.
The dashboard and bufferline also adapt to narrow windows; overflow buffers are
summarized instead of pushing the active buffer off-screen.

## Use

Pause after Space, or after comma in Markdown, to open the contextual key
guide. `SPC ?` opens the searchable full cheatsheet and `SPC h` the health
report; the start screen names both.

```text
Ctrl-s  save              Ctrl-p / ;f  find files
;r      project grep      \             list buffers
H / L   previous/next     sh/sj/sk/sl   focus window
ss / sv split/vsplit      sq            close window
SPC e   toggle file tree  SPC u i       toggle icons
SPC u d cycle UI density  SPC u b       toggle transparency

SPC b   buffers           SPC c         code
SPC f   files             SPC g         Git
SPC r   run               SPC s         search
SPC t   terminal          SPC w         windows
SPC x   diagnostics       SPC u         toggles
```

Inside Fern, `CR` or `l` toggles a directory without leaving its row; `h`
collapses it or moves to its parent. `q`, `Esc`, or `SPC e` closes the drawer.

Comma is the Markdown LocalLeader:

```text
,o  heading outline       ,O  insert TOC
,x  toggle task           ,tt table mode
,tr realign table         ,i  paste clipboard image
,p  browser preview       ,g  Glow preview
,z  focus mode            ,f  format
,l  lint                  ,?  Markdown keys
```

```vim
:ChopsticksHealth
:ChopsticksCheatsheet
```

Project sessions use Vim's native `:mksession`, stored under the platform data
directory (`~/.vim/.sessions` on Unix and `~/vimfiles/.sessions` on Windows);
Startify is not required. Paths are keyed by the resolved project root and Vim
release, so projects with the same directory name do not collide and
incompatible Vim session formats do not overwrite each other.

```vim
:ChopsticksSessionSave
:ChopsticksSessionLoad
:ChopsticksSessionLoad! " explicitly load despite modified listed buffers
```

Sessions store layout and file references, not unsaved text, and deliberately
do not restart terminal jobs. A normal load refuses to alter the current layout
while any listed buffer is modified; write it first or use the bang form as an
explicit opt-in. On POSIX, Chopsticks writes private modes and refuses session
directories or files writable by another group/user. Windows relies on the
user-profile ACL. Every platform rejects non-regular session input; only load
sessions from a directory you trust.

## Layout

```text
.vimrc                    bootstrap and configuration
plugin/chopsticks.vim     the public Chopsticks* commands and functions
autoload/chopsticks/      behaviour, in Vim9script, loaded on first use
```

`.vimrc` holds what a person edits: which key does what, which filetype gets
which indent, what each plugin is told. It stays legacy Vim script because
vimlint — the linter that checks it on every commit — cannot parse Vim9
`import`, and `.vimrc` is the one file vimlint still covers. Its own first
job is to add this repository to `'runtimepath'`, since nothing below can
reach a module before that.

Everything those settings drive lives under `autoload/chopsticks/` in
Vim9script, and Vim does not read a module until one of its functions is
called. Starting Vim on an ordinary file leaves the dashboard, session,
health, clipboard, and scratch-window modules declared but unsourced; the
rest load because something on the startup path genuinely uses them — the
statusline and tabline draw, the key catalogue is built, and a
`BufWinEnter` guard checks every buffer for a line long enough to make
'breakindent' expensive.

To see it for a given file:

```vim
:echo filter(getscriptinfo(), {_, i -> i.name =~# 'chopsticks/'})
```

An entry with `autoload: v:true` is declared but has not been read.

Nine `Chopsticks*` functions are declared in `.vimrc` rather than in
`plugin/`. `'statusline'` and `'tabline'` name two of them, and a redraw can
evaluate those while `.vimrc` is still executing — before Vim sources
anything under `plugin/`, so a definition there would be too late. The rest
are reachable from those two, or from `.vimrc`'s own top level, and are
declared alongside them for the same reason.

## Design lineage

Chopsticks ports established interaction patterns to Vim 9.1.1947 instead of
recreating a Neovim runtime:

- Dashboard actions and semantic icons follow
  [Snacks](https://github.com/folke/snacks.nvim/blob/882c996cf28183f4d63640de0b4c02ec886d01f2/lua/snacks/dashboard.lua#L80-L200)
  and
  [LazyVim](https://github.com/LazyVim/LazyVim/blob/459a4c3b1059671e766a46c7cc223827dc67e3d0/lua/lazyvim/plugins/ui.lua#L300-L328),
  with navigable current-item behavior from
  [mini.starter](https://github.com/nvim-mini/mini.starter/blob/25de4998197d59673f1918968a8f4060195edca0/lua/mini/starter.lua#L1374-L1420).
- Semantic key groups and icon/text fallbacks draw from
  [which-key](https://github.com/folke/which-key.nvim) and
  [AstroUI](https://github.com/AstroNvim/AstroNvim/blob/11ac246aae7218ad077f94a2807e142c48d2510c/lua/astronvim/plugins/_astroui.lua#L43-L124).
- Reversible tree navigation uses Fern's official
  [`fern#smart#leaf()`](https://github.com/lambdalisue/vim-fern/blob/3bbca3c87a57cdc87495b91a695b8eda722a1de1/doc/fern.txt#L657-L684)
  model, matching the `h`/`l` conventions in
  [AstroNvim](https://github.com/AstroNvim/AstroNvim/blob/11ac246aae7218ad077f94a2807e142c48d2510c/lua/astronvim/plugins/neo-tree.lua#L73-L184)
  and
  [SpaceVim](https://github.com/SpaceVim/SpaceVim/blob/eed9d8f14951d9802665aa3429e449b71bb15a3a/docs/documentation.md#L904-L934).
- Colors, diagnostic severities, and Git hunk counts stay delegated to the
  official APIs of [Everforest](https://github.com/sainnhe/everforest),
  [ALE](https://github.com/dense-analysis/ale), and
  [vim-gitgutter](https://github.com/airblade/vim-gitgutter/blob/90b75207bd9b55d8ac4af15f72b4e935462014d0/README.mkd#L279-L288).

## Reproduce the demo

The hero GIF is generated by [VHS](https://github.com/charmbracelet/vhs) from
`.github/demo.tape`. Its recording harness forces the documented rich profile
but still sources the real `.vimrc` and installed plugins.

```sh
brew install vhs ffmpeg
npm run demo
```

The tape expects `rg`, `fzf`, and **JetBrainsMono Nerd Font Mono** so icon and
cell widths remain deterministic.

## Update

```sh
git -C "$HOME/chopsticks" pull --ff-only
vim +PlugUpdate +qall
```

## License

MIT

[demo]: .github/demo.gif
