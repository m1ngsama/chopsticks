vim9script

# .vimrc calls Apply() and DefineInterfaceColors() at its own top level, before
# plugin/chopsticks.vim exists, so it reaches them by dotted name. This module
# therefore loads early in every startup rather than on a user action.
#
# ResolveSwitch duplicates .vimrc's s:ResolveSwitch(): Vim9 script-local names
# cannot cross files, and this is the only piece of it needed here.

def ResolveSwitch(value: any, automatic: number): number
  if type(value) == v:t_number
    return value != 0 ? 1 : 0
  elseif type(value) == v:t_bool
    return value ? 1 : 0
  elseif type(value) == v:t_string
    var lowered = tolower(value)
    if index(['0', 'off', 'false', 'no'], lowered) >= 0
      return 0
    elseif index(['1', 'on', 'true', 'yes'], lowered) >= 0
      return 1
    endif
  endif
  return automatic
enddef

export def TransparencyEnabled(): number
  # Terminals expose color depth, not whether their compositor is
  # transparent.
  return ResolveSwitch(g:chopsticks_transparent_background, 0)
enddef

export def Apply(): void
  var scheme = type(g:chopsticks_colorscheme) == v:t_string
    && !empty(g:chopsticks_colorscheme)
    ? g:chopsticks_colorscheme : 'everforest'
  if scheme ==# 'everforest'
    g:everforest_background = get(g:, 'everforest_background', 'medium')
    g:everforest_better_performance = 1
    g:everforest_transparent_background = TransparencyEnabled()
  endif
  try
    execute 'colorscheme ' .. fnameescape(scheme)
  catch /^Vim\%((\a\+)\)\=:E185/
    colorscheme default
  endtry
enddef

export def HighlightColor(group: string, attribute: string, fallback: string): string
  var id = synIDtrans(hlID(group))
  var value = synIDattr(id, attribute, 'gui')
  return empty(value) || value ==# 'NONE' ? fallback : value
enddef

