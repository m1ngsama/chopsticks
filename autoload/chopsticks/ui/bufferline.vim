vim9script

# Vim's tabline reused to list open file buffers. Render() runs on every tabline
# redraw. .vimrc calls Refresh() from its own top level, which is why this
# module's globals are declared there and not in plugin/chopsticks.vim.

import autoload 'chopsticks/ui/text.vim'
import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/ui/statusline.vim'

# Terminals, quickfix, help and the dashboard all set 'buftype' and are not
# open files.
export def FileBufferCount(): number
  var total = 0
  for buffer in getbufinfo({buflisted: 1})
    if getbufvar(buffer.bufnr, '&buftype') ==# ''
      total += 1
    endif
  endfor
  return total
enddef

export def Refresh()
  &showtabline = &filetype ==# 'chopsticks-dashboard' || exists('t:goyo_master')
    ? 0
    : (g:ChopsticksBufferlineEnabled() ? 2 : 0)
  execute 'redrawtabline'
enddef

def RefreshTimer(id: number)
  if id >= 0
    Refresh()
  endif
enddef

# Deferred by a zero-delay timer so the count reflects the buffer list after
# the current command finishes, not part-way through it: a :bdelete or an
# :argadd is not visible in getbufinfo() until its autocommands have run.
export def ScheduleRefresh()
  if exists('*timer_start')
    timer_start(0, RefreshTimer)
  else
    Refresh()
  endif
enddef

export def Render(): string
  var density = statusline.UiDensity()
  var segments = []
  var active = -1
  for buffer in getbufinfo({buflisted: 1})
    if getbufvar(buffer.bufnr, '&buftype') !=# ''
      continue
    endif
    var name = fnamemodify(buffer.name, ':t')
    name = empty(name) ? '[No Name]' : name
    name = text.Truncate(name, density ==# 'rich' ? 28 : 22)
    var icon = icons.FileIcon(buffer.name)
    var changed = get(buffer, 'changed', 0) ? ' ' .. icons.Get('modified') : ''
    var number = density ==# 'rich' ? buffer.bufnr .. ' ' : ''
    if buffer.bufnr == bufnr('%')
      active = len(segments)
    elseif active < 0 && buffer.bufnr == bufnr('#')
      active = len(segments)
    endif
    add(segments, {
      bufnr: buffer.bufnr,
      text: ' ' .. number .. icon .. name .. changed .. ' ',
    })
  endfor
  if empty(segments)
    return '%#TabLineFill#%='
  endif

  # Grow outward from the current buffer until the row is full, so the
  # buffer you are in stays visible however many others are open.
  var anchor = active >= 0 ? active : 0
  var left = anchor
  var right = anchor
  var show_overflow = &columns >= 16
  var budget = max([1, &columns - (show_overflow ? 10 : 0)])
  segments[anchor].text = text.Truncate(segments[anchor].text, budget)
  var used = strwidth(segments[anchor].text)
  while true
    var grew = false
    if left > 0
      var width = strwidth(segments[left - 1].text)
      if used + width <= budget
        left -= 1
        used += width
        grew = true
      endif
    endif
    if right + 1 < len(segments)
      var width = strwidth(segments[right + 1].text)
      if used + width <= budget
        right += 1
        used += width
        grew = true
      endif
    endif
    if !grew
      break
    endif
  endwhile

  var left_hint = show_overflow && left > 0 ? ' ‹' .. left .. ' ' : ''
  var right_hint = show_overflow && right + 1 < len(segments)
    ? ' ' .. (len(segments) - right - 1) .. '› ' : ''
  var hint_width = strwidth(left_hint) + strwidth(right_hint)
  if hint_width >= &columns
    # No room for the counts themselves: drop them and show the current
    # buffer alone.
    show_overflow = false
    left_hint = ''
    right_hint = ''
    left = anchor
    right = anchor
    segments[anchor].text =
      text.Truncate(segments[anchor].text, max([1, &columns]))
  elseif used + hint_width > &columns
    left = anchor
    right = anchor
    left_hint = anchor > 0 ? ' ‹' .. anchor .. ' ' : ''
    right_hint = anchor + 1 < len(segments)
      ? ' ' .. (len(segments) - anchor - 1) .. '› ' : ''
    hint_width = strwidth(left_hint) + strwidth(right_hint)
    segments[anchor].text = text.Truncate(segments[anchor].text,
      max([1, &columns - hint_width]))
  endif

  var line = empty(left_hint) ? '' : '%#TabLine#' .. left_hint
  for index in range(left, right)
    line ..= index == active ? '%#TabLineSel#' : '%#TabLine#'
    line ..= substitute(segments[index].text, '%', '%%', 'g')
  endfor
  if !empty(right_hint)
    line ..= '%#TabLine#' .. right_hint
  endif
  return line .. '%#TabLineFill#%='
enddef
