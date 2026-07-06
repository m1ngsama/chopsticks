# Learning Surface Consumers Use Model Adapters

The Learning Surface now exposes shared daily-loop and LSP-loop info, but
consumer views still need fallback behavior when info producers are late-loaded,
disabled, or incomplete. Keeping those fallback rules in every view makes tutor,
cheat sheet, and beta guide drift even when the visible output is unchanged.

## Decision

- Use `ChopsticksLearningLoopEnabled()` for LSP learning readiness precedence:
  LSP-loop `enabled`, then daily-loop `lsp_enabled`, then the existing LSP
  learning fallback.
- Use `ChopsticksLearningKey()` for nested `info.keys` lookups with explicit
  fallback keys.
- Use `ChopsticksLearningInfoRowLinesOr()` when a learning view renders a row
  field such as `tutor_rows`, `beta_rows`, or `cheat_rows`.
- Keep these adapters pure Vimscript in `modules/env.vim`; they consume
  Learning Surface info dictionaries and do not add Neovim or Lua paths.

## Consequences

- Tutor, cheat sheet, and beta guide still own their layouts, but no longer
  repeat the same row-field fallback and LSP-readiness checks.
- The Learning Surface producer can move between owner modules without changing
  how consumer views read daily-loop or LSP-loop models.
- Adapter interface tests cover the fallback rules once, while existing Vim
  smoke tests continue to verify the rendered views.
