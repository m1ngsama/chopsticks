# chopsticks demo — narrative: "what can I do with this?"
# Rule: NEVER use Escape to close FZF — always Enter (deterministic).
# Pacing: each scene holds long enough for a viewer to read and understand.

Output .github/demo.gif
Set Shell bash
Set FontSize 14
Set Width 1080
Set Height 620
Set Theme "Builtin Solarized Dark"
Set TypingSpeed 50ms
Set Padding 10

# ── 1. Open file — syntax highlighting + statusline ────────────────────────
Type "cd /tmp/demo-project"
Enter
Sleep 0.8s
Type "vim server.py"
Enter
Sleep 3.5s

# ── 2. Fuzzy find files (Ctrl+p → type → select) ──────────────────────────
Ctrl+p
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

# ── 4. Run file (,cr) ─────────────────────────────────────────────────────
Type ":edit server.py"
Enter
Sleep 1.5s
Type ",cr"
Sleep 4s
Enter
Sleep 1.5s

# ── 5. Cheat sheet (,?) ───────────────────────────────────────────────────
Type ",?"
Sleep 5.5s
Type "q"
Sleep 0.5s

# ── done ───────────────────────────────────────────────────────────────────
Type ":qa!"
Enter
Sleep 0.5s
