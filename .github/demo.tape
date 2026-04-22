# chopsticks demo — "what can I do with this?"
# Record: cd ~/.vim && vhs .github/demo.tape
#
# Setup: mkdir -p /tmp/demo-project && cd /tmp/demo-project
#   Create app.py, utils.py, config.yaml (small Python project)
#   git init && git add -A && git commit -m "init"
#
# Optional LSP: open a .py file in vim, run :LspInstallServer
#   then uncomment the LSP section below

Output .github/demo.gif
Set Shell bash
Set FontSize 14
Set Width 1080
Set Height 620
Set Theme "Builtin Solarized Dark"
Set TypingSpeed 40ms
Set Padding 10

# ── 1. Open project — sidebar + dashboard ──────────────────────────────────
Type "cd /tmp/demo-project && vim ."
Enter
Sleep 2.5s

# ── 2. Fuzzy find — instant file search ────────────────────────────────────
Ctrl+p
Sleep 0.8s
Type "utils"
Sleep 1s
Enter
Sleep 1.2s

# ── 3. Ripgrep — search across entire project ──────────────────────────────
Type ",rg"
Sleep 0.8s
Type "greet"
Sleep 1s
Escape
Sleep 0.5s

# ── 4. Run file — one keystroke ─────────────────────────────────────────────
# open app.py first
Ctrl+p
Sleep 0.5s
Type "app"
Sleep 0.8s
Enter
Sleep 1s
Type ",cr"
Sleep 2s
Enter
Sleep 0.5s

# ── 5. File sidebar toggle ─────────────────────────────────────────────────
Type ",e"
Sleep 1.5s
Type ",e"
Sleep 0.8s

# ── 6. Git status ──────────────────────────────────────────────────────────
Type ",gs"
Sleep 1.5s
Type "q"
Sleep 0.5s

# ── 7. Cheat sheet — discover everything ───────────────────────────────────
Type ",?"
Sleep 2.5s
Type "q"
Sleep 0.5s

# ── done ────────────────────────────────────────────────────────────────────
Type ":qa!"
Enter
Sleep 0.5s

# ── (optional) LSP — uncomment after :LspInstallServer in a .py file ──────
# Ctrl+p
# Sleep 0.5s
# Type "utils"
# Sleep 0.8s
# Enter
# Sleep 1.5s
# Type "/greet"
# Enter
# Sleep 0.5s
# Type "K"
# Sleep 2s
# Escape
# Sleep 0.5s
# Type "gd"
# Sleep 1.5s
# Ctrl+o
# Sleep 0.8s
