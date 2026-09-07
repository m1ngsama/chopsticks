vim9script

# chopsticks#keys#Lines() sizes its columns from the longest entry, so the
# fields are found by shape rather than by column number: an entry line is two
# spaces and then key, mode and description separated by runs of two or more
# spaces. The header is the first six lines; every later line at column one is
# a group heading.

if exists('b:current_syntax')
  finish
endif

syntax match chopsticksCheatTitle /\%1l.*/
syntax match chopsticksCheatLegend /\%>2l\%<7l.*/
syntax match chopsticksCheatGroup /^\%>6l\S.*/
syntax match chopsticksCheatEntry /^ \{2}\S.*/
  \ contains=chopsticksCheatKey,chopsticksCheatMode
syntax match chopsticksCheatKey /\%3c.\{-}\ze\s\{2,}/ contained
syntax match chopsticksCheatMode /\%3c.\{-}\s\{2,}\zs\S\+/ contained

highlight default link chopsticksCheatTitle ChopCheatTitle
highlight default link chopsticksCheatLegend ChopCheatLegend
highlight default link chopsticksCheatGroup ChopCheatGroup
highlight default link chopsticksCheatEntry ChopCheatEntry
highlight default link chopsticksCheatKey ChopCheatKey
highlight default link chopsticksCheatMode ChopCheatMode

b:current_syntax = 'chopsticks-cheatsheet'
