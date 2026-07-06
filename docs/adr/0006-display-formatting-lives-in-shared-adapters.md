# Display Formatting Lives in Shared Adapters

Chopsticks renders several in-editor reference and diagnostic views from the
same kinds of rows: fixed-width key/label pairs, info details, state-bearing
items, nested info sections, footers, and summary counts. Keeping those display
rules inside each view makes small spacing or counting changes spread across
learning, status, health, and audit modules.

## Decision

- Use `ChopsticksDisplayKeyLine()` for fixed-column key/label rows in learning
  and command/keymap display surfaces.
- Use `ChopsticksStatusDisplay()` to turn a status header and a list of
  `Chopsticks...Info()` dictionaries into the `:ChopsticksStatus` scratch-view
  lines, counts, and footers.
- Keep display adapters pure Vimscript in `modules/env.vim`; they format data
  already produced by owning modules and do not add Neovim or Lua paths.

## Consequences

- Modules still own their domain facts and `Chopsticks...Info()` interfaces,
  but they do not each own low-level spacing, recursive info-section rendering,
  or status count policy.
- The display adapter interface becomes the test surface for status formatting
  and fixed-column row alignment.
- New reference or diagnostic views should consume the shared display adapters
  before adding local `printf('%-...')` formatting or status summary counting.
