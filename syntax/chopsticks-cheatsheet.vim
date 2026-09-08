vim9script

# Columns are sized per panel, so fields are found by shape, not column number:
# two spaces, an optional glyph, then key, mode and description separated by
# runs of two or more spaces. window.vim passes the legend height because the
# line anchors below depend on it and it differs per panel.

if exists('b:current_syntax')
  finish
endif

var legend = get(b:, 'chopsticks_legend', 0)

# Every key the sheet prints is ASCII, so a non-ASCII run is the glyph. In
# ASCII mode this never matches and the key keeps column three.
const GLYPH = '[^\x00-\x7F]\+'

execute 'syntax match chopsticksCheatLegend /\%<' .. (legend + 1) .. 'l.*/'
execute 'syntax match chopsticksCheatGroup /^\%>' .. legend .. 'l\S.*/'
  .. ' contains=chopsticksCheatGroupIcon'
execute 'syntax match chopsticksCheatGroupIcon /^' .. GLYPH .. '/ contained'
# The mode is reachable only through the key's nextgroup: listed in contains
# as well, its \S\+ also matches the key's first word, and the later rule wins.
syntax match chopsticksCheatEntry /^ \{2}\S.*/
  \ contains=chopsticksCheatIcon,chopsticksCheatKey,chopsticksCheatAlias
# Safe in contains where the mode is not: it needs two spaces then a bracket,
# which column three of an entry line can never be.
syntax match chopsticksCheatAlias /\s\{2}(\%(\S\| \)\+)$/ contained
syntax match chopsticksCheatKey /\%3c.\{-}\ze\s\{2,}/ contained
  \ nextgroup=chopsticksCheatMode skipwhite
# No column anchor: reached only from the icon, which displaces the key.
syntax match chopsticksCheatKeyed /.\{-}\ze\s\{2,}/ contained
  \ nextgroup=chopsticksCheatMode skipwhite
# Must stay after the key: both can start at column three and the last one
# defined wins.
execute 'syntax match chopsticksCheatIcon /\%3c' .. GLYPH .. '/ contained'
  .. ' nextgroup=chopsticksCheatKeyed skipwhite'
syntax match chopsticksCheatMode /\S\+/ contained

highlight default link chopsticksCheatLegend ChopCheatLegend
highlight default link chopsticksCheatGroup ChopCheatGroup
highlight default link chopsticksCheatGroupIcon ChopCheatIcon
highlight default link chopsticksCheatEntry ChopCheatEntry
highlight default link chopsticksCheatIcon ChopCheatIcon
highlight default link chopsticksCheatKey ChopCheatKey
highlight default link chopsticksCheatKeyed ChopCheatKey
highlight default link chopsticksCheatMode ChopCheatMode
highlight default link chopsticksCheatAlias ChopCheatAlias

b:current_syntax = 'chopsticks-cheatsheet'
