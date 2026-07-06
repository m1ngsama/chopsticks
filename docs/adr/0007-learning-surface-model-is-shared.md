# Learning Surface Model Is Shared

Chopsticks teaches one trained project loop through the active cheat sheet,
guided tutor, and release guide. Those views can have different
layouts, but their row, task, and drill models should not be rebuilt in each
module. GitHub Wiki is intentionally disabled, so durable usage memory must
live in Vim-native learning surfaces instead of an external wiki.

## Decision

- Use `ChopsticksLearningRowLines()` and `ChopsticksLearningRowLinesOr()` to
  render Learning Surface rows that may be fixed-column key/label rows,
  preformatted lines, or custom-gap rows.
- Use `ChopsticksLearningTaskLine()` for release-guide task-list text.
- Use `ChopsticksLearningDrillLine()` for tutor daily-drill text.
- Keep the Learning Display Adapter pure Vimscript in `modules/env.vim`; it
  renders learning data already owned by the Learning Surface and does not add
  Neovim or Lua paths.
- Keep GitHub Wiki off. Add new reference material to the in-editor cheatmap,
  tutor, native help, README, or release guide instead of creating a separate
  wiki surface.

## Consequences

- Cheat sheet, tutor, and beta guide keep their own layouts, but consume the
  same row/task/drill model.
- Changes to daily-loop or LSP-loop learning rows can be tested once at the
  adapter interface and then through the existing view smoke tests.
- New learning views should consume the shared Learning Display Adapter before
  adding local row loops or task/drill string joins.
- Users can recover the keymap from inside Vim over SSH without opening
  GitHub Wiki or a browser.
