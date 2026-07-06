# Learning Surface Model Is Shared

Chopsticks teaches one trained project loop through the active cheat sheet,
guided tutor, and release-candidate guide. Those views can have different
layouts, but their row, task, and drill models should not be rebuilt in each
module.

## Decision

- Use `ChopsticksLearningRowLines()` and `ChopsticksLearningRowLinesOr()` to
  render Learning Surface rows that may be fixed-column key/label rows,
  preformatted lines, or custom-gap rows.
- Use `ChopsticksLearningTaskLine()` for release-guide task-list text.
- Use `ChopsticksLearningDrillLine()` for tutor daily-drill text.
- Keep the Learning Display Adapter pure Vimscript in `modules/env.vim`; it
  renders learning data already owned by the Learning Surface and does not add
  Neovim or Lua paths.

## Consequences

- Cheat sheet, tutor, and beta guide keep their own layouts, but consume the
  same row/task/drill model.
- Changes to daily-loop or LSP-loop learning rows can be tested once at the
  adapter interface and then through the existing view smoke tests.
- New learning views should consume the shared Learning Display Adapter before
  adding local row loops or task/drill string joins.
