vim9script

import autoload 'chopsticks/session.vim'
import autoload 'chopsticks/ui/motion.vim'
import autoload 'chopsticks/ui/window.vim'

export def MakeParent(path: string)
  if empty(path) || &buftype !=# '' || path =~# '^\w\+://'
    return
  endif
  var directory = fnamemodify(path, ':h')
  if !isdirectory(directory)
    silent! mkdir(directory, 'p')
  endif
enddef

export def Save()
  if &buftype ==# '' && empty(bufname('%'))
    var name = input('Save as: ', '', 'file')
    if !empty(name)
      execute 'saveas ' .. fnameescape(name)
    endif
  else
    update
    if !&modified
      motion.Saved()
    endif
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

export def DeleteBuffer()
  var target = bufnr('%')
  if &buftype !=# ''
    execute 'bdelete ' .. target
    return
  endif
  if getbufvar(target, '&modified')
    echohl WarningMsg
    echomsg 'chopsticks: write or undo the changes first'
    echohl None
    return
  endif
  var files = getbufinfo({buflisted: 1})
    ->filter((_, b) => b.bufnr != target && getbufvar(b.bufnr, '&buftype') ==# '')
    ->mapnew((_, b) => b.bufnr)
  var alternate = index(files, bufnr('#')) >= 0 ? bufnr('#') : get(files, 0, -1)
  for window in win_findbuf(target)
    win_execute(window, alternate < 0 ? 'enew' : 'buffer ' .. alternate)
    alternate = alternate < 0 ? winbufnr(window) : alternate
  endfor
  execute 'bdelete ' .. target
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

export def Clip()
  if !empty(&clipboard)
    setreg('+', getreg('"', 1, 1), getregtype('"'))
    return
  endif
  var lines = getreg('"', 1, 1) + (getregtype('"') ==# 'V' ? [''] : [])
  echoraw("\e]52;c;" .. base64_encode(str2blob(lines)) .. "\x07")
enddef

export def YankOperator(type: string)
  var mode = type ==# 'line' ? "'[V']" : type ==# 'block' ? "`[\<C-v>`]" : '`[v`]'
  execute 'normal! ' .. mode .. 'y'
  Clip()
enddef

export def CopyPath(relative: bool)
  if empty(expand('%:p'))
    echohl WarningMsg
    echomsg 'chopsticks: current buffer has no file path'
    echohl None
    return
  endif
  var path = relative ? fnamemodify(expand('%:p'), ':.') : expand('%:p')
  setreg('"', path)
  Clip()
  var shown = relative ? path : fnamemodify(path, ':~')
  echo 'copied: ' .. (strwidth(shown) < &columns - 10 ? shown : pathshorten(shown))
enddef

export def Lazygit()
  window.Terminal(['lazygit', '--path', session.ProjectRoot()], 'tab')
enddef
