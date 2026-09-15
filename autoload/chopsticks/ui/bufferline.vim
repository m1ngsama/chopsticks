vim9script

import autoload 'chopsticks/ui/text.vim'
import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/ui/statusline.vim'

export def Refresh()
  var start_screen = winnr('$') == 1 && &filetype ==# 'chopsticks-dashboard'
  var view = winsaveview()
  if !exists('t:goyo_master')
    &laststatus = start_screen ? 0 : 2
  endif
  &showtabline = start_screen || exists('t:goyo_master') ? 0 : 2
  winrestview(view)
  execute 'redrawtabline'
enddef

export def ScheduleRefresh()
  timer_start(0, (_) => Refresh())
enddef

def Context(): list<string>
  var project = fnamemodify(getcwd(), ':t')
  if empty(project)
    return ['', '']
  endif
  var icon = icons.Get('folder_open')
  return [' ' .. (empty(icon) ? '' : icon .. ' ') .. project .. ' ',
    statusline.GitBranch()]
enddef

export def Render(): string
  var segments = []
  var active = -1
  for buffer in getbufinfo({buflisted: 1})
    if getbufvar(buffer.bufnr, '&buftype') !=# ''
      continue
    endif
    var name = fnamemodify(buffer.name, ':t')
    name = empty(name) ? '[No Name]' : name
    name = text.Truncate(name, 28)
    var icon = icons.FileIcon(buffer.name)
    var changed = get(buffer, 'changed', 0) ? ' ' .. icons.Get('modified') : ''
    var number = buffer.bufnr .. ' '
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

  var anchor = active >= 0 ? active : 0
  var left = anchor
  var right = anchor
  var [project, branch] = Context()
  if strwidth(project .. branch) * 3 > &columns
    [project, branch] = ['', '']
  endif
  var room = &columns - strwidth(project .. branch)
  var show_overflow = room >= 16
  var budget = max([1, room - (show_overflow ? 10 : 0)])
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
  if hint_width >= room
    show_overflow = false
    left_hint = ''
    right_hint = ''
    left = anchor
    right = anchor
    segments[anchor].text =
      text.Truncate(segments[anchor].text, max([1, room]))
  elseif used + hint_width > room
    left = anchor
    right = anchor
    left_hint = anchor > 0 ? ' ‹' .. anchor .. ' ' : ''
    right_hint = anchor + 1 < len(segments)
      ? ' ' .. (len(segments) - anchor - 1) .. '› ' : ''
    hint_width = strwidth(left_hint) + strwidth(right_hint)
    segments[anchor].text = text.Truncate(segments[anchor].text,
      max([1, room - hint_width]))
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
    .. (empty(project) ? ''
      : '%#ChopStatusMuted#' .. substitute(project, '%', '%%', 'g'))
    .. (empty(branch) ? '' : '%#ChopStatusGit#' .. branch)
enddef
