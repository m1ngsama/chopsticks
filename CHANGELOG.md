# Changelog

Notable user-facing changes are recorded here. This project follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and uses semantic
versions for the current Vim-first line.

The project was rebooted at `v0.1.0` on 2026-08-04. Historical `v1.x` and
`v2.x` tags describe a retired, modular implementation and are not newer
releases of the current line.

## [Unreleased]

### Fixed

- The cheatsheet's mode column takes its own colour. Two syntax rules were
  anchored to the same start column, the key won every time, and the mode rule
  never fired -- so the colour 0.2.7 defined for it was never reached.
- `:ChopKeys` was defined twice, and an internal autocommand group was renamed
  along with the commands in 0.3.0 although only commands were meant to change.

## [0.3.0] - 2026-09-07

### Changed

- **Every command is shorter, and the old names are gone.** The `Chopsticks`
  prefix became `Chop` and `Markdown` became `Md`, which is the prefix this
  codebase already used for its highlight groups. `:ChopsticksProjectGrep` is
  `:ChopGrep`, `:ChopsticksTransparencyToggle` is `:ChopTransparency`,
  `:MarkdownPasteImage` is `:MdPaste`; average length falls from 18 characters
  to 9. `:ChopsticksKeys` and `:ChopsticksCheatsheet` were two names for one
  action and are now just `:ChopKeys`.

  Nothing is aliased: keeping the old names would leave fifteen extra entries
  in command completion, which is the thing that made the short names worth
  having. A local configuration or script that calls one by its old name must
  be updated. The `g:chopsticks_*` settings and the `Chopsticks*()` functions
  a statusline might call are untouched.

## [0.2.8] - 2026-09-07

### Added

- A `Start here` block at the top of `SPC ?`. It teaches the four prefixes the
  rest of the map hangs off -- `;` to find, `SPC` for everything by category,
  `s` for windows, `,` for Markdown -- rather than picking a dozen individual
  keys out of the hundred and sixty below it.

## [0.2.7] - 2026-09-07

### Fixed

- The full cheatsheet on `SPC ?` is readable. The buffer has carried
  `filetype=chopsticks-cheatsheet` since it was written with no syntax file
  behind it, so 163 rows rendered in one colour; the title, section headings,
  keys and mode column now follow the active theme like every other surface.
- The cheatsheet's description column no longer goes ragged. Its columns are
  measured from the longest entry rather than fixed, which a five-wide mode
  such as `n/i/x` had already outgrown.

## [0.2.6] - 2026-09-07

### Fixed

- `<Tab>` and `<S-Tab>` now move between snippet placeholders. vim-vsnip
  leaves the placeholder selected in select mode, where an insert-mode mapping
  never fires, so expanding a snippet and pressing `<Tab>` to keep the default
  and move on did nothing at all. Typing over the placeholder first happened
  to work, which is why this survived its own release.
- `:ChopsticksDebug` reports a missing termdebug package instead of raising
  `E919` on a Vim built without it.
- `g:chopsticks_cmdline_autocomplete` and `g:chopsticks_autocomplete` accept
  `on`, `true` and `yes` like every other switch. Both read the raw value
  before, so `= 'yes'` silently meant off.
- Clippy is no longer enabled where nothing can run it: `executable()` answers
  `-1` when it cannot tell, and `-1` is true.

## [0.2.5] - 2026-09-07

### Added

- `g:chopsticks_autocomplete = 1` turns on Vim's insert-mode autocompletion:
  suggestions appear as you type rather than on `<Tab>`. **It is off by
  default.** The migration design that scheduled it recorded it as the least
  proven change in the series, and unlike the command line this rebuilds a
  menu on every keystroke of every buffer; the mechanism ships so the choice
  is one line, and the default waits for the `<Tab>` path to have had real
  use. The omni source is added per buffer when a language server attaches,
  never globally -- at keystroke rate a filetype's own omni-completion
  answers a half-typed line with an error, once per character.

## [0.2.4] - 2026-09-07

### Added

