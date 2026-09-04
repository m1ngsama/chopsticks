vim9script

# The statusline, and the UI density that decides how much of it is shown.
#
# 'statusline' is set to '%!ChopsticksStatusline()', so Render() runs on
# every redraw of every window. Everything here is written to be cheap and to
# never throw: a statusline that errors makes Vim unusable, not just ugly,
# so each segment checks for its plugin before asking it anything.
#
# .vimrc keeps one-line wrappers for the Chopsticks* globals this module
# backs, rather than plugin/chopsticks.vim declaring them, because
# 'statusline' and 'tabline' can be evaluated during .vimrc's own execution —
# a redraw forces it — which is before Vim's plugin-loading pass has run. See
# plugin/chopsticks.vim's header.

import autoload 'chopsticks/ui/icons.vim'
import autoload 'chopsticks/ui/bufferline.vim'
import autoload 'chopsticks/ui/dashboard.vim'

# The three density steps, most to least detailed. A density is never trusted
# from the user without being checked against this list.
const DENSITIES = ['minimal', 'balanced', 'rich']

export def UiDensity(): string
  var value = type(g:chopsticks_ui_density) == type('')
    ? tolower(g:chopsticks_ui_density) : ''
  return index(DENSITIES, value) >= 0 ? value : 'balanced'
enddef

# This and bufferline.vim import each other. That is fine: `import autoload`
# binds lazily, so a mutual pair resolves at call time rather than at source
# time (verified on Vim 9.2 with a minimal a/b pair). The dashboard import is
# lazy for the same reason — it is only reached when a dashboard is on
# screen, so declaring it here does not source it on an ordinary start.
export def SetUiDensity(value: string)
  if empty(value)
    var current = index(DENSITIES, UiDensity())
    g:chopsticks_ui_density = DENSITIES[(current + 1) % len(DENSITIES)]
  elseif index(DENSITIES, tolower(value)) >= 0
    g:chopsticks_ui_density = tolower(value)
  else
    echohl WarningMsg
    echomsg 'chopsticks: density must be minimal, balanced, or rich'
    echohl None
    return
  endif
  bufferline.Refresh()
  if &filetype ==# 'chopsticks-dashboard'
    dashboard.Render()
  endif
  redrawstatus!
  echo 'UI density: ' .. UiDensity()
enddef

def Mode(active: number = 1): list<string>
  if !active
    return [' - ', 'ChopStatusMuted']
  endif
  var current = mode(1)
  if current =~# '^i'
    return [' I ', 'ChopStatusInsert']
  elseif current =~# '^[vV\x16]'
    return [' V ', 'ChopStatusVisual']
  elseif current =~# '^R'
    return [' R ', 'ChopStatusReplace']
  elseif current =~# '^[c!t]'
    return [toupper(' ' .. current[0] .. ' '), 'ChopStatusCommand']
  endif
  return [' N ', 'ChopStatusNormal']
enddef

# FugitiveHead() is reached through call() rather than named directly, and
# that is not style. Vim9 compiles a plain function name at :def-compile
# time, so naming an optional plugin's function makes this whole module fail
# to compile on a machine where the plugin is absent -- the exists() guard
# above never gets a chance to run, because compilation happens first. An
# autoload-style name (ale#statusline#Count, gitgutter#hunk#summary) is
# exempt: Vim assumes those resolve later, which is why they appear
# literally below. call() defers the lookup to run time for the rest.
def GitBranch(buffer: number = -1): string
  if !exists('*FugitiveHead')
    return ''
  endif
  var target = buffer < 0 ? bufnr('') : buffer
  var branch = call('FugitiveHead', [0, target])
  return empty(branch) ? '' : '  ' .. icons.Get('git_branch') .. ' '
    .. substitute(branch, '%', '%%', 'g') .. ' '
enddef

# The `buffer < 0` default reproduces the legacy `a:0 ? a:1 : bufnr('')`
# for every argument these are actually called with, including an explicit
# 0. It differs only for an explicit NEGATIVE buffer number, which the
# legacy form would have passed through to getbufvar() and this treats as
# "not given". No caller passes one; buffer numbers come from getwininfo()
# and getbufinfo().
export def GitDiff(buffer: number = -1): string
  if !exists('*GitGutterGetHunkSummary')
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

export def WritingMode(buffer: number = -1, window: number = -1): string
  var target = buffer < 0 ? bufnr('') : buffer
  var window_id = window < 0 ? win_getid() : window
  var window_number = win_id2win(window_id)
  var parts = []
  if window_number > 0 && getwinvar(window_number, '&spell')
    add(parts, icons.Get('spell'))
  endif
  # getbufvar() returns `any`, and a Vim9 comparison against a Number
  # raises E1030 if a plugin ever sets this to a String. Pencil sets a
  # Number today; str2nr() keeps that from mattering.
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

# Which window this evaluation is for. Vim sets g:statusline_winid while
# drawing an inactive window's statusline, which is how one function can
# render every window's line differently.
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
    # Number, not bool. Vim9 comparisons produce bool where legacy script
    # produced 0 or 1, and Mode() below takes a number, so without the
    # coercion this is E1013 at the call in Render().
    active: window == win_getid() ? 1 : 0,
  }
enddef

# A narrow window steps the density down regardless of the configured value,
# so a split never renders a statusline wider than its own window.
def EffectiveDensity(width: number): string
  var density = UiDensity()
  if width < 70
    return 'minimal'
  elseif density ==# 'rich' && width < 110
    return 'balanced'
  endif
  return density
enddef

export def Render(): string
  var context = Context()
  var [label, group] = Mode(context.active)
  var density = EffectiveDensity(context.width)
  var line = '%#' .. group .. '#' .. label
  line ..= '%#ChopStatusBody# '
    .. (density ==# 'rich' ? icons.FileIcon(bufname(context.bufnr)) : '')
    .. '%<%f '
  line ..= '%#ChopStatusAccent#' .. BufferFlags(context.bufnr)
  if density !=# 'minimal'
    line ..= WritingMode(context.bufnr, context.winid)
  endif
  line ..= '%#ChopStatusBody#%='
  line ..= Diagnostics(context.bufnr)
  if density ==# 'rich'
    line ..= GitDiff(context.bufnr)
  endif
  if density !=# 'minimal'
    line ..= '%#ChopStatusGit#' .. GitBranch(context.bufnr)
  endif
  line ..= '%#ChopStatusMuted# '
  if density ==# 'rich'
    line ..= '%y  '
  endif
  line ..= '%l:%c'
  if density !=# 'minimal'
    line ..= '  %P'
  endif
  line ..= ' '
  return line
enddef
