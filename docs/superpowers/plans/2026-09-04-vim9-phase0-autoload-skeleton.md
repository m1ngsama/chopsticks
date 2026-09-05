# Vim9 Phase 0: autoload skeleton implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move Chopsticks' own code out of a single 2843-line legacy-script
`.vimrc` into Vim9script `autoload/` modules, with behavior provably unchanged.

**Architecture:** `.vimrc` stays legacy script and shrinks to bootstrap only.
`plugin/chopsticks.vim` is Vim9script and declares every command, mapping, and
public `Chopsticks*` global function; each global delegates to an
`autoload/chopsticks/**` module through `import autoload`, so a module is not
read until one of its functions is first called. No plugin is added, removed, or
swapped in this phase.

**Tech Stack:** Vim 9.1.1947+, Vim9script, vim-plug, vimlint (legacy files),
`:defcompile` (Vim9 files), POSIX sh test harness.

**Spec:** `docs/superpowers/specs/2026-09-04-vim9-core-migration-design.md`

## Global Constraints

- Vim floor is **9.1.1947** on every platform. Neovim is not supported.
- **Zero behavior change.** Every documented command, mapping, and
  `g:chopsticks_*` switch behaves exactly as before this phase.

- Startup must not use the network.
- These eight globals are a public contract asserted by `tests/ui.vim` and must
  keep their names and signatures: `ChopsticksStatusline()`,
  `ChopsticksTabline()`, `ChopsticksIcon(name)`, `ChopsticksUiDensity()`,
  `ChopsticksSessionPath()`, `ChopsticksDashboardEnabled()`,
  `ChopsticksTransparencyEnabled()`, `ChopsticksSystemClipboardEnabled()`.
  `&statusline` and `&tabline` reference the first two on every redraw.

- Startup time must not regress; `scripts/benchmark-vim.py --check` is the gate.
- Every `autoload/**/*.vim`, `plugin/*.vim` file begins with `vim9script` on
  line 1.

- Vim9 modules must not depend on their own file path (no `expand('<sfile>')`),
  because the linter sources a copy from a temporary directory.

---

### Task 1: Raise the version floor to 9.1.1947

Nothing else can land first: CI's `vim-minimum` job runs Vim 8.2.0000, where
`vim9script` does not exist, so the first Vim9 file added would fail CI.

**Files:**

- Modify: `.vimrc:13-23` (version guard), `.vimrc:471`, `.vimrc:583`,
  `.vimrc:626`, `.vimrc:1821` (dead `patch-8.2.*` guards)

- Modify: `.github/workflows/check.yml:31`
- Modify: `README.md:7-9`, `README.md:21`, `README.md:265`
- Modify: `CONTRIBUTING.md:13-14`

- [x] **Step 1: Read the current guard and the four dead patch checks**

```bash
sed -n '10,25p' .vimrc
sed -n '471p;583p;626p;1821p' .vimrc
```

- [x] **Step 2: Replace the two-platform guard with one floor**

`.vimrc` currently errors below 8.2 and separately below 9.1.1947 on Windows.
Replace both with a single check. Keep it legacy script; `.vimrc` stays legacy
for the whole phase.

```vim
if !has('patch-9.1.1947')
    echoerr 'chopsticks requires Vim 9.1.1947 or newer'
    finish
endif
```

- [x] **Step 3: Delete the four now-dead patch guards**

`has('patch-8.2.5136')`, `has('patch-8.2.4325')`, and `has('patch-8.2.2508')`
are all unconditionally true at the new floor. Remove each `if`/`endif` wrapper
and keep the body at the outer indentation. `.vimrc:1821` also tests
`exists(':Fern') == 2`; keep that half, drop only the `has('patch-8.2.5136')`
conjunct.

- [x] **Step 4: Repin the CI minimum job**

In `.github/workflows/check.yml`, change `version: v8.2.0000` to `version:
v9.1.1947` and rename the job title from `Vim 8.2 baseline` to `Vim 9.1.1947
baseline`.

- [x] **Step 5: Update the two prose claims**

`README.md:7` says "Vim 8.2/9.x"; `README.md:21` says "Requires Vim 8.2+ (Vim
9.1.1947+ on Windows)"; `README.md:265` says "ports established interaction
patterns to Vim 8.2". `CONTRIBUTING.md:13-14` says "support Vim 8.2 and 9.x ...
Windows support starts at Vim 9.1.1947." Each becomes a single floor of 9.1.1947
with no platform split. Keep the existing sentence about the Windows advisory as
the *reason* the floor is where it is.

- [x] **Step 6: Verify the guard rejects an old Vim and the suite still passes**

```bash
sh scripts/lint-vim.sh
npm run lint
```

Expected: both pass. `lint-vim.sh` runs vimlint plus all 21 UI cases.

- [x] **Step 7: Commit**

```bash
git add .vimrc .github/workflows/check.yml README.md CONTRIBUTING.md
git commit -m "Require Vim 9.1.1947 on every platform

Vim9script needs 9.0, wildtrigger() landed in 9.1.1576, 'autocomplete'
in 9.1.1590, and the last fix in that series is 9.1.1920. Windows
already required 9.1.1947 for the executable search-path advisory, so
adopting it everywhere adds no constraint Windows did not carry and
retires the platform split along with four dead patch guards."
```

---

### Task 2: Teach the linter about many files and about Vim9

`scripts/lint-vim.sh` lints exactly one path, `$chopsticks_root/.vimrc`, at
lines 163 and 206. Every module added later would ship unchecked. vimlint parses
legacy script and cannot read `vim9script`, so Vim9 files need a different
check.

