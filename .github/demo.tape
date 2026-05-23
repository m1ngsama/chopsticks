# chopsticks demo — for people who already know Vim:
# show the project workflow layer Vim does not assemble by default.
# project loop: visible jump → files → run → grep → git → active key help.
# Rule: NEVER use Escape to close FZF — always Enter (deterministic).
# Pacing: hold each scene long enough for the viewer to read.

Output .github/demo.gif
Require bash
Require vim
Require python3
Require git
Set Shell bash
Set FontSize 14
Set Width 1080
Set Height 620
Set Theme "Builtin Solarized Dark"
Set TypingSpeed 50ms
Set Padding 10

# ── 0. Prepare deterministic fixture and local config ─────────────────────
Hide
Type "export CHOPSTICKS_ROOT=$(git rev-parse --show-toplevel)"
Enter
Type "export XDG_CONFIG_HOME=$(mktemp -d /tmp/chopsticks-demo-xdg-XXXXXX)"
Enter
Type "export CHOPSTICKS_DEMO_PROJECT=$(mktemp -d /tmp/chopsticks-demo-project-XXXXXX)"
Enter
Type `cp "$CHOPSTICKS_ROOT/.github/demo-project/"*.py "$CHOPSTICKS_DEMO_PROJECT/"`
Enter
Type "cd $CHOPSTICKS_DEMO_PROJECT"
Enter
Type "git init -q && git symbolic-ref HEAD refs/heads/main && git add ."
Enter
Type `clear && printf "%s\n" "chopsticks: a long-term Vim efficiency kit" "" "For experienced Vim users who already know how to edit." "Keep Vim's language. Standardize the project loop:" "" "  s + 2 chars   visible jump on the current screen" "  SPC SPC       project-aware file switcher" "  SPC rr        run the current file" "  SPC /         ripgrep the project" "  SPC gs        git status, with no push/pull hotkeys" "  SPC ?         active keys explained inside Vim"`
Enter
Show
Sleep 6s
Type "clear"
Enter
Type `vim -Nu "$CHOPSTICKS_ROOT/.vimrc" server.py`
Enter
Wait+Screen /server.py/
Sleep 1s

# ── 1. Screen-local motion: stop counting hjkl across dense code ───────────
Type "s"
Sleep 0.5s
Type "di"
Sleep 2s
Ctrl+C
Sleep 1s

# ── 2. Project files: one habit for git-aware file switching ───────────────
Space 2
Sleep 1.5s
Type "report"
Sleep 2s
Enter
Sleep 3s

# ── 3. Edit-run loop: run the current file without leaving Vim ─────────────
Space
Type "rr"
Sleep 4s
Enter
Sleep 1s

# ── 4. Project grep: ripgrep as part of the same muscle-memory layer ───────
Space
Type "/"
Sleep 1s
Type "def get_users"
Sleep 2.5s
Enter
Sleep 3s

# ── 5. Git boundary: status is fast; push/pull stay explicit commands ──────
Space
Type "gs"
Sleep 3s
Type ":bd!"
Enter
Sleep 1s

# ── 6. Self-documenting config: no private wiki required ───────────────────
Space
Type "?"
Sleep 5.5s
Type "q"
Sleep 0.5s

# ── done ───────────────────────────────────────────────────────────────────
Hide
Type ":qa!"
Enter
Sleep 0.5s
Type `test -n "$CHOPSTICKS_DEMO_PROJECT" && rm -rf "$CHOPSTICKS_DEMO_PROJECT"`
Enter
Sleep 0.5s
