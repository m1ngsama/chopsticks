vim9script

# The startup dashboard: the buffer Vim opens when it starts with no file
# argument. Rendering, cursor locking, and the item actions all live here.
#
# Entry points, and who calls them:
#   Open()       :ChopsticksDashboard, and chopsticks#startup#MaybeOpenDashboard()
#   Render()     .vimrc, on an icon/theme/density change and on BufEnter
#   Enter()      .vimrc, on BufEnter into a dashboard buffer
#   Leave()      .vimrc, on BufLeave out of one
#   LockCursor() .vimrc, on CursorMoved and FocusGained
#
# .vimrc reaches all of those by the classic dotted name
# (chopsticks#ui#dashboard#Render()), the same as every other module; see
# plugin/chopsticks.vim's header for why that is the rule everywhere rather
# than a special case here.
#
# What is NOT here, deliberately: the VimEnter decision about whether this
# start should land on a dashboard at all. That lives in
# autoload/chopsticks/startup.vim, so that a start which opens a file never
# sources this file. See that module's own comment.
#
# This module depends on .vimrc for two values it does not own —
# g:ChopsticksUiDensity() and g:ChopsticksDashboardEnabled() — and on
# plugin/chopsticks.vim for g:ChopsticksProjectRoot() and
# g:ChopsticksSessionPath().

import autoload 'chopsticks/ui/text.vim'
import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/startup.vim'

const LOGO = [
  '███╗   ███╗ ██╗███╗   ██╗ ██████╗ ███████╗ █████╗ ███╗   ███╗ █████╗',
  '████╗ ████║███║████╗  ██║██╔════╝ ██╔════╝██╔══██╗████╗ ████║██╔══██╗',
  '██╔████╔██║╚██║██╔██╗ ██║██║  ███╗███████╗███████║██╔████╔██║███████║',
  '██║╚██╔╝██║ ██║██║╚██╗██║██║   ██║╚════██║██╔══██║██║╚██╔╝██║██╔══██║',
  '██║ ╚═╝ ██║ ██║██║ ╚████║╚██████╔╝███████║██║  ██║██║ ╚═╝ ██║██║  ██║',
  '╚═╝     ╚═╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝',
]

const COMPACT_LOGO = [
  '╭────────────────────────────────╮',
  '│           CHOPSTICKS           │',
  '╰────────────────────────────────╯',
]

const ITEMS = [
  {key: 'f', icon: 'search', label: 'Find File', action: 'ChopsticksFindFiles'},
  {key: 'n', icon: 'new_file', label: 'New File', action: 'enew | startinsert'},
  {key: 'g', icon: 'grep', label: 'Find Text', action: 'ChopsticksProjectGrep'},
  {key: 'r', icon: 'recent', label: 'Recent Files', action: 'ChopsticksRecentFiles'},
  {key: 'c', icon: 'config', label: 'Config', action: 'edit $MYVIMRC'},
  {key: 's', icon: 'session', label: 'Restore Session', action: 'ChopsticksSessionLoad'},
  {key: 'q', icon: 'quit', label: 'Quit', action: 'qall'},
]