The Vim9 check is `:defcompile`, which compiles every `def` in the *current
script* and fails on type and syntax errors. It only works from inside the file,
so the linter copies each module to a temporary file, appends `defcompile`, and
sources the copy with the repo on `runtimepath` so `import autoload` still
resolves.

**Files:**

- Modify: `scripts/lint-vim.sh:144-186`
- Create: `tests/vim9-lint-fixtures/valid.vim`,
  `tests/vim9-lint-fixtures/broken.vim`

**Interfaces:**

- Produces: shell function `lint_vim9_file <path>` returning 0 on clean, 1 on
  error; called for every `plugin/*.vim` and `autoload/**/*.vim`. Tasks 3 onward
  rely on it running in `sh scripts/lint-vim.sh`.

- [x] **Step 1: Write the failing fixtures**

`tests/vim9-lint-fixtures/valid.vim`:

```vim
vim9script

export def Add(a: number, b: number): number
  return a + b
enddef
```

`tests/vim9-lint-fixtures/broken.vim`:

```vim
vim9script

export def Bad(a: number): string
  return a
enddef
```

- [x] **Step 2: Confirm by hand that the mechanism separates them**

```bash
for f in tests/vim9-lint-fixtures/valid.vim tests/vim9-lint-fixtures/broken.vim; do
  cp "$f" /tmp/chk.vim
  printf '\ndefcompile\n' >> /tmp/chk.vim
  vim -Nu NONE -i NONE -n -es \
    -c 'try | source /tmp/chk.vim | catch | cquit | endtry' -c 'qall!' \
    >/dev/null 2>&1
  echo "$f -> exit=$?"
done
```

Expected: `valid.vim -> exit=0` and `broken.vim -> exit=1`. If both are 0, the
`defcompile` line was not appended inside the sourced file and the rest of this
task will not work.

- [x] **Step 3: Add the Vim9 lint function to `scripts/lint-vim.sh`**

Insert after the existing vimlint block (which ends at line 186 with its closing
`fi`). It reuses `$test_vim`, `$test_root`, and `path_for_vim` already defined
in the script.

```sh
lint_vim9_file() {
    vim9_source=$1
    vim9_copy=$test_root/vim9-$(printf '%s' "$vim9_source" |
        tr '/.' '__').vim
    cp "$vim9_source" "$vim9_copy"
    printf '\ndefcompile\n' >>"$vim9_copy"
    vim9_copy_for_vim=$(path_for_vim "$vim9_copy")
    vim9_root_for_vim=$(path_for_vim "$chopsticks_root")
    vim9_log=$vim9_copy.log
    if ! "$test_vim" \
        -Nu NONE -i NONE -n -N -es \
        -V1"$vim9_log" \
        --cmd "set runtimepath^=$vim9_root_for_vim" \
        -c "try | source $vim9_copy_for_vim | catch | cquit | endtry" \
        -c 'qall!' >/dev/null 2>&1
    then
        printf 'vim9 compile failed: %s\n' "$vim9_source" >&2
        sed 's/^/  /' "$vim9_log" >&2
        return 1
    fi
    return 0
}

vim9_failed=0
for vim9_candidate in \
    "$chopsticks_root"/plugin/*.vim \
    "$chopsticks_root"/autoload/chopsticks/*.vim \
    "$chopsticks_root"/autoload/chopsticks/*/*.vim \
    "$chopsticks_root"/lang/*.vim
do
    [ -f "$vim9_candidate" ] || continue
    lint_vim9_file "$vim9_candidate" || vim9_failed=1
done
if [ "$vim9_failed" -ne 0 ]; then
    exit 1
fi
```

The glob guard `[ -f ... ] || continue` matters: these directories do not exist
yet, so an unmatched glob must be skipped rather than treated as a filename.

- [x] **Step 4: Prove the linter catches a broken module**

```bash
mkdir -p plugin
cp tests/vim9-lint-fixtures/broken.vim plugin/zz-scratch.vim
sh scripts/lint-vim.sh; echo "exit=$?"
```

Expected: non-zero exit with `vim9 compile failed: .../plugin/zz-scratch.vim`.

- [x] **Step 5: Prove it passes a good module, then clean up**

```bash
cp tests/vim9-lint-fixtures/valid.vim plugin/zz-scratch.vim
sh scripts/lint-vim.sh; echo "exit=$?"
rm -f plugin/zz-scratch.vim
rmdir plugin 2>/dev/null || true
```

Expected: exit 0 on the second run.

- [x] **Step 6: Commit**

```bash
git add scripts/lint-vim.sh tests/vim9-lint-fixtures
git commit -m "Lint every Vim file, and compile the Vim9 ones

vimlint reads legacy script only and was pointed at .vimrc alone, so
modules added by the autoload split would ship unchecked. Walk plugin/
and autoload/ as well, and check those with :defcompile, which reports
Vim9 type and syntax errors. defcompile only compiles the script it
runs inside, so each file is copied and the directive appended."
```

---

### Task 3: Create the skeleton and prove the delegation contract

Establishes `plugin/chopsticks.vim` and moves exactly one small, well-tested
function so the shim pattern is verified before anything large depends on it.
`ChopsticksSystemClipboardEnabled()` is the right first move: it is asserted by
`tests/ui.vim`, has no callers inside `.vimrc` beyond its own definition site,
and is nine lines.

**Files:**

- Create: `plugin/chopsticks.vim`, `autoload/chopsticks/clipboard.vim`
- Modify: `.vimrc:141-145`

**Interfaces:**

- Produces: `autoload/chopsticks/clipboard.vim` exporting `def Enabled(): bool`.
  `plugin/chopsticks.vim` exposes `g:ChopsticksSystemClipboardEnabled()`. Tasks
  4 onward add modules and globals to these same two locations using this exact
  shape.

