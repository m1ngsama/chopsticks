vim9script

# Finding files and text, through fzf when it is available and degrading to
# Vim's own commands when it is not.
#
# Every entry point checks for fzf and its plugin before using them, so the
# same keys keep working on a machine with neither. The project root, not the
# working directory, is what these search: g:ChopsticksProjectRoot() resolves
# it from the current buffer, so :ChopsticksFindFiles finds the same files
# whichever file you happen to have open.
#
# fzf#vim#... names are autoload-style, so Vim resolves them at call time and
# they can appear literally even where fzf.vim is absent. Plain COMMANDS
# cannot: Vim9 resolves a command name when the :def is compiled, so :History
# and friends go through :execute or this module would fail to compile
# wherever fzf.vim is not installed.

import autoload 'chopsticks/ui/icons.vim'

const ABORT_KEYS = 'esc:abort,ctrl-c:abort,ctrl-g:abort,ctrl-q:abort'

# Directories never worth walking: version control, package caches, build
# output, and virtualenvs.
const SKIP_DIRS = [
  '.git', '.cache', '.cargo', '.npm', '.pnpm-store', '.rustup',
  '.bun', '.codex', 'Library', 'node_modules', 'plugged',
  '.venv', 'venv', '__pycache__', 'build', 'dist', 'target', 'vendor',
]

export def AbortKeys(): string
  return ABORT_KEYS
enddef

# The icon-bearing half of fzf's appearance. Re-read on an icon toggle rather
# than baked in once, which is why it is a function and not a constant.
export def VisualOptions(): list<string>
  return [
    '--prompt', icons.Get('search') .. ' ',
    '--pointer', icons.Get('pointer'),
    '--marker', icons.Get('marker'),
  ]
enddef

# fd first, ripgrep second, and fzf's own default when neither is installed.
def FileSource(): string
  if executable('fd') == 1
    var parts = ['fd', '--type', 'f', '--hidden', '--color', 'never']
    for directory in SKIP_DIRS
      extend(parts, ['--exclude', shellescape(directory)])
    endfor
    return join(parts, ' ')
  endif
  if executable('rg') == 1
    var parts = ['rg', '--files', '--hidden', '--color', 'never']
    for directory in SKIP_DIRS
      extend(parts, ['--glob', shellescape('!**/' .. directory .. '/**')])
    endfor
    return join(parts, ' ')
  endif
  return ''
enddef

export def Files(path: string, bang: bool)
  var root = fnamemodify(
    empty(path) ? g:ChopsticksProjectRoot() : expand(path), ':p')
  var options = [
    '--bind', ABORT_KEYS,
    '--header', icons.Get('quit') .. ' ESC / CTRL-Q close · ENTER open',
  ]
  extend(options, VisualOptions())
  var spec = {dir: root, options: options}
  var source = FileSource()
  if !empty(source)
    spec.source = source
  endif
  fzf#vim#files(root, fzf#vim#with_preview(spec), bang)
enddef

# Searches stay rooted at the project even when the window's directory is
# elsewhere; tests/ui.vim asserts this does not change the working directory.
export def ProjectSpec(): dict<string>
  return {dir: g:ChopsticksProjectRoot()}
enddef

export def Grep(query: string, bang: bool)
  if exists(':Rg') != 2 || executable('rg') != 1 || executable('fzf') != 1
    echohl WarningMsg
    echomsg 'chopsticks: project grep needs fzf.vim and rg'
    echohl None
    return
  endif
  var command = 'rg --column --line-number --no-heading '
    .. '--color=always --smart-case -- ' .. fzf#shellescape(query)
  fzf#vim#grep(command, fzf#vim#with_preview(ProjectSpec()), bang)
enddef

export def GitFiles()
  if exists(':GFiles') != 2 || executable('git') != 1 || executable('fzf') != 1
    echohl WarningMsg
    echomsg 'chopsticks: Git file search needs Git and fzf.vim'
    echohl None
    return
  endif
  var root = g:ChopsticksProjectRoot()
  system('git -C ' .. shellescape(root) .. ' rev-parse --is-inside-work-tree')
  if v:shell_error != 0
    echohl WarningMsg
    echomsg 'chopsticks: current buffer is outside a Git worktree'
    echohl None
    return
  endif
  fzf#vim#gitfiles('', fzf#vim#with_preview(ProjectSpec()), 0)
enddef

# Prefer Git's file list inside a worktree, fzf's walk outside one, and a
# plain :edit of the root when fzf is missing entirely.
export def FindFiles()
  if executable('fzf') == 1 && exists(':GFiles') == 2 && executable('git') == 1
    var root = g:ChopsticksProjectRoot()
    system('git -C ' .. shellescape(root) .. ' rev-parse --is-inside-work-tree')
    if v:shell_error == 0
      GitFiles()
      return
    endif
  endif
  if executable('fzf') == 1 && exists(':Files') == 2
    execute 'Files ' .. fnameescape(g:ChopsticksProjectRoot())
    return
  endif
  execute 'edit ' .. fnameescape(g:ChopsticksProjectRoot())
enddef

export def RecentFiles()
  if executable('fzf') == 1 && exists(':History') == 2
    execute 'History'
  elseif !empty(v:oldfiles)
    execute 'browse oldfiles'
  else
    echohl WarningMsg
    echomsg 'chopsticks: no recent files yet'
    echohl None
  endif
enddef

# Replace fzf.vim's :Files with one that searches the project root and uses
# the source and appearance above. Only when fzf.vim actually defined it.
export def DefineCommands()
  if executable('fzf') == 1 && exists(':Files') == 2
    command! -bang -nargs=? -complete=dir Files
      \ chopsticks#find#Files(<q-args>, <bang>0)
  endif
enddef
