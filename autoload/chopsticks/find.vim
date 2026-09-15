vim9script

import autoload 'chopsticks/session.vim'

export def FindFiles()
  fuzzbox#Launch('files', {cwd: session.ProjectRoot()})
enddef

export def Grep(query: string)
  fuzzbox#Launch('grep', {cwd: session.ProjectRoot(), prompt_text: query})
enddef

export def GitFiles()
  var root = session.ProjectRoot()
  system('git -C ' .. shellescape(root) .. ' rev-parse --is-inside-work-tree')
  if v:shell_error != 0
    echohl WarningMsg
    echomsg 'chopsticks: current buffer is outside a Git worktree'
    echohl None
    return
  endif
  fuzzbox#Launch('files', {cwd: root, command: 'git ls-files'})
enddef

export def RecentFiles()
  fuzzbox#Launch('mru')
enddef