- [x] **Step 1: Read the function being moved**

```bash
sed -n '135,146p' .vimrc
```

- [x] **Step 2: Create the autoload module**

`autoload/chopsticks/clipboard.vim`. Translate the legacy body to Vim9: `let`
becomes `var`, `a:name` becomes `name`, `.` concatenation becomes `..`, and the
function is `export def` with a declared return type.

```vim
vim9script

# Whether p/P and yanks should use the system clipboard. Resolved from
# g:chopsticks_system_clipboard, which s:ResolveSwitch() in .vimrc has already
# reduced from 'auto' to 0 or 1 by the time this runs.
export def Enabled(): bool
  return g:chopsticks_system_clipboard ? true : false
enddef
```

- [x] **Step 3: Create the plugin shim**

`plugin/chopsticks.vim`:

```vim
vim9script

# Public interface. Every Chopsticks* global is declared here and delegates to
# an autoload module, which Vim does not read until the first call. Names in
# this file are a contract: tests/ui.vim asserts them, and 'statusline' and
# 'tabline' evaluate two of them on every redraw.

import autoload 'chopsticks/clipboard.vim'

def g:ChopsticksSystemClipboardEnabled(): bool
  return clipboard.Enabled()
enddef
```

- [x] **Step 4: Delete the old definition from `.vimrc`**

Remove the `function! ChopsticksSystemClipboardEnabled() ... endfunction` block
at `.vimrc:141-145`. Leave everything else untouched.

- [x] **Step 5: Verify the contract holds and nothing regressed**

```bash
sh scripts/lint-vim.sh
```

Expected: pass. `tests/ui.vim` asserts
`exists('*ChopsticksSystemClipboardEnabled')` in `s:AssertPublicInterface()`, so
a broken shim fails every one of the 21 UI cases rather than passing quietly.

- [x] **Step 6: Confirm laziness — the module is not read at startup**

```bash
vim -Nu .vimrc -i NONE -n -es \
  -c 'echo len(filter(split(execute("scriptnames"), "\n"), "v:val =~# \"clipboard\""))' \
  -c 'qall!'
```

Expected: `0`. The module has not been sourced because nothing has called it
yet.

- [x] **Step 7: Commit**

```bash
git add plugin/chopsticks.vim autoload/chopsticks/clipboard.vim .vimrc
git commit -m "Add the autoload skeleton and prove the delegation contract

plugin/chopsticks.vim declares the public Chopsticks* globals and
delegates each to an autoload module that Vim does not read until the
first call. Move one small function to establish the shape before
anything larger depends on it."
```

---

### Task 4: Move session and health

Session is the most self-contained region and has its own UI case (`session`).
Health has no dedicated case, so it gets one first.

**Files:**

- Create: `autoload/chopsticks/session.vim`, `autoload/chopsticks/health.vim`
- Modify: `plugin/chopsticks.vim`, `.vimrc:1474-1560` (session helpers),
  `.vimrc:2020-2110` (health)

- Modify: `tests/ui.vim`, `scripts/lint-vim.sh:267-355` (register the new case)

**Interfaces:**

- Consumes: nothing from Tasks 1-3 beyond the shim shape.
- Produces: `session.vim` exporting `def Path(): string`, `def Save(): void`,
  `def Load(force: bool): void`, `def ProjectRoot(): string`. `health.vim`
  exporting `def Lines(): list<string>`, `def Show(): void`. Globals
  `g:ChopsticksSessionPath()` and `g:ChopsticksHealthLines()`.

- [x] **Step 1: Write a failing health test case**

Add to `tests/ui.vim`, following the existing case dispatch:

```vim
function! s:CaseHealth() abort
    call s:AssertPublicInterface()
    let l:lines = ChopsticksHealthLines()
    call assert_equal(type([]), type(l:lines))
    call assert_true(len(l:lines) > 0)
    call assert_true(exists(':ChopsticksHealth') == 2)
endfunction
```

Register `health` in the same dispatch table the other cases use, and add
`run_ui_test health` to `scripts/lint-vim.sh` beside the other `run_ui_test`
lines.

- [x] **Step 2: Run it and confirm it passes before the move**

```bash
CHOPSTICKS_TEST_UI_CASES=health sh scripts/lint-vim.sh
```

Expected: pass. This is a characterization test — it must be green *before* the
refactor so a failure afterwards means the move broke something.

- [x] **Step 3: Commit the test alone**

```bash
git add tests/ui.vim scripts/lint-vim.sh
git commit -m "Cover ChopsticksHealthLines before moving it"
```

- [x] **Step 4: Create `autoload/chopsticks/session.vim`**

Move `s:MakeParent`, `s:ProjectRoot`, `s:SessionRoot`, `s:SessionDigest`, and
the session save/load bodies. Script-local `s:Name` becomes a plain module-level
`def Name()` (unexported functions are private to the script in Vim9); only
`Path`, `Save`, `Load`, and `ProjectRoot` are `export def`. Preserve the POSIX
permission checks and the refusal to load over modified listed buffers exactly;
they are documented behavior in `README.md:255-261`.

- [x] **Step 5: Create `autoload/chopsticks/health.vim`**

Move `ChopsticksHealthLines()` and `s:Health()` bodies to `export def Lines():
list<string>` and `export def Show(): void`.

- [x] **Step 6: Add the globals and commands to `plugin/chopsticks.vim`**

```vim
import autoload 'chopsticks/session.vim'
import autoload 'chopsticks/health.vim'

def g:ChopsticksSessionPath(): string
  return session.Path()
enddef

def g:ChopsticksHealthLines(): list<string>
  return health.Lines()
enddef

command! ChopsticksSessionSave session.Save()
command! -bang ChopsticksSessionLoad session.Load(<bang>0)
command! ChopsticksHealth health.Show()
```

