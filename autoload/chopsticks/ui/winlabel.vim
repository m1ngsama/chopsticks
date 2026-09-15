vim9script

import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/ui/text.vim'

const ZINDEX = 30
const MAX_WIDTH = 40
const MIN_WIDTH = 12

var labels: dict<number> = {}
var modified: dict<number> = {}
var busy = false

def Wanted(id: number): bool
  var buf = winbufnr(id)
  if buf <= 0
    return false
  endif
  var kind = getbufvar(buf, '&buftype')
  return kind ==# '' || kind ==# 'terminal' || kind ==# 'help'
enddef

def Text(id: number, width: number): string
  var buf = winbufnr(id)
  var name = bufname(buf)
  var label = icons.FileIcon(name)
    .. (empty(name) ? '[No Name]' : fnamemodify(name, ':t'))
  if getbufvar(buf, '&modified')
    label ..= ' [+]'
  endif
  return ' ' .. text.Truncate(label, min([MAX_WIDTH, width - 2])) .. ' '
enddef

def Show(id: number): bool
  var pos = win_screenpos(id)
  var width = winwidth(id)
  if pos == [0, 0] || width < MIN_WIDTH
    return false
  endif
  var body = Text(id, width)
  var column = pos[1] + width - strwidth(body)
  var group = id == win_getid() ? 'ChopWinLabel' : 'ChopWinLabelNC'
  var key = string(id)
  if labels->has_key(key) && !empty(popup_getpos(labels[key]))
    popup_settext(labels[key], body)
    popup_move(labels[key], {line: pos[0], col: max([1, column])})
    popup_setoptions(labels[key], {highlight: group})
    return true
  endif
  labels[key] = popup_create(body, {
    line: pos[0],
    col: max([1, column]),
    zindex: ZINDEX,
    highlight: group,
    mapping: false,
    wrap: false,
    })
  return true
enddef

export def Clear()
  for id in values(labels)
    popup_close(id)
  endfor
  labels = {}
enddef

export def Refresh()
  if busy
    return
  endif
  if !exists('*g:ChopsticksWindowLabelsEnabled')
    return
  endif
  var labelable = range(1, winnr('$'))->filter((_, nr) => Wanted(win_getid(nr)))
  if !g:ChopsticksWindowLabelsEnabled() || len(labelable) < 2
    Clear()
    return
  endif
  busy = true
  try
    var live: list<string> = []
    for nr in range(1, winnr('$'))
      var id = win_getid(nr)
      if Wanted(id) && Show(id)
        live->add(string(id))
      endif
    endfor
    for key in keys(labels)
      if index(live, key) < 0
        popup_close(labels[key])
        remove(labels, key)
      endif
    endfor
  finally
    busy = false
  endtry
enddef

export def OnTextChanged()
  var key = string(bufnr('%'))
  var state = &modified ? 1 : 0
  if get(modified, key, -1) == state
    return
  endif
  modified[key] = state
  Refresh()
enddef
