# Contributing

## Rules

1. **No Node.js dependencies.** The LSP engine is pure VimScript. Some language servers need Node — that's fine. The config itself must not.
2. **Startup matters.** Run `vim -u .vimrc -i NONE --startuptime /tmp/s.log -es -N -c qa!` before and after. If your change adds >1ms, it needs a good reason.
3. **Works on TTY.** Test over SSH. If it breaks in a terminal without true color, fix it or gate it behind `g:is_tty`.
4. **One module, one concern.** Don't put git config in lsp.vim.

## Adding a plugin

1. Add the `Plug` line to `modules/plugins.vim`
2. If it's not needed at startup, lazy-load it: `Plug 'foo/bar', { 'on': 'FooCommand' }`
3. Put config in the appropriate module
4. Update the cheat sheet in `modules/tools.vim` if you add keybindings
5. Run `scripts/test.sh vim` locally after installing plugins
6. Test on both macOS and Linux when changing terminal or package-manager behavior

## Local tests

```bash
scripts/test.sh shell docs installer bootstrap
scripts/test.sh vim
```

`scripts/test.sh vim` expects plugins to be installed under `~/.vim/plugged`.
Use `STARTUP_LIMIT_MS=150 scripts/test.sh vim` to match CI's startup threshold.

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