- [x] **Step 7: Delete the moved definitions and their `command!` lines from
      `.vimrc`**

- [x] **Step 8: Run the full suite**

```bash
sh scripts/lint-vim.sh
```

Expected: all 22 UI cases pass, including `session` and the new `health`.

- [x] **Step 9: Commit**

```bash
git add plugin/chopsticks.vim autoload/chopsticks/session.vim autoload/chopsticks/health.vim .vimrc
git commit -m "Move session and health into autoload modules"
```

---

### Task 5: Move icons and theme

`ChopsticksIcon()` is consumed by the dashboard, statusline, ALE sign
definitions, and Fern, so it moves before any of them. Theme has four UI cases
already (`theme-valid`, `theme-fallback`, `transparent`, `opaque`).

**Files:**

- Create: `autoload/chopsticks/ui/icons.vim`, `autoload/chopsticks/ui/theme.vim`
- Modify: `plugin/chopsticks.vim`, `.vimrc:222-251` (icons), `.vimrc:644-724`
  (colors), `.vimrc:1383-1450` (toggles and commands)

**Interfaces:**

- Consumes: the shim shape from Task 3.
- Produces: `icons.vim` exporting `def Enabled(): bool`, `def Get(name: string):
  string`, `def Group(group: string): string`, `def Apply(): void`, `def
  Toggle(): void`. `theme.vim` exporting `def Apply(): void`, `def Set(name:
  string): void`, `def TransparencyEnabled(): bool`, `def ToggleTransparency():
  void`, `def DefineInterfaceColors(): void`, `def HighlightColor(group: string,
  attribute: string, fallback: string): string`. Task 6 and Task 7 call
  `icons.Get()` and `theme.HighlightColor()`.

- [x] **Step 1: Create `autoload/chopsticks/ui/icons.vim`**

Move `ChopsticksIconsEnabled()`, `ChopsticksIcon()`, `s:GroupIcon()`,
`s:ApplyIconMode()`, and `s:ToggleIcons()`. Keep the icon dictionary itself
module-level.

- [x] **Step 2: Create `autoload/chopsticks/ui/theme.vim`**

Move `s:ApplyColorscheme()`, `s:HighlightColor()`, `s:DefineInterfaceColors()`,
`s:SetTheme()`, `s:ToggleTransparency()`, and `ChopsticksTransparencyEnabled()`.
Preserve the fallback to Vim's built-in `default` scheme on a missing
colorscheme; `theme-fallback` asserts it.

- [x] **Step 3: Wire the globals and commands**

```vim
import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/ui/theme.vim'

def g:ChopsticksIcon(name: string): string
  return icons.Get(name)
enddef

def g:ChopsticksIconsEnabled(): bool
  return icons.Enabled()
enddef

def g:ChopsticksTransparencyEnabled(): bool
  return theme.TransparencyEnabled()
enddef

command! ChopsticksIconsToggle icons.Toggle()
command! ChopsticksTransparencyToggle theme.ToggleTransparency()
command! -nargs=1 -complete=color ChopsticksTheme theme.Set(<q-args>)
```

- [x] **Step 4: Delete the moved definitions from `.vimrc`**

Leave the ALE sign assignments at `.vimrc:351-353` in place; they call
`ChopsticksIcon()`, which still resolves through the shim.

- [x] **Step 5: Run the suite**

```bash
sh scripts/lint-vim.sh
```

Expected: pass, including `theme-valid`, `theme-fallback`, `transparent`,
`opaque`. `tests/ui.vim` also asserts `strwidth(ChopsticksIcon('info')) == 1`.

- [x] **Step 6: Commit**

```bash
git add plugin/chopsticks.vim autoload/chopsticks/ui .vimrc
git commit -m "Move icons and theme into autoload modules"
```

---

### Task 6: Move the dashboard

Three UI cases cover it: `dashboard-off`, `dashboard-on`, `dashboard-wide`.

**Files:**

- Create: `autoload/chopsticks/ui/dashboard.vim`
- Modify: `plugin/chopsticks.vim`, `.vimrc:444-600` (items), `.vimrc:725-1052`
  (render and interaction)

**Interfaces:**

- Consumes: `icons.Get()` and `theme.HighlightColor()` from Task 5.
- Produces: `dashboard.vim` exporting `def Enabled(): bool`, `def Open(): void`,
  `def MaybeOpen(): void`. Global `g:ChopsticksDashboardEnabled()`.

- [x] **Step 1: Create the module**

Move `s:DashboardItems`, `s:TruncateText`, `s:DashboardCenter`,
`s:DashboardLogoLine`, `s:DashboardPluginStats`, `s:CaptureStartupTime`,
`s:DashboardFooter`, `s:DashboardEnter`, `s:DashboardLeave`,
`s:DashboardMapItems`, `s:DashboardRender`, `s:DashboardSelectNearest`,
`s:DashboardLockCursor`, `s:DashboardMove`, `s:DashboardRun`,
`s:DashboardRunCurrent`, `s:OpenDashboard`, `s:MaybeOpenDashboard`, and
`ChopsticksDashboardEnabled`.

The buffer-local mappings at `.vimrc:1032-1040` use `<SID>` to reach
script-local functions. In a Vim9 module `<SID>` does not resolve from a mapping
created elsewhere; build them with `<ScriptCmd>` instead, which runs in the
defining script's context:

```vim
nnoremap <silent><buffer> j <ScriptCmd>Move(1)<CR>
nnoremap <silent><buffer> k <ScriptCmd>Move(-1)<CR>
nnoremap <silent><buffer> <CR> <ScriptCmd>RunCurrent()<CR>
```

