# Pin Vim Plugins by Default

Chopsticks pins vim-plug plugin declarations to verified commits by default.
Personal editor configs become hard to debug when a remote plugin update changes
behavior silently, so plugin upgrades should be deliberate, tested, and then
relocked.

## Consequences

- `g:chopsticks_pin_plugins` defaults on.
- Maintainers may set `g:chopsticks_pin_plugins = 0` only while testing updates.
- Adding a plugin requires adding a verified commit to the plugin lock table.