# The item list depends on what is actually available, not only on density:
# the grep entry needs fzf.vim's :Rg plus both binaries, and the session entry
# needs a session file that already exists for this project.
#
# The legacy version took an optional argument and branched on arity; this
# branches on emptiness instead. No caller passes an empty density —
# g:ChopsticksUiDensity() only ever returns minimal, balanced, or rich — so
# the two agree today, but they are not the same contract. Pass a real
# density or nothing.
def Items(requested_density: string = ''): list<dict<string>>
  var density = empty(requested_density)
    ? g:ChopsticksUiDensity() : requested_density
  var keys = density ==# 'minimal'
    ? ['f', 'n', 'r', 'c', 'q']
    : ['f', 'n', 'g', 'r', 'c', 's', 'q']
  var items = filter(copy(ITEMS), (_, item) => index(keys, item.key) >= 0)
  if exists(':Rg') != 2 || executable('rg') != 1 || executable('fzf') != 1
    filter(items, (_, item) => item.key !=# 'g')
  endif
  if !exists('*ChopsticksSessionPath') || !filereadable(g:ChopsticksSessionPath())
    filter(items, (_, item) => item.key !=# 's')
  endif
  return items
enddef

def Center(text_value: string): string
  return repeat(' ', max([0, (winwidth(0) - strwidth(text_value)) / 2]))
    .. text_value
enddef

def LogoLine(text_value: string, block_width: number): string
  var left = max([0, (winwidth(0) - block_width) / 2])
  return repeat(' ', left) .. text_value
enddef

def PluginStats(): list<number>
  var plugs = get(g:, 'plugs', {})
  var runtime = mapnew(split(&runtimepath, ','),
    (_, entry) => resolve(fnamemodify(entry, ':p')))
  var loaded = 0
  for plug in values(plugs)
    if index(runtime, resolve(fnamemodify(plug.dir, ':p'))) >= 0
      loaded += 1
    endif
  endfor
  return [loaded, len(plugs)]
enddef

def Footer(): string
  # Idempotent, and normally a no-op: .vimrc's VimEnter autocommand has
  # already taken the measurement. This covers a dashboard rendered before
  # VimEnter fires.
  startup.CaptureMs()
  var density = g:ChopsticksUiDensity()
  if density ==# 'minimal'
    return '? keys  ·  h health'
  elseif density ==# 'balanced'
    return printf('%s ready in %.2fms  ·  ? keys  ·  h health',
      icons.Get('startup'), g:chopsticks_startup_ms)
  endif
  var [loaded, total] = PluginStats()
  return total > 0
    ? printf('%s Vim loaded %d/%d plugins in %.2fms',
        icons.Get('startup'), loaded, total, g:chopsticks_startup_ms)
    : printf('%s Vim ready in %.2fms',
        icons.Get('startup'), g:chopsticks_startup_ms)
enddef

export def Enter()
  if !exists('b:chopsticks_dashboard_showtabline')
    b:chopsticks_dashboard_showtabline = &showtabline
  endif
  if !exists('b:chopsticks_dashboard_laststatus')
    b:chopsticks_dashboard_laststatus = &laststatus
  endif
  set showtabline=0 laststatus=0
  setlocal nonumber norelativenumber nolist cursorline signcolumn=no
  setlocal nowrap nospell foldcolumn=0 colorcolumn= tabstop=2
  if exists('+winhighlight')
    &l:winhighlight = 'CursorLine:ChopDashboardCurrent'
  endif
  &l:statusline = '%#ChopDashboardStatus#%='
enddef

export def Leave()
  if exists('b:chopsticks_dashboard_showtabline')
    &showtabline = b:chopsticks_dashboard_showtabline
    unlet b:chopsticks_dashboard_showtabline
  endif
  if exists('b:chopsticks_dashboard_laststatus')
    &laststatus = b:chopsticks_dashboard_laststatus
    unlet b:chopsticks_dashboard_laststatus
  endif
enddef

# Clear every item key this buffer might still hold from a previous render at
# a different density, then map only the keys the current item list uses.
# The unmap loop walks the full ITEMS list, not the filtered one, precisely
# so a key that existed at the previous density is removed at this one.
#
# The right-hand sides use <ScriptCmd> where the legacy version used
# `:call <SID>Name()<CR>`. <SID> cannot reach a Vim9 module's script-local
# functions from a mapping, and <ScriptCmd> runs in the defining script's
# context, which is what makes these private functions reachable at all. It
# also does not enter command-line mode, so unlike the legacy form it leaves
# @: alone and fires no CmdlineEnter/CmdlineLeave — a small, deliberate
# improvement rather than an accident.
def MapItems(items: list<dict<string>>)
  for item in ITEMS
    var mapping = maparg(item.key, 'n', 0, 1)
    if !empty(mapping) && get(mapping, 'buffer', 0)
      execute 'nunmap <buffer> ' .. item.key
    endif
  endfor
  for item in items
    execute 'nnoremap <silent><nowait><buffer> ' .. item.key
      .. ' <ScriptCmd>Run(' .. string(item.key) .. ')<CR>'
  endfor
enddef

export def Render()
  if &filetype !=# 'chopsticks-dashboard'
    return
  endif
  var width = winwidth(0)
  var height = winheight(0) + &cmdheight
  var density = g:ChopsticksUiDensity()
  if height < 16 || width < 34
    density = 'minimal'
  elseif density ==# 'rich' && (height < 24 || width < 80)
    density = 'balanced'
  endif
  var items = Items(density)
  var full_logo = density ==# 'rich' && width >= 100 && height >= 24
  var logo = full_logo ? LOGO
    : width >= 38 && height >= 12 ? COMPACT_LOGO
    : [text.Truncate('CHOPSTICKS', max([1, width - 2]))]
  var logo_width = max(mapnew(logo, (_, line) => strwidth(line)))
  var gap = density ==# 'rich' && height >= 32 ? 1 : 0
  var target_width = density ==# 'rich' ? 60
    : density ==# 'balanced' ? 48 : 40
  var dashboard_width = min([target_width, max([1, width - 2])])
  var header_gap = density ==# 'rich' ? 3 : 1
  var content_height = len(logo) + header_gap + len(items)
    + (len(items) - 1) * gap + 2
  var top = max([1, (height - content_height) / 2])
  var lines = repeat([''], top)
  var logo_matches: list<list<number>> = []
  var item_matches: list<list<number>> = []
  var icon_matches: list<list<number>> = []
  var key_matches: list<list<number>> = []
  var item_lines: list<number> = []
  var desc_cols: dict<number> = {}
  var actions: dict<string> = {}

  for logo_text in logo
    var line = LogoLine(logo_text, logo_width)
    add(lines, line)
    var column = match(line, '\S') + 1
    add(logo_matches, [len(lines), column, strlen(logo_text)])
  endfor
  extend(lines, repeat([''], header_gap))

  for index in range(len(items))
    var item = items[index]
    var icon = width < 20 ? '' : icons.Get(item.icon)
    var key_text = width < 20 ? item.key : '[' .. item.key .. ']'
    var body = ''
    var key_offset = 0
    var cursor_offset = 0
    if width < 20
      body = key_text
      if dashboard_width >= strwidth(item.key) + 2
        body ..= ' ' .. text.Truncate(item.label,
          dashboard_width - strwidth(item.key) - 1)
      endif
    else
      var label_width = max([1, dashboard_width
        - strwidth(icon) - strwidth(key_text) - 4])
      var label = text.Truncate(item.label, label_width)
      body = icon .. '  ' .. label
      body ..= repeat(' ', max([1, dashboard_width
        - strwidth(body) - strwidth(key_text)]))
      body ..= key_text
      key_offset = strlen(body) - strlen(key_text)
      cursor_offset = key_offset + 1
    endif
    var line = Center(body)
    add(lines, line)
    var line_number = len(lines)
    var column = strlen(matchstr(line, '^ *')) + 1
    add(item_matches, [line_number, column, strlen(body)])
    if !empty(icon)
      add(icon_matches, [line_number, column, strlen(icon)])
    endif
    add(key_matches, [line_number, column + key_offset, strlen(key_text)])
    add(item_lines, line_number)
    desc_cols[string(line_number)] = column + cursor_offset
    actions[string(line_number)] = item.key
    if gap && index + 1 < len(items)
      add(lines, '')
    endif
  endfor

  add(lines, '')
  var footer = text.Truncate(Footer(), max([1, width - 2]))
  var footer_line = Center(footer)
  add(lines, footer_line)
  var footer_column = strlen(matchstr(footer_line, '^ *')) + 1

  setlocal modifiable
  silent keepjumps :%delete _
  setline(1, lines)
  setlocal nomodified nomodifiable
  clearmatches()
  matchaddpos('ChopDashboardLogo', logo_matches, 10)
  matchaddpos('ChopDashboardItem', item_matches, 10)
  if !empty(icon_matches)
    matchaddpos('ChopDashboardIcon', icon_matches, 20)
  endif
  matchaddpos('ChopDashboardKey', key_matches, 20)
  matchaddpos('ChopDashboardFooter',
    [[len(lines), footer_column, strlen(footer)]], 10)
  b:chopsticks_dashboard_item_lines = item_lines
  b:chopsticks_dashboard_desc_cols = desc_cols
  b:chopsticks_dashboard_actions = actions
  MapItems(items)
  cursor(item_lines[0], desc_cols[string(item_lines[0])])
enddef

def SelectNearest()
  var lines = get(b:, 'chopsticks_dashboard_item_lines', [])
  if empty(lines)
    return
  endif
  var current = line('.')
  var target = lines[0]
  var distance = abs(target - current)
  for candidate in lines[1 : ]
    if abs(candidate - current) < distance
      target = candidate
      distance = abs(candidate - current)
    endif
  endfor
  cursor(target, get(b:chopsticks_dashboard_desc_cols, string(target), 1))
enddef

# The cursor may only rest on an item line, at that item's description
# column, so the highlighted row always matches what <CR> would run.
export def LockCursor()
  if &filetype !=# 'chopsticks-dashboard'
    return
  endif
  var lines = get(b:, 'chopsticks_dashboard_item_lines', [])
  if index(lines, line('.')) < 0
    SelectNearest()
    return
  endif
  var column = get(b:chopsticks_dashboard_desc_cols, string(line('.')), 1)
  if col('.') != column
    cursor(line('.'), column)
  endif
enddef

def Move(delta: number)
  var lines = get(b:, 'chopsticks_dashboard_item_lines', [])
  if empty(lines)
    return
  endif
  var index = index(lines, line('.'))
  if index < 0
    SelectNearest()
    index = index(lines, line('.'))
  endif
  index = (index + delta + len(lines)) % len(lines)
  var target = lines[index]
  cursor(target, get(b:chopsticks_dashboard_desc_cols, string(target), 1))
enddef

def Run(key: string)
  for item in Items()
    if item.key ==# key
      try
        execute item.action
      catch
        echohl ErrorMsg
        echomsg 'Dashboard: ' .. v:exception
        echohl None
      endtry
      return
    endif
  endfor
enddef

def RunCurrent()
  var key = get(get(b:, 'chopsticks_dashboard_actions', {}),
    string(line('.')), '')
  if !empty(key)
    Run(key)
  endif
enddef

export def Open()
  if &filetype !=# 'chopsticks-dashboard'
    var project_root = g:ChopsticksProjectRoot()
    silent keepalt enew
    silent file [chopsticks]
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
    setfiletype chopsticks-dashboard
    b:chopsticks_project_root = project_root
  endif
  Enter()
  nnoremap <silent><buffer> <CR> <ScriptCmd>RunCurrent()<CR>
  nnoremap <silent><buffer> j <ScriptCmd>Move(1)<CR>
  nnoremap <silent><buffer> k <ScriptCmd>Move(-1)<CR>
  nnoremap <silent><buffer> <Down> <ScriptCmd>Move(1)<CR>
  nnoremap <silent><buffer> <Up> <ScriptCmd>Move(-1)<CR>
  nnoremap <silent><buffer> <Tab> <ScriptCmd>Move(1)<CR>
  nnoremap <silent><buffer> <S-Tab> <ScriptCmd>Move(-1)<CR>
  nnoremap <silent><nowait><buffer> ? :ChopsticksCheatsheet<CR>
  nnoremap <silent><nowait><buffer> h :ChopsticksHealth<CR>
  Render()
enddef