- [x] **Step 2: Wire the global and command**

```vim
import autoload 'chopsticks/ui/dashboard.vim'

def g:ChopsticksDashboardEnabled(): bool
  return dashboard.Enabled()
enddef

command! ChopsticksDashboard dashboard.Open()
```

- [x] **Step 3: Delete the moved definitions from `.vimrc`**

Keep the `ChopsticksDashboard` augroup at `.vimrc:2828-2832`, changing its body
to call `dashboard.MaybeOpen()`.

- [x] **Step 4: Run the suite**

```bash
sh scripts/lint-vim.sh
```

Expected: pass. `dashboard-wide` runs in a real terminal rather than `-es`, so
it catches rendering and cursor-lock regressions the other cases miss.

- [x] **Step 5: Commit**

```bash
git add plugin/chopsticks.vim autoload/chopsticks/ui/dashboard.vim .vimrc
git commit -m "Move the dashboard into an autoload module"
```

---

### Task 7: Move the statusline and bufferline

These evaluate on every redraw, so this is the task where a laziness mistake
shows up as a startup regression. Five UI cases cover them: `status-context`,
`tabline-width`, `bufferline-off`, `bufferline-on`, `density`.

**Files:**

- Create: `autoload/chopsticks/ui/statusline.vim`,
  `autoload/chopsticks/ui/bufferline.vim`

- Modify: `plugin/chopsticks.vim`, `.vimrc:1054-1382`, `.vimrc:1452-1469`

**Interfaces:**

- Consumes: `icons.Get()` from Task 5.
- Produces: `statusline.vim` exporting `def Render(): string`, `def UiDensity():
  string`, `def SetUiDensity(value: string): void`, `def GitDiff(bufnr: number):
  string`, `def Diagnostics(bufnr: number): string`, `def WritingMode(bufnr:
  number): string`. `bufferline.vim` exporting `def Render(): string`, `def
  Enabled(): bool`, `def Schedule(): void`. Globals `g:ChopsticksStatusline()`,
  `g:ChopsticksTabline()`, `g:ChopsticksUiDensity()`,
  `g:ChopsticksBufferlineEnabled()`, `g:ChopsticksGitDiff()`,
  `g:ChopsticksDiagnostics()`, `g:ChopsticksWritingMode()`.

- [x] **Step 1: Determine which component functions must stay global**

`ChopsticksStatusline()` calls its components as ordinary function calls, not as
`%{...}` callbacks embedded in the returned string, so a component used only by
`Render()` can become a private `def` in the module. A component referenced from
outside the module cannot.

```bash
for f in ChopsticksMode ChopsticksFileIcon ChopsticksGitBranch \
         ChopsticksGitDiff ChopsticksDiagnostics ChopsticksWritingMode \
         ChopsticksBufferFlags ChopsticksBufferlineEnabled; do
  printf '%-30s vimrc=%s tests=%s\n' "$f" \
    "$(grep -c "$f" .vimrc)" \
    "$(cat tests/*.vim | grep -c "$f")"
done
```

Expected, and the rule this task follows: `ChopsticksGitDiff`,
`ChopsticksDiagnostics`, and `ChopsticksWritingMode` report a non-zero `tests`
count, so those three keep their globals. `ChopsticksMode`,
`ChopsticksFileIcon`, `ChopsticksGitBranch`, and `ChopsticksBufferFlags` report
`tests=0` and are referenced only by `Render()`, so they become private `def`s
with no global shim. If this run disagrees with those counts, follow the counts,
not this paragraph.

- [x] **Step 2: Create the two modules**

`statusline.vim` takes `ChopsticksMode`, `ChopsticksFileIcon`,
`ChopsticksGitBranch`, `ChopsticksGitDiff`, `ChopsticksDiagnostics`,
`ChopsticksWritingMode`, `ChopsticksBufferFlags`, `s:StatuslineContext`,
`s:EffectiveStatuslineDensity`, `ChopsticksStatusline`, `ChopsticksUiDensity`,
and `s:SetUiDensity`. `bufferline.vim` takes `s:FileBufferCount`,
`ChopsticksBufferlineEnabled`, `s:RefreshBufferline`,
`s:RefreshBufferlineTimer`, `s:ScheduleBufferlineRefresh`, and
`ChopsticksTabline`.

- [x] **Step 3: Wire the globals and the density command**

```vim
import autoload 'chopsticks/ui/statusline.vim'
import autoload 'chopsticks/ui/bufferline.vim'

def g:ChopsticksStatusline(): string
  return statusline.Render()
enddef

def g:ChopsticksTabline(): string
  return bufferline.Render()
enddef

def g:ChopsticksUiDensity(): string
  return statusline.UiDensity()
enddef

def g:ChopsticksBufferlineEnabled(): bool
  return bufferline.Enabled()
enddef

# Kept global because tests/ui.vim references them directly; see Step 1.
def g:ChopsticksGitDiff(bufnr: number): string
  return statusline.GitDiff(bufnr)
enddef

def g:ChopsticksDiagnostics(bufnr: number): string
  return statusline.Diagnostics(bufnr)
enddef

def g:ChopsticksWritingMode(bufnr: number): string
  return statusline.WritingMode(bufnr)
enddef

command! -nargs=? ChopsticksUiDensity statusline.SetUiDensity(<q-args>)
```

- [x] **Step 4: Delete the moved definitions from `.vimrc`**

`set statusline=%!ChopsticksStatusline()` and `set
tabline=%!ChopsticksTabline()` stay in `.vimrc` unchanged; they now resolve
through the shim.

- [x] **Step 5: Run the suite and the benchmark**

