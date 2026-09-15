vim9script

import autoload 'chopsticks/ui/icons.vim'

const MODE_NAMES = {c: 'COMMAND', '!': 'SHELL', t: 'TERMINAL'}

def Mode(active: number = 1, wide: bool = false): list<string>
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

export def GitBranch(buffer: number = -1): string
  if !exists('*g:FugitiveHead')
    return ''
  endif
  var target = buffer < 0 ? bufnr('') : buffer
  var branch = call('FugitiveHead', [0, target])
  return empty(branch) ? '' : '  ' .. icons.Get('git_branch') .. ' '
    .. substitute(branch, '%', '%%', 'g') .. ' '
enddef

export def GitDiff(buffer: number = -1): string
  if !exists('*g:GitGutterGetHunkSummary')
    return ''
  endif
  var target = buffer < 0 ? bufnr('') : buffer
  var [added, changed, removed] = gitgutter#hunk#summary(target)
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

export def Diagnostics(buffer: number = -1): string
  if !exists('*ale#statusline#Count')
    return ''
  endif
  var target = buffer < 0 ? bufnr('') : buffer
  var counts = ale#statusline#Count(target)
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

export def Signals(buffer: number = -1): string
  var target = buffer < 0 ? bufnr('') : buffer
  var parts = []
  var encoding = getbufvar(target, '&fileencoding')
  if !empty(encoding) && encoding !=? 'utf-8'
    add(parts, encoding)
  endif
  var format = getbufvar(target, '&fileformat')
  if format !=# 'unix'
    add(parts, format ==# 'dos' ? 'CRLF' : 'CR')
  endif
  var width = getbufvar(target, '&shiftwidth')
  if !getbufvar(target, '&expandtab')
    add(parts, 'tab-' .. width)
  elseif width != 4
    add(parts, 'sp-' .. width)
  endif
  return empty(parts) ? '' : ' ' .. join(parts, ' ') .. ' '
enddef

export def WordCount(active: number = 1): string
  if !active || &filetype !=# 'markdown'
    return ''
  endif
  var counted = wordcount()
  return counted->has_key('visual_words')
    ? printf(' %s %d/%d ', icons.Get('words'),
        counted.visual_words, counted.words)
    : printf(' %s %d ', icons.Get('words'), counted.words)
enddef

export def WritingMode(buffer: number = -1, window: number = -1): string
  var target = buffer < 0 ? bufnr('') : buffer
  var window_id = window < 0 ? win_getid() : window
  var window_number = win_id2win(window_id)
  var parts = []
  if window_number > 0 && getwinvar(window_number, '&spell')
    add(parts, icons.Get('spell'))
  endif
  var pencil = str2nr(string(getbufvar(target, 'pencil_wrap_mode', 0)))
  if pencil == 2
    add(parts, icons.Get('wrap') .. ':'
      .. get(get(g:, 'pencil#mode_indicators', {}), 'soft', 'S'))
  elseif pencil == 1
    var kind = getbufvar(target, '&formatoptions') =~# 'a' ? 'auto' : 'hard'
    add(parts, icons.Get('wrap') .. ':'
      .. get(get(g:, 'pencil#mode_indicators', {}), kind,
             kind ==# 'auto' ? 'A' : 'H'))
  endif
  return empty(parts) ? '' : ' ' .. join(parts, ' ') .. ' '
enddef

def BufferFlags(buffer: number = -1): string
  var target = buffer < 0 ? bufnr('') : buffer
  var parts = []
  if getbufvar(target, '&modified')
    add(parts, icons.Get('modified'))
  endif
  if getbufvar(target, '&readonly')
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
  line ..= '%#ChopStatusBody# '
    .. (density ==# 'rich' ? icons.FileIcon(bufname(context.bufnr)) : '')
    .. '%<%f '
  line ..= '%#ChopStatusAccent#' .. BufferFlags(context.bufnr)
  if density !=# 'minimal'
    var writing = WritingMode(context.bufnr, context.winid)
    line ..= empty(writing) ? '' : '%#ChopStatusMuted#' .. writing
  endif
  line ..= '%#ChopStatusBody#%='
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
