vim9script

import autoload 'chopsticks/ui/icons.vim'

const MODE_NAMES = {c: 'COMMAND', '!': 'SHELL', t: 'TERMINAL'}

def Mode(active: number, wide: bool): list<string>
  if !active
    return [' - ', 'ChopStatusMuted']
  endif
  var current = mode(1)
  var [short, name, group] =
    current =~# '^i' ? ['I', 'INSERT', 'ChopStatusInsert']
    : current =~# '^[vV\x16]' ? ['V', 'VISUAL', 'ChopStatusVisual']
    : current =~# '^R' ? ['R', 'REPLACE', 'ChopStatusReplace']
    : current =~# '^[c!t]' ? [toupper(current[0]),
        MODE_NAMES[current[0]], 'ChopStatusCommand']
    : ['N', 'NORMAL', 'ChopStatusNormal']
  return [' ' .. (wide ? name : short) .. ' ', group]
enddef

export def GitBranch(): string
  if !exists('*g:FugitiveHead')
    return ''
  endif
  var branch = call('FugitiveHead', [0, bufnr('')])
  return empty(branch) ? '' : '  ' .. icons.Get('git_branch') .. ' '
    .. substitute(branch, '%', '%%', 'g') .. ' '
enddef

def GitDiff(buffer: number): string
  if !exists('*g:GitGutterGetHunkSummary')
    return ''
  endif
  var [added, changed, removed] = gitgutter#hunk#summary(buffer)
  var parts = []
  if added > 0
    add(parts, printf('%%#ChopStatusGitAdd#%s %d', icons.Get('git_add'), added))
  endif
  if changed > 0
    add(parts, printf('%%#ChopStatusGitChange#%s %d',
      icons.Get('git_change'), changed))
  endif
  if removed > 0
    add(parts, printf('%%#ChopStatusGitDelete#%s %d',
      icons.Get('git_delete'), removed))
  endif
  return empty(parts) ? '' : ' ' .. join(parts, ' ') .. ' '
enddef

def Diagnostics(buffer: number): string
  if !exists('*ale#statusline#Count')
    return ''
  endif
  var counts = ale#statusline#Count(buffer)
  var errors = counts.error + counts.style_error
  var warnings = counts.warning + counts.style_warning
  var info = get(counts, 'info', 0)
  var parts = []
  if errors > 0
    add(parts, printf('%%#ChopStatusError# %s %d', icons.Get('error'), errors))
  endif
  if warnings > 0
    add(parts, printf('%%#ChopStatusWarning# %s %d',
      icons.Get('warning'), warnings))
  endif
  if info > 0
    add(parts, printf('%%#ChopStatusInfo# %s %d', icons.Get('info'), info))
  endif
  return empty(parts) ? '' : join(parts, ' ') .. ' '
enddef

