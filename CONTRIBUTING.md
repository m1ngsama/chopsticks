# Contributing to chopsticks

Thanks for helping make chopsticks better. Small, focused changes are easiest
to review, and bug fixes with a regression test are especially welcome.

Security reports do not belong in public issues. Follow
[SECURITY.md](SECURITY.md) instead.

## Project contract

Changes should preserve these properties:

- Vim only: support Vim 8.2 and 9.x, not Neovim. Windows support starts at
  Vim 9.1.1947.
- Offline startup: opening Vim must never download or update software.
- Reproducible plugins: every `Plug` declaration stays pinned to a full commit.
- Non-executing plugin installation: plugin declarations do not use
  post-install hooks; install external binaries through a system package
  manager.
- Graceful fallback: optional tools and rich terminal features may improve the
  experience, but their absence must not prevent editing.
- One-file runtime: user-facing behavior remains understandable from `.vimrc`.
- Discoverability: public commands and mappings stay represented in
  `:ChopsticksHealth`, `:ChopsticksCheatsheet`, tests, or documentation as
  appropriate.

Avoid adding a plugin when Vim already provides a clear, maintainable solution.
When a plugin is justified, prefer a focused Vimscript dependency with a stable
upstream and a lazy-loading path.

## Development setup

You need Vim, Git, Python 3.8+, Node.js 22.22.2+, 24.15.0+, or 26+, npm,
Go, and ShellCheck. Install the repository's exact JavaScript development
dependencies with:

```sh
npm ci --ignore-scripts
```

The npm scripts find Python without requiring a platform-specific alias: they
try `py -3` and `python` on Windows, and `python3` then `python` elsewhere. They
fail before running a task when the interpreter is older than Python 3.8.

Install `fzf` as a system dependency before testing fuzzy-finder features.
Chopsticks deliberately does not run fzf's plugin-provided binary downloader;
use one of the upstream-supported package-manager commands instead:

```sh
# macOS with Homebrew
brew install fzf

# Debian or Ubuntu
sudo apt install fzf
```

```powershell
# Windows PowerShell with WinGet
winget install --exact --id junegunn.fzf
```

After installing with WinGet, open a new PowerShell session so the updated
`PATH` is visible.

Each Vim lint run downloads two commit-pinned linters into a fresh, isolated
temporary directory and removes it afterward. On a trusted development
machine, set `CHOPSTICKS_LINT_CACHE` to reuse a persistent cache; the script
still verifies the exact commits and rejects a dirty checkout.

Run the complete local gate before submitting a change:

```sh
npm run lint
npm test
git diff --check
```

`npm run lint` checks formatting, Markdown, GitHub Actions, shell, Vimscript,
and the headless UI behavior. `npm test` also runs the launcher and benchmark
unit tests. CI additionally installs every declared plugin and runs the
integration scenarios in `tests/plugins.vim`.

For the focused runtime and benchmark gate, use:

```sh
npm test
```

That runs the launcher and benchmark unit tests followed by the Vim lint and
headless UI suite. To isolate one layer, run:

```sh
npm run test:benchmark # Python benchmark harness only
npm run lint:vim       # Vim runtime only
```

## Making changes

1. Start from an up-to-date branch and keep the patch focused.
2. Add or update a headless test for behavior changes.
3. Update `README.md` only for the main user journey; put detailed guidance in
   `docs/`.
4. Add a concise entry under `Unreleased` in `CHANGELOG.md` for user-visible
   changes.
5. Run the complete local gate and describe any manual checks in the pull
   request.

When changing terminal, filesystem, session, or shell behavior, test the
relevant platform boundary. When changing the interface, test ASCII icons and
the `minimal`, `balanced`, and `rich` densities. Keymap changes must keep the
searchable cheat sheet accurate.

## Plugin updates

For each plugin change:

1. Use a full, reviewed commit hash rather than a branch or floating tag.
2. Read the upstream changes between the old and new commits.
3. Confirm that `:PlugInstall` succeeds from an empty plugin directory.
4. Run the plugin integration tests and exercise any affected command.
5. Record compatibility or security consequences in the pull request.

Do not add automatic network access to `.vimrc`. Installation and updates stay
explicit user actions through vim-plug.

## Pull requests

Explain the user problem, the chosen solution, and the evidence that it works.
Keep unrelated formatting or refactors out of the patch. A maintainer may ask
for a smaller change when that makes compatibility or rollback easier to
reason about.

Maintainers should follow the [release checklist](docs/releasing.md) when
preparing a tag.
