# chopsticks demo — "what can I do with this?"
# Record: cd ~/.vim && vhs .github/demo.tape
#
# Pre-record setup:
#   1. Create demo project:
#      mkdir -p /tmp/demo-project && cd /tmp/demo-project
#      Create app.py, utils.py, config.yaml (with docstrings to avoid lint noise)
#      git init && git add -A && git commit -m "init"
#
#   2. Clean Startify recent files so personal paths don't leak:
#      rm -f ~/.viminfo
#
#   3. Optional LSP: vim utils.py → :LspInstallServer → quit
#      then uncomment LSP section below

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

# ── 2. Fuzzy find — open a file instantly ──────────────────────────────────
# move focus to the main window first
Type@100ms "\x17l"
Sleep 0.3s
Ctrl+p
Sleep 0.8s
Type "app"
Sleep 1s
Enter
Sleep 1.5s

# ── 3. Ripgrep — search "greet" across project ─────────────────────────────
Type ",rg"
Sleep 0.8s
Type "greet"
Sleep 1.2s
Escape
Sleep 0.5s

# ── 4. Run file — see output immediately ───────────────────────────────────
Type ",cr"
Sleep 2.5s
# dismiss "Press ENTER" prompt
Enter
Sleep 0.8s

# ── 5. Git status ──────────────────────────────────────────────────────────
Type ",gs"
Sleep 2s
Type "q"
Sleep 0.5s

# ── 6. Sidebar toggle ──────────────────────────────────────────────────────
# close the vim . sidebar first
Type ",e"
Sleep 0.5s
# re-open it
Type ",e"
Sleep 1.5s
# close it
Type ",e"
Sleep 0.8s

# ── 7. Cheat sheet — discover all keybindings ──────────────────────────────
Type ",?"
Sleep 3s
Type "q"
Sleep 0.5s

# ── done ────────────────────────────────────────────────────────────────────
Type ":qa!"
Enter
Sleep 0.5s
