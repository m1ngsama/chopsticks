# chopsticks demo — the project loop stock Vim does not assemble for you:
# visible jump → file finder → run file → project grep → active key help.
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
Type "clear"
Enter
Type `vim -Nu "$CHOPSTICKS_ROOT/.vimrc" server.py`
Enter
Wait+Screen /server.py/
Show
Sleep 1s

# ── 1. Pain: moving inside a dense screen should not mean counting hjkl ────
Type "s"
Sleep 0.5s
Type "di"
Sleep 2s
Ctrl+C
Sleep 1s

# ── 2. Pain: project files should be one habit, not :find/:edit plumbing ───
Space 2
Sleep 1.5s
Type "report"
Sleep 2s
Enter
Sleep 3s

# ── 3. Pain: edit→run should be one repeatable project loop ────────────────
Space
Type "rr"
Sleep 4s
Enter
Sleep 1s

# ── 4. Pain: project search should not leave Vim or require remembering rg ─
Space
Type "/"
Sleep 1s
Type "def get_users"
Sleep 2.5s
Enter
Sleep 3s

# ── 5. Pain: custom keymaps must explain themselves in the editor ──────────
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
