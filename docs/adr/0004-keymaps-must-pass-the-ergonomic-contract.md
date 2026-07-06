# Keymaps Must Pass the Ergonomic Contract

Chopsticks keymaps must preserve Vim's native editing language, stay usable over
SSH, and avoid dangerous default hotkeys such as Git push or pull. The executable
contract is `:ChopsticksKeymapAudit`, so keymap changes must update the audit,
cheat sheet, tutor, help, and tests together.

## Consequences

- Space and classic layouts can differ, but both must pass the same audit.
- Any intentional native-key override needs a documented native replacement.
- Keymap documentation without a matching audit check is incomplete.
