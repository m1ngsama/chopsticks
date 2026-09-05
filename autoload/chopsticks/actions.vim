vim9script

# Key-bound actions each too small for a module of its own.

import autoload 'chopsticks/ui/window.vim'

# So `:e src/new/x.txt` saves into a directory that does not exist yet. The URL
# guard is for the paths netrw and fugitive produce.
export def MakeParent(path: string)
  if empty(path) || &buftype !=# '' || path =~# '^\w\+://'
    return
  endif
  var directory = fnamemodify(path, ':h')
  if !isdirectory(directory)
    silent! mkdir(directory, 'p')
  endif
enddef

export def ToggleQuickfix()
  for window in getwininfo()
    if get(window, 'quickfix', 0) && !get(window, 'loclist', 0)
      cclose
      return
    endif
  endfor
  copen
enddef

export def ToggleLocationList()
  for window in getwininfo()
    if get(window, 'quickfix', 0) && get(window, 'loclist', 0)
      lclose
      return
    endif
  endfor
  try
    lopen
  catch /^Vim\%((\a\+)\)\=:E776/
    echohl WarningMsg
    echomsg 'chopsticks: location list is empty'
    echohl None
  endtry
enddef

export def DeleteOtherBuffers()
  var current = bufnr('%')
  var deleted = 0
  var kept = 0
  for buffer in getbufinfo({buflisted: 1})
    if buffer.bufnr == current
      continue
    endif
    if getbufvar(buffer.bufnr, '&modified')
      kept += 1
      continue
    endif
    execute 'silent bdelete ' .. buffer.bufnr
    deleted += 1
  endfor
  echo printf('buffers: deleted %d, kept %d modified', deleted, kept)
enddef

export def CopyPath(relative: bool)
  if empty(expand('%:p'))
    echohl WarningMsg
    echomsg 'chopsticks: current buffer has no file path'
    echohl None
    return
  endif
  var path = relative ? fnamemodify(expand('%:p'), ':.') : expand('%:p')
  if has('clipboard')
    setreg('+', path)
  endif
  setreg('"', path)
  echo 'copied: ' .. path
enddef

export def Lazygit()
  if executable('lazygit') != 1
    echohl WarningMsg
    echomsg 'chopsticks: lazygit is not installed'
    echohl None
    return
  endif
  window.Terminal(['lazygit', '--path', g:ChopsticksProjectRoot()], 'tab')
enddef
