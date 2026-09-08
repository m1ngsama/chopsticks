vim9script

# Same panel as the cheatsheet, so it borrows those groups; only the bracketed
# status column differs.

if exists('b:current_syntax')
  finish
endif

var legend = get(b:, 'chopsticks_legend', 0)

execute 'syntax match chopsticksHealthLegend /\%<' .. (legend + 1) .. 'l.*/'
execute 'syntax match chopsticksHealthGroup /^\%>' .. legend .. 'l\S.*/'
  .. ' contains=chopsticksHealthGroupIcon'
syntax match chopsticksHealthGroupIcon /^[^\x00-\x7F]\+/ contained
syntax match chopsticksHealthRow /^ \{2}\S.*/
  \ contains=chopsticksHealthOk,chopsticksHealthBad,chopsticksHealthOff
# Two trailing spaces, so this is the padded name column and not the first
# word of a Notes sentence.
syntax match chopsticksHealthName /\S\+\ze\s\{2,}/ contained
syntax match chopsticksHealthOk /\%3c\[ok\]/ contained
  \ nextgroup=chopsticksHealthName skipwhite
syntax match chopsticksHealthBad /\%3c\[!!\]/ contained
  \ nextgroup=chopsticksHealthName skipwhite
syntax match chopsticksHealthOff /\%3c\[--\]/ contained
  \ nextgroup=chopsticksHealthName skipwhite

highlight default link chopsticksHealthLegend ChopCheatLegend
highlight default link chopsticksHealthGroup ChopCheatGroup
highlight default link chopsticksHealthGroupIcon ChopCheatIcon
highlight default link chopsticksHealthRow ChopCheatEntry
highlight default link chopsticksHealthName ChopCheatKey
highlight default link chopsticksHealthOk ChopHealthOk
highlight default link chopsticksHealthBad ChopHealthBad
highlight default link chopsticksHealthOff ChopHealthOff

b:current_syntax = 'chopsticks-health'
