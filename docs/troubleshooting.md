# Troubleshooting

Start with:

```vim
:ChopsticksHealth
:messages
```

When opening a bug report, include the health output after removing private
paths, `:version`, the terminal name, and whether Vim is local or over SSH.

## Plugins or commands are missing

Confirm that vim-plug exists at `~/.vim/autoload/plug.vim` on Unix or
`~/vimfiles/autoload/plug.vim` on Windows, then run:

```vim
:PlugInstall
```

Restart Vim after installation. Startup intentionally stays offline and will
not install a missing plugin or the `fzf` executable for you. Confirm the latter
with `:echo executable('fzf')`; install it with `brew install fzf`,
`sudo apt-get install fzf`, or `winget install --exact --id junegunn.fzf`.
Chopsticks does not run fzf's bundled unverified release downloader. On Vim
versions older than patch 8.2.5136, Fern is unavailable and `SPC e`
deliberately falls back to netrw.

## Icons are boxes or columns do not align

Select a Nerd Font v3 **Mono** font in the terminal, not only in the operating
system. If the terminal cannot use that font, force the tested ASCII path in
`<data-dir>/chopsticks.local.vim` (`~/.vim` on Unix and `~/vimfiles` on
Windows):

```vim
let g:chopsticks_icons = 0
```

Restart Vim so Fern and key-guide groups are rebuilt consistently.

## System clipboard integration is unavailable

Check the Vim feature and effective setting:

```vim
:echo has('clipboard')
:set clipboard?
```

A Vim build without `+clipboard` cannot use the system clipboard. Automatic
integration is disabled over SSH and when no desktop display is detected. Force
it only when the remote or forwarded clipboard is known to work:

```vim
let g:chopsticks_system_clipboard = 1
```

`SPC p` and `SPC P` use register 0 regardless, preserving the last explicit
yank after a delete.

## Search is empty or slow

Inside a Git worktree, file search prefers Git's tracked-file list. Elsewhere it
uses `fd`, then `rg`, then fzf's native file source. Install `git`, `fzf`,
`ripgrep`, and optionally `fd`, and verify that each command is visible in
`:ChopsticksHealth`.

Project grep requires `rg`. The project root is the nearest parent containing
`.git`; outside a worktree it is Vim's current directory.

## LSP, linting, or formatting does not run

Plugins provide the editor integration, while language servers, linters, and
formatters are separate executables. Inspect:

```vim
:LspStatus
:ALEInfo
:ChopsticksHealth
```

Linting is manual by default. Use `,l` or `:ALELint` in a Markdown buffer. To
lint automatically when entering and saving supported files, add this to
`<data-dir>/chopsticks.local.vim`:

```vim
let g:chopsticks_auto_lint = 1
```

Open a buffer with the expected filetype before checking. Install the relevant
tool using its official package instructions, restart Vim, and check `:messages`
for discovery errors.

## The theme or background is wrong

Test a built-in theme to separate theme installation from terminal rendering:

```vim
:ChopsticksTheme default
:ChopsticksTransparencyToggle
```

An unknown theme safely falls back to Vim's `default`. Transparency is opaque
in `auto` mode; enable it explicitly only when the terminal compositor has a
transparent background.

## A session is refused or does not restore edits

Sessions store windows, buffers, and file references, not unsaved contents or
running terminal jobs. Write modified files before
`:ChopsticksSessionSave`.

A normal `:ChopsticksSessionLoad` also refuses to change the current layout
while any listed buffer is modified. Write those buffers, or deliberately use
`:ChopsticksSessionLoad!` to load anyway. The bang does not bypass path safety.

On POSIX, Chopsticks refuses a session directory or file writable by group or
other users. Fix ownership and modes instead of bypassing the check. Windows
uses the user-profile ACL rather than interpreting `getfperm()` as Unix mode
bits. Both platforms require a real session directory and a regular session
file. Never load a session received from someone else: a Vim session is
executable script.

## Windows exits during startup

Windows requires Vim 9.1.1947 or newer. Upgrade Vim rather than bypassing the
guard; older builds have an upstream executable search-path vulnerability.

Chopsticks now follows Vim's Windows-native `~/vimfiles` data directory. If an
older install intentionally keeps plugins and state under `~/.vim`, either move
that content to `~/vimfiles` or set the legacy root before sourcing Chopsticks
from `~/_vimrc`:

```vim
let g:chopsticks_data_dir = '~/.vim'
execute 'source ' . fnameescape(expand('~/chopsticks/.vimrc'))
```

## Report a reproducible problem

Use the
[bug report form](https://github.com/m1ngsama/chopsticks/issues/new?template=bug_report.yml)
and reduce the problem to the smallest file and command sequence you can. Send
security-sensitive reports through the private channel in
[SECURITY.md](../SECURITY.md).
