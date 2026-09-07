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

export def Start(arguments: string)
  var debugger = Debugger(&filetype)
  if empty(debugger)
    echohl WarningMsg
    echomsg 'chopsticks: debugging needs gdb; lldb speaks a protocol termdebug '
      .. 'does not'
    echohl None
    return
  endif
  # Set every time rather than once at startup: the right debugger depends on
  # the buffer being debugged, and a session moves between languages.
  g:termdebugger = debugger
  if exists(':Termdebug') != 2
    packadd termdebug
  endif
  if exists(':Termdebug') != 2
    echohl WarningMsg
    echomsg 'chopsticks: this Vim ships no termdebug package'
    echohl None
    return
  endif
  execute 'Termdebug' arguments
enddef
