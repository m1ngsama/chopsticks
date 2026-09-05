vim9script

# Duplicates .vimrc's s:FernAvailable(), which the two must keep agreeing on:
# Vim9 script-local names cannot cross files, and three lines beat a global.

import autoload 'chopsticks/ui/window.vim'
import autoload 'chopsticks/switch.vim'

def FernAvailable(): bool
  return switch.Truthy(get(g:, 'chopsticks_use_fern', 1))
    && exists(':Fern') == 2
enddef

const IS_WINDOWS = has('win32') || has('win64')

# Directory equality, not a string prefix: a sibling of $VIMRUNTIME whose
# name merely extends it (…/vim92-sibling/lang/x.vim) must not match.
# Windows normalises separators and compares case-insensitively, matching
# explorer.vim's PathInside().
def UnderVimRuntimeLang(file: string): bool
  var parent = fnamemodify(file, ':h')
  var target = $VIMRUNTIME .. '/lang'
  if IS_WINDOWS
    parent = substitute(parent, '\\', '/', 'g')
    target = substitute(target, '\\', '/', 'g')
    return parent ==? target
  endif
  return parent ==# target
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
  lines->extend(['', 'Language servers (on PATH; not verified to start)'])
  # $VIMRUNTIME ships its own lang/ full of menu_*.vim locale files that
  # otherwise swamp this section with irrelevant "no binary named" rows.
  for file in sort(globpath(&runtimepath, 'lang/*.vim', false, true)
      ->filter((_, val) => !UnderVimRuntimeLang(val)))
    var language = fnamemodify(file, ':t:r')
    var binary = matchstr(join(readfile(file), ' '), "exepath('\\zs[^']\\+")
    var path = empty(binary) ? '' : exepath(binary)
    lines->add(printf('[%s] %-14s %s',
      empty(path) ? '--' : 'ok', language,
      empty(path) ? (empty(binary) ? 'no binary named' : binary .. ' not installed')
        : 'on PATH: ' .. path))
  endfor
  lines->extend([
    '',
    'Run :PlugInstall for missing plugins.',
    'A server on PATH may still fail to start; run :LspShowAllServers to check.',
    'Press q to close.',
    ])
  return lines
enddef

export def Show(): void
  window.Scratch('[chopsticks-health]', Lines())
enddef
