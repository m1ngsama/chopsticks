# Learning Surface Producer Lives in the Learning Module

The active cheat sheet originally owned both the visible reference view and the
Learning Surface producer interfaces. That made `modules/cheatsheet.vim` too
deeply coupled to tutor, beta guide, status, and health checks because it had
to define the daily-loop, LSP-loop, entrypoint, and learning-readiness models
before other views could consume them.

## Decision

- Move `ChopsticksLearningEntrypointInfo()`,
  `ChopsticksLearningDailyLoopInfo()`, `ChopsticksLearningLspLoopInfo()`, and
  `ChopsticksLearningInfo()` into `modules/learning.vim`.
- Load `modules/learning.vim` before the cheat sheet, tutor, beta guide, and
  help modules in the `.vimrc` module manifest.
- Keep `modules/cheatsheet.vim` as the active reference view and command owner
  for `:ChopsticksCheatSheet`.
- Keep the implementation pure Vimscript; this producer split does not add
  Neovim, Lua, or alternate runtime paths.

## Consequences

- Learning Surface model changes now have one owner module.
- Cheat sheet, tutor, beta guide, status, and health consume the same public
  Learning Surface interfaces without relying on the cheat sheet being a model
  producer.
- Future learning views should consume `ChopsticksLearning...Info()` from
  `modules/learning.vim` instead of adding producer logic to a view module.
