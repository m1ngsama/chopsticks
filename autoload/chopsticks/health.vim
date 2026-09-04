vim9script

# The :ChopsticksHealth report, backing ChopsticksHealthLines() (a
# documented public global, see plugin/chopsticks.vim) and the
# :ChopsticksHealth command.
#
# Lines() reads a wide slice of global state and other Chopsticks* globals.
# .vimrc still defines ChopsticksIconsEnabled(), ChopsticksIcon(),
# ChopsticksUiDensity(), ChopsticksTransparencyEnabled(),
# ChopsticksDashboardEnabled(), and ChopsticksBufferlineEnabled() at global
# scope -- they have not moved yet -- so they are called here with an
# explicit g: prefix: unlike .vimrc's own legacy-script calls, a Vim9 def
# only resolves an unqualified name to a script-local function or a Vim
# builtin, never to a global one.
#
# FernAvailable() duplicates a small, self-contained .vimrc helper
# (s:FernAvailable()), because Vim9 script-local names cannot cross files
# and reproducing three lines beats inventing a global for them. The scratch
# buffer used to be duplicated here too; it now comes from
# autoload/chopsticks/ui/window.vim, which the cheatsheet and the Markdown
# help sheet share.
#
# g:chopsticks_use_fern is read raw here, exactly like .vimrc's own
# s:FernAvailable() reads it: .vimrc never runs it through s:ResolveSwitch()
# (unlike g:chopsticks_auto_lint, g:chopsticks_dashboard, and friends), so it
# holds whatever type and value the user last assigned. Legacy `&&`/`if`
# coerce any Number or String to a boolean without erroring (a String is
# truthy iff str2nr() on it is nonzero, matching .vimrc's own && exactly);
# Vim9's `&&`, `||`, and `if`/`?:` raise E1023 (Number) or E1135 (String) on
# anything that is not already exactly 0, 1, true, or false. switch.Truthy()
# reproduces the legacy coercion so a value that s:FernAvailable() and this
# function must keep agreeing on (say, 2 or 'no') is handled the same way
# here as there, instead of throwing.

import autoload 'chopsticks/ui/window.vim'
import autoload 'chopsticks/switch.vim'

def FernAvailable(): bool
  return switch.Truthy(get(g:, 'chopsticks_use_fern', 1))
    && exists(':Fern') == 2
enddef

export def Lines(): list<string>
  var requested_theme = type(g:chopsticks_colorscheme) == type('')
    && !empty(g:chopsticks_colorscheme)
    ? g:chopsticks_colorscheme : 'everforest'
  var lines = [
    'chopsticks ' .. g:chopsticks_version .. ' health',
    '',
    printf('[ok] Vim %d.%d (%s)', v:version / 100, v:version % 100,
      has('gui_running') ? 'GUI' : 'terminal'),
    printf('[%s] +job +channel +timers +popupwin +terminal',
      has('job') && has('channel') && has('timers')
        && exists('*popup_create') && has('terminal') ? 'ok' : '!!'),
    '',
    'Interface',
    printf('[%s] %-14s %s',
      !g:ChopsticksIconsEnabled()
        || strwidth(g:ChopsticksIcon('file')) == 1 ? 'ok' : '!!',
      'icons', g:ChopsticksIconsEnabled()
        ? 'Nerd Font (' .. g:ChopsticksIcon('file') .. ' sample)'
        : 'ASCII fallback'),
    printf('[ok] %-14s %s', 'explorer',
      FernAvailable() ? 'Fern drawer' : 'netrw fallback'),
    printf('[ok] %-14s %s', 'UI density', g:ChopsticksUiDensity()),
    printf('[ok] %-14s %s', 'theme',
      get(g:, 'colors_name', 'default')
      .. (get(g:, 'colors_name', 'default') ==# requested_theme
        ? '' : ' (fallback from ' .. requested_theme .. ')')),
    printf('[ok] %-14s %s', 'background',
      g:ChopsticksTransparencyEnabled() ? 'transparent' : 'opaque'),
    printf('[ok] %-14s %s', 'dashboard',
      g:ChopsticksDashboardEnabled() ? 'enabled' : 'disabled'),
    printf('[ok] %-14s %s', 'bufferline',
      g:ChopsticksBufferlineEnabled() ? 'visible' : 'adaptive / hidden'),
    printf('[ok] %-14s %s', 'linting',
      g:chopsticks_auto_lint
        ? 'automatic on enter and save'
        : 'manual (,l / :ALELint)'),
    printf('[%s] %-14s %s',
      g:ChopsticksSystemClipboardEnabled() ? 'ok' : '--',
      'clipboard', !has('clipboard') ? 'Vim lacks +clipboard'
        : g:ChopsticksSystemClipboardEnabled()
          ? 'system register' : 'Vim registers only'),
    printf('[%s] %-14s %s',
      filereadable(g:ChopsticksSessionPath()) ? 'ok' : '--',
      'session', filereadable(g:ChopsticksSessionPath())
        ? fnamemodify(g:ChopsticksSessionPath(), ':t') : 'not saved'),
    '',
    'Tools',
    ]
  for tool in ['git', 'rg', 'fzf', 'fd', 'lazygit', 'marksman',
      'markdownlint', 'prettier', 'glow', 'pandoc', 'pngpaste']
    var available = executable(tool) == 1
    lines->add(printf('[%s] %-14s %s',
      available ? 'ok' : '--', tool,
      available ? exepath(tool) : 'optional / missing'))
  endfor
  lines->extend(['', 'Plugins'])
  if exists('g:plugs')
    var missing: list<string> = []
    for name in sort(keys(g:plugs))
      var dir = get(g:plugs[name], 'dir', '')
      if empty(dir) || !isdirectory(dir)
        missing->add(name)
      endif
    endfor
    lines->add(empty(missing)
      ? '[ok] all declared plugins installed'
      : '[!!] missing: ' .. join(missing, ', '))
  else
    lines->add('[--] vim-plug is not installed')
  endif
  lines->extend([
    '',
    'Run :PlugInstall for missing plugins.',
    'Run :LspStatus in a source buffer to inspect language servers.',
    'Press q to close.',
    ])
  return lines
enddef


export def Show(): void
  window.Scratch('[chopsticks-health]', Lines())
enddef
