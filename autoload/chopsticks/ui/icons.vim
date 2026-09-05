vim9script

# .vimrc reaches this module by dotted name from its own top level, so it loads
# early in every startup rather than on a user action.
#
# A live icon toggle also has to refresh things that are not icon concerns --
# fzf's gfiles options, the dashboard, the status and tab lines -- which stay in
# .vimrc because they are script-local there. Toggle() fires a guarded
# `User ChopsticksIconsToggled` so .vimrc can run that refresh in its old order.

var auto_enabled = &encoding ==# 'utf-8'
  && empty($SSH_CONNECTION) && empty($SSH_CLIENT) && empty($SSH_TTY)
  && $TERM !=# 'dumb'
  && (index(['iTerm.app', 'WezTerm', 'vscode'], $TERM_PROGRAM) >= 0
    || !empty($KITTY_WINDOW_ID) || !empty($WEZTERM_PANE)
    || !empty($WT_SESSION) || !empty($GHOSTTY_RESOURCES_DIR)
    || $TERM =~# '\<\%(xterm-kitty\|xterm-ghostty\|wezterm\)\>')
  ? 1 : 0

var glyphs = {
  'search': ['', '?'],
  'new_file': ['', '+'],
  'grep': ['', '/'],
  'recent': ['', '~'],
  'config': ['', '#'],
  'session': ['', '@'],
  'quit': ['', 'q'],
  'file': ['', '-'],
  'folder_open': ['', ''],
  'git_branch': ['', 'git:'],
  'git_add': ['', '+'],
  'git_change': ['', '~'],
  'git_delete': ['', '-'],
  'error': ['', 'E'],
  'warning': ['', 'W'],
  'info': ['', 'I'],
  'modified': ['●', '+'],
  'readonly': ['', 'RO'],
  'spell': ['󰓆', 'SPELL'],
  'wrap': ['󰖶', 'WRAP'],
  'startup': ['', '*'],
  'pointer': ['', '>'],
  'marker': ['', '*'],
  'group_home': ['', ''],
  'group_find': ['', ''],
  'group_buffer': ['󰓩', ''],
  'group_window': ['', ''],
  'group_file': ['󰈔', ''],
  'group_git': ['', ''],
  'group_code': ['', ''],
  'group_check': ['󰒡', ''],
  'group_run': ['', ''],
  'group_term': ['', ''],
  'group_toggle': ['', ''],
  'group_edit': ['', ''],
  'group_nav': ['', ''],
  'group_markdown': ['', ''],
  'group_table': ['', ''],
  'group_quit': ['', ''],
  }
var group_glyphs = {
  'Essentials': 'group_home', 'Fast find': 'group_find',
  'Buffers': 'group_buffer', 'Windows': 'group_window',
  'Files': 'group_file', 'Search': 'group_find', 'Quit': 'group_quit',
  'Git': 'group_git', 'Code': 'group_code',
  'Diagnostics': 'group_check', 'Run': 'group_run',
  'Terminal': 'group_term', 'Tabs': 'group_buffer',
  'Toggles': 'group_toggle', 'Editing': 'group_edit',
  'Navigation': 'group_nav', 'Markdown': 'group_markdown',
  'Table': 'group_table',
  }

export def Enabled(): number
  if type(g:chopsticks_icons) == v:t_number
    return g:chopsticks_icons != 0 ? 1 : 0
  elseif type(g:chopsticks_icons) == v:t_bool
    return g:chopsticks_icons ? 1 : 0
  elseif type(g:chopsticks_icons) == v:t_string
    var value = tolower(g:chopsticks_icons)
    if index(['0', 'off', 'false', 'ascii'], value) >= 0
      return 0
    elseif index(['1', 'on', 'true', 'nerd'], value) >= 0
      return 1
    endif
  endif
  return auto_enabled
enddef

export def Get(name: string): string
  var icon = get(glyphs, name, ['', ''])
  return icon[Enabled() ? 0 : 1]
enddef

export def Group(group: string): string
  return Get(get(group_glyphs, group, ''))
enddef

# The statusline and tabline ask for the same handful of paths on every redraw
# and nerdfont#find() is a pattern walk. Apply() clears this, so an icon-mode
# change cannot leave stale glyphs behind.
var file_icon_cache = {}

export def FileIcon(path: string): string
  if !Enabled()
    return ''
  endif
  var key = empty(path) ? '[No Name]' : path
  if !has_key(file_icon_cache, key)
    if empty(globpath(&runtimepath, 'autoload/nerdfont.vim'))
      file_icon_cache[key] = Get('file')
    else
      try
        file_icon_cache[key] = nerdfont#find(key, isdirectory(key))
      catch
        file_icon_cache[key] = Get('file')
      endtry
    endif
  endif
  var icon = file_icon_cache[key]
  return empty(icon) ? '' : icon .. ' '
enddef

export def Apply(): void
  file_icon_cache = {}
  g:fern#renderer = Enabled() ? 'nerdfont' : 'default'
  g:fern#renderer#nerdfont#root_symbol = Get('folder_open')
  g:fern#mark_symbol = Get('marker')
  g:ale_sign_error = Get('error')
  g:ale_sign_warning = Get('warning')
  g:ale_sign_info = Get('info')
enddef

export def Toggle(): void
  g:chopsticks_icons = Enabled() ? 0 : 1
  Apply()
  if exists('#User#ChopsticksIconsToggled')
    doautocmd User ChopsticksIconsToggled
  endif
  echo 'icons: ' .. (Enabled() ? 'Nerd Font' : 'ASCII')
    .. ' (restart Vim to refresh Fern and key groups)'
enddef
