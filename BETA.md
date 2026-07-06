# Release Checklist

Use this before tagging a stable chopsticks release. It does not publish
anything by itself; publishing happens only after a semver tag is intentionally
created and pushed.

The goal is to prove the daily project loop in real Vim sessions, not only in a
demo recording:

- `SPC ?` answers "what key do I press next?"
- `s` jump, native `gd`/`gr`/`K`, and `SPC rr` feel faster than assembling the
  same workflow by hand.
- Git push and pull stay explicit shell or Fugitive actions, not default
  hotkeys.
- SSH, TTY, macOS, and Linux sessions stay predictable.

## Install The Build Under Test

Existing install:

```bash
cd ~/.vim
git fetch origin --tags
git checkout main
git pull --ff-only
./install.sh --profile=engineer
```

Fresh install:

```bash
git clone https://github.com/m1ngsama/chopsticks.git ~/.vim
cd ~/.vim
./install.sh --profile=engineer
```

If you are testing a release branch or tag, replace `main` with that exact ref
before running `./install.sh`.

Open Vim, wait for pinned plugins to install, then restart Vim.

## In-Vim Checklist

Run these inside Vim:

```vim
:ChopsticksStatus
:ChopsticksDoctor
:ChopsticksKeymapAudit
:ChopsticksHelp
:ChopsticksConfig
:ChopsticksReload
:ChopsticksBeta
:ChopsticksBetaLog
:ChopsticksBetaSession
```

Use the build for real editing. A useful session should touch:

- project files: `SPC SPC`, `SPC ff`, `SPC ,`
- visible jumps: `s`, fallback `SPC S`
- code inspection: `gd`, `gr`, `K`
- run/search/git: `SPC rr`, `SPC /`, `SPC gs`
- quickfix/location-list: `[q`, `]q`, `[l`, `]l`
- Markdown-local actions: `,mt`, `,mp`
- help surfaces: `SPC ?`, `:ChopsticksTutor`, `:help chopsticks`

`:ChopsticksBetaLog` opens
`${XDG_CONFIG_HOME:-~/.config}/chopsticks-<release-label>.md` by default.
The default label is the current release label. Override it when preparing a
specific release:

```vim
let g:chopsticks_release_label = 'vX.Y.Z'
" Legacy name still works:
" let g:chopsticks_beta_label = 'vX.Y.Z'
```

You can also set a custom log path:

```vim
let g:chopsticks_beta_log = expand('~/.config/chopsticks-release.md')
```

## Local Checks

Before tagging, run:

```bash
scripts/test.sh quick
scripts/test.sh vim
scripts/release-notes.sh vX.Y.Z
```

The release notes command only reads `CHANGELOG.md`; it does not publish.

## Exit Criteria

- quick and Vim smoke checks pass locally.
- `:ChopsticksStatus` has no unexpected attention rows.
- `SPC ?`, `:ChopsticksTutor`, README, QUICKSTART, and `:help chopsticks`
  teach the same layout.
- `s` remains worth the native substitute override, with `cl` and `cc`
  documented as the native substitute path.
- Git push/pull remain unbound by default.
- The release log has at least one real session note, not just a demo note.
- Rollback has been tested or is mechanically obvious.

## Rollback

Keep rollback explicit:

```bash
cd ~/.vim
git fetch origin --tags
git tag --sort=-version:refname | head -1
git checkout <last-stable-tag>
./install.sh --configure-only --profile=engineer
```

If plugin state is suspect:

```bash
vim -Nu NONE -n +'set nomore' +PlugClean +PlugInstall +qa
```

Then open Vim and run `:ChopsticksStatus`.
