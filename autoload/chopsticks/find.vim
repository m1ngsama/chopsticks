vim9script

export def FindFiles()
  fuzzbox#Launch('files', {cwd: g:ChopsticksProjectRoot()})
enddef

export def Grep(query: string)
  fuzzbox#Launch('grep', {cwd: g:ChopsticksProjectRoot(), prompt_text: query})
enddef

export def GitFiles()
  var root = g:ChopsticksProjectRoot()
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
