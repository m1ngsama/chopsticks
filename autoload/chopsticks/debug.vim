vim9script

# termdebug ships with Vim but is not loaded until :packadd, and it speaks
# GDB/MI: only gdb and gdb-compatible front ends work, which is why lldb is
# never chosen here however available it is on macOS.

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
  # Inside try/catch because :packadd raises E919 on a Vim built without the
  # package, and an error in a :def aborts the function -- the check below it
  # would never be reached, and the user would read E919 instead of a sentence.
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
  # Last, so that every path that gives up leaves this unset: the no-debugger
  # path is asserted on exactly that.
  g:termdebugger = debugger
  execute 'Termdebug' arguments
enddef