```bash
sh scripts/lint-vim.sh
npm run benchmark
```

Expected: suite passes; `tests/ui.vim` asserts `&statusline ==#
'%!ChopsticksStatusline()'` and `&tabline ==# '%!ChopsticksTabline()'`. Startup
time must not regress — these two modules load during the first redraw, so they
are on the startup path by design and the benchmark is the check that delegation
added no measurable cost.

- [x] **Step 6: Commit**

```bash
git add plugin/chopsticks.vim autoload/chopsticks/ui .vimrc
git commit -m "Move the statusline and bufferline into autoload modules"
```

---

### Task 8: Move keys, which-key, and Markdown

Neither region has a UI case, so both get characterization tests first. This is
the largest remaining move and the one with the least existing cover.

**Files:**

- Create: `autoload/chopsticks/keys.vim`, `autoload/chopsticks/markdown.vim`
- Modify: `plugin/chopsticks.vim`, `.vimrc:243-308` (which-key setup),
  `.vimrc:2111-2214` (key catalog), `.vimrc:2261-2467` (Markdown),
  `.vimrc:2696-2766` (plugin maps)

- Modify: `tests/ui.vim`, `scripts/lint-vim.sh`

**Interfaces:**

- Consumes: `icons.Get()` from Task 5.
- Produces: `keys.vim` exporting `def Lines(): list<string>`, `def Show():
  void`, `def Register(): void`, `def ApplyPluginMaps(): void`. `markdown.vim`
  exporting `def Setup(): void`, `def ProseSetup(): void`, `def PasteImage(name:
  string): void`, `def Glow(): void`, `def Help(): void`, `def ToggleConceal():
  void`, `def GuardLongLines(): void`. Globals `g:ChopsticksKeyLines()`.

- [x] **Step 1: Write failing characterization tests**

Add to `tests/ui.vim`:

```vim
function! s:CaseKeys() abort
    call s:AssertPublicInterface()
    let l:lines = ChopsticksKeyLines()
    call assert_equal(type([]), type(l:lines))
    call assert_true(len(l:lines) > 0)
    call assert_equal(2, exists(':ChopsticksCheatsheet'))
    call assert_equal(2, exists(':ChopsticksKeys'))
    call assert_true(!empty(maparg('<Space>', 'n')))
endfunction

function! s:CaseMarkdown() abort
    call s:AssertPublicInterface()
    silent edit README.md
    call assert_equal('markdown', &filetype)
    call assert_equal(2, exists(':MarkdownPasteImage'))
    call assert_equal(2, exists(':MarkdownGlow'))
    call assert_true(!empty(maparg('<LocalLeader>o', 'n')))
    call assert_true(!empty(maparg('<LocalLeader>x', 'n')))
endfunction
```

Register both in the case dispatch and add `run_ui_test keys` and `run_ui_test
markdown` to `scripts/lint-vim.sh`.

- [x] **Step 2: Run them and confirm green before the move**

```bash
CHOPSTICKS_TEST_UI_CASES="keys markdown" sh scripts/lint-vim.sh
```

Expected: pass. If `maparg('<LocalLeader>o', 'n')` is empty, the Markdown case
is not opening a Markdown buffer; fix the test before proceeding, not after.

- [x] **Step 3: Commit the tests alone**

```bash
git add tests/ui.vim scripts/lint-vim.sh
git commit -m "Cover the key catalog and Markdown setup before moving them"
```

- [x] **Step 4: Create `autoload/chopsticks/keys.vim`**

Move `s:WhichKeyGroup`, `s:WhichKeySetup`, `s:Catalog`, `s:LeaderLabel`,
`s:WhichKeyAdd`, `s:LeaderN`, `s:LeaderX`, `s:DirectN`, `s:DirectX`,
`ChopsticksKeyLines`, `s:Keys`, `s:PluginMaps`, and `s:RegisterWhichKey`.

- [x] **Step 5: Create `autoload/chopsticks/markdown.vim`**

Move `s:MarkdownToggleConceal`, `s:MarkdownGlow`, `s:MarkdownPasteImage`,
`s:MarkdownHelp`, `s:HasLongLine`, `s:GuardLongLines`, `s:MarkdownSetup`,
`s:ProseSetup`, `s:GoyoEnter`, and `s:GoyoLeave`.

The buffer-local `<LocalLeader>` mappings at `.vimrc:2408-2433` use `<SID>` to
reach script-local functions. In a Vim9 module `<SID>` does not resolve from a
mapping created elsewhere; build them with `<ScriptCmd>`, which runs in the
defining script's context:

```vim
nnoremap <silent><buffer> <LocalLeader>c <ScriptCmd>ToggleConceal()<CR>
nnoremap <silent><buffer> <LocalLeader>g <ScriptCmd>Glow()<CR>
nnoremap <silent><buffer> <LocalLeader>? <ScriptCmd>Help()<CR>
```

Mappings whose right-hand side is a plugin command rather than a Chopsticks
function — `<LocalLeader>o` to `:Toc`, `<LocalLeader>tt` to `:TableModeToggle`,
`<LocalLeader>z` to `:Goyo`, `<LocalLeader>l` to `:ALELint`, `<LocalLeader>f` to
`:ALEFix` — are unaffected and move across verbatim.

- [x] **Step 6: Wire the globals and commands**

```vim
import autoload 'chopsticks/keys.vim'
import autoload 'chopsticks/markdown.vim'

def g:ChopsticksKeyLines(): list<string>
  return keys.Lines()
enddef

command! ChopsticksKeys keys.Show()
command! ChopsticksCheatsheet keys.Show()
command! -nargs=? -complete=file MarkdownPasteImage markdown.PasteImage(<q-args>)
command! MarkdownGlow markdown.Glow()
command! MarkdownHelp markdown.Help()
```

