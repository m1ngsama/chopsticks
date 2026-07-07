# decision log

## Keep remote state explicit

Git status, diff, blame, commits, and logs are fast local inspection actions.
Push and pull change remote state, so they stay explicit shell or Fugitive
commands instead of default hotkeys.

## Keep help inside Vim

The first lookup should be `SPC ?`, `:ChopsticksTutor`, or `:help chopsticks`,
not a browser tab or external wiki.
