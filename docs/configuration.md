# Configuration

Chopsticks keeps machine-specific choices outside the tracked `.vimrc`. Create
`~/.vim/chopsticks.local.vim` on Unix or
`~/vimfiles/chopsticks.local.vim` on Windows. It is loaded before defaults,
plugins, mappings, and the interface are configured.

```vim
let g:chopsticks_ui_density = 'balanced'
let g:chopsticks_colorscheme = 'everforest'
let g:chopsticks_icons = 'auto'
let g:chopsticks_system_clipboard = 'auto'
```

The local file is executable Vimscript. Keep it private and only copy settings
from sources you trust.

## Data directory

Chopsticks follows Vim's native user runtime convention: `~/.vim` on Unix and
`~/vimfiles` on Windows. vim-plug, installed plugins, the local config, backup,
swap, undo, view, and session files all derive from this root.

To use another root, set it in the wrapper that sources the tracked file. This
setting must come before `:source` because it also controls where Chopsticks
looks for the local config and vim-plug:

```vim
let g:chopsticks_data_dir = '~/private/vim-data'
execute 'source ' . fnameescape(expand('~/chopsticks/.vimrc'))
```

The value is expanded to an absolute directory with a trailing separator.
Empty or non-string values safely fall back to the platform default. Set
`g:chopsticks_local_config` or `g:chopsticks_session_dir` before sourcing to
override either derived path independently.

## Settings

| Variable                              | Default                           | Accepted values               | Effect                                   |
| ------------------------------------- | --------------------------------- | ----------------------------- | ---------------------------------------- |
| `g:chopsticks_data_dir`               | `~/.vim` / `~/vimfiles`           | Directory                     | Stores plugins and generated state       |
| `g:chopsticks_local_config`           | `<data-dir>/chopsticks.local.vim` | File or empty string          | Selects the trusted local config         |
| `g:chopsticks_session_dir`            | `<data-dir>/.sessions`            | Directory                     | Stores project session files             |
| `g:chopsticks_ui_density`             | `balanced`                        | `minimal`, `balanced`, `rich` | Controls interface detail                |
| `g:chopsticks_colorscheme`            | `everforest`                      | Vim color name                | Selects the theme                        |
| `g:chopsticks_transparent_background` | `auto`                            | `auto`, `0`, `1`              | Uses an opaque or transparent background |
| `g:chopsticks_dashboard`              | `auto`                            | `auto`, `0`, `1`              | Controls the startup dashboard           |
| `g:chopsticks_bufferline`             | `auto`                            | `auto`, `0`, `1`              | Controls the buffer tabline              |
| `g:chopsticks_system_clipboard`       | `auto`                            | `auto`, `0`, `1`              | Enables the `+` clipboard when available |
| `g:chopsticks_icons`                  | `auto`                            | `auto`, `0`, `1`              | Selects Nerd Font icons or ASCII         |
| `g:chopsticks_use_fern`               | `1`                               | `0`, `1`                      | Uses Fern instead of the netrw fallback  |
| `g:chopsticks_markdown_spell`         | `1`                               | `0`, `1`                      | Enables Markdown spelling                |
| `g:chopsticks_markdown_conceal`       | `0`                               | `0`, `1`                      | Conceals Markdown markup                 |
| `g:chopsticks_markdown_image_dir`     | `assets`                          | Relative directory            | Stores images pasted with `,i`           |
| `g:chopsticks_auto_lint`              | `0`                               | `0`, `1`                      | Lints automatically on enter and save    |
| `g:chopsticks_long_line_threshold`    | `4096`                            | Columns, or `0` to disable    | Drops `breakindent` on very long lines   |

For automatic switches, the strings `on`, `true`, and `yes` are also enabled
values; `off`, `false`, and `no` are disabled values. The numeric forms are the
clearest choice for a local config.

`auto` enables the dashboard outside the `minimal` density. It always shows the
bufferline in `rich`, shows it for two or more file buffers in `balanced`, and
hides it in `minimal`. Clipboard auto-detection requires a local desktop Vim
with `+clipboard`; remote sessions keep Vim registers isolated. Transparency is
opaque by default because terminals cannot report compositor transparency.

Fern requires Vim patch 8.2.5136 or newer. Older supported Vim versions and
`g:chopsticks_use_fern = 0` use netrw without breaking the explorer mapping.

## Live interface commands

These commands update the current Vim process. Add the corresponding setting to
the local config to make a choice persistent.

```vim
:ChopsticksUiDensity
:ChopsticksUiDensity rich
:ChopsticksTheme everforest
:ChopsticksIconsToggle
:ChopsticksTransparencyToggle
```

Calling `:ChopsticksUiDensity` without an argument cycles through all three
densities.

## Sessions

Sessions are keyed by resolved project path and Vim release, which prevents
same-name projects and incompatible Vim formats from colliding.

```vim
:ChopsticksSessionSave
:ChopsticksSessionLoad
:ChopsticksSessionLoad!
```

Save modified files first: native Vim sessions preserve layout and file
references, not unsaved text. The normal load refuses to change the layout when
listed buffers are modified; the bang form is an explicit opt-in to load
anyway. Neither form bypasses session file type, directory, or permission
checks. Session files are executable Vimscript when loaded. Keep
`g:chopsticks_session_dir` private and trusted; see the [security
policy](../SECURITY.md#trust-model).

## Diagnostics

Use these built-in views before changing configuration:

```vim
:ChopsticksHealth
:ChopsticksCheatsheet
```

Health reports effective interface choices, optional tools, plugin state, and
the current project's session. The cheat sheet is generated from the public
mapping catalog and is safer than relying on a copied key list.