- [x] **Step 7: Delete the moved definitions from `.vimrc`**

The `FileType markdown` and `FileType text,gitcommit,mail` autocommands at
`.vimrc:2803-2804` stay, with bodies calling `markdown.Setup()` and
`markdown.ProseSetup()`.

- [x] **Step 8: Run the suite**

```bash
sh scripts/lint-vim.sh
```

Expected: all 24 UI cases pass.

- [x] **Step 9: Commit**

```bash
git add plugin/chopsticks.vim autoload/chopsticks/keys.vim autoload/chopsticks/markdown.vim .vimrc
git commit -m "Move the key catalog and Markdown support into autoload modules"
```

---

### Task 8b: finding, the file tree, and the small actions *(unplanned)*

This task is not in the original plan. Task 8 left more behaviour in `.vimrc`
than the plan accounted for, and it had to move before Task 9 could claim the
behaviour was out. Commit `2dc34c4` added four modules:

- `find.vim` — file and text search: the fd/ripgrep source, the fzf specs,
  project grep, Git files, recent files, the `:Files` override, and the fzf
  abort keys and skip-directory list, reached through `AbortKeys()` and
  `VisualOptions()` where `.vimrc` still needs them.

- `explorer.vim` — the file-tree drawer, Fern or netrw, and the
  directory-argument startup behaviour.

- `actions.vim` — the quickfix and location-list toggles, buffer cleanup, path
  copying, parent-directory creation on write, and the lazygit launcher.

- plus `switch.vim`, `startup.vim`, `ui/text.vim`, and `ui/window.vim` for the
  helpers several of the above share.

`:History` and `:browse oldfiles` go through `:execute`, for the same reason
`:Limelight` did in Task 8: Vim9 resolves command names at `:def`-compile time,
so naming fzf.vim's commands directly would make the module fail to compile
wherever fzf.vim is absent.

Two test-harness defects surfaced here and were fixed in `61c2339` and
`d8f99be`. `tests/ui.vim` found the project-root spec builder by searching
`:function` output for a script-local `<SNR>` name that no longer existed;
guarding the replacement with `exists('*name')` is *not* a fix, because
`exists()` does not trigger autoloading and the false guard silently turns the
assertion into a passing early return. And two cases were exiting 0 partway
through, which the harness read as success while every later assertion never
ran. `tests/ui.vim` now writes a completion marker as its final act and
`run_ui_test` rejects a case that exits 0 without one. Two cases —
`default-dashboard` and `rich` — are still knowingly excused and warn on every
run; that is tracked as follow-up work, not as part of this phase.

---

### Task 9: Move options and autocommands; reduce `.vimrc` to bootstrap

What remains in `.vimrc` after Task 8 is option assignments, the plugin list,
and four augroups. Options move to a module; `.vimrc` keeps only what must run
before anything else.

> **Steps 2-4 were superseded during execution. See "Task 9 as executed" below
> for what was done instead and why.** The premise above is wrong: it assumed
> the configuration would move out alongside the behaviour. It should not.

**Files:**

- Create: ~~`autoload/chopsticks/options.vim`,
  `autoload/chopsticks/autocmds.vim`~~ — neither was created.
- Modify: `plugin/chopsticks.vim`, `.vimrc` (everything except bootstrap)

**Interfaces:**

- Consumes: every module from Tasks 3-8.
- Produces: ~~`options.vim` exporting `def Apply(): void`. `autocmds.vim`
  exporting `def Register(): void`.~~ Neither export exists.

- [x] **Step 1: Identify what must stay in `.vimrc`**

These stay, in this order, and stay legacy script: the `has('patch-9.1.1947')`
guard from Task 1; `g:chopsticks_version`; `s:NormalizeDirectory` and
`s:DirectoryFileType`; `g:chopsticks_data_dir` resolution; the local-config
`:source` and the data-dir re-resolution that follows it at `.vimrc:84-88`; the
`g:chopsticks_*` switch defaults at `.vimrc:90-110`; `s:ResolveSwitch` and the
calls that reduce `auto` to 0 or 1; and the `plug#begin`/`plug#end` block.

The local config must keep loading before the switch defaults, and the data-dir
must keep being re-resolved after it, because a local config is executable code
that may replace the value. That ordering is load-bearing and
`data-dir-override`, `data-dir-invalid-type`, `data-dir-empty`, and
`path-overrides` all assert on it.

- [ ] **Step 2: Create `autoload/chopsticks/options.vim`** *(superseded)*

Move the `set` blocks: recovery-file locations at `.vimrc:601-629`, the Windows
`E954` workaround at `.vimrc:630-643`, and the remaining editor options. Keep
the comment explaining why the Windows console rejects the option at assignment
time.

- [ ] **Step 3: Create `autoload/chopsticks/autocmds.vim`** *(superseded)*

Move the `Chopsticks`, `ChopsticksPlugins`, `ChopsticksDirectory`, and
`ChopsticksDashboard` augroups from `.vimrc:2780-2832`, plus `s:HandleResize`
and the `ChopsticksInterface` augroup from `.vimrc:1452-1469`. Keep the
`pencil_autoformat` and `pencil_cursorwrap` pre-creation at `.vimrc:389-396` in
`.vimrc`: its comment says Pencil clears those groups before first use and Vim 9
emits `E216` otherwise, so it must run while plugins are sourced.

- [ ] **Step 4: Call them from the shim** *(superseded)*

```vim
import autoload 'chopsticks/options.vim'
import autoload 'chopsticks/autocmds.vim'

options.Apply()
autocmds.Register()
```