def Signals(buffer: number): string
  var parts = []
  var encoding = getbufvar(buffer, '&fileencoding')
  if !empty(encoding) && encoding !=? 'utf-8'
    add(parts, encoding)
  endif
  var format = getbufvar(buffer, '&fileformat')
  if format !=# 'unix'
    add(parts, format ==# 'dos' ? 'CRLF' : 'CR')
  endif
  var width = getbufvar(buffer, '&shiftwidth')
  if !getbufvar(buffer, '&expandtab')
    add(parts, 'tab-' .. width)
  elseif width != 4
    add(parts, 'sp-' .. width)
  endif
  return empty(parts) ? '' : ' ' .. join(parts, ' ') .. ' '
enddef

def WordCount(active: number): string
  if !active || &filetype !=# 'markdown'
    return ''
  endif
  var counted = wordcount()
  return counted->has_key('visual_words')
    ? printf(' %s %d/%d ', icons.Get('words'),
        counted.visual_words, counted.words)
    : printf(' %s %d ', icons.Get('words'), counted.words)
enddef

def WritingMode(buffer: number, window: number): string
  var window_number = win_id2win(window)
  var parts = []
  if window_number > 0 && getwinvar(window_number, '&spell')
    add(parts, icons.Get('spell'))
  endif
  var pencil = str2nr(string(getbufvar(buffer, 'pencil_wrap_mode', 0)))
  if pencil == 2
    add(parts, icons.Get('wrap') .. ':'
      .. get(get(g:, 'pencil#mode_indicators', {}), 'soft', 'S'))
  elseif pencil == 1
    var kind = getbufvar(buffer, '&formatoptions') =~# 'a' ? 'auto' : 'hard'
    add(parts, icons.Get('wrap') .. ':'
      .. get(get(g:, 'pencil#mode_indicators', {}), kind,
             kind ==# 'auto' ? 'A' : 'H'))
  endif
  return empty(parts) ? '' : ' ' .. join(parts, ' ') .. ' '
enddef

def SearchCount(): string
  if !v:hlsearch || empty(@/)
    return ''
  endif
  var count = searchcount({maxcount: 999, timeout: 10})
  return get(count, 'total', 0) == 0 ? '' : printf('%%#ChopStatusAccent# %d/%s ', count.current,
    count.incomplete > 0 ? '>' .. count.maxcount : string(count.total))
enddef

def BufferFlags(buffer: number): string
  var parts = []
  if getbufvar(buffer, '&modified')
    add(parts, icons.Get('modified'))
  endif
  if getbufvar(buffer, '&readonly')
    add(parts, icons.Get('readonly'))
  endif
  return empty(parts) ? '' : ' ' .. join(parts, ' ') .. ' '
enddef

def Context(): dict<any>
  var window = get(g:, 'statusline_winid', win_getid())
  var info = getwininfo(window)
  if empty(info)
    window = win_getid()
    info = getwininfo(window)
  endif
  return {
    winid: window,
    bufnr: empty(info) ? bufnr('') : info[0].bufnr,
    width: empty(info) ? winwidth(0) : info[0].width,
    active: window == win_getid() ? 1 : 0,
  }
enddef

def EffectiveDensity(width: number): string
  return width < 70 ? 'minimal' : width < 110 ? 'balanced' : 'rich'
enddef

const KINDS = {fern: 'EXPLORER', netrw: 'EXPLORER', qf: 'QUICKFIX', help: 'HELP'}

def SpecialKind(buffer: number): string
  var buftype = getbufvar(buffer, '&buftype')
  if buftype ==# ''
    return ''
  elseif buftype ==# 'terminal'
    return toupper(fnamemodify(matchstr(bufname(buffer), '^!\zs\S\+'), ':t'))
  endif
  var filetype = getbufvar(buffer, '&filetype')
  return get(KINDS, filetype, toupper(empty(filetype) ? buftype : filetype))
enddef

export def Render(): string
  var context = Context()
  var density = EffectiveDensity(context.width)
  var [label, group] = Mode(context.active, density ==# 'rich')
  var line = '%#' .. group .. '#' .. label
  var kind = SpecialKind(context.bufnr)
  if !empty(kind)
    return line .. '%#ChopStatusBody# ' .. kind .. ' %='
  endif
  line ..= (getbufvar(context.bufnr, 'chopsticks_saved', 0) ? '%#ChopStatusSaved# ' : '%#ChopStatusBody# ')
    .. (density ==# 'rich' ? icons.FileIcon(bufname(context.bufnr)) : '')
    .. '%<%f '
  line ..= '%#ChopStatusAccent#' .. BufferFlags(context.bufnr)
  if density !=# 'minimal'
    var writing = WritingMode(context.bufnr, context.winid)
    line ..= empty(writing) ? '' : '%#ChopStatusMuted#' .. writing
  endif
  line ..= '%#ChopStatusBody#%='
  line ..= context.active ? SearchCount() : ''
  line ..= Diagnostics(context.bufnr)
  if density ==# 'rich'
    line ..= GitDiff(context.bufnr)
    line ..= '%#ChopStatusMuted#' .. Signals(context.bufnr)
      .. WordCount(context.active) .. ' %y '
  endif
  line ..= '%#ChopStatusPosition# %l:%c'
  if density !=# 'minimal'
    line ..= '  %P'
  endif
  line ..= ' '
  return line
enddef
