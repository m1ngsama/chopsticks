vim9script

def Available(): bool
  return exists(':FuzzyFiles') == 2
enddef

export def FindFiles()
  if Available()
    fuzzbox#Launch('files', {cwd: g:ChopsticksProjectRoot()})
  else
    execute 'edit' fnameescape(g:ChopsticksProjectRoot())
  endif
enddef

export def Grep(query: string)
  if !Available()
    echohl WarningMsg
    echomsg 'chopsticks: project grep needs fuzzbox'
    echohl None
    return
  endif
  fuzzbox#Launch('grep', {cwd: g:ChopsticksProjectRoot(), prompt_text: query})
enddef

export def GitFiles()
  if !Available()
    echohl WarningMsg
    echomsg 'chopsticks: Git file search needs fuzzbox'
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
  fuzzbox#Launch('files', {cwd: root, command: 'git ls-files'})
enddef

export def RecentFiles()
  if Available()
    fuzzbox#Launch('mru')
  elseif !empty(v:oldfiles)
    execute 'browse oldfiles'
  else
    echohl WarningMsg
    echomsg 'chopsticks: no recent files yet'
    echohl None
  endif
enddef
