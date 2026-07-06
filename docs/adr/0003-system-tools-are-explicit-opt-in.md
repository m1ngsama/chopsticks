# System Tools Are Explicit Opt-In

The default installer manages the Vim config and pinned Vim plugins, but it
does not install system packages, formatter suites, LSP servers, Go tools, npm
tools, Python tools, or tmux integration unless the user passes
`--install-tools`. A dotfile installer should not take over a machine merely
because someone wants the Vim runtime.

## Consequences

- `--yes` chooses defaults but does not imply system tool installation.
- Missing optional tools should be reported by `:ChopsticksStatus`, not treated
  as startup failures.
- Tool installation code must stay separate from config/profile setup.