- Snippets, through `hrsh7th/vim-vsnip` and `hrsh7th/vim-vsnip-integ`. A
  completion item that arrives from a language server as a snippet now expands
  instead of landing as literal `${1:...}` text, and `<Tab>` and `<S-Tab>`
  move between its placeholders before they mean anything else. Your own
  snippets go in `<data-dir>/vsnip`, alongside sessions rather than in the
  plugin's `~/.vsnip`.

## [0.2.3] - 2026-09-07

### Added

- `SPC r d` and `:ChopsticksDebug` start Vim's built-in `termdebug` in a
  window layout, choosing `rust-gdb` for Rust and `gdb` elsewhere, and loading
  the package on first use rather than at startup. termdebug speaks GDB/MI, so
  `lldb` is refused even where it is the only debugger installed; on macOS
  that means `brew install gdb` and codesigning it. `:ChopsticksHealth` reports
  whether `gdb` is present.

## [0.2.2] - 2026-09-07

### Added

- Python and Rust linting and formatting. `,l` runs `ruff` on Python and
  `cargo clippy` on Rust, and `,f` formats with `ruff_format` and `rustfmt`.
  Both languages previously had neither: `g:ale_linters_explicit` means only
  the languages named in the list are linted, and they were not in it.
  `:ChopsticksHealth` now reports whether `ruff` and `rustfmt` are installed.

## [0.2.1] - 2026-09-07

### Added

- Command-line autocompletion. Typing `:`, `/` or `?` raises the suggestion
  popup as you type instead of only on `<Tab>`; searches complete from words
  in the buffer. Nothing is selected until you choose it, so `<CR>` still runs
  exactly what you typed, and `<Up>`/`<Down>` still reach command-line history.
  Set `g:chopsticks_cmdline_autocomplete = 0` to go back to completing on
  `<Tab>` alone.

## [0.2.0] - 2026-09-07

### Added

- `minimal`, `balanced`, and `rich` interface densities, with live theme and
  transparency controls.
- Adaptive dashboard, statusline, and bufferline surfaces with Nerd Font and
  ASCII presentation modes.
- Fern file drawer with a built-in netrw fallback.
- Project-scoped native Vim sessions stored with private permissions.
- Machine-local overrides through `~/.vim/chopsticks.local.vim` on Unix and
  `~/vimfiles/chopsticks.local.vim` on Windows.
- Headless UI coverage, plugin integration scenarios, a minimum-supported-Vim
  baseline job,
  and a native Windows Vim smoke job.
- A reproducible offline benchmark with 1 MiB Markdown workloads, regression
  budgets, plugin profiles, and per-commit JSON artifacts in CI.
- Contributor, security, release, performance, configuration, and
  troubleshooting guides plus issue and pull-request templates.
- Code outline on `SPC c l`, inlay hints, and semantic highlighting, from the
  new Vim9script LSP client.
- `g:chopsticks_finder_exclude_dir`, the directories file search never lists.
  Entries are normalised to end in a slash, so a bare `vendor` excludes the
  directory rather than every file anywhere that happens to be named `vendor`.

### Changed

- The dashboard and key guide now share semantic icons and responsive layout.
- Project sessions no longer depend on Startify.
- Linting is manual by default, and expensive syntax and LSP work is bounded
  for large files.
- The vim-plug bootstrap is checksum-verified, plugins and Actions are
  commit-pinned, post-install download hooks are forbidden, and CI enforces the
  pin policy. An isolated, verified Vim-lint cache keeps those dependencies
  maintainable.
- Plugins, local configuration, sessions, and generated state now derive from
  Vim's platform-native data root (`~/.vim` or `~/vimfiles`), with an explicit
  `g:chopsticks_data_dir` override.
