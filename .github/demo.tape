# chopsticks README demo.
# Start with the in-editor map, then use that map for one project loop.
# Rule: NEVER use Escape to close FZF. Always Enter for deterministic output.

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
Type "stty -echo"
Enter
Type "clear"
Enter
Type `vim -Nu "$CHOPSTICKS_ROOT/.vimrc" server.py`
Enter
Wait+Screen /server.py/
Type ":ChopsticksCheatSheet"
Enter
Wait+Screen /trained loop/
Show
Sleep 4s
Type "q"
Sleep 0.5s

# ── 1. Screen-local motion: jump where the eye already is ──────────────────
Type "s"
Sleep 0.5s
Type "di"
Sleep 1.5s
Ctrl+C
Sleep 0.8s

# ── 2. Project files: switch files from the same map ───────────────────────
Space 2
Sleep 1s
Type "report"
Sleep 1.4s
Enter
Sleep 1.8s

# ── 3. Edit-run loop: run the current file without leaving Vim ─────────────
Space
Type "rr"
Sleep 2.5s
Enter
Sleep 0.8s

# ── 4. Project grep: search the repo and land in the result ────────────────
Space
Type "/"
Sleep 0.8s
Type "def get_users"
Sleep 1.5s
Enter
Sleep 2s

# ── 5. Git boundary: status is fast; push/pull stay explicit commands ──────
Space
Type "gs"
Sleep 2.2s
Type ":bd!"
Enter
Sleep 0.8s

# ── 6. End where the user learns: inside Vim ───────────────────────────────
Space
Type "?"
Sleep 4s
Type "q"
Sleep 0.5s

# ── done ───────────────────────────────────────────────────────────────────
Hide
Type ":qa!"
Enter
Sleep 0.5s
Type "stty echo"
Enter
Sleep 0.2s
Type `test -n "$CHOPSTICKS_DEMO_PROJECT" && rm -rf "$CHOPSTICKS_DEMO_PROJECT"`
Enter
Sleep 0.5s
