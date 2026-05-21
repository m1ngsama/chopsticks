# chopsticks demo — "what can I do with this?"
# Rule: NEVER use Escape to close FZF — always Enter (deterministic).
# Pacing: hold each scene long enough for the viewer to read.

Output .github/demo.gif
Set Shell bash
Set FontSize 14
Set Width 1080
Set Height 620
Set Theme "Builtin Solarized Dark"
Set TypingSpeed 50ms
Set Padding 10

# ── 0. Start API server in background ──────────────────────────────────────
Type "cd /tmp/demo-project"
Enter
Sleep 0.5s
Type "python3 serve.py > /dev/null 2>&1 &"
Enter
Sleep 1s

# ── 1. Open file — syntax highlighting + statusline ────────────────────────
Type "vim server.py"
Enter
Sleep 3.5s

# ── 2. Fuzzy find files (,ff → type → select) ────────────────────────────
Type ",ff"
Sleep 1.5s
Type "route"
Sleep 2.5s
Enter
Sleep 3s

# ── 3. Ripgrep project search (,rg → query → select) ──────────────────────
Type ",rg"
Sleep 1.5s
Type "def "
Sleep 3s
Enter
Sleep 3s

# ── 4. Curl the running API from inside Vim ────────────────────────────────
Type ":!curl -s localhost:8080/users | python3 -m json.tool"
Enter
Sleep 4.5s
Enter
Sleep 1.5s

# ── 5. Cheat sheet (,?) ───────────────────────────────────────────────────
# Reset to server.py so cheat sheet shows code on left, keys on right.
Type ":edit server.py"
Enter
Sleep 1s
Type ",?"
Sleep 5.5s
Type "q"
Sleep 0.5s

# ── done ───────────────────────────────────────────────────────────────────
Type ":qa!"
Enter
Sleep 0.5s
