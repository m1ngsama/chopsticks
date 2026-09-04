# Changelog

Notable user-facing changes are recorded here. This project follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and uses semantic
versions for the current Vim-first line.

The project was rebooted at `v0.1.0` on 2026-08-04. Historical `v1.x` and
`v2.x` tags describe a retired, modular implementation and are not newer
releases of the current line.

## [Unreleased]

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
- fzf is an explicit system prerequisite; startup no longer invokes the
  plugin's unverified release downloader.
- Vim 9.1.1947 or newer is required on every platform, not only Windows. The
  reason is unchanged -- older builds carry an upstream executable search-path
  vulnerability -- but the floor is no longer split by platform.
- Configuration and behavior are separated. `.vimrc` keeps the bootstrap and
  the settings a person edits; the code those settings drive moved into
  Vim9script modules under `autoload/chopsticks/`, which Vim does not read
  until one of their functions is called. Starting Vim on a file no longer
  sources the dashboard, session, health, Markdown, or cheatsheet code.

### Fixed

- The documented symlink install works. `.vimrc` derived its own directory
  from `$MYVIMRC`, which names the symlink rather than this repository, so a
  README-following install silently added `$HOME` to `'runtimepath'` instead.
  A regression test now performs that install.
- The session directory is created with the intended private permissions.
  Its mode was written as `0700`, which Vim9 reads as decimal 700 rather than
  octal 448.
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
- The fzf `Ctrl-O` action now opens the selected file instead of invoking
  Vim's unrelated legacy `:open` command.
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

[Unreleased]: https://github.com/m1ngsama/chopsticks/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/m1ngsama/chopsticks/releases/tag/v0.1.0
