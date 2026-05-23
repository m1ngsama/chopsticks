# Beta Testing

This branch is the v3 beta candidate. Do not tag or publish it as `v3.0.0`
until the checklist below is closed.

## Install the beta

Existing checkout:

```bash
cd ~/.vim
git fetch origin
git checkout release/v3-candidate
git pull --ff-only
vim -Nu ~/.vimrc -n -es +'PlugInstall --sync' +'qa!'
```

Fresh checkout:

```bash
git clone --branch release/v3-candidate https://github.com/m1ngsama/chopsticks.git ~/.vim
ln -sf ~/.vim/.vimrc ~/.vimrc
vim -Nu ~/.vimrc -n -es +'PlugInstall --sync' +'qa!'
```

Keep local choices in `${XDG_CONFIG_HOME:-~/.config}/chopsticks.vim`:

```vim
let g:chopsticks_profile = 'engineer'
let g:chopsticks_keymap_style = 'space'
```

## Daily test loop

Use the beta for real editing, not only demos. For each session, record:

- The task: project navigation, code edit, grep, git, LSP, Markdown, SSH.
- The first key you tried when you got stuck.
- Whether `SPC ?`, `:ChopsticksTutor`, or `:ChopsticksStatus` answered it.
- Any mapping that felt slow, awkward, surprising, or too easy to mistype.
- Any documentation line that was wrong, missing, or redundant.

## Workflows to exercise

```text
SPC SPC   find file              SPC /     grep project
s + 2ch   jump on screen         gd / gr   definition / references
SPC rr    run current file       SPC gs    git status
SPC cf    format                 SPC ca    code action
SPC ?     active cheat sheet     :ChopsticksStatus health
```

Also test the boring path: save, quit, reopen Vim, edit over SSH, open a large
file, edit Markdown, and use a machine with missing optional tools.

## Exit criteria

- `s` as the default visible jump still feels worth the native override after
  real editing.
- No high-frequency action requires remembering an undocumented key.
- README, QUICKSTART, `SPC ?`, and `:ChopsticksTutor` teach the same layout.
- `scripts/test.sh quick` and `scripts/test.sh vim` pass locally.
- The README GIF has been regenerated from `.github/demo.tape` after any public
  key change.
- The beta has been tested on macOS and over SSH on Linux.

## Roll back

Return to the latest stable release:

```bash
cd ~/.vim
git fetch origin --tags
git checkout v2.2.0
vim -Nu ~/.vimrc -n -es +'PlugInstall --sync' +'qa!'
```

Or keep the code but switch back to the legacy layout:

```vim
let g:chopsticks_keymap_style = 'classic'
```
