vim9script

const DEBUGGERS = {
  rust: ['rust-gdb', 'gdb'],
  c: ['gdb'],
  cpp: ['gdb'],
  go: ['gdb'],
  }

def Debugger(filetype: string): string
  for candidate in DEBUGGERS->get(filetype, ['gdb'])
    if executable(candidate) == 1
      return candidate
    endif
  endfor
  return ''
enddef

def Warn(message: string)
  echohl WarningMsg
  echomsg 'chopsticks: ' .. message
  echohl None
enddef

export def Start(arguments: string)
  var debugger = Debugger(&filetype)
  if empty(debugger)
    Warn('debugging needs gdb; lldb speaks a protocol termdebug does not')
    return
  endif
  if exists(':Termdebug') != 2
    try
      packadd termdebug
    catch
      Warn('this Vim ships no termdebug package')
      return
    endtry
  endif
  if exists(':Termdebug') != 2
    Warn('this Vim ships no termdebug package')
    return
  endif
  g:termdebugger = debugger
  execute 'Termdebug' arguments
enddef
