Output .github/demo.gif
Set Shell bash
Set FontSize 14
Set Width 960
Set Height 540
Set Theme "Builtin Solarized Dark"
Set TypingSpeed 50ms
Set Padding 10

Type "vim ~/.vim/modules/core.vim"
Enter
Sleep 1.5s

# Show the code with solarized theme and statusline
Sleep 1s

# Use Ctrl+p for fuzzy find
Type "\x10"
Sleep 1s
Type "lsp"
Sleep 1s
Escape
Sleep 0.5s

# Go to definition
Type "gg"
Sleep 0.3s
Type "/mapleader"
Enter
Sleep 1s

# Show cheat sheet
Type ",?"
Sleep 2s
Type "q"
Sleep 0.5s

# Open file browser
Type ",e"
Sleep 1.5s
Escape
Sleep 0.5s

# Quit
Type ":qa!"
Enter
Sleep 0.5s
