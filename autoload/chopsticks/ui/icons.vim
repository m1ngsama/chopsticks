vim9script

# Nerd Font icon lookup, backing ChopsticksIcon() and ChopsticksIconsEnabled()
# (documented public globals, see plugin/chopsticks.vim), the
# :ChopsticksIconsToggle command, and every consumer of the icon dictionary:
# the dashboard, statusline, tabline, ALE's sign definitions, and Fern.
#
# .vimrc calls Enabled(), Get(), and Group() through Vim's classic dotted
# autoload name (chopsticks#ui#icons#Enabled(), etc.), almost everywhere it
# needs an icon -- fern/ALE setup, which-key group labels, the
# statusline/tabline/dashboard functions, fzf option builders -- rather than
# through the g:ChopsticksIcon() / g:ChopsticksIconsEnabled() shim
# plugin/chopsticks.vim declares for the same functions. Several of those
# call sites run at .vimrc's own script top level (some behind an immediate
# `redrawstatus!`/`redrawtabline`, which forces the statusline/tabline
# functions to evaluate right there), well before Vim's automatic
# plugin-loading pass sources plugin/chopsticks.vim and defines that shim;
# calling it there would fail with E117. The classic dotted name resolves
# against 'runtimepath' the moment it is referenced and needs no shim, and
# works just as correctly at the handful of call sites that really are safely
# deferred, so .vimrc uses it uniformly instead of having to prove which case
# applies at each call site; see .vimrc's own comment next to
# s:WhichKeyGroup(), and plugin/chopsticks.vim's comment on why sourcing that
# shim early is not a usable fix. One consequence: because .vimrc's own top
# level calls these almost immediately, this module loads (on first call)
# very early in every startup, unlike clipboard.vim/session.vim/health.vim,
# which stay unloaded until the user takes an action that needs them -- the
# classic dotted name is just as lazy, it is only reached this early by
# necessity, not by accident. tests/ui.vim and health.vim are the only
# callers that go through the g:ChopsticksIcon() / g:ChopsticksIconsEnabled()
# shim, since both only ever run once Vim has fully started.
#
# Apply() only re-applies the fern/ALE icon variables above. A live icon
# toggle also has to refresh things that are not icon concerns at all: fzf's
# gfiles options, the statusline's file-icon cache, a dashboard re-render,
# and the status/tabline redraw. Those stay in .vimrc, since Vim9
# script-local names cannot cross files and none of that logic belongs here.
# Toggle() fires a guarded `User ChopsticksIconsToggled` autocommand after
# applying so .vimrc can still run that refresh, in the same order it always
# has, without plugin/chopsticks.vim needing a second global just for it.

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

# Per-path filetype glyph, for the statusline and the buffer tabline.
#
# Cached because both surfaces ask for the same handful of paths on every
# redraw, and nerdfont#find() is a pattern walk. The cache is cleared by
# Apply() below, so an icon-mode change cannot leave stale glyphs behind;
# nothing outside this module has to remember to do that.
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
