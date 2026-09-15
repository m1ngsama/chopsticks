vim9script

const FLASH_MS = 200
const BEACON_MS = 300
const SAVED_MS = 600

var scroll_timer = 0
var scroll_window = 0
var scroll_final: dict<number> = {}

def Flash(group: string, first: list<number>, last: list<number>, type: string, ms: number)
  if first[1] <= 0 || last[1] <= 0
    return
  endif
  var positions = getregionpos(first, last, {type: type, exclusive: false})
    ->mapnew((_, region) => [region[0][1], region[0][2] + region[0][3],
      region[1][2] + region[1][3] + 1 - region[0][2] - region[0][3]])
  var window = win_getid()
  var id = matchaddpos(group, positions, 20)
  timer_start(ms, (_) => {
    silent! matchdelete(id, window)
  })
enddef

export def Yanked()
  if v:event.operator ==# 'y'
    Flash('ChopFlash', getpos("'["), getpos("']"), v:event.regtype ?? 'v', FLASH_MS)
  endif
enddef

export def Changed()
  var [first, last] = [getpos("'["), getpos("']")]
  var linewise = first[2] == 1 && last[2] == 1 && last[1] > first[1]
  Flash('ChopFlash', first, last, linewise ? 'V' : 'v', FLASH_MS)
enddef

export def Moved()
  var here = [bufnr(), line('.')]
  var last = get(w:, 'chopsticks_position', here)
  w:chopsticks_position = here
  if scroll_timer == 0 && &buftype ==# ''
      && (here[0] != last[0] || abs(here[1] - last[1]) > winheight(0) / 2)
    var position = getpos('.')
    Flash('ChopBeacon', position, position, 'V', BEACON_MS)
  endif
enddef

export def Saved()
  var buffer = bufnr()
  setbufvar(buffer, 'chopsticks_saved', 1)
  redrawstatus
  timer_start(SAVED_MS, (_) => {
    setbufvar(buffer, 'chopsticks_saved', 0)
    redrawstatus!
  })
enddef

export def Focus()
  var current = win_getid()
  var dim = winnr('$') > 1 && !empty(synIDattr(synIDtrans(hlID('NormalNC')), 'bg'))
  for window in getwininfo()
    if window.tabnr != tabpagenr() || getbufvar(window.bufnr, '&buftype') !=# ''
      continue
    endif
    var focused = window.winid == current
    setwinvar(window.winid, '&cursorline', focused && mode() !~# '^i')
    setwinvar(window.winid, '&wincolor', focused || !dim ? '' : 'NormalNC')
  endfor
enddef