These two run at startup by design; they are the only eager calls in
`plugin/chopsticks.vim`.

#### Task 9 as executed

Commit `b336724` moved the last of the *behaviour*: the buffer-local
language-server mappings and the two insert-mode completion handlers into
`autoload/chopsticks/lsp.vim`, and the cheatsheet's `Show()` into
`autoload/chopsticks/keys.vim`, joining the catalogue it displays. The Tab
mappings reach `lsp.vim` by dotted name from their `<expr>` right-hand sides,
because `<SID>` in a mapping cannot resolve a Vim9 module's functions.

Options, the plugin policy, the key registrations, and the autocommand wiring
stayed in `.vimrc`. Which key does what, which filetype gets which indent, and
what each plugin is told are the parts a person edits; they belong in the file
named after the person's config, with the behaviour they drive now living in
`autoload/`. Also staying, because Vim's startup order forces it: directory
resolution and switch normalisation, which run before `'runtimepath'` names this
repository at all; the `Chopsticks*` wrappers that `'statusline'` and
`'tabline'` evaluate during `.vimrc`'s own execution; and the four mapping
helpers, whose `:execute`'d right-hand sides contain `<SID>` and would repoint
~85 mappings at nothing if they moved.

`plugin/chopsticks.vim` therefore ends the phase with **no eager calls at all** —
six `import autoload` lines and nothing that runs one at startup — which is a
stronger laziness result than Step 4 planned for.

- [x] **Step 5: Run the suite and the benchmark**

```bash
sh scripts/lint-vim.sh
npm run benchmark
wc -l .vimrc
```

Expected: all 24 UI cases pass and startup does not regress. ~~`.vimrc` should
now be roughly 150-250 lines.~~ It ends at 1087, down from 2843. The difference
is not unfinished work; it is the configuration that was never meant to move.

- [x] **Step 6: Commit**

```bash
git add plugin/chopsticks.vim autoload/chopsticks/lsp.vim autoload/chopsticks/keys.vim .vimrc
git commit -m "Move the LSP keys and the cheatsheet display into their modules"
```

---

### Task 10: Retire the single-file claim

The README opens by describing Chopsticks as a single-file configuration. That
is no longer true, and the spec's risk table calls for replacing the claim
rather than deleting it.

**Files:**

- Modify: `README.md:7-10`, `README.md:34-77` (install path),
  `README.md:118-119` (Windows `_vimrc`)

- Modify: `CONTRIBUTING.md`, `docs/configuration.md`
- Modify: `CHANGELOG.md`

- [x] **Step 1: Rewrite the opening description**

Replace "A single-file configuration for Vim 8.2/9.x" with a description of what
actually holds now: a Vim 9.1.1947+ configuration that never uses the network at
startup, pins every dependency by commit, and loads its own modules lazily.

- [x] **Step 2: Check the install instructions still work**

The POSIX path symlinks `~/.vimrc` to `$HOME/chopsticks/.vimrc`. With `plugin/`
and `autoload/` now beside it, a symlinked `.vimrc` alone does not put them on
`runtimepath`. Verify and fix:

```bash
rm -rf /tmp/rtp-check && mkdir -p /tmp/rtp-check
ln -s "$PWD/.vimrc" /tmp/rtp-check/.vimrc
HOME=/tmp/rtp-check vim -Nu /tmp/rtp-check/.vimrc -i NONE -n -es \
  -c 'echo exists("*ChopsticksStatusline")' -c 'qall!'
```

Expected: `1`. If it prints `0`, `.vimrc` must add its own directory to
`runtimepath` before anything else, using its resolved path:

```vim
let s:chopsticks_root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
execute 'set runtimepath^=' . fnameescape(s:chopsticks_root)
```

This is the one place `expand('<sfile>')` is required, and it is why `.vimrc`
stays legacy script and is excluded from the Vim9 linter's file list.

- [x] **Step 3: Update the Windows install path**

The PowerShell block writes `_vimrc` containing `execute 'source ' .
fnameescape(expand('~/chopsticks/.vimrc'))`. Confirm the `runtimepath` line from
Step 2 resolves correctly when sourced that way rather than symlinked, since
`expand('<sfile>')` differs between the two.

- [x] **Step 4: Add a changelog entry**

Record the version floor change and the restructure as the breaking changes they
are.

- [x] **Step 5: Run everything**

```bash
sh scripts/lint-vim.sh
npm run lint
npm run benchmark
git diff --check
```

- [x] **Step 6: Commit**

```bash
git add README.md CONTRIBUTING.md docs/configuration.md CHANGELOG.md .vimrc
git commit -m "Document the module layout and the 9.1.1947 floor"
```

---

## Done when

- All 24 UI cases and both plugin-integration suites pass on macOS, Linux, and
  Windows CI.

- `scripts/benchmark-vim.py --check` reports no startup regression.
- `sh scripts/lint-vim.sh` lints `.vimrc` with vimlint and every `plugin/` and
  `autoload/` file with `:defcompile`.

- No plugin was added, removed, or swapped.
- Laziness is real, not nominal. Starting Vim on a non-Markdown file must not
  source `markdown.vim`, `session.vim`, `health.vim`, or `keys.vim`:

  ```bash
  vim -Nu .vimrc -i NONE -n -es README.md \
    -c 'echo filter(split(execute("scriptnames"), "\n"),
    \   "v:val =~# \"chopsticks/\\\\(markdown\\\\|session\\\\|health\\\\)\"")' \
    -c 'qall!'
  ```

Expected: an empty list. `statusline.vim`, `bufferline.vim`, `icons.vim`,
`theme.vim`, `options.vim`, and `autocmds.vim` are expected to appear; they are
on the startup path by design.
