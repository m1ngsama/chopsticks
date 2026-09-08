vim9script

# One label per window, the way tmux names a pane: which file a split holds,
# without hunting for its statusline. Popups rather than buffer text, so the
# file being edited carries none of it.

import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/ui/text.vim'

# Under the finder, which owns the screen while it is open, and over the text
# the label floats on.
const ZINDEX = 30
const MAX_WIDTH = 40

var labels: dict<number> = {}
var modified: dict<number> = {}
# Creating a popup moves windows, which fires the events that call Refresh().
var busy = false

def Wanted(id: number): bool
  var buf = winbufnr(id)
  if buf <= 0
    return false
  endif
  # A drawer, the dashboard and quickfix say what they are already.
  var kind = getbufvar(buf, '&buftype')
  return kind ==# '' || kind ==# 'terminal' || kind ==# 'help'
enddef

def Text(id: number): string
  var buf = winbufnr(id)
  var name = bufname(buf)
  var label = icons.FileIcon(name)
    .. (empty(name) ? '[No Name]' : fnamemodify(name, ':t'))
  if getbufvar(buf, '&modified')
    label ..= ' [+]'
  endif
  return ' ' .. text.Truncate(label, MAX_WIDTH) .. ' '
enddef

def Show(id: number)
  var pos = win_screenpos(id)
  if pos == [0, 0]
    return
  endif
  var body = Text(id)
  var column = pos[1] + winwidth(id) - strwidth(body)
  var group = id == win_getid() ? 'ChopWinLabel' : 'ChopWinLabelNC'
  var key = string(id)
  if labels->has_key(key) && !empty(popup_getpos(labels[key]))
    popup_settext(labels[key], body)
    popup_move(labels[key], {line: pos[0], col: max([1, column])})
    popup_setoptions(labels[key], {highlight: group})
    return
  endif
  labels[key] = popup_create(body, {
    line: pos[0],
    col: max([1, column]),
    zindex: ZINDEX,
    highlight: group,
    mapping: false,
    wrap: false,
    })
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
  # A lone window already names its file in the statusline, and saying it
  # twice is the thing this is meant to avoid.
  if !g:ChopsticksWindowLabelsEnabled() || winnr('$') < 2
    Clear()
    return
  endif
  busy = true
  try
    var live: list<string> = []
    for nr in range(1, winnr('$'))
      var id = win_getid(nr)
      if Wanted(id)
        live->add(string(id))
        Show(id)
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

# TextChanged fires on every keystroke; only the [+] flag flipping changes the
# label, so everything else must not reach popup_settext().
export def OnTextChanged()
  var key = string(bufnr('%'))
  var state = &modified ? 1 : 0
  if get(modified, key, -1) == state
    return
  endif
  modified[key] = state
  Refresh()
enddef
