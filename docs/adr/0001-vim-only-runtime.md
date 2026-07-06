# Vim-Only Runtime

Chopsticks targets Vim 8.2 and Vim 9.x only. The runtime rejects Neovim,
excludes Lua and `stdpath()` branches, and avoids Neovim-only plugin
dependencies because the project is meant to be a portable Vim dotfile kit that
works the same over local terminals and SSH.

## Consequences

- Vim compatibility is a release gate, not a best-effort fallback.
- Neovim ecosystem convenience is not a reason to add a parallel runtime path.
- New plugins must have a pure VimScript-compatible path.
- `scripts/test.sh quick` must reject Neovim-only runtime markers such as
  `stdpath()`, `nvim_` APIs, Lua runtime entry points, and stray `has('nvim')`
  branches outside the startup/runtime gate.
