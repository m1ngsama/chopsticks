# A repeatable tour of the real rich profile.  The interaction sequence follows
# the same Dashboard → find → explore → focus loop documented in README.md.

Output .github/demo.gif
Require bash
Require vim
Require git
Require rg
Require fzf

Set Shell bash
Set FontFamily "JetBrainsMono Nerd Font Mono"
Set FontSize 14
Set LetterSpacing 0
Set Width 1080
Set Height 620
Set LineHeight 1.1
Set Theme { "name": "Everforest Hard", "black": "#4b565c", "red": "#e67e80", "green": "#a7c080", "yellow": "#dbbc7f", "blue": "#7fbbb3", "magenta": "#d699b6", "cyan": "#83c092", "white": "#d3c6aa", "brightBlack": "#7a8478", "brightRed": "#e67e80", "brightGreen": "#a7c080", "brightYellow": "#dbbc7f", "brightBlue": "#7fbbb3", "brightMagenta": "#d699b6", "brightCyan": "#83c092", "brightWhite": "#fff9e8", "background": "#272e33", "foreground": "#d3c6aa", "selection": "#475258", "cursor": "#d3c6aa" }
Set TypingSpeed 45ms
Set Padding 10
Set Margin 12
Set MarginFill "#1e2326"
Set BorderRadius 10
Set WindowBar Colorful
Set Framerate 20
Set CursorBlink false

Env TERM "xterm-256color"
Env COLORTERM "truecolor"
Env TERM_PROGRAM "WezTerm"

# Prepare without recording shell noise, then reveal the real Dashboard.
Hide
Type `cd "$(git rev-parse --show-toplevel)"`
Enter
Type "clear"
Enter
Type "vim -Nu .github/demo.vim -i NONE -n"
Enter
Wait+Screen /Find File/
Type ":edit README.md"
Enter
Wait+Screen /A single-file configuration/
Type ":Goyo"
Enter
Sleep 500ms
Type ":Goyo"
Enter
Sleep 500ms
Type ":normal! gg"
Enter
Type ":ChopsticksDashboard"
Enter
Wait+Screen /Find File/
Type ":redraw!"
Enter
Show
Sleep 2.5s

# Discoverability: the contextual key guide uses the same semantic groups.
Space
Wait+Screen /SPC-/
Sleep 2s
Ctrl+C
Sleep 500ms

# Find and open the README through the real fzf.vim integration.
Type "f"
Wait+Screen /README.md/
Type "README"
Sleep 1s
Enter
Wait+Screen /A single-file configuration/
Sleep 1.5s

# Toggle the real Fern drawer open and closed with the same command.
Type@40ms " e"
Wait+Screen /tests/
Sleep 1.5s
Type@40ms " e"
Wait+Screen /A single-file configuration/
Sleep 750ms

# Search inside the current file, then enter the Markdown focus mode.
Type@40ms ";l"
Wait+Screen /BLines/
Type "Interface"
Sleep 1s
Enter
Wait+Screen /## Interface/
Sleep 1.5s
Type@40ms ",z"
Sleep 2.5s
Type@40ms ",z"
Sleep 750ms

# Return to the Dashboard so the GIF loops on the strongest frame.
Type ":ChopsticksDashboard"
Enter
Wait+Screen /Find File/
Hide
Type ":redraw!"
Enter
Show
Sleep 2s
Hide
Type ":qa!"
Enter
