# Contributing

## Rules

1. **Vim only.** Target Vim 8.2 and Vim 9.x. Do not add Neovim-only branches, `stdpath()` paths, Lua modules, or Neovim plugin dependencies. `scripts/test.sh quick` has a static gate for this.
2. **No Node.js in the Vim runtime.** Plugins must work with pure VimScript — no coc.nvim or other Node-backed completion engines. External CLIs (prettier, eslint, markdownlint, stylelint, tsc) installed via npm are fine; ALE shells out to them as optional system tools, not as part of the Vim runtime.
3. **Startup matters.** Run `vim -u .vimrc -i NONE --startuptime /tmp/s.log -es -N -c qa!` before and after. If your change adds >1ms, it needs a good reason.
4. **Works on TTY.** Test over SSH. If it breaks in a terminal without true color, fix it or gate it behind `g:is_tty`.
5. **Native-first keymaps.** Enhance Vim's native behavior instead of replacing it. Do not override built-in motions, operators, text objects, or help-oriented keys for discoverability alone. Rare exceptions, such as the default Space-layout `s` jump, must have a documented native replacement, cheat-sheet coverage, and a classic-layout fallback.
6. **One module, one concern.** Don't put git config in lsp.vim.
7. **Keep architecture memory current.** Use `CONTEXT.md` for project vocabulary
   and `docs/adr/` for hard-to-reverse decisions such as runtime scope, plugin
   reproducibility, installer behavior, or keymap policy.

## Adding a plugin

1. Add the `Plug` line to `modules/plugins.vim`
2. Add its verified commit to `s:plugin_locks`; keep `g:chopsticks_pin_plugins` on by default
3. If it's not needed at startup, lazy-load it: `Plug 'foo/bar', { 'on': 'FooCommand' }`
4. Put config in the appropriate module
5. Check new mappings against native Vim behavior before adding them
6. Update the cheat sheet definitions in `modules/cheatsheet.vim` if you add keybindings
7. Update `:ChopsticksKeymapAudit` expectations if the public keymap changes
8. Run `scripts/test.sh vim` locally after installing plugins
9. Test on both macOS and Linux when changing terminal or package-manager behavior

## Local tests

```bash
scripts/test.sh --help
scripts/test.sh quick
scripts/test.sh vim
```

`scripts/test.sh quick` runs shell, Vim-only static gates, docs, installer, and bootstrap checks without requiring Vim plugins.
`scripts/test.sh vim` expects plugins to be installed under `~/.vim/plugged`.
Use `STARTUP_LIMIT_MS=150 scripts/test.sh vim` to match CI's startup threshold.

## CI and releases

GitHub Actions intentionally stays small:

- `.github/workflows/check.yml` runs `scripts/test.sh quick` plus one Ubuntu Vim smoke check on pushes and pull requests to `main`.
- `.github/workflows/release.yml` runs only for stable tags like `v2.3.0`, repeats the same checks, extracts the matching `CHANGELOG.md` section, and creates the GitHub Release.

Release flow: update `CHANGELOG.md`, complete the release checklist, create `vX.Y.Z`, then push that tag. The release workflow does not push tags, publish packages, deploy a site, or regenerate the README GIF.

## Reporting bugs

Open an issue. Include:

- OS and Vim version
- Whether you're on SSH/TTY
- Steps to reproduce

## Code style

- Named augroups with `autocmd!`
- No comments explaining _what_ — only _why_
- `exists('g:plugs["..."]')` guards for plugin-dependent config
- Test with `scripts/test.sh vim`
