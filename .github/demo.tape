# chopsticks demo — narrative: "what can I do with this?"
# Rule: NEVER use Escape to close FZF — always Enter (deterministic).

Output .github/demo.gif
Set Shell bash
Set FontSize 14
Set Width 1080
Set Height 620
Set Theme "Builtin Solarized Dark"
Set TypingSpeed 35ms
Set Padding 10

# ── 1. Context + open ──────────────────────────────────────────────────────
# The tagline tells the viewer WHY before showing WHAT.
Type "cd /tmp/demo-project"
Enter
Sleep 0.8s
Type "vim server.py"
Enter
Sleep 2.5s

# ── 2. Fuzzy find files (Ctrl+p → type → select) ──────────────────────────
# Shows: IDE-level file navigation — fuzzy match + live preview.
Ctrl+p
Sleep 1s
Type "route"
Sleep 1.5s
Enter
Sleep 2s

# ── 3. Ripgrep project search (,rg → query → select) ──────────────────────
# Shows: grep entire project with preview — like VS Code Ctrl+Shift+F.
Type ",rg"
Sleep 1s
Type "def "
Sleep 1.5s
Enter
Sleep 2s

# ── 4. Run file (,cr) ─────────────────────────────────────────────────────
# Shows: one-key execution — no switching to terminal.
Type ":edit server.py"
Enter
Sleep 1s
Type ",cr"
Sleep 3s
Enter
Sleep 1s

# ── 5. Cheat sheet (,?) ───────────────────────────────────────────────────
# Shows: it's discoverable — every keybinding in one sidebar.
Type ",?"
Sleep 4s
Type "q"
Sleep 0.5s

# ── done ───────────────────────────────────────────────────────────────────
Type ":qa!"
Enter
Sleep 0.5s
