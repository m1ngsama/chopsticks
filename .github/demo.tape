# chopsticks README demo.
# Start with the in-editor map, then use it for the most common Vim project
# loop: find a file, search text, edit, save, inspect Git.
# Rule: NEVER use Escape to close FZF. Always Enter for deterministic output.

Output .github/demo.gif
Require bash
Require vim
Require git
Require rg
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
Type `cp -R "$CHOPSTICKS_ROOT/.github/demo-project/." "$CHOPSTICKS_DEMO_PROJECT/"`
Enter
Type "cd $CHOPSTICKS_DEMO_PROJECT"
Enter
Type "git init -q && git symbolic-ref HEAD refs/heads/main"
Enter
Type "git config user.email demo@chopsticks.local && git config user.name demo"
Enter
Type "git add . && git commit -qm 'Seed language-neutral demo'"
Enter
Type "stty -echo"
Enter
Type "clear"
Enter
Type `vim -Nu "$CHOPSTICKS_ROOT/.vimrc" README.md`
Enter
Wait+Screen /project notes/
Space
Type "?"
Wait+Screen /trained loop/
Show
Sleep 3s
Type "q"
Sleep 0.5s

# ── 1. Find a project file from normal mode ────────────────────────────────
Space 2
Sleep 1s
Type "today"
Sleep 1.2s
Enter
Wait+Screen /maintenance/
Sleep 1.4s

# ── 2. Search the whole project and land on the match ──────────────────────
Space
Type "/"
Sleep 0.8s
Type "remote state"
Sleep 1.2s
Enter
Wait+Screen /remote state/
Sleep 1.2s

# ── 3. Make the ordinary edit and save it ──────────────────────────────────
Type "o"
Type "Remote changes stay deliberate."
Sleep 0.8s
Ctrl+C
Sleep 0.5s
Space
Type "w"
Sleep 1.2s

# ── 4. Inspect Git, no push/pull hotkeys ───────────────────────────────────
Space
Type "gs"
Wait+Screen /decision-log.md/
Sleep 4s

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
