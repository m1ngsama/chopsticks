vim9script

if exists('b:current_syntax')
  finish
endif

var legend = get(b:, 'chopsticks_legend', 0)

const GLYPH = '[^\x00-\x7F]\+'

execute 'syntax match chopsticksCheatLegend /\%<' .. (legend + 1) .. 'l.*/'
execute 'syntax match chopsticksCheatGroup /^\%>' .. legend .. 'l\S.*/'
  .. ' contains=chopsticksCheatGroupIcon'
execute 'syntax match chopsticksCheatGroupIcon /^' .. GLYPH .. '/ contained'
syntax match chopsticksCheatEntry /^ \{2}\S.*/
  \ contains=chopsticksCheatIcon,chopsticksCheatKey,chopsticksCheatAlias
syntax match chopsticksCheatAlias /\s\{2}(\%(\S\| \)\+)$/ contained
syntax match chopsticksCheatKey /\%3c.\{-}\ze\s\{2,}/ contained
  \ nextgroup=chopsticksCheatMode skipwhite
syntax match chopsticksCheatKeyed /.\{-}\ze\s\{2,}/ contained
  \ nextgroup=chopsticksCheatMode skipwhite
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
