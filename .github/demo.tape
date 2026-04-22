# chopsticks demo — reliable version
# Key insight: NEVER use Escape to close FZF — always Enter (select result).
# This guarantees Vim returns to Normal mode with a known buffer.

Output .github/demo.gif
Set Shell bash
Set FontSize 14
Set Width 1080
Set Height 620
Set Theme "Builtin Solarized Dark"
Set TypingSpeed 40ms
Set Padding 10

# ── 1. Open file — syntax + statusline ─────────────────────────────────────
Type "cd /tmp/demo-project && vim app.py"
Enter
Sleep 2.5s

# ── 2. Fuzzy find — open another file ──────────────────────────────────────
Ctrl+p
Sleep 1s
Type "utils"
Sleep 1.2s
Enter
Sleep 2s

# ── 3. Ripgrep — search + jump to result ───────────────────────────────────
Type ",rg"
Sleep 1s
Type "greet"
Sleep 1.5s
Enter
Sleep 2s

# ── 4. Run file ────────────────────────────────────────────────────────────
# reset to app.py (known state)
Type ":edit app.py"
Enter
Sleep 1s
Type ",cr"
Sleep 3s
Enter
Sleep 1s

# ── 5. Git log ─────────────────────────────────────────────────────────────
Type ",gL"
Sleep 2.5s
Type "q"
Sleep 1s

# ── 6. Cheat sheet ─────────────────────────────────────────────────────────
Type ",?"
Sleep 3.5s
Type "q"
Sleep 0.5s

# ── done ───────────────────────────────────────────────────────────────────
Type ":qa!"
Enter
Sleep 0.5s