export def DefineInterfaceColors(): void
  var bg = HighlightColor('Normal', 'bg', '#2d353b')
  var surface = HighlightColor('CursorLine', 'bg', '#343f44')
  var fg = HighlightColor('Normal', 'fg', '#d3c6aa')
  # Everforest names its palette groups; other themes fall back to canonical
  # syntax groups rather than to hard-coded colors.
  var muted = HighlightColor('Grey', 'fg', HighlightColor('Comment', 'fg', '#859289'))
  var red = HighlightColor('Red', 'fg', HighlightColor('ErrorMsg', 'fg', '#e67e80'))
  var orange = HighlightColor('Orange', 'fg', HighlightColor('Special', 'fg', '#e69875'))
  var yellow = HighlightColor('Yellow', 'fg', HighlightColor('WarningMsg', 'fg', '#dbbc7f'))
  var green = HighlightColor('Green', 'fg', HighlightColor('String', 'fg', '#a7c080'))
  var aqua = HighlightColor('Aqua', 'fg', HighlightColor('Identifier', 'fg', '#83c092'))
  var blue = HighlightColor('Blue', 'fg', HighlightColor('Function', 'fg', '#7fbbb3'))
  var purple = HighlightColor('Purple', 'fg', HighlightColor('Statement', 'fg', '#d699b6'))
  execute 'highlight ChopStatusNormal ctermbg=106 ctermfg=234 cterm=bold guibg=' .. green .. ' guifg=' .. bg .. ' gui=bold'
  execute 'highlight ChopStatusInsert ctermbg=109 ctermfg=234 cterm=bold guibg=' .. blue .. ' guifg=' .. bg .. ' gui=bold'
  execute 'highlight ChopStatusVisual ctermbg=175 ctermfg=234 cterm=bold guibg=' .. purple .. ' guifg=' .. bg .. ' gui=bold'
  execute 'highlight ChopStatusReplace ctermbg=174 ctermfg=234 cterm=bold guibg=' .. red .. ' guifg=' .. bg .. ' gui=bold'
  execute 'highlight ChopStatusCommand ctermbg=108 ctermfg=234 cterm=bold guibg=' .. aqua .. ' guifg=' .. bg .. ' gui=bold'
  execute 'highlight ChopStatusBody ctermbg=237 ctermfg=187 cterm=none guibg=' .. surface .. ' guifg=' .. fg .. ' gui=none'
  execute 'highlight ChopStatusAccent ctermbg=237 ctermfg=180 cterm=none guibg=' .. surface .. ' guifg=' .. yellow .. ' gui=none'
  execute 'highlight ChopStatusError ctermbg=237 ctermfg=174 cterm=bold guibg=' .. surface .. ' guifg=' .. red .. ' gui=bold'
  execute 'highlight ChopStatusWarning ctermbg=237 ctermfg=180 cterm=bold guibg=' .. surface .. ' guifg=' .. yellow .. ' gui=bold'
  execute 'highlight ChopStatusInfo ctermbg=237 ctermfg=109 cterm=bold guibg=' .. surface .. ' guifg=' .. blue .. ' gui=bold'
  execute 'highlight ChopStatusGitAdd ctermbg=237 ctermfg=108 cterm=none guibg=' .. surface .. ' guifg=' .. green .. ' gui=none'
  execute 'highlight ChopStatusGitChange ctermbg=237 ctermfg=180 cterm=none guibg=' .. surface .. ' guifg=' .. yellow .. ' gui=none'
  execute 'highlight ChopStatusGitDelete ctermbg=237 ctermfg=174 cterm=none guibg=' .. surface .. ' guifg=' .. red .. ' gui=none'
  execute 'highlight ChopStatusGit ctermbg=237 ctermfg=108 cterm=none guibg=' .. surface .. ' guifg=' .. aqua .. ' gui=none'
  execute 'highlight ChopStatusMuted ctermbg=237 ctermfg=108 cterm=none guibg=' .. surface .. ' guifg=' .. muted .. ' gui=none'
  execute 'highlight ChopDashboardLogo ctermfg=109 cterm=none guifg=' .. blue .. ' gui=none'
  execute 'highlight ChopDashboardItem ctermfg=187 cterm=none guifg=' .. fg .. ' gui=none'
  execute 'highlight ChopDashboardIcon ctermfg=108 cterm=bold guifg=' .. aqua .. ' gui=bold'
  execute 'highlight ChopDashboardKey ctermfg=173 cterm=none guifg=' .. orange .. ' gui=none'
  execute 'highlight ChopDashboardCurrent ctermbg=237 cterm=none guibg=' .. surface .. ' gui=none'
  execute 'highlight ChopDashboardFooter ctermfg=180 cterm=italic guifg=' .. yellow .. ' gui=italic'
  execute 'highlight ChopDashboardStatus ctermbg=237 ctermfg=237 guibg=' .. surface .. ' guifg=' .. surface
  if TransparencyEnabled()
    highlight Normal ctermbg=NONE guibg=NONE
    highlight NormalNC ctermbg=NONE guibg=NONE
    highlight NonText ctermbg=NONE guibg=NONE
    highlight EndOfBuffer ctermbg=NONE guibg=NONE
    highlight SignColumn ctermbg=NONE guibg=NONE
  endif
enddef

export def Set(name: string): void
  g:chopsticks_colorscheme = name
  Apply()
  DefineInterfaceColors()
  redraw!
  echo 'theme: ' .. get(g:, 'colors_name', 'default')
enddef

export def ToggleTransparency(): void
  g:chopsticks_transparent_background = TransparencyEnabled() ? 0 : 1
  Apply()
  DefineInterfaceColors()
  redraw!
  echo 'background: ' .. (TransparencyEnabled() ? 'transparent' : 'opaque')
enddef
