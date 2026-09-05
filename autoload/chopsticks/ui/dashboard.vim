vim9script

# Deliberately not here: the VimEnter decision about whether a start should
# land on a dashboard at all. That lives in startup.vim, so a start that opens
# a file never sources this file.

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

# Availability, not only density: the grep entry needs fzf.vim's :Rg plus both
# binaries, and the session entry needs a session file for this project.
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
  # g:, not a bare name: a bare name is the script-local one, so the guard
  # would be false forever and the entry would silently never appear.
  if !exists('*g:ChopsticksSessionPath')
      || !filereadable(g:ChopsticksSessionPath())
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
  # Normally a no-op; covers a dashboard rendered before VimEnter fires.
  startup.CaptureMs()
  var density = g:ChopsticksUiDensity()
  if density ==# 'minimal'
    return 'SPC ? keys  ·  SPC h health'
  elseif density ==# 'balanced'
    return printf('%s ready in %.2fms  ·  SPC ? keys  ·  SPC h health',
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
  # :execute, because the guard alone is not enough: Vim9 resolves an option
  # name at :def-compile time too, so naming one this Vim lacks fails the whole
  # module with E113 before the guard runs. 'winhighlight' is missing from
  # older builds, which is why this surfaced on CI and not locally.
  if exists('+winhighlight')
    execute 'setlocal winhighlight=CursorLine:ChopDashboardCurrent'
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

# The unmap loop walks the full ITEMS list, not the filtered one, so a key that
# existed at the previous density is cleared at this one.
#
# <ScriptCmd> because <SID> in a mapping cannot reach a Vim9 module's
# script-local functions. It also leaves @: alone and fires no
# CmdlineEnter/CmdlineLeave.
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
  setline(1, lines)
  if line('$') > len(lines)
    deletebufline('%', len(lines) + 1, '$')
  endif
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