- The fuzzy finder is now fuzzbox, a Vim9script plugin with no binary
  dependency, so no separate finder executable is required on any platform.
  `Esc`, `Ctrl-c`, `Ctrl-g` and `Ctrl-q` still close the finder, and `Ctrl-t`,
  `Ctrl-x` and `Ctrl-v` still open the selection in a tab or a split. Two keys
  are gone: `Ctrl-o`, which opened the selection in the current window as
  `Enter` already does, and `Ctrl-/`, which toggled the preview and has no
  fuzzbox equivalent. File search no longer lists only Git-tracked files, so a
  newly created file appears immediately, but it now skips `node_modules/`,
  `vendor/`, `dist/`, `build/`, `target/` and the other directories in
  `g:fuzzbox_files_exclude_dir` even when their contents are tracked. `SPC f g`
  lists tracked files without that exclusion. Project grep matches a literal
  string as you type, where it previously took a regular expression and then
  filtered fuzzily.
- Vim 9.1.1947 or newer is required on every platform, not only Windows. The
  reason is unchanged -- older builds carry an upstream executable search-path
  vulnerability -- but the floor is no longer split by platform.
- Configuration and behavior are separated. `.vimrc` keeps the bootstrap and
  the settings a person edits; the code those settings drive moved into
  Vim9script modules under `autoload/chopsticks/`, which Vim does not read
  until one of their functions is called. Starting Vim on an ordinary file
  leaves the dashboard, session, health, clipboard, and scratch-window
  modules unread.
- Language servers are registered from `lang/` and installed by you, rather
  than downloaded automatically. `:ChopsticksHealth` reports which are present.

### Removed

- `SPC s B` (search all open buffers) and `SPC s m` (search mappings). The
  cheatsheet on `SPC ?` supersedes the latter; the project grep covers the
  former.

### Fixed

- The documented symlink install works. `.vimrc` derived its own directory
  from `$MYVIMRC`, which names the symlink rather than this repository, so a
  README-following install silently added `$HOME` to `'runtimepath'` instead.
  A regression test now performs that install.
- `autoload/chopsticks/session.vim` is tracked. A `Session.vim` ignore rule
  matched it on case-insensitive filesystems.
- A UI test case that quits part-way through is reported instead of passing.
  Failures are recorded as the script runs but reported from its last line,
  so an early exit discarded them and the case reported success.
- Directory startup now opens the selected project in a stable two-pane
  explorer layout.
- File search cancellation consistently returns to Vim.
- Project grep and Git-file search now use the current file's nearest Git root
  without changing Vim's working-directory scope.
- Re-sourcing `.vimrc` no longer duplicates key-guide state or autocommands.
- Session loading now refuses modified buffers and symlink or non-regular
  inputs, enforces private POSIX permissions, and respects the Windows profile
  ACL boundary.
- Buffers holding a very long line no longer freeze a redraw. `breakindent` is
  recomputed while laying out every wrapped screen line, so a 1 MiB single-line
  Markdown file cost tens of seconds per redraw; it is now dropped for such
  buffers, controlled by `g:chopsticks_long_line_threshold`.
- The benchmark's plugin-parser test now derives the vim-plug root from Vim's
  native data directory instead of assuming `~/.vim`, so it passes on Windows.

## [0.1.0] - 2026-08-04

### Added

- Vim-first single-file configuration for Vim 8.2 and 9.x.
- Development, Git, LSP, diagnostics, fuzzy finding, and Markdown workflows.
- Contextual Space and Markdown key guides plus a searchable cheat sheet.
- Headless startup checks and Markdown linting in GitHub Actions.

### Changed

- Replaced the retired multi-module distribution with an auditable `.vimrc`.
- Made plugin installation explicit; startup itself no longer uses the network.

[Unreleased]: https://github.com/m1ngsama/chopsticks/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/m1ngsama/chopsticks/compare/v0.2.8...v0.3.0
[0.2.8]: https://github.com/m1ngsama/chopsticks/compare/v0.2.7...v0.2.8
[0.2.7]: https://github.com/m1ngsama/chopsticks/compare/v0.2.6...v0.2.7
[0.2.6]: https://github.com/m1ngsama/chopsticks/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/m1ngsama/chopsticks/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/m1ngsama/chopsticks/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/m1ngsama/chopsticks/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/m1ngsama/chopsticks/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/m1ngsama/chopsticks/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/m1ngsama/chopsticks/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/m1ngsama/chopsticks/releases/tag/v0.1.0
