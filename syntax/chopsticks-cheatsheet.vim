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
# The mode is reachable only through the key's nextgroup: listed in contains
# as well, its \S\+ also matches the key's first word, and the later rule wins.
syntax match chopsticksCheatEntry /^ \{2}\S.*/
  \ contains=chopsticksCheatKey,chopsticksCheatAlias
# Safe in contains where the mode is not: it needs two spaces then a bracket,
# which column three of an entry line can never be.
syntax match chopsticksCheatAlias /\s\{2}(\%(\S\| \)\+)$/ contained
# nextgroup, not a second \%3c anchor: two contained matches cannot both begin
# at column three, and the key wins, which left the mode column uncoloured and
# ChopCheatMode dead.
syntax match chopsticksCheatKey /\%3c.\{-}\ze\s\{2,}/ contained
  \ nextgroup=chopsticksCheatMode skipwhite
syntax match chopsticksCheatMode /\S\+/ contained

highlight default link chopsticksCheatTitle ChopCheatTitle
highlight default link chopsticksCheatLegend ChopCheatLegend
highlight default link chopsticksCheatGroup ChopCheatGroup
highlight default link chopsticksCheatEntry ChopCheatEntry
highlight default link chopsticksCheatKey ChopCheatKey
highlight default link chopsticksCheatMode ChopCheatMode
highlight default link chopsticksCheatAlias ChopCheatAlias

b:current_syntax = 'chopsticks-cheatsheet'
