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
# FernAvailable() and OpenScratch() duplicate two small, self-contained
# .vimrc helpers (s:FernAvailable() and s:OpenScratch()). s:OpenScratch() in
# particular is shared with the cheatsheet and markdown-image features, so
# it stays in .vimrc; Vim9 script-local names cannot cross files, so the
# small amount of logic actually needed here is reproduced instead of
# reaching back into .vimrc.

def FernAvailable(): bool
  return get(g:, 'chopsticks_use_fern', 1) && exists(':Fern') == 2
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

def OpenScratch(name: string, lines: list<string>): void
  botright new
  execute 'file ' .. fnameescape(name)
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal nowrap nonumber norelativenumber signcolumn=no
  setlocal modifiable
  silent :%delete _
  setline(1, lines)
  setlocal nomodifiable nomodified
  nnoremap <silent><buffer> q :close<CR>
  nnoremap <silent><buffer> <Esc> :close<CR>
  normal! gg
enddef

export def Show(): void
  OpenScratch('[chopsticks-health]', Lines())
enddef
